#!/usr/bin/env python3
"""Raw-byte structural checks for module 12 (nodes 002a/002b).

These run *before* the COBOL validator on purpose: a production batch must
measure the physical record length of the received bytes, not rely on a
space-trimmed picture size.  A short or long record, CRLF, or a missing final
LF is a structural error (RC8), never silently padded or truncated.

The customer feed is the independent, versioned CAP-CUSTOMER-FEED layout
(v1 = 31 B, v2 = 32 B); it embeds the canonical 27 byte CUSTOMER v1, whose
byte 27 is the record status.  The customer classification is separate.

  length  --tx FILE [--customer FILE] --layout v1|v2
  numeric --tx FILE [--customer FILE] --layout v1|v2

Receives the frozen snapshot paths; writes nothing but stdout counts.
"""
from __future__ import annotations

import argparse
import sys

TX_WIDTH = 55
# Enterprise customer feed widths (independent, versioned layout that
# embeds the 27 byte canonical CUSTOMER v1; byte 27 is the status).
CUST_V1 = 31
CUST_V2 = 32


def fail(message: str) -> "NoReturn":  # type: ignore[name-defined]
    print(f"validate: {message}", file=sys.stderr)
    raise SystemExit(8)


def die_system(message: str) -> "NoReturn":  # type: ignore[name-defined]
    print(f"validate: {message}", file=sys.stderr)
    raise SystemExit(12)


def read_raw(path: str, width: int, label: str) -> list[bytes]:
    try:
        with open(path, "rb") as handle:
            data = handle.read()
    except OSError as error:
        die_system(f"cannot read {label}: {error}")
    if data == b"":
        return []
    if not data.endswith(b"\n"):
        fail(f"{label} missing final LF")
    if b"\r" in data:
        fail(f"{label} contains CR (CRLF not allowed)")
    rows = data[:-1].split(b"\n")
    for index, row in enumerate(rows, 1):
        if len(row) != width:
            fail(f"{label} line {index} width {len(row)} != {width}")
    return rows


def cmd_length(args: argparse.Namespace) -> int:
    tx = read_raw(args.tx, TX_WIDTH, "transaction")
    out = [f"tx_records={len(tx)}", f"tx_width={TX_WIDTH}"]
    if args.customer:
        width = CUST_V1 if args.layout == "v1" else CUST_V2
        cust = read_raw(args.customer, width, "customer")
        out.append(f"customer_records={len(cust)}")
        out.append(f"customer_width={width}")
    print(" ".join(out))
    return 0


def cmd_numeric(args: argparse.Namespace) -> int:
    tx = read_raw(args.tx, TX_WIDTH, "transaction")
    for index, row in enumerate(tx, 1):
        if not row[0:10].isdigit():
            fail(f"transaction line {index}: non-numeric account_id")
        if not row[26:34].isdigit():
            fail(f"transaction line {index}: non-numeric business_date")
        if not row[34:40].isdigit():
            fail(f"transaction line {index}: non-numeric sequence_no")
        if not row[41:54].isdigit():
            fail(f"transaction line {index}: non-numeric amount")
        if row[10:26].strip() == b"":
            fail(f"transaction line {index}: blank transaction_id")
    out = [f"tx_numeric_ok={len(tx)}"]
    if args.customer:
        width = CUST_V1 if args.layout == "v1" else CUST_V2
        cust = read_raw(args.customer, width, "customer")
        for index, row in enumerate(cust, 1):
            if not row[0:8].isdigit():
                fail(f"customer line {index}: non-numeric customer_id")
        out.append(f"customer_numeric_ok={len(cust)}")
    print(" ".join(out))
    return 0


def cmd_keys(args: argparse.Namespace) -> int:
    """Detect duplicate transaction_id values with a clear, loggable reason."""
    tx = read_raw(args.tx, TX_WIDTH, "transaction")
    seen: dict[bytes, int] = {}
    duplicates: list[str] = []
    for row in tx:
        txid = row[10:26]
        seen[txid] = seen.get(txid, 0) + 1
    for txid, count in seen.items():
        if count > 1:
            duplicates.append(f"{txid.decode('ascii')}x{count}")
    if duplicates:
        print("validate: duplicate transaction_id " + ",".join(sorted(duplicates)),
              file=sys.stderr)
        return 8
    print(f"keys_unique={len(seen)}")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="validate.py")
    sub = parser.add_subparsers(dest="command", required=True)
    for name, func in (("length", cmd_length), ("numeric", cmd_numeric),
                       ("keys", cmd_keys)):
        p = sub.add_parser(name)
        p.add_argument("--tx", required=True)
        p.add_argument("--customer")
        p.add_argument("--layout", choices=["v1", "v2"], default="v1")
        p.set_defaults(func=func)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except OSError as error:
        print(f"validate: system error: {error}", file=sys.stderr)
        raise SystemExit(12)
