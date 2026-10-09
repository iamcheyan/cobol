#!/usr/bin/env python3
"""Independent bounded-memory byte, order, and multiset verification."""
from pathlib import Path
import subprocess
import os
import sys
import tempfile

source_files = [Path(value) for value in sys.argv[1:-1]]
candidate = Path(sys.argv[-1])
with tempfile.TemporaryDirectory(prefix="b02-sort-oracle-") as temp:
    left, right = Path(temp) / "source.sorted", Path(temp) / "candidate.sorted"
    combined = Path(temp) / "all-inputs"
    with combined.open("wb") as out:
        for src in source_files:
            with src.open("rb") as inp:
                while chunk := inp.read(65536):
                    out.write(chunk)
    for src, dst in ((combined, left), (candidate, right)):
        # Compare byte-sorted rows independent of the lesson's business key.
        with src.open("rb") as inp, dst.open("wb") as out:
            proc = subprocess.run(["sort", "-T", temp], stdin=inp,
                                  stdout=out, env={**os.environ,
                                                   "LC_ALL":"C"})
        if proc.returncode:
            raise SystemExit(12)
    with left.open("rb") as a, right.open("rb") as b:
        while True:
            x, y = a.read(65536), b.read(65536)
            if x != y:
                raise SystemExit("RC12: output is not the exact input multiset")
            if not x:
                break

prev = None
count = 0
with candidate.open("rb") as stream:
    while line := stream.readline(57):
        if len(line) != 56 or line[-1:] != b"\n":
            raise SystemExit("RC12: candidate has malformed record bytes")
        row = line[:-1]
        key = (row[:10], row[34:40], row[10:26])
        if prev is not None and key <= prev:
            raise SystemExit("RC12: candidate business keys are not strict")
        prev = key
        count += 1
print(f"Verified {count} exact 55-byte records")
