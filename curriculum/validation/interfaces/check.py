#!/usr/bin/env python3
"""Frozen bank interface guard.

Every ACCOUNT-V1/TRANSACTION-V1/CUSTOMER-V1 copybook that ships under a
``copybooks/`` directory must compile against the real GnuCOBOL ABI to the
frozen record width (47 / 55 / 27 bytes).  This protects the frozen layout
from silent drift even though modules may give the fields locally scoped
COBOL names (prefixes are sometimes needed to avoid duplicate data names when
several interfaces are COPYed into one program).  Intentional teaching
deviations (e.g. module 02's off-by-one layout experiment) live outside
``copybooks/`` and are therefore not treated as the frozen interface.
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[2]          # curriculum/
instructor = root.parent / "instructor"
EXPECTED = {"ACCOUNT-V1.CPY": 47, "TRANSACTION-V1.CPY": 55, "CUSTOMER-V1.CPY": 27}

targets = sorted(p for p in (*root.glob("**/copybooks/*.CPY"),
                             *instructor.glob("**/copybooks/*.CPY"))
                 if p.name in EXPECTED)
if not targets:
    print("no frozen interface copybooks found", file=sys.stderr)
    raise SystemExit(12)

failures = []
with tempfile.TemporaryDirectory(prefix="ifguard-") as tmp:
    tmp = Path(tmp)
    for copybook in targets:
        recorded = re.search(r"^\s*01\s+([A-Z0-9-]+)\.",
                             copybook.read_text(), re.M)
        if not recorded:
            failures.append((copybook, "no 01-level record"))
            continue
        record = recorded.group(1)
        source = tmp / "probe.COB"
        exe = tmp / "probe"
        source.write_text(
            "       IDENTIFICATION DIVISION.\n"
            "       PROGRAM-ID. IFGUARD.\n"
            "       DATA DIVISION.\n"
            "       WORKING-STORAGE SECTION.\n"
            f"          COPY {copybook.name}.\n"
            "       PROCEDURE DIVISION.\n"
            f"           DISPLAY LENGTH OF {record}.\n"
            "           STOP RUN.\n")
        built = subprocess.run(
            ["cobc", "-I", str(copybook.parent), "-x", "-o", str(exe), str(source)],
            capture_output=True, text=True)
        if built.returncode:
            failures.append((copybook, "compile: " +
                             " | ".join(built.stderr.strip().splitlines()[-2:])))
            continue
        measured = subprocess.run([str(exe)], capture_output=True,
                                  text=True).stdout.strip().splitlines()
        width = measured[-1] if measured else ""
        if width != str(EXPECTED[copybook.name]):
            failures.append((copybook, f"width {width} != {EXPECTED[copybook.name]}"))

for path, reason in failures:
    print(f"FAIL {path.relative_to(root.parent)}: {reason}", file=sys.stderr)
if failures:
    raise SystemExit(12)
print(f"PASS: {len(targets)} frozen bank interface copybooks compile to 27/47/55 bytes")
