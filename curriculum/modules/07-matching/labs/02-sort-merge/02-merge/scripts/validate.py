#!/usr/bin/env python3
"""Streaming raw-byte contract gate; uniqueness spills to disk and sort(1)."""
from datetime import date
from pathlib import Path
import subprocess
import sys
import tempfile

WIDTH = 55

def key(row):
    return row[:10], row[34:40], row[10:26]

def valid(row, business_date):
    if len(row) != WIDTH or any(byte > 0x7e or byte < 0x20 for byte in row):
        return False
    if (not row[:10].isdigit() or not all(
            48 <= c <= 57 or 65 <= c <= 90 for c in row[10:26])):
        return False
    if row[26:34] != business_date.encode("ascii"):
        return False
    try:
        date(int(row[26:30]), int(row[30:32]), int(row[32:34]))
    except ValueError:
        return False
    return (row[34:40].isdigit() and row[40:41] in (b"C", b"D")
            and row[41:54].isdigit()
            and row[54:55] == b"N")

def main():
    date_text = sys.argv[1]
    ids_path = Path(sys.argv[2])
    require_sorted = sys.argv[3] == "strict"
    sources = [Path(value) for value in sys.argv[4:]]
    try:
        date(int(date_text[:4]), int(date_text[4:6]), int(date_text[6:8]))
    except (ValueError, IndexError):
        return 8
    if len(date_text) != 8 or not date_text.isascii() or not date_text.isdigit():
        return 8
    count = 0
    with ids_path.open("wb") as ids:
        for source in sources:
            previous_key = None
            with source.open("rb") as inp:
                while True:
                    line = inp.readline(WIDTH + 2)
                    if not line:
                        break
                    if len(line) != WIDTH + 1 or line[-1:] != b"\n":
                        return 8
                    row = line[:-1]
                    if not valid(row, date_text):
                        return 8
                    current_key = key(row)
                    if (require_sorted and previous_key is not None
                            and current_key <= previous_key):
                        return 8
                    previous_key = current_key
                    ids.write(row[10:26] + b"\n")
                    count += 1
    sorted_ids = ids_path.with_suffix(".sorted")
    with sorted_ids.open("wb") as target:
        proc = subprocess.run(["sort", "-T", str(ids_path.parent),
                               str(ids_path)], stdout=target,
                              stderr=subprocess.PIPE)
    if proc.returncode:
        return 12
    with sorted_ids.open("rb") as inp:
        previous = None
        while line := inp.readline(18):
            if len(line) != 17 or line[-1:] != b"\n":
                return 12
            current = line[:-1]
            if current == previous:
                return 8
            previous = current
    print(count)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
