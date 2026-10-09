#!/usr/bin/env python3
"""Run instructor MERGE core directly, bypassing the Python preflight."""
from pathlib import Path
import os
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[5]
SOURCE = Path(os.environ.get(
    "COURSE_SOURCE", REPO / "instructor/modules/07/02-sort-merge/MERGETX.COB"))
COPYBOOKS = REPO / "curriculum/bank/copybooks"
base = (LAB / "fixtures/normal/feed-a.dat").read_bytes()
row = base.split(b"\n", 1)[0]
variants = {
    "valid": (base, 0),
    "short": (row[:-1] + b"\n", 8),
    "long": (row + b"X\n", 8),
    "no-lf": (row, 8),
    "crlf": (row + b"\r\n", 8),
    "tab": (row[:10] + b"\t" + row[11:] + b"\n", 8),
    "nul": (row[:10] + b"\0" + row[11:] + b"\n", 8),
    "bad-date": (row[:26] + b"20260230" + row[34:] + b"\n", 8),
    "bad-direction": (row[:40] + b"X" + row[41:] + b"\n", 8),
    "reverse": (b"\n".join(reversed(base.splitlines())) + b"\n", 8),
}
with tempfile.TemporaryDirectory(prefix="b02-merge-core-") as tmp:
    binary = Path(tmp) / "mergetx"
    built = subprocess.run(["cobc", "-Wall", "-I", str(COPYBOOKS), "-x",
                            "-o", str(binary), str(SOURCE)],
                           text=True, capture_output=True)
    assert built.returncode == 0, built.stderr
    for name, (payload, expected_rc) in variants.items():
        source = Path(tmp) / f"{name}.dat"
        empty = Path(tmp) / "empty.dat"
        output = Path(tmp) / f"{name}.candidate"
        source.write_bytes(payload)
        empty.write_bytes(b"")
        env = dict(os.environ, B02_INPUT_A=str(source), B02_INPUT_B=str(empty),
                   B02_OUTPUT=str(output), B02_DATE="20261009",
                   COB_SORT_MEMORY="2M", TMPDIR=tmp)
        proc = subprocess.run([str(binary)], env=env, text=True,
                              capture_output=True)
        assert proc.returncode == expected_rc, (name, proc.returncode,
                                                 proc.stdout, proc.stderr)
        if expected_rc:
            assert not output.exists(), f"{name}: rejected feed opened output"
    print("PASS: COBOL MERGE validates raw bytes, fields, date, and feed order")
