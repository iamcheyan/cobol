#!/usr/bin/env python3
"""End-to-end contract checks for the module 02 data lab."""
from pathlib import Path
import hashlib
import os
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[2]
FIXTURES = LAB / "fixtures"
EXPECTED = LAB / "expected"
COPYBOOKS = LAB / "copybooks"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed_rows(path: Path, width: int = 27):
    data = path.read_bytes()
    if data == b"":
        return []
    assert data.endswith(b"\n"), f"missing final LF: {path}"
    rows = data[:-1].split(b"\n")
    assert all(len(row) == width and b"\r" not in row for row in rows), path
    return rows


def reason_for(row: bytes):
    if row[8:18] == b" " * 10:
        return b"NAME-MISSING"
    if not row[18:26].isdigit():
        return b"BAD-AMOUNT"
    if row[26:27] not in (b"A", b"D"):
        return b"UNKNOWN-STATUS"
    return None


def expected_split(path: Path):
    accepted, rejected = [], []
    for row in fixed_rows(path):
        reason = reason_for(row)
        if reason is None:
            accepted.append(row)
        else:
            rejected.append(row + b"|" + reason)
    return accepted, rejected


def run_case(name: str, path: Path, rc: int, expected_control: Path | None,
             output_name: str = "published") -> None:
    with tempfile.TemporaryDirectory(prefix="bank-m02-check-") as tmp:
        output = Path(tmp) / output_name
        before = digest(path)
        proc = subprocess.run(
            ["bash", str(LAB / "scripts" / "run.sh"), str(path), str(output)],
            cwd=tmp, text=True, capture_output=True)
        assert proc.returncode == rc, (
            name, proc.returncode, proc.stdout, proc.stderr)
        assert digest(path) == before, f"{name}: run changed the fixture"
        if rc in (8, 12):
            assert not output.exists(), f"{name}: failed run published output"
            return
        assert output.is_dir(), name
        actual = (output / "control.txt").read_bytes()
        assert actual == expected_control.read_bytes(), (
            f"{name}: control mismatch\n{actual!r}")
        accepted, rejected = expected_split(path)
        assert (output / "accepted.dat").read_bytes() == b"".join(
            r + b"\n" for r in accepted), name
        assert (output / "rejected.dat").read_bytes() == b"".join(
            r + b"\n" for r in rejected), name
        assert subprocess.run(["sha256sum", "-c", "inputs.sha256"],
                              cwd=output, capture_output=True).returncode == 0
        assert subprocess.run(["sha256sum", "-c", "outputs.sha256"],
                              cwd=output, capture_output=True).returncode == 0
        assert proc.stdout == "PASS: customer counts and balance verified\n", proc.stdout


def check_source_format() -> None:
    scanned = [LAB / "starter/CUSTLOAD.COB",
               LAB / "experiments/move/MOVELAB.COB",
               LAB / "experiments/types/TYPESLAB.COB",
               LAB / "experiments/layout/LENGTH-PROBE.COB",
               COPYBOOKS / "CUSTOMER-V1.CPY",
               LAB / "experiments/layout/CUSTOMER-V1.CPY"]
    # The instructor reference is an authoring artifact; in a student bundle it
    # is intentionally absent, so scan whatever is actually shipped.
    instructor = REPO / "instructor/modules/02-data/CUSTLOAD.COB"
    if instructor.exists():
        scanned.insert(0, instructor)
    for path in scanned:
        for number, line in enumerate(path.read_text().splitlines(), 1):
            assert line.isascii(), (path, number, "non-ASCII")
            assert len(line) <= 72, (path, number, "beyond column 72")
            assert "\t" not in line, (path, number, "tab")


def check_move_experiment() -> None:
    with tempfile.TemporaryDirectory(prefix="bank-m02-move-") as tmp:
        binary = Path(tmp) / "movelab"
        build = subprocess.run(
            ["cobc", "-Wall", "-x", "-o", str(binary),
             str(LAB / "experiments" / "move" / "MOVELAB.COB")],
            text=True, capture_output=True)
        assert build.returncode == 0, build.stderr
        run = subprocess.run([str(binary)], text=True, capture_output=True)
        assert run.returncode == 0, run.stderr
        expected = (EXPECTED / "movelab.txt").read_bytes()
        assert run.stdout.encode("ascii") == expected, (
            run.stdout.encode("ascii"), expected)


def check_types_experiment() -> None:
    """R12: a real, runnable PIC A / 78 / 77 / 88 / group experiment."""
    with tempfile.TemporaryDirectory(prefix="bank-m02-types-") as tmp:
        root = Path(tmp)
        binary = root / "typeslab"
        build = subprocess.run(
            ["cobc", "-Wall", "-x", "-o", str(binary),
             str(LAB / "experiments" / "types" / "TYPESLAB.COB")],
            text=True, capture_output=True)
        assert build.returncode == 0, build.stderr
        run = subprocess.run(
            [str(binary)], text=True, capture_output=True,
            env=dict(os.environ,
                     TYPESLAB_INPUT=str(FIXTURES / "types" / "typeinput.dat")))
        assert run.returncode == 0, run.stderr
        expected = (EXPECTED / "typeslab.txt").read_bytes()
        assert run.stdout.encode("ascii") == expected, (
            run.stdout.encode("ascii"), expected)
        # Central teaching fact: PIC A does NOT reject digits moved from X.
        assert "00002|AB123|AB123|M|" in run.stdout
        # Fault: a numeric item cannot be moved to PIC A (compile error).
        fault = root / "BADTYPE.COB"
        fault.write_text(
            "       IDENTIFICATION DIVISION.\n"
            "       PROGRAM-ID. BADTYPE.\n"
            "       DATA DIVISION.\n"
            "       WORKING-STORAGE SECTION.\n"
            "       01 WS-A PIC A(5).\n"
            "       01 WS-N PIC 9(5) VALUE 12345.\n"
            "       PROCEDURE DIVISION.\n"
            "           MOVE WS-N TO WS-A\n"
            "           STOP RUN.\n")
        bad = subprocess.run(["cobc", "-x", "-o", str(root / "badtype"),
                              str(fault)], text=True, capture_output=True)
        assert bad.returncode != 0, "numeric MOVE to PIC A must not compile"


def check_layout_experiment() -> None:
    probe = LAB / "experiments" / "layout" / "LENGTH-PROBE.COB"
    with tempfile.TemporaryDirectory(prefix="bank-m02-layout-") as tmp:
        results = {}
        for name, include in (("canonical", COPYBOOKS),
                              ("offbyone", LAB / "experiments" / "layout")):
            binary = Path(tmp) / name
            build = subprocess.run(
                ["cobc", "-Wall", "-I", str(include), "-x", "-o", str(binary),
                 str(probe)], text=True, capture_output=True)
            assert build.returncode == 0, (name, build.stderr)
            run = subprocess.run([str(binary)], text=True, capture_output=True)
            results[name] = run.stdout
        assert results["canonical"] == "CUSTOMER-RECORD=27\nNAME-LENGTH=10\n", (
            results["canonical"])
        assert results["offbyone"] == "CUSTOMER-RECORD=28\nNAME-LENGTH=11\n", (
            results["offbyone"])


def check_lock_and_protection() -> None:
    fixture = FIXTURES / "normal" / "customer.dat"
    base = ["bash", str(LAB / "scripts" / "run.sh"), str(fixture)]
    with tempfile.TemporaryDirectory(prefix="bank-m02-protect-") as temp:
        root = Path(temp)
        existing = root / "existing"
        existing.mkdir()
        sentinel = existing / "keep.txt"
        sentinel.write_text("preserve\n")
        failed = subprocess.run(base + [str(existing)],
                                text=True, capture_output=True)
        assert failed.returncode == 12 and sentinel.read_text() == "preserve\n"
        target = root / "locked"
        lock = Path(str(target) + ".lock")
        lock.mkdir()
        marker = lock / "owner"
        marker.write_text("another run owns this lock\n")
        failed = subprocess.run(base + [str(target)],
                                text=True, capture_output=True)
        assert failed.returncode == 12 and marker.exists() and not target.exists()


def check_build_and_reset() -> None:
    with tempfile.TemporaryDirectory(prefix="bank-m02-build-") as temp:
        root = Path(temp)
        binary = root / "custload"
        build = subprocess.run(["bash", str(LAB / "scripts" / "build.sh"),
                                str(binary)], text=True, capture_output=True)
        assert build.returncode == 0 and binary.is_file(), build.stderr
        broken = root / "broken.COB"
        broken.write_text("not COBOL\n")
        refused_target = root / "must-not-exist"
        failed = subprocess.run(
            ["bash", str(LAB / "scripts" / "build.sh"), str(refused_target),
             str(broken)], text=True, capture_output=True)
        assert failed.returncode == 12 and not refused_target.exists()
        unmarked = root / "keep"
        unmarked.mkdir()
        marker = unmarked / "important.txt"
        marker.write_text("keep\n")
        refused = subprocess.run(["bash", str(LAB / "scripts" / "reset.sh"),
                                  str(unmarked)], text=True, capture_output=True)
        assert refused.returncode == 12 and marker.read_text() == "keep\n"
        output = root / "course-output"
        run = subprocess.run(
            ["bash", str(LAB / "scripts" / "run.sh"),
             str(FIXTURES / "normal" / "customer.dat"), str(output)],
            text=True, capture_output=True)
        assert run.returncode == 0 and output.is_dir()
        reset = subprocess.run(["bash", str(LAB / "scripts" / "reset.sh"),
                                str(output)], text=True, capture_output=True)
        assert reset.returncode == 0 and not output.exists(), reset.stderr


def main() -> None:
    check_source_format()
    manifest = subprocess.run(["sha256sum", "-c", "SHA256SUMS"],
                              cwd=FIXTURES, text=True, capture_output=True)
    assert manifest.returncode == 0, manifest.stdout + manifest.stderr
    published = {
        "normal": FIXTURES / "normal" / "customer.dat",
        "empty": FIXTURES / "boundary" / "empty.dat",
        "single": FIXTURES / "boundary" / "single.dat",
        "max-balance": FIXTURES / "boundary" / "max-balance.dat",
        "name-full": FIXTURES / "boundary" / "name-full.dat",
        "name-missing": FIXTURES / "invalid" / "name-missing.dat",
        "bad-amount": FIXTURES / "invalid" / "bad-amount.dat",
        "unknown-status": FIXTURES / "invalid" / "unknown-status.dat",
    }
    for name, path in published.items():
        rc = 4 if name in ("name-missing", "bad-amount",
                           "unknown-status") else 0
        run_case(name, path, rc, EXPECTED / f"{name}.control.txt",
                 output_name="output with spaces" if name == "normal"
                 else "published")
    structural = {
        "no-final-lf": FIXTURES / "boundary" / "no-final-lf.dat",
        "short": FIXTURES / "invalid" / "short.dat",
        "long": FIXTURES / "invalid" / "long.dat",
        "crlf": FIXTURES / "invalid" / "crlf.dat",
        "bad-id": FIXTURES / "invalid" / "bad-id.dat",
        "duplicate-id": FIXTURES / "invalid" / "duplicate-id.dat",
        "unsorted": FIXTURES / "invalid" / "unsorted.dat",
    }
    for name, path in structural.items():
        run_case(name, path, 8, None)
    # RED state: the unimplemented starter must fail closed (RC12, no output).
    # Authoring invariant only: it needs the pristine starter beside the
    # reference.  In a student bundle the learner is expected to complete the
    # starter, so skip it there.
    instructor = REPO / "instructor/modules/02-data/CUSTLOAD.COB"
    if instructor.exists():
        with tempfile.TemporaryDirectory(prefix="bank-m02-red-") as temp:
            output = Path(temp) / "starter-output"
            env = dict(os.environ,
                       COURSE_SOURCE=str(LAB / "starter" / "CUSTLOAD.COB"))
            starter = subprocess.run(
                ["bash", str(LAB / "scripts" / "run.sh"),
                 str(FIXTURES / "normal" / "customer.dat"), str(output)],
                env=env, text=True, capture_output=True)
            assert starter.returncode == 12 and not output.exists(), (
                starter.returncode, starter.stderr)
    check_move_experiment()
    check_types_experiment()
    check_layout_experiment()
    check_lock_and_protection()
    check_build_and_reset()
    print("PASS: module 02 data contracts")


if __name__ == "__main__":
    main()
