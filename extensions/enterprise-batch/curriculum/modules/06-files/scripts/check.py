#!/usr/bin/env python3
"""End-to-end contract checks for the module 06 file-validation lab."""
from pathlib import Path
import hashlib
import os
import select
import stat
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[2]
INSTRUCTOR = REPO / "instructor/modules/06-files/FILEVAL.COB"

CASES = [
    ("normal/valid.dat", 0, "normal-valid.txt"),
    ("boundary/empty.dat", 0, "boundary-empty.txt"),
    ("boundary/single.dat", 0, "boundary-single.txt"),
    ("boundary/negative-balance.dat", 0, "boundary-negative-balance.txt"),
    ("boundary/zero-balance.dat", 0, "boundary-zero-balance.txt"),
    ("invalid/bad-account-id.dat", 4, "invalid-bad-account-id.txt"),
    ("invalid/bad-customer-id.dat", 4, "invalid-bad-customer-id.txt"),
    ("invalid/unknown-currency.dat", 4, "invalid-unknown-currency.txt"),
    ("invalid/bad-sign.dat", 4, "invalid-bad-sign.txt"),
    ("invalid/bad-balance.dat", 4, "invalid-bad-balance.txt"),
    ("invalid/bad-date.dat", 4, "invalid-bad-date.txt"),
    ("invalid/date-mismatch.dat", 4, "invalid-date-mismatch.txt"),
    ("invalid/unknown-status.dat", 4, "invalid-unknown-status.txt"),
    ("invalid/duplicate-id.dat", 4, "invalid-duplicate-id.txt"),
    ("invalid/mixed.dat", 4, "invalid-mixed.txt"),
    ("invalid/bad-layout.dat", 8, None),
    ("invalid/unsorted.dat", 8, None),
    ("invalid/short-record.dat", 8, None),
    ("invalid/long-record.dat", 8, None),
    ("invalid/no-trailing-lf.dat", 8, None),
    ("invalid/crlf.dat", 8, None),
]

FILESTATUS = "OPEN|ACCOUNT|00\nEOF|ACCOUNT|10\n"


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
    with tempfile.TemporaryDirectory(prefix="bank-fileval-check-") as tmp:
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
        assert (output / "report.txt").read_text() == expected_text
        assert (output / "filestatus.log").read_text() == FILESTATUS

        rows = [row.split("|") for row in expected_text.splitlines()
                if row.startswith("ACCT|")]
        control = [row for row in expected_text.splitlines()
                   if row.startswith("CONTROL|")][0].split("|")
        records = fixed_lf_records(fixture, 47)
        assert len(records) == len(rows), (relative, len(records), len(rows))
        accepted: list[bytes] = []
        rejected: list[bytes] = []
        balance = 0
        for record, row in zip(records, rows):
            assert record[:10].decode("ascii") == row[1], relative
            if row[2] == "ACCEPT":
                accepted.append(record + b"\n")
                sign = -1 if record[21:22] == b"-" else 1
                balance += sign * int(record[22:35])
            else:
                rejected.append(record + b"|" +
                                row[3].encode("ascii") + b"\n")
        assert (output / "accepted.dat").read_bytes() == b"".join(accepted)
        assert (output / "rejected.dat").read_bytes() == b"".join(rejected)
        counts = dict(item.split("=", 1) for item in control[1:])
        assert int(counts["READ"]) == len(records)
        assert int(counts["ACCEPT"]) == len(accepted)
        assert int(counts["REJECT"]) == len(rejected)
        assert int(counts["BALANCE"][1:]) * (-1 if counts["BALANCE"][0] == "-"
                                             else 1) == balance
        assert len(records) == len(accepted) + len(rejected)
        assert (output / "account.input.dat").read_bytes() == \
            fixture.read_bytes()
        for manifest in ("inputs.sha256", "outputs.sha256"):
            verified = subprocess.run(["sha256sum", "-c", manifest],
                                      cwd=output, text=True,
                                      capture_output=True)
            assert verified.returncode == 0, verified.stdout + verified.stderr
        assert proc.stdout == "PASS: file contract and control totals verified\n"


def check_protection() -> None:
    fixture = LAB / "fixtures" / "normal" / "valid.dat"
    base = ["bash", str(LAB / "scripts" / "run.sh"), str(fixture)]
    with tempfile.TemporaryDirectory(prefix="bank-fileval-protect-") as temp:
        root = Path(temp)
        existing = root / "existing"
        existing.mkdir()
        sentinel = existing / "keep.txt"
        sentinel.write_text("preserve\n")
        failed = subprocess.run(base + [str(existing), "20261009"],
                                text=True, capture_output=True)
        assert failed.returncode == 12 and sentinel.read_text() == "preserve\n"

        absent = subprocess.run(["bash", str(LAB / "scripts" / "run.sh"),
                                 str(root / "nope.dat"), str(root / "out"),
                                 "20261009"], text=True, capture_output=True)
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
        loser = p1 if first.returncode == 12 else p2
        assert "Run locked" in loser[1], loser
        assert (concurrent / "report.txt").read_text() == (
            LAB / "expected" / "normal-valid.txt").read_text()
        assert not Path(str(concurrent) + ".lock").exists()


def check_bad_date() -> None:
    fixture = LAB / "fixtures" / "normal" / "valid.dat"
    with tempfile.TemporaryDirectory(prefix="bank-fileval-date-") as temp:
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
    with tempfile.TemporaryDirectory(prefix="bank-fileval-build-") as temp:
        root = Path(temp)
        binary = root / "fileval"
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
        fixture = LAB / "fixtures" / "normal" / "valid.dat"
        run = subprocess.run(["bash", str(LAB / "scripts/run.sh"),
                              str(fixture), str(output), "20261009"],
                             text=True, capture_output=True)
        assert run.returncode == 0 and output.is_dir()
        verifier = ["python3", str(LAB / "scripts" / "verify-publish.py"),
                    str(output / "account.input.dat"),
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
    # RED state is an authoring invariant (needs instructor/ next to a pristine
    # starter); a student bundle has no reference and expects the learner to
    # complete the starter, so skip it there.
    if not INSTRUCTOR.exists():
        return
    fixture = LAB / "fixtures" / "normal" / "valid.dat"
    with tempfile.TemporaryDirectory(prefix="bank-fileval-starter-") as temp:
        output = Path(temp) / "starter-out"
        env = dict(os.environ,
                   COURSE_SOURCE=str(LAB / "starter" / "FILEVAL.COB"))
        run = subprocess.run(["bash", str(LAB / "scripts/run.sh"),
                              str(fixture), str(output), "20261009"],
                             env=env, text=True, capture_output=True)
        assert run.returncode == 12 and not output.exists(), run.stderr


def check_probes() -> None:
    with tempfile.TemporaryDirectory(prefix="bank-fileval-probe-") as temp:
        root = Path(temp)

        lang = root / "lsp"
        subprocess.run(["cobc", "-Wall", "-x", "-o", str(lang),
                        str(LAB / "scripts" / "line-seq-probe.COB")],
                       check=True)
        env = dict(os.environ, LINE_PATH=str(root / "line.dat"),
                   FIXED_PATH=str(root / "fixed.dat"))
        probe = subprocess.run([str(lang)], env=env, text=True,
                               capture_output=True)
        assert probe.returncode == 0, probe.stderr
        lines = [line.rstrip() for line in probe.stdout.splitlines()]
        assert lines == ["LINE-LOGICAL=HELLO", "LINE-NEXT=10",
                         "LINE-RAW-BYTES=06", "LINE-RAW-LF=Y",
                         "FIXED-RAW-BYTES=05"], lines
        assert (root / "line.dat").read_bytes() == b"HELLO\n"
        assert (root / "fixed.dat").read_bytes() == b"HELLO"

        ix = root / "ixp"
        subprocess.run(["cobc", "-Wall", "-x", "-o", str(ix),
                        str(LAB / "scripts" / "indexed-probe.COB")],
                       check=True)
        env = dict(os.environ, IX_PATH=str(root / "ix.dat"),
                   IX_MISSING_PATH=str(root / "missing" / "ix.dat"))
        ix_run = subprocess.run([str(ix)], env=env, text=True,
                                capture_output=True)
        assert ix_run.returncode == 0, ix_run.stderr
        text = ix_run.stdout
        for token in ("CREATE=00", "WRITE1=00", "DUPLICATE=22", "CLOSE=00",
                      "IO=00", "READ=V1", "REWRITE=00", "MISSING=23",
                      "DELETE=00", "DELETED-READ=23", "REOPEN=41",
                      "MISS-OPEN=35"):
            assert token in text, (token, text)

        rel = root / "rp"
        subprocess.run(["cobc", "-Wall", "-x", "-o", str(rel),
                        str(LAB / "scripts" / "relative-probe.COB")],
                       check=True)
        rel_run = subprocess.run([str(rel)],
                                 env=dict(os.environ,
                                          RELPATH=str(root / "rel.dat")),
                                 text=True, capture_output=True)
        assert rel_run.returncode == 0, rel_run.stderr
        rtext = rel_run.stdout
        for token in ("CREATE=00", "WRITE1=00", "WRITE2=00", "DUPLICATE=22",
                      "IO=00", "READ1=00 AAAA", "REWRITE=00", "READ9=23",
                      "DELETE=00", "DELETED-READ=23"):
            assert token in rtext, (token, rtext)


def check_line_sequential_and_sd() -> None:
    """Lesson 06.1/06.2: SD work file + SORT, and LINE SEQUENTIAL width."""
    # covered in check_probes for LINE SEQUENTIAL; SD/SORT here
    with tempfile.TemporaryDirectory(prefix="bank-fileval-sd-") as temp:
        root = Path(temp)
        probe = root / "sd"
        subprocess.run(["cobc", "-Wall", "-x", "-o", str(probe),
                        str(LAB / "scripts" / "sort-sd-probe.COB")],
                       check=True)
        (root / "in.dat").write_text("CAROL\nALICE\nBOB\n")
        env = dict(os.environ, SI_PATH=str(root / "in.dat"),
                   SO_PATH=str(root / "sd-out.dat"))
        run = subprocess.run([str(probe)], env=env, text=True,
                             capture_output=True)
        assert run.returncode == 0, run.stderr
        assert run.stdout.splitlines() == ["ALICE", "BOB", "CAROL"], run.stdout


def check_cross_process_lock() -> None:
    """Lesson 06.4: measure the handler's cross-process behaviour for real.

    Two processes open the *same* indexed file I-O and hold it at once.  Both
    reporting 00 proves the default GnuCOBOL/BDB handler has no cross-process
    mutual exclusion, so consistency must come from the JOB-layer lock that
    check_protection exercises (two concurrent run.sh, loser RC12 "Run locked").
    """
    with tempfile.TemporaryDirectory(prefix="bank-fileval-hold-") as temp:
        root = Path(temp)
        maker = root / "mkix"
        subprocess.run(["cobc", "-Wall", "-x", "-o", str(maker),
                        str(LAB / "scripts" / "indexed-probe.COB")],
                       check=True)
        ixfile = root / "ix.dat"
        subprocess.run([str(maker)], check=True, text=True,
                       capture_output=True,
                       env=dict(os.environ, IX_PATH=str(ixfile),
                                IX_MISSING_PATH=str(root / "missing"/"ix.dat")))
        assert ixfile.exists(), "indexed probe did not create the file"

        hold = root / "hold"
        subprocess.run(["cobc", "-Wall", "-x", "-o", str(hold),
                        str(LAB / "scripts" / "indexed-hold-probe.COB")],
                       check=True)
        env = dict(os.environ, IX_PATH=str(ixfile))
        first = subprocess.Popen([str(hold)], env=env, text=True,
                                 stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        assert first.stdout.readline().strip() == "HOLD-OPEN=00", "first open"
        second = subprocess.Popen([str(hold)], env=env, text=True,
                                  stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE)
        ready, _, _ = select.select([second.stdout], [], [], 10)
        assert ready, "second opener blocked: unexpected handler-level mutex"
        status = second.stdout.readline().strip()
        assert status == "HOLD-OPEN=00", (
            "default handler serialised the second process:", status)
        # Both hold the file simultaneously; release and drain.
        for proc in (first, second):
            proc.stdin.write("\n")
            proc.stdin.flush()
            proc.stdin.close()
        for proc in (first, second):
            proc.wait(timeout=10)
            assert proc.returncode == 0, proc.returncode
            assert "HOLD-CLOSE=00" in proc.stdout.read()


def check_full_device_fail_closed() -> None:
    full = Path("/dev/full")
    if not full.exists() or not stat.S_ISCHR(full.stat().st_mode):
        return
    if not INSTRUCTOR.exists():
        return
    source = INSTRUCTOR.read_text()
    fixture = LAB / "fixtures" / "normal" / "valid.dat"
    with tempfile.TemporaryDirectory(prefix="bank-fileval-full-") as temp:
        root = Path(temp)
        for name, variable, cobol_path in (
                ("accepted", "ACCEPT_OUTPUT_FILE", "OK-PATH"),
                ("rejected", "REJECT_OUTPUT_FILE", "RJ-PATH")):
            failed_source = root / f"full-{name}.COB"
            failed_source.write_text(source.replace(
                f"           ACCEPT {cobol_path} FROM ENVIRONMENT "
                f"'{variable}'",
                f"           MOVE '/dev/full' TO {cobol_path}"))
            target = root / f"must-not-publish-{name}"
            env = dict(os.environ, COURSE_SOURCE=str(failed_source))
            run = subprocess.run(["bash", str(LAB / "scripts" / "run.sh"),
                                  str(fixture), str(target), "20261009"],
                                 env=env, text=True, capture_output=True)
            assert run.returncode == 12 and not target.exists(), (
                name, run.returncode, run.stderr)


def check_source_format() -> None:
    sources = [LAB / "starter" / "FILEVAL.COB",
               LAB / "scripts" / "line-seq-probe.COB",
               LAB / "scripts" / "indexed-probe.COB",
               LAB / "scripts" / "indexed-hold-probe.COB",
               LAB / "scripts" / "sort-sd-probe.COB",
               LAB / "scripts" / "relative-probe.COB"]
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
    check_line_sequential_and_sd()
    check_cross_process_lock()
    check_full_device_fail_closed()
    print("PASS: module 06 file contract, boundary and invalid cases")


if __name__ == "__main__":
    main()
