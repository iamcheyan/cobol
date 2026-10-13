#!/usr/bin/env python3
"""End-to-end contract checks for the module 01 foundations lab."""
from pathlib import Path
import hashlib
import os
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[2]
FIXTURES = LAB / "fixtures"
EXPECTED = LAB / "expected"
INSTRUCTOR = REPO / "instructor/modules/01-foundations/BANK-ENTRY.COB"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed_rows(path: Path, width: int = 47):
    data = path.read_bytes()
    if data == b"":
        return []
    assert data.endswith(b"\n"), f"missing final LF: {path}"
    rows = data[:-1].split(b"\n")
    assert all(len(row) == width and b"\r" not in row for row in rows), path
    return rows


def expected_split(path: Path):
    """Accepted/rejected split by the business rule status in {A,F,C}."""
    accepted, rejected = [], []
    for row in fixed_rows(path):
        if row[35:36] in (b"A", b"F", b"C"):
            accepted.append(row)
        else:
            rejected.append(row)
    return accepted, rejected


def run_case(name: str, path: Path, rc: int, expected_control: Path | None,
             output_name: str = "published") -> None:
    with tempfile.TemporaryDirectory(prefix="bank-m01-check-") as tmp:
        output = Path(tmp) / output_name
        before = digest(path)
        proc = subprocess.run(
            ["bash", str(LAB / "scripts" / "run.sh"), str(path), str(output),
             "20261009"], cwd=tmp, text=True, capture_output=True)
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
            r + b"|UNKNOWN-STATUS\n" for r in rejected), name
        assert subprocess.run(["sha256sum", "-c", "inputs.sha256"],
                              cwd=output, capture_output=True).returncode == 0
        assert subprocess.run(["sha256sum", "-c", "outputs.sha256"],
                              cwd=output, capture_output=True).returncode == 0
        assert proc.stdout == "PASS: account entry counts verified\n", proc.stdout


def check_source_format() -> None:
    # The instructor reference is an authoring artifact; in a student bundle it
    # is intentionally absent, so scan whatever is actually shipped.
    scanned = [LAB / "starter/BANK-ENTRY.COB"]
    if INSTRUCTOR.exists():
        scanned.insert(0, INSTRUCTOR)
    for pattern in ("experiments/**/*.COB",):
        scanned += [p for p in LAB.glob(pattern) if p.is_file()]
    for path in scanned:
        for number, line in enumerate(path.read_text().splitlines(), 1):
            assert line.isascii(), (path, number, "non-ASCII")
            assert len(line) <= 72, (path, number, "beyond column 72")
            assert "\t" not in line, (path, number, "tab")
    # The truncation template intentionally exceeds column 72; it is not
    # a .COB so the global gate skips it. It must stay ASCII and tab free.
    template = LAB / "experiments" / "columns" / "TRUNC-BAD.COB.src"
    for number, line in enumerate(template.read_text().splitlines(), 1):
        assert line.isascii(), (template, number, "non-ASCII")
        assert "\t" not in line, (template, number, "tab")
    assert len(template.read_text().splitlines()[12]) == 73


def check_experiments() -> None:
    columns = LAB / "experiments" / "columns"
    failures = LAB / "experiments" / "build-failure"
    with tempfile.TemporaryDirectory(prefix="bank-m01-exp-") as tmp:
        root = Path(tmp)
        for broken in ("BROKEN-PERFORM.COB", "BROKEN-AREA.COB"):
            result = subprocess.run(
                ["cobc", "-fsyntax-only", str(failures / broken)],
                text=True, capture_output=True)
            assert result.returncode != 0, broken
            assert "error" in (result.stdout + result.stderr), broken
        bad = root / "TRUNC-BAD.COB"
        bad.write_bytes((columns / "TRUNC-BAD.COB.src").read_bytes())
        outputs = {}
        for name, source in (("bad", bad),
                             ("good", columns / "TRUNC-GOOD.COB"),
                             ("fixed", columns / "FIXED.COB"),
                             ("free", columns / "FREE.COB")):
            binary = root / name
            build = subprocess.run(
                ["cobc", "-Wall", "-x", "-o", str(binary), str(source)],
                text=True, capture_output=True)
            assert build.returncode == 0, (name, build.stderr)
            run = subprocess.run([str(binary)], text=True, capture_output=True)
            assert run.returncode == 0, name
            outputs[name] = run.stdout
        assert outputs["bad"] == f"RESULT={11112:038d}\n", outputs["bad"]
        assert outputs["good"] == f"RESULT={111111:038d}\n", outputs["good"]
        assert outputs["fixed"] == outputs["free"] == outputs["good"]


def check_lock_and_protection() -> None:
    fixture = FIXTURES / "normal" / "account.dat"
    base = ["bash", str(LAB / "scripts" / "run.sh"), str(fixture)]
    with tempfile.TemporaryDirectory(prefix="bank-m01-protect-") as temp:
        root = Path(temp)
        existing = root / "existing"
        existing.mkdir()
        sentinel = existing / "keep.txt"
        sentinel.write_text("preserve\n")
        failed = subprocess.run(base + [str(existing), "20261009"],
                                text=True, capture_output=True)
        assert failed.returncode == 12 and sentinel.read_text() == "preserve\n"
        target = root / "locked"
        lock = Path(str(target) + ".lock")
        lock.mkdir()
        marker = lock / "owner"
        marker.write_text("another run owns this lock\n")
        failed = subprocess.run(base + [str(target), "20261009"],
                                text=True, capture_output=True)
        assert failed.returncode == 12 and marker.exists() and not target.exists()


def check_build_and_reset() -> None:
    with tempfile.TemporaryDirectory(prefix="bank-m01-build-") as temp:
        root = Path(temp)
        binary = root / "bankentry"
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
             str(FIXTURES / "normal" / "account.dat"), str(output),
             "20261009"], text=True, capture_output=True)
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
        "normal": FIXTURES / "normal" / "account.dat",
        "empty": FIXTURES / "boundary" / "empty.dat",
        "single": FIXTURES / "boundary" / "single.dat",
        "unknown-status": FIXTURES / "invalid" / "unknown-status.dat",
    }
    for name, path in published.items():
        rc = 4 if name == "unknown-status" else 0
        run_case(name, path, rc, EXPECTED / f"{name}.control.txt",
                 output_name="output with spaces" if name == "normal"
                 else "published")
    structural = {
        "no-final-lf": FIXTURES / "boundary" / "no-final-lf.dat",
        "short": FIXTURES / "invalid" / "short.dat",
        "long": FIXTURES / "invalid" / "long.dat",
        "crlf": FIXTURES / "invalid" / "crlf.dat",
        "bad-id": FIXTURES / "invalid" / "bad-id.dat",
        "bad-layout": FIXTURES / "invalid" / "bad-layout.dat",
        "bad-date": FIXTURES / "invalid" / "bad-date.dat",
        "duplicate-id": FIXTURES / "invalid" / "duplicate-id.dat",
        "unsorted": FIXTURES / "invalid" / "unsorted.dat",
    }
    for name, path in structural.items():
        run_case(name, path, 8, None)
    # Calendar validation at the JOB boundary.
    run_case("leap-day", FIXTURES / "boundary" / "empty.dat", 0,
             EXPECTED / "empty.control.txt")
    with tempfile.TemporaryDirectory(prefix="bank-m01-date-") as temp:
        bad_date = subprocess.run(
            ["bash", str(LAB / "scripts" / "run.sh"),
             str(FIXTURES / "boundary" / "empty.dat"),
             str(Path(temp) / "nope"), "20260230"],
            text=True, capture_output=True)
        assert bad_date.returncode == 8, bad_date
        assert not (Path(temp) / "nope").exists()
    # RED state: the unimplemented starter must fail closed (RC12, no output).
    # This is an authoring invariant: it only holds while instructor/ ships
    # alongside a pristine starter.  In a student bundle there is no reference
    # and the learner is expected to make the starter pass, so we skip the
    # assertion there instead of forcing the starter to stay broken.
    if INSTRUCTOR.exists():
        with tempfile.TemporaryDirectory(prefix="bank-m01-red-") as temp:
            output = Path(temp) / "starter-output"
            env = dict(os.environ,
                       COURSE_SOURCE=str(LAB / "starter" / "BANK-ENTRY.COB"))
            starter = subprocess.run(
                ["bash", str(LAB / "scripts" / "run.sh"),
                 str(FIXTURES / "normal" / "account.dat"), str(output),
                 "20261009"], env=env, text=True, capture_output=True)
            assert starter.returncode == 12 and not output.exists(), (
                starter.returncode, starter.stderr)
    check_experiments()
    check_lock_and_protection()
    check_build_and_reset()
    print("PASS: module 01 foundations contracts")


if __name__ == "__main__":
    main()
