#!/usr/bin/env python3
"""Run instructor SORT core directly to prove COBOL raw-byte rejection."""
from pathlib import Path
import os
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[5]
SOURCE = Path(os.environ.get(
    "COURSE_SOURCE", REPO / "instructor/modules/07/02-sort-merge/SORTTX.COB"))
COPYBOOKS = REPO / "curriculum/bank/copybooks"
base = (LAB / "fixtures/normal/transaction.dat").read_bytes().split(b"\n", 1)[0]
valid = base + b"\n"
variants = {
    "valid": (valid, 0),
    "zero-amount": (base[:41] + b"0000000000000" + base[54:] + b"\n", 0),
    "short": (base[:-1] + b"\n", 8),
    "long": (base + b"X\n", 8),
    "no-lf": (base, 8),
    "crlf": (base + b"\r\n", 8),
    "tab": (base[:10] + b"\t" + base[11:] + b"\n", 8),
    "nul": (base[:10] + b"\0" + base[11:] + b"\n", 8),
    "bad-date": (base[:26] + b"20260230" + base[34:] + b"\n", 8),
    "bad-direction": (base[:40] + b"X" + base[41:] + b"\n", 8),
    "lowercase-id": (base[:10] + b"z" + base[11:] + b"\n", 8),
    "space-id": (base[:10] + b" " + base[11:] + b"\n", 8),
    "status-r": (base[:54] + b"R\n", 8),
}
with tempfile.TemporaryDirectory(prefix="b02-sort-core-") as tmp:
    binary = Path(tmp) / "sorttx"
    built = subprocess.run(["cobc", "-Wall", "-I", str(COPYBOOKS), "-x",
                            "-o", str(binary), str(SOURCE)],
                           text=True, capture_output=True)
    assert built.returncode == 0, built.stderr
    for name, (payload, expected_rc) in variants.items():
        source = Path(tmp) / f"{name}.dat"
        output = Path(tmp) / f"{name}.candidate"
        source.write_bytes(payload)
        env = dict(os.environ, B02_INPUT=str(source), B02_OUTPUT=str(output),
                   B02_DATE="20261009", COB_SORT_MEMORY="2M", TMPDIR=tmp)
        proc = subprocess.run([str(binary)], env=env, text=True,
                              capture_output=True)
        assert proc.returncode == expected_rc, (name, proc.returncode,
                                                 proc.stdout, proc.stderr)
    print("PASS: COBOL SORT validates raw 55B+LF, fields, and Gregorian date")
