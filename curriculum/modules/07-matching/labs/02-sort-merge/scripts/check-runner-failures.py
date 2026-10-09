#!/usr/bin/env python3
"""Runner protection and system-RC checks for both B02 lessons."""
from pathlib import Path
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CASES = [
    ("01-sort", ["fixtures/normal/transaction.dat"]),
    ("02-merge", ["fixtures/normal/feed-a.dat",
                   "fixtures/normal/feed-b.dat"]),
]
for lesson, inputs in CASES:
    lab = ROOT / lesson
    with tempfile.TemporaryDirectory(prefix="b02-failure-check-") as tmp:
        work = Path(tmp)
        command = ["bash", str(lab / "scripts/run.sh"),
                   *(str(lab / path) for path in inputs)]

        target = work / "result with spaces.dat"
        shim = work / "bin"
        shim.mkdir()
        (shim / "mktemp").write_text("#!/bin/sh\nexit 1\n")
        (shim / "mktemp").chmod(0o755)
        env = dict(os.environ, PATH=f"{shim}:{os.environ['PATH']}")
        failed = subprocess.run(command + [str(target)], env=env,
                                text=True, capture_output=True)
        assert failed.returncode == 12 and not target.exists()
        assert not Path(str(target) + ".lock").exists()


        broken_source = work / "broken.COB"
        broken_source.write_text("not valid COBOL\n")
        failed_target = work / "bad-build.dat"
        broken_env = dict(os.environ, COURSE_SOURCE=str(broken_source))
        failed_build = subprocess.run(command + [str(failed_target)],
                                      env=broken_env, text=True,
                                      capture_output=True)
        assert failed_build.returncode == 12 and not failed_target.exists()
        assert not Path(str(failed_target) + ".lock").exists()

        target.write_text("preserve\n")
        refused = subprocess.run(command + [str(target)], text=True,
                                 capture_output=True)
        assert refused.returncode == 12 and target.read_text() == "preserve\n"

        target.unlink()
        lock = Path(str(target) + ".lock")
        lock.mkdir()
        owner = lock / "owner"
        owner.write_text("existing lock\n")
        refused = subprocess.run(command + [str(target)], text=True,
                                 capture_output=True)
        assert refused.returncode == 12 and owner.read_text() == "existing lock\n"
        assert not target.exists()
print("PASS: runner no-clobber, lock, and mktemp failures map to RC12")
