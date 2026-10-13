#!/usr/bin/env python3
"""Contract checks for the 07.1 stream SORT runner."""
from pathlib import Path
import hashlib
import os
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[5]


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def run(input_file, expected_rc, expected=None, extra_env=None):
    with tempfile.TemporaryDirectory(prefix="b02-sort-check-") as tmp:
        output = Path(tmp) / "sorted.dat"
        env = dict(os.environ)
        env["COB_SORT_MEMORY"] = "2M"
        if extra_env:
            env.update(extra_env)
        before = sha(input_file)
        proc = subprocess.run(["bash", str(LAB / "scripts/run.sh"),
                               str(input_file), str(output)], env=env,
                              text=True, capture_output=True)
        assert proc.returncode == expected_rc, (proc.returncode,
                                                proc.stdout, proc.stderr)
        assert sha(input_file) == before
        if expected_rc:
            assert not output.exists(), "failed candidate was published"
        else:
            assert output.read_bytes() == expected.read_bytes()
        return proc


def main():
    fixture = LAB / "fixtures"
    run(fixture / "normal/transaction.dat", 0, LAB / "expected/normal.dat")
    run(fixture / "boundary/single-record.dat", 0,
        LAB / "expected/single-record.dat")
    run(fixture / "boundary/empty.dat", 0, LAB / "expected/empty.dat")
    run(fixture / "boundary/leap-day.dat", 0,
        LAB / "expected/leap-day.dat", {"B02_DATE": "20240229"})
    run(fixture / "boundary/zero-amount.dat", 0,
        LAB / "expected/zero-amount.dat")
    for bad in sorted((fixture / "invalid").glob("*.dat")):
        run(bad, 8)
    with tempfile.TemporaryDirectory(prefix="b02-sort-l2-bridge-") as tmp:
        root = Path(tmp)
        sorted_file = root / "sorted.dat"
        output = root / "l2-output"
        sort_run = subprocess.run(["bash", str(LAB / "scripts/run.sh"),
                                   str(fixture / "normal/transaction.dat"),
                                   str(sorted_file)], text=True,
                                  capture_output=True)
        assert sort_run.returncode == 0, (sort_run.returncode,
                                          sort_run.stdout, sort_run.stderr)
        common = LAB.parent / "common/fixtures/integration"
        expected = LAB.parent / "common/expected"
        l2 = REPO / "curriculum/modules/07-matching/labs/03-one-to-many"
        result = subprocess.run(
            ["bash", str(l2 / "scripts/run.sh"),
             str(common / "account.dat"), str(sorted_file),
             str(common / "reversal-link.dat"), str(output), "20261009"],
            text=True, capture_output=True)
        assert result.returncode == 0, (result.returncode, result.stdout,
                                        result.stderr)
        assert (output / "report.txt").read_bytes() == (
            expected / "l2-report.txt").read_bytes()
        assert (output / "master.dat").read_bytes() == (
            expected / "l2-master.dat").read_bytes()
        assert (output / "accepted.dat").read_bytes() == (
            LAB / "expected/normal.dat").read_bytes()
        assert (output / "rejected.dat").read_bytes() == b""
    with tempfile.TemporaryDirectory(prefix="b02-zero-l2-") as tmp:
        root = Path(tmp)
        sorted_file = root / "zero.sorted"
        output = root / "l2-zero-output"
        empty_links = root / "no-links.dat"
        empty_links.write_bytes(b"")
        sorted_run = subprocess.run(["bash", str(LAB / "scripts/run.sh"),
                                     str(fixture / "boundary/zero-amount.dat"),
                                     str(sorted_file)], text=True,
                                    capture_output=True)
        assert sorted_run.returncode == 0
        common = LAB.parent / "common/fixtures/integration"
        expected = LAB.parent / "common/expected"
        l2 = REPO / "curriculum/modules/07-matching/labs/03-one-to-many"
        result = subprocess.run(
            ["bash", str(l2 / "scripts/run.sh"),
             str(common / "account.dat"), str(sorted_file),
             str(empty_links), str(output), "20261009"],
            text=True, capture_output=True)
        assert result.returncode == 4, (result.returncode, result.stdout,
                                        result.stderr)
        assert (output / "report.txt").read_bytes() == (
            expected / "l2-zero-report.txt").read_bytes()
        assert (output / "master.dat").read_bytes() == (
            expected / "l2-zero-master.dat").read_bytes()
        assert (output / "accepted.dat").read_bytes() == b""
        row = (fixture / "boundary/zero-amount.dat").read_bytes()
        assert (output / "rejected.dat").read_bytes() == (
            row[:-1] + b"|ZERO-AMOUNT\n")
    with tempfile.TemporaryDirectory(prefix="b02-starter-") as tmp:
        out = Path(tmp) / "starter-output.dat"
        env = dict(os.environ, COURSE_SOURCE=str(LAB / "starter" / "SORTTX.COB"))
        args = ["bash", str(LAB / "scripts/run.sh"),
                str(fixture / "normal/transaction.dat"), str(out)]
        proc = subprocess.run(args, env=env, text=True, capture_output=True)
        assert proc.returncode == 12 and not out.exists(), (proc.returncode,
                                                            proc.stdout, proc.stderr)
        assert "TODO" in proc.stdout or "TODO" in proc.stderr
    with tempfile.TemporaryDirectory(prefix="b02-reset-") as tmp:
        workspace = Path(tmp) / "workspace"
        workspace.mkdir()
        init = subprocess.run(["bash", str(LAB / "scripts/init-workspace.sh"),
                               str(workspace)], text=True, capture_output=True)
        assert init.returncode == 0, init.stderr
        (workspace / "sorttx").write_text("generated\n")
        (workspace / "sorted.dat").write_bytes(b"candidate\n")
        (workspace / "student-notes.txt").write_text("preserve\n")
        reset = subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                                str(workspace)], text=True, capture_output=True)
        assert reset.returncode == 0 and not (workspace / "sorttx").exists()
        assert not (workspace / "sorted.dat").exists()
        assert (workspace / "student-notes.txt").read_text() == "preserve\n"
        (workspace / "sorttx").write_text("keep while locked\n")
        (workspace / "sorted.dat").write_bytes(b"keep while locked\n")
        (workspace / "sorted.dat.lock").mkdir()
        locked = subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                                 str(workspace)], text=True, capture_output=True)
        assert locked.returncode == 12
        assert (workspace / "sorttx").read_text() == "keep while locked\n"
        assert (workspace / "sorted.dat").read_bytes() == b"keep while locked\n"
        assert (workspace / "sorted.dat.lock").is_dir()
        unmarked = Path(tmp) / "unmarked"
        unmarked.mkdir()
        refused = subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                                  str(unmarked)], text=True, capture_output=True)
        assert refused.returncode == 12
    print("PASS: 07.1 SORT contract")


if __name__ == "__main__":
    main()
