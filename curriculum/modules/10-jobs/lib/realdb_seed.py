#!/usr/bin/env python3
"""Emit PostgreSQL seed SQL for module 10's real-DB (JOB004/JOB006) route.

Reads the frozen module 10 seed files (ACCOUNT v1 47B, CUSTOMER v1 27B) and
emits INSERTs for the canonical module 08 schema (customer/account/
account_balance).  This is only data loading; the real extraction and the
single-transaction apply are performed by the canonical ESQL programs
(SNAPSHOT.COB / APPLY.COB) in the tool container, and verified by an
independent psql connection.

  realdb_seed.py --account ACCOUNT.DAT --customer CUSTOMER.DAT --date YYYYMMDD
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

ACCOUNT_WIDTH = 47
CUSTOMER_WIDTH = 27


def rows(path: Path, width: int) -> list[bytes]:
    data = path.read_bytes()
    if not data.endswith(b"\n"):
        raise SystemExit(f"{path}: missing final LF")
    out = []
    for row in data[:-1].split(b"\n"):
        if len(row) != width:
            raise SystemExit(f"{path}: width {len(row)} != {width}")
        out.append(row)
    return out


def sql_str(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--account", required=True)
    parser.add_argument("--customer", required=True)
    parser.add_argument("--date", required=True)
    args = parser.parse_args(argv)

    accounts = rows(Path(args.account), ACCOUNT_WIDTH)
    customers = rows(Path(args.customer), CUSTOMER_WIDTH)

    lines = ["BEGIN;"]
    for row in customers:
        cid = row[0:8].decode("ascii")
        name = row[8:18].decode("ascii")
        balance = int(row[18:26].decode("ascii"))
        status = row[26:27].decode("ascii")
        lines.append(
            "INSERT INTO customer (customer_id, customer_name, balance_demo, "
            "status, contact_note, business_date, layout_version) VALUES ("
            f"{sql_str(cid)}, {sql_str(name)}, {balance}, {sql_str(status)}, "
            f"NULL, {sql_str(args.date)}, '001');")
    for row in accounts:
        aid = row[0:10].decode("ascii")
        cid = row[10:18].decode("ascii")
        currency = row[18:21].decode("ascii")
        sign = row[21:22].decode("ascii")
        opening = int(row[22:35].decode("ascii"))
        if sign == "-":
            opening = -opening
        status = row[35:36].decode("ascii")
        lines.append(
            "INSERT INTO account (account_id, customer_id, currency, "
            "balance_sign, opening_balance, closing_balance, account_status, "
            "business_date, layout_version) VALUES ("
            f"{sql_str(aid)}, {sql_str(cid)}, {sql_str(currency)}, "
            f"{sql_str(sign)}, {opening}, {opening}, {sql_str(status)}, "
            f"{sql_str(args.date)}, '001');")
        lines.append(
            "INSERT INTO account_balance (account_id, balance) VALUES ("
            f"{sql_str(aid)}, {opening});")
    lines.append("COMMIT;")
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
