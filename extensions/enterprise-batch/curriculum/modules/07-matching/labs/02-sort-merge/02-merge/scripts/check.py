#!/usr/bin/env python3
"""Contract checks for the 07.2 two-stream COBOL MERGE runner."""
from pathlib import Path
import hashlib
import os
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[5]


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def run(a, b, expected_rc, expected=None):
    with tempfile.TemporaryDirectory(prefix="b02-merge-check-") as tmp:
        output = Path(tmp) / "merged.dat"
        env = dict(os.environ)
        env["COB_SORT_MEMORY"] = "2M"
        before = (sha(a), sha(b))
        proc = subprocess.run(["bash", str(LAB / "scripts/run.sh"),
                               str(a), str(b), str(output)], env=env,
                              text=True, capture_output=True)
        assert proc.returncode == expected_rc, (proc.returncode,
                                                proc.stdout, proc.stderr)
        assert before == (sha(a), sha(b))
        if expected_rc:
            assert not output.exists(), "failed candidate was published"
        else:
            assert output.read_bytes() == expected.read_bytes()
        return proc


def main():
    f = LAB / "fixtures"
    a, b = f / "normal/feed-a.dat", f / "normal/feed-b.dat"
    run(a, b, 0, LAB / "expected/normal.dat")
    run(f / "boundary/empty-a.dat", f / "boundary/empty-b.dat", 0,
        LAB / "expected/empty.dat")
    run(f / "boundary/single-a.dat", f / "boundary/single-b.dat", 0,
        LAB / "expected/single-a.dat")
    run(f / "boundary/zero-amount.dat", f / "boundary/empty-b.dat", 0,
        LAB / "expected/zero-amount.dat")
    for bad in sorted((f / "invalid").glob("*.dat")):
        if bad.name == "duplicate-feed-a.dat":
            run(bad, f / "invalid/duplicate-feed-b.dat", 8)
        elif bad.name == "duplicate-feed-b.dat":
            continue
        elif bad.name == "reversed-feed-a.dat":
            run(bad, b, 8)
        else:
            run(bad, b, 8)
    with tempfile.TemporaryDirectory(prefix="b02-l2-bridge-") as tmp:
        root = Path(tmp)
        merged = root / "merged.dat"
        output = root / "l2-output"
        merge = subprocess.run(["bash", str(LAB / "scripts/run.sh"),
                                str(a), str(b), str(merged)], text=True,
                               capture_output=True)
        assert merge.returncode == 0, (merge.returncode, merge.stdout,
                                       merge.stderr)
        common = LAB.parent / "common/fixtures/integration"
        l2 = REPO / "curriculum/modules/07-matching/labs/03-one-to-many"
        result = subprocess.run(
            ["bash", str(l2 / "scripts/run.sh"),
             str(common / "account.dat"), str(merged),
             str(common / "reversal-link.dat"), str(output), "20261009"],
            text=True, capture_output=True)
        assert result.returncode == 0, (result.returncode, result.stdout,
                                        result.stderr)
        assert (output / "report.txt").read_bytes() == (
            LAB.parent / "common/expected/l2-report.txt").read_bytes()
        assert (output / "master.dat").read_bytes() == (
            LAB.parent / "common/expected/l2-master.dat").read_bytes()
        assert (output / "accepted.dat").read_bytes() == (
            LAB / "expected/normal.dat").read_bytes()
        assert (output / "rejected.dat").read_bytes() == b""
    with tempfile.TemporaryDirectory(prefix="b02-starter-") as tmp:
        out = Path(tmp) / "starter-output.dat"
        env = dict(os.environ, COURSE_SOURCE=str(LAB / "starter" / "MERGETX.COB"))
        args = ["bash", str(LAB / "scripts/run.sh"),
                str(f / "normal/feed-a.dat"),
                str(f / "normal/feed-b.dat"), str(out)]
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
        (workspace / "mergetx").write_text("generated\n")
        (workspace / "merged.dat").write_bytes(b"candidate\n")
        (workspace / "student-notes.txt").write_text("preserve\n")
        reset = subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                                str(workspace)], text=True, capture_output=True)
        assert reset.returncode == 0 and not (workspace / "mergetx").exists()
        assert not (workspace / "merged.dat").exists()
        assert (workspace / "student-notes.txt").read_text() == "preserve\n"
        (workspace / "mergetx").write_text("keep while locked\n")
        (workspace / "merged.dat").write_bytes(b"keep while locked\n")
        (workspace / "merged.dat.lock").mkdir()
        locked = subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                                 str(workspace)], text=True, capture_output=True)
        assert locked.returncode == 12
        assert (workspace / "mergetx").read_text() == "keep while locked\n"
        assert (workspace / "merged.dat").read_bytes() == b"keep while locked\n"
        assert (workspace / "merged.dat.lock").is_dir()
        unmarked = Path(tmp) / "unmarked"
        unmarked.mkdir()
        refused = subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                                  str(unmarked)], text=True, capture_output=True)
        assert refused.returncode == 12
    print("PASS: 07.2 MERGE contract")


if __name__ == "__main__":
    main()
