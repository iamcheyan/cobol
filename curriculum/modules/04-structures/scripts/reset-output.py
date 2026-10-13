#!/usr/bin/env python3
"""Remove a module 04 runner output directory only if it is complete and its
manifest verifies. Any unexpected file, symlink, or failed checksum refuses."""
from pathlib import Path
import shutil
import subprocess
import sys

root = Path(sys.argv[1])
allowed = [
    {"compiler.txt", "manifest.sha256", "report.txt", "source.sha256",
     "stderr.txt"},
    {"compiler.txt", "input.dat", "inputs.sha256", "manifest.sha256",
     "report.txt", "source.sha256", "stderr.txt"},
]
if not root.is_dir() or root.is_symlink():
    raise SystemExit(12)
names = {p.name for p in root.iterdir()}
if names not in allowed:
    raise SystemExit(12)
result = subprocess.run(["sha256sum", "-c", "manifest.sha256"], cwd=root,
                        capture_output=True, text=True)
if result.returncode:
    raise SystemExit(12)
shutil.rmtree(root)
