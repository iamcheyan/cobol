#!/usr/bin/env python3
"""Enterprise customer CLASS layout v1 <-> v2 migration and validation.

Module 11 maintenance 11.5.  The field being widened is the customer
DISTINCTION (classification) of the independent, versioned
ENTERPRISE-CLASS layout -- NOT the 27-byte canonical CUSTOMER v1 record,
whose byte 27 is the record STATUS (A/D).

The lab layout deliberately uses a distinct name (ENTERPRISE-CLASS) from
the canonical 175-field / 1778-byte module 07 L4 record
ENTERPRISE-CUSTOMER-V1, so a 23/24-byte lab record never collides with the
canonical enterprise record (no same-name / different-layout drift).

  enterprise-class v1 = 23 bytes, layout 001:
      layout_version(3) customer_id(8) record_status(1)
      customer_name(10) classification(1)
  enterprise-class v2 = 24 bytes, layout 002:
      ... classification(2)
  mapping: A -> A1, B -> B1, C -> C1, D -> D1.

The mapper never rewrites a v1 file in place; it writes a NEW v2 file and
can roll back v2 -> v1.  Unknown single-character codes, a wrong layout
version or a wrong width are rejected (RC8) instead of being guessed.

Commands:
  to-v2   IN.v1 OUT.v2
  to-v1   IN.v2 OUT.v1        (rollback; requires the second char '1')
  verify  A.v1  B.v2          (parallel validation, RC0/8)
"""
from __future__ import annotations

import sys
from pathlib import Path

V1_WIDTH = 23
V2_WIDTH = 24
V1_VERSION = "001"
V2_VERSION = "002"
MAPPING = {"A": "A1", "B": "B1", "C": "C1", "D": "D1"}
HEAD = slice(3, 22)  # customer_id + record_status + customer_name


def read_lines(path: Path, width: int) -> list[str]:
    data = path.read_bytes()
    if data == b"":
        return []
    if not data.endswith(b"\n"):
        raise ValueError(f"{path} missing final LF")
    rows = []
    for i, raw in enumerate(data[:-1].split(b"\n"), 1):
        if len(raw) != width:
            raise ValueError(f"{path}:{i} width {len(raw)} != {width}")
        rows.append(raw.decode("ascii"))
    return rows


def write_lines(path: Path, rows: list[str]) -> None:
    path.write_text("".join(r + "\n" for r in rows), encoding="ascii")


def to_v2(src: Path, dst: Path) -> int:
    out = []
    for text in read_lines(src, V1_WIDTH):
        if text[0:3] != V1_VERSION:
            print(f"migrate: v1 layout version {text[0:3]!r} not 001",
                  file=sys.stderr)
            return 8
        code = text[22:23]
        if code not in MAPPING:
            print(f"migrate: unknown v1 classification {code!r}",
                  file=sys.stderr)
            return 8
        out.append(V2_VERSION + text[HEAD] + MAPPING[code])
    write_lines(dst, out)
    return 0


def to_v1(src: Path, dst: Path) -> int:
    out = []
    for text in read_lines(src, V2_WIDTH):
        if text[0:3] != V2_VERSION:
            print(f"migrate: v2 layout version {text[0:3]!r} not 002",
                  file=sys.stderr)
            return 8
        code = text[22:24]
        if code not in MAPPING.values():
            print(f"migrate: cannot roll back v2 code {code!r}",
                  file=sys.stderr)
            return 8
        out.append(V1_VERSION + text[HEAD] + code[0])
    write_lines(dst, out)
    return 0


def verify(v1: Path, v2: Path) -> int:
    a = read_lines(v1, V1_WIDTH)
    b = read_lines(v2, V2_WIDTH)
    if len(a) != len(b):
        print("verify: row count differs", file=sys.stderr)
        return 8
    for left, right in zip(a, b):
        if left[0:3] != V1_VERSION or right[0:3] != V2_VERSION \
                or left[HEAD] != right[HEAD] \
                or right[22:24] != MAPPING.get(left[22:23]):
            print(f"verify: mismatch {left!r} vs {right!r}",
                  file=sys.stderr)
            return 8
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 4:
        print(__doc__, file=sys.stderr)
        return 12
    command, a, b = argv[1], Path(argv[2]), Path(argv[3])
    try:
        if command == "to-v2":
            return to_v2(a, b)
        if command == "to-v1":
            return to_v1(a, b)
        if command == "verify":
            return verify(a, b)
    except (OSError, ValueError) as error:
        print(f"migrate system error: {error}", file=sys.stderr)
        return 12
    print(f"unknown command {command!r}", file=sys.stderr)
    return 12


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
