#!/usr/bin/env python3
"""Remove only a complete, hash-verified B04 runner output directory."""
from pathlib import Path
import shutil
import subprocess
import sys

root = Path(sys.argv[1])
expected = {"compiler.txt", "inputs.sha256", "manifest.sha256", "new.dat",
            "old.dat", "report.txt", "source.sha256"}
if not root.is_dir() or root.is_symlink():
    raise SystemExit(12)
if {p.name for p in root.iterdir()} != expected:
    raise SystemExit(12)
for checksum in ("inputs.sha256", "manifest.sha256"):
    result = subprocess.run(["sha256sum", "-c", checksum], cwd=root,
                            capture_output=True, text=True)
    if result.returncode:
        raise SystemExit(12)
shutil.rmtree(root)
