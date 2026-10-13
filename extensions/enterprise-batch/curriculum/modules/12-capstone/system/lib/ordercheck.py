#!/usr/bin/env python3
"""Sorted-order and duplicate-key evidence for module 12 node 003c.

The course contract (BANK-SYSTEM 4) is that transactions are ordered by
account_id, sequence_no, transaction_id before the sequential match, and
that a duplicate transaction_id is a business error, never applied twice.

  ordercheck.py --tx FILE

RC0: strictly ascending and no duplicate transaction_id.
RC8: out of order, or a duplicate transaction_id was found.
"""
from __future__ import annotations

import argparse
import sys

WIDTH = 55


def key(row: bytes) -> tuple[bytes, bytes, bytes]:
    return (row[0:10], row[34:40], row[10:26])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tx", required=True)
    args = parser.parse_args()
    with open(args.tx, "rb") as handle:
        data = handle.read()
    rows = data[:-1].split(b"\n") if data.endswith(b"\n") else \
        data.split(b"\n")
    rows = [r for r in rows if r != b""]
    seen: set[bytes] = set()
    previous: tuple[bytes, bytes, bytes] | None = None
    for index, row in enumerate(rows, 1):
        if len(row) != WIDTH:
            print(f"ordercheck: line {index} width {len(row)}", file=sys.stderr)
            return 8
        txid = row[10:26]
        if txid in seen:
            print(f"ordercheck: duplicate transaction_id {txid.decode()}",
                  file=sys.stderr)
            return 8
        seen.add(txid)
        current = key(row)
        if previous is not None and current < previous:
            print(f"ordercheck: line {index} out of order", file=sys.stderr)
            return 8
        previous = current
    print(f"ordercheck: sorted_ok={len(rows)} duplicates=0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
