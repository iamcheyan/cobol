#!/usr/bin/env python3
"""End-to-end contract checks for the module 05 cleansing lab."""
from pathlib import Path
import hashlib
import os
import stat
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[2]
INSTRUCTOR = REPO / "instructor/modules/05-control/CLEANSE.COB"

# (fixture, expected RC, expected report name or None)
CASES = [
    ("normal/clean.dat", 0, "normal-clean.txt"),
    ("boundary/empty.dat", 0, "boundary-empty.txt"),
    ("boundary/min-amount.dat", 0, "boundary-min-amount.txt"),
    ("boundary/max-amount.dat", 0, "boundary-max-amount.txt"),
    ("boundary/single.dat", 0, "boundary-single.txt"),
    ("invalid/amount-over-cap.dat", 4, "invalid-amount-over-cap.txt"),
    ("invalid/bad-id.dat", 4, "invalid-bad-id.txt"),
    ("invalid/duplicate-id.dat", 4, "invalid-duplicate-id.txt"),
    ("invalid/missing-name.dat", 4, "invalid-missing-name.txt"),
    ("invalid/mixed.dat", 4, "invalid-mixed.txt"),
    ("invalid/non-numeric-amount.dat", 4,
     "invalid-non-numeric-amount.txt"),
    ("invalid/unknown-status.dat", 4, "invalid-unknown-status.txt"),
    ("invalid/unsorted.dat", 8, None),
    ("invalid/short-record.dat", 8, None),
    ("invalid/long-record.dat", 8, None),
    ("invalid/no-trailing-lf.dat", 8, None),
    ("invalid/crlf.dat", 8, None),
]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed_lf_records(path: Path, width: int) -> list[bytes]:
    data = path.read_bytes()
    records = data.split(b"\n")
    assert records[-1] == b"", f"missing final LF: {path}"
    records.pop()
    assert all(len(row) == width and b"\r" not in row for row in records), path
    return records


def run_case(relative: str, rc: int, expected_name: str | None,
             business_date: str = "20261009") -> None:
    fixture = LAB / "fixtures" / relative
    with tempfile.TemporaryDirectory(prefix="bank-cleanse-check-") as tmp:
        root = Path(tmp)
        output = root / ("output with spaces" if expected_name and
                         "mixed" in expected_name else "published")
        before = digest(fixture)
        cmd = ["bash", str(LAB / "scripts/run.sh"), str(fixture),
               str(output), business_date]
        proc = subprocess.run(cmd, cwd=tmp, text=True, capture_output=True)
        assert proc.returncode == rc, (relative, proc.returncode,
                                       proc.stdout, proc.stderr)
        assert digest(fixture) == before, "run changed an original fixture"
        if rc in (8, 12):
            assert not output.exists(), "failed run published an output"
            assert proc.stdout == ""
            return
        assert output.is_dir(), proc.stderr
        expected_text = (LAB / "expected" / expected_name).read_text()
        actual_text = (output / "report.txt").read_text()
        assert actual_text == expected_text, f"{relative}\n{actual_text}"

        rows = [row.split("|") for row in expected_text.splitlines()
                if row.startswith("CUST|")]
        control = [row for row in expected_text.splitlines()
                   if row.startswith("CONTROL|")][0].split("|")
        records = fixed_lf_records(fixture, 27)
        assert len(records) == len(rows), (relative, len(records), len(rows))
        accepted: list[bytes] = []
        rejected: list[bytes] = []
        amount = 0
        for record, row in zip(records, rows):
            assert record[:8].decode("ascii") == row[1], relative
            if row[2] == "ACCEPT":
                status = chr(record[26]).upper().encode("ascii")
                accepted.append(record[:26] + status + b"\n")
                amount += int(row[4])
            else:
                rejected.append(record + b"|" +
                                row[3].encode("ascii") + b"\n")
        assert (output / "accepted.dat").read_bytes() == b"".join(accepted)
        assert (output / "rejected.dat").read_bytes() == b"".join(rejected)
        counts = dict(item.split("=", 1) for item in control[1:])
        assert int(counts["READ"]) == len(records)
        assert int(counts["ACCEPT"]) == len(accepted)
        assert int(counts["REJECT"]) == len(rejected)
        assert int(counts["AMOUNT"]) == amount
        assert len(records) == len(accepted) + len(rejected)
        assert (output / "customer.input.dat").read_bytes() == \
            fixture.read_bytes()
        for manifest in ("inputs.sha256", "outputs.sha256"):
            verified = subprocess.run(["sha256sum", "-c", manifest],
                                      cwd=output, text=True,
                                      capture_output=True)
            assert verified.returncode == 0, verified.stdout + verified.stderr
        assert proc.stdout == "PASS: business and control totals verified\n"


def check_protection() -> None:
    fixture = LAB / "fixtures" / "normal" / "clean.dat"
    base = ["bash", str(LAB / "scripts" / "run.sh"), str(fixture)]
    with tempfile.TemporaryDirectory(prefix="bank-cleanse-protect-") as temp:
        root = Path(temp)
        existing = root / "existing"
        existing.mkdir()
        sentinel = existing / "keep.txt"
        sentinel.write_text("preserve\n")
        failed = subprocess.run(base + [str(existing), "20261009"],
                                text=True, capture_output=True)
        assert failed.returncode == 12 and sentinel.read_text() == "preserve\n"

        missing = root / "nope.dat"
        absent = subprocess.run(["bash", str(LAB / "scripts" / "run.sh"),
                                 str(missing), str(root / "out"), "20261009"],
                                text=True, capture_output=True)
        assert absent.returncode == 12 and not (root / "out").exists()

        target = root / "locked"
        lock = Path(str(target) + ".lock")
        lock.mkdir()
        marker = lock / "owner"
        marker.write_text("another run owns this lock\n")
        locked = subprocess.run(base + [str(target), "20261009"],
                                text=True, capture_output=True)
        assert locked.returncode == 12 and marker.exists()
        assert not target.exists()

        concurrent = root / "concurrent output"
        commands = base + [str(concurrent), "20261009"]
        first = subprocess.Popen(commands, text=True, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
        second = subprocess.Popen(commands, text=True, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE)
        p1 = first.communicate()
        p2 = second.communicate()
        assert sorted((first.returncode, second.returncode)) == [0, 12], (
            p1, p2)
        assert (concurrent / "report.txt").read_text() == (
            LAB / "expected" / "normal-clean.txt").read_text()
        assert not Path(str(concurrent) + ".lock").exists()


def check_bad_date() -> None:
    fixture = LAB / "fixtures" / "normal" / "clean.dat"
    with tempfile.TemporaryDirectory(prefix="bank-cleanse-date-") as temp:
        root = Path(temp)
        malformed = subprocess.run(
            ["bash", str(LAB / "scripts" / "run.sh"), str(fixture),
             str(root / "a"), "2026-1-1"], text=True, capture_output=True)
        assert malformed.returncode == 8 and not (root / "a").exists()
        impossible = subprocess.run(
            ["bash", str(LAB / "scripts" / "run.sh"), str(fixture),
             str(root / "b"), "20260230"], text=True, capture_output=True)
        assert impossible.returncode == 8 and not (root / "b").exists()


def check_build_and_reset() -> None:
    with tempfile.TemporaryDirectory(prefix="bank-cleanse-build-") as temp:
        root = Path(temp)
        binary = root / "cleanse"
        build = subprocess.run(["bash", str(LAB / "scripts/build.sh"),
                                str(binary)], text=True, capture_output=True)
        assert build.returncode == 0 and binary.is_file(), build.stderr
        broken = root / "broken.COB"
        broken.write_text("not COBOL\n")
        failed_target = root / "must-not-exist"
        failed_build = subprocess.run(
            ["bash", str(LAB / "scripts/build.sh"), str(failed_target),
             str(broken)], text=True, capture_output=True)
        assert failed_build.returncode == 12 and not failed_target.exists()

        unmarked = root / "keep"
        unmarked.mkdir()
        marker = unmarked / "important.txt"
        marker.write_text("keep\n")
        refused = subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                                  str(unmarked)], text=True,
                                 capture_output=True)
        assert refused.returncode == 12 and marker.read_text() == "keep\n"

        output = root / "course-output"
        fixture = LAB / "fixtures" / "normal" / "clean.dat"
        run = subprocess.run(["bash", str(LAB / "scripts/run.sh"),
                              str(fixture), str(output), "20261009"],
                             text=True, capture_output=True)
        assert run.returncode == 0 and output.is_dir()
        verifier = ["python3", str(LAB / "scripts" / "verify-publish.py"),
                    str(output / "customer.input.dat"),
                    str(output / "report.txt"), str(output / "accepted.dat"),
                    str(output / "rejected.dat")]
        assert subprocess.run(verifier, text=True,
                              capture_output=True).returncode == 0
        report_file = output / "report.txt"
        report_bytes = report_file.read_bytes()
        report_file.write_bytes(report_bytes.replace(
            b"CONTROL|BUSINESS-DATE=20261009|READ=000000003",
            b"CONTROL|BUSINESS-DATE=20261009|READ=000000004", 1))
        assert subprocess.run(verifier, text=True,
                              capture_output=True).returncode == 12
        report_file.write_bytes(report_bytes)
        accepted_file = output / "accepted.dat"
        accepted_bytes = accepted_file.read_bytes()
        accepted_file.write_bytes(accepted_bytes[:-1])
        assert subprocess.run(verifier, text=True,
                              capture_output=True).returncode == 12
        accepted_file.write_bytes(accepted_bytes.replace(b"\n", b"\r\n", 1))
        assert subprocess.run(verifier, text=True,
                              capture_output=True).returncode == 12
        accepted_file.write_bytes(accepted_bytes)

        reset = subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                                str(output)], text=True, capture_output=True)
        assert reset.returncode == 0 and not output.exists(), reset.stderr


def check_starter() -> None:
    # RED state is an authoring invariant: it needs the pristine starter to
    # ship next to the reference.  A student bundle has no instructor/ and the
    # learner is expected to complete the starter, so skip it there.
    if not INSTRUCTOR.exists():
        return
    fixture = LAB / "fixtures" / "normal" / "clean.dat"
    with tempfile.TemporaryDirectory(prefix="bank-cleanse-starter-") as temp:
        output = Path(temp) / "starter-out"
        env = dict(os.environ,
                   COURSE_SOURCE=str(LAB / "starter" / "CLEANSE.COB"))
        run = subprocess.run(["bash", str(LAB / "scripts/run.sh"),
                              str(fixture), str(output), "20261009"],
                             env=env, text=True, capture_output=True)
        assert run.returncode == 12 and not output.exists(), run.stderr


def check_probes() -> None:
    with tempfile.TemporaryDirectory(prefix="bank-cleanse-probe-") as temp:
        root = Path(temp)
        lang = root / "lang"
        subprocess.run(["cobc", "-Wall", "-x", "-o", str(lang),
                        str(LAB / "scripts" / "language-probe.COB")],
                       check=True)
        (root / "map.txt").write_text("a=ACTIVE\nd=DISABLED\nx=UNKNOWN\n")
        (root / "names.txt").write_text(
            "00000001,_Alice_,a\n00000002,Bob,d\n00000003,_Carol_,q\n")
        env = dict(os.environ, MAP_FILE=str(root / "map.txt"),
                   NAME_FILE=str(root / "names.txt"))
        probe = subprocess.run([str(lang)], env=env, text=True,
                               capture_output=True)
        assert probe.returncode == 0, probe.stderr
        lines = probe.stdout.splitlines()
        expected = ["NORM|00000001|Alice|ACTIVE",
                    "NORM|00000002|Bob|DISABLED",
                    "NORM|00000003|Carol|UNMAPPED"]
        assert lines == expected, lines

        sall = root / "sall"
        subprocess.run(["cobc", "-Wall", "-x", "-o", str(sall),
                        str(LAB / "scripts" / "search-all-probe.COB")],
                       check=True)
        sall_run = subprocess.run([str(sall)], text=True, capture_output=True)
        assert sall_run.returncode == 0, sall_run.stderr
        assert sall_run.stdout.splitlines() == ["SORTED=FOUND", "UNSORTED=MISS"]


def check_control_flow() -> None:
    """Lesson 05.1: PERFORM VARYING, inline PERFORM, scope, fall-through."""
    with tempfile.TemporaryDirectory(prefix="bank-cleanse-flow-") as temp:
        root = Path(temp)
        probe = root / "flow"
        subprocess.run(["cobc", "-Wall", "-x", "-o", str(probe),
                        str(LAB / "scripts" / "control-flow-probe.COB")],
                       check=True)
        flow = subprocess.run([str(probe)], text=True, capture_output=True)
        assert flow.returncode == 0, flow.stderr
        assert flow.stdout.splitlines() == [
            "VARYING=15",      # PERFORM VARYING 1..5
            "INLINE=20",       # inline PERFORM 2 TIMES
            "FIRST",           # PERFORM 2000-FIRST: scope stops at paragraph
            "SCOPE-DONE",
            "FIRST",           # PERFORM ... THRU falls into the next paragraph
            "SECOND",
            "THRU-DONE",
        ], flow.stdout


def check_full_device_fail_closed() -> None:
    full = Path("/dev/full")
    if not full.exists() or not stat.S_ISCHR(full.stat().st_mode):
        return
    if not INSTRUCTOR.exists():
        return
    source = INSTRUCTOR.read_text()
    fixture = LAB / "fixtures" / "normal" / "clean.dat"
    with tempfile.TemporaryDirectory(prefix="bank-cleanse-full-") as temp:
        root = Path(temp)
        for name, variable in (("accepted", "ACCEPT_OUTPUT_FILE"),
                               ("rejected", "REJECT_OUTPUT_FILE")):
            failed_source = root / f"full-{name}.COB"
            failed_source.write_text(source.replace(
                f"           ACCEPT {'OK-PATH' if name == 'accepted' else 'RJ-PATH'} "
                f"FROM ENVIRONMENT '{variable}'",
                f"           MOVE '/dev/full' TO "
                f"{'OK-PATH' if name == 'accepted' else 'RJ-PATH'}"))
            target = root / f"must-not-publish-{name}"
            env = dict(os.environ, COURSE_SOURCE=str(failed_source))
            run = subprocess.run(["bash", str(LAB / "scripts" / "run.sh"),
                                  str(fixture), str(target), "20261009"],
                                 env=env, text=True, capture_output=True)
            assert run.returncode == 12 and not target.exists(), (
                name, run.returncode, run.stderr)


def check_source_format() -> None:
    sources = [LAB / "starter" / "CLEANSE.COB",
               LAB / "scripts" / "language-probe.COB",
               LAB / "scripts" / "search-all-probe.COB",
               LAB / "scripts" / "control-flow-probe.COB",
               LAB / "copybooks" / "CUSTOMER-V1.CPY"]
    if INSTRUCTOR.exists():
        sources.insert(0, INSTRUCTOR)
    for source in sources:
        for number, line in enumerate(source.read_text().splitlines(), 1):
            assert line.isascii(), (source, number, "non-ASCII")
            assert len(line) <= 72, (source, number, "beyond column 72")
            assert "\t" not in line, (source, number, "tab")


def main() -> None:
    check_source_format()
    manifest = subprocess.run(["sha256sum", "-c", "SHA256SUMS"],
                              cwd=LAB / "fixtures", text=True,
                              capture_output=True)
    assert manifest.returncode == 0, manifest.stdout + manifest.stderr
    for relative, rc, expected in CASES:
        run_case(relative, rc, expected)
    check_protection()
    check_bad_date()
    check_build_and_reset()
    check_starter()
    check_probes()
    check_control_flow()
    check_full_device_fail_closed()
    print("PASS: module 05 cleanse normal, boundary and invalid contracts")


if __name__ == "__main__":
    main()
