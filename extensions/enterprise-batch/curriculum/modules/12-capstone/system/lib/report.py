#!/usr/bin/env python3
"""Independent conservation and customer-day checks for module 12 JOB007.

Reads the real streams the run produced and reconciles them against the
written contracts.  It never trusts a program's own success message; a
mismatch is RC8 and blocks publication.

  report.py counts       -- count conservation across the stages
  report.py amounts      -- opening + credits - debits == closing, per account
  report.py ledger       -- DB ledger agrees with the accepted stream
  report.py customerday  -- NIGHTRPT customer-day file agrees with closing
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

ACCOUNT_WIDTH = 47
TX_WIDTH = 55
DAY_WIDTH = 30
DAY_DIST_OFFSET = 8
DAY_COUNT_OFFSET = 10
DAY_SIGN_OFFSET = 16
DAY_TOTAL_OFFSET = 17


def die(message: str) -> "NoReturn":  # type: ignore[name-defined]
    print(f"report: {message}", file=sys.stderr)
    raise SystemExit(8)


def system(message: str) -> "NoReturn":  # type: ignore[name-defined]
    print(f"report: {message}", file=sys.stderr)
    raise SystemExit(12)


def rows(path: Path, width: int) -> list[bytes]:
    try:
        data = path.read_bytes()
    except OSError as error:
        system(f"cannot read {path}: {error}")
    if data == b"":
        return []
    if not data.endswith(b"\n"):
        die(f"{path} missing final LF")
    out = data[:-1].split(b"\n")
    for row in out:
        if len(row) != width:
            die(f"{path} width {len(row)} != {width}")
    return out


def signed(sign: bytes, digits: bytes) -> int:
    value = int(digits.decode("ascii"))
    return -value if sign == b"-" else value


def parse_validate_control(path: Path) -> dict[str, int]:
    values: dict[str, int] = {}
    try:
        text = path.read_text(encoding="ascii")
    except OSError as error:
        system(f"cannot read {path}: {error}")
    for line in text.splitlines():
        for item in line.split("|")[1:]:
            key, _, value = item.partition("=")
            if value.isdigit():
                values[key] = int(value)
    return values


def env_run() -> tuple[Path, Path, str]:
    return (Path(os.environ["NIGHT_OUTPUT"]), Path(os.environ["NIGHT_DB"]),
            os.environ["NIGHT_DATE"])


def cmd_counts(_args: argparse.Namespace) -> int:
    run, _, _ = env_run()
    conf = parse_validate_control(run / "work/validate/control.txt")
    v_accepted = rows(run / "work/validate/accepted_tx.dat", TX_WIDTH)
    m_accepted = rows(run / "work/closing/accepted.dat", TX_WIDTH)
    m_rejected = (run / "work/closing/rejected.dat").read_text(
        encoding="ascii").splitlines()
    m_rejected = [r for r in m_rejected if r.strip()]
    received, acc, rej = conf.get("RECEIVED", -1), conf.get("ACCEPTED", -1), \
        conf.get("REJECTED", -1)
    if received != acc + rej or received < 0:
        die("JOB002 receive/accepted/rejected not conserved")
    if acc != len(v_accepted):
        die("JOB002 accepted != accepted_tx rows")
    if acc != len(m_accepted) + len(m_rejected):
        die("validate accepted != match accepted + match rejected")
    print(f"counts_ok received={received} validate_accepted={acc} "
          f"match_accepted={len(m_accepted)} match_rejected={len(m_rejected)}")
    return 0


def cmd_amounts(_args: argparse.Namespace) -> int:
    run, _, _ = env_run()
    opening = rows(run / "work/db/account_master.dat", ACCOUNT_WIDTH)
    closing = rows(run / "work/closing/master.dat", ACCOUNT_WIDTH)
    accepted = rows(run / "work/closing/accepted.dat", TX_WIDTH)
    if len(opening) != len(closing):
        die("opening/closing account count differ")
    by_acct: dict[str, list[int]] = {}
    for row in accepted:
        entry = by_acct.setdefault(row[:10], [0, 0])
        entry[0 if row[40:41] == b"C" else 1] += int(row[41:54])
    open_map = {r[:10]: signed(r[21:22], r[22:35]) for r in opening}
    for row in closing:
        acct = row[:10]
        if acct not in open_map:
            die(f"account {acct.decode()} missing in opening")
        cr, dr = by_acct.get(acct, [0, 0])
        if open_map[acct] + cr - dr != signed(row[21:22], row[22:35]):
            die(f"account {acct.decode()}: {open_map[acct]}+{cr}-{dr} != "
                f"{signed(row[21:22], row[22:35])}")
    print(f"amounts_ok accounts={len(opening)} "
          f"opening={sum(open_map.values())} "
          f"closing={sum(signed(r[21:22], r[22:35]) for r in closing)}")
    return 0


def cmd_ledger(_args: argparse.Namespace) -> int:
    run, db, date = env_run()
    accepted = rows(run / "work/closing/accepted.dat", TX_WIDTH)
    lines = []
    if (db / "ledger.dat").exists():
        lines = [l for l in (db / "ledger.dat").read_text(
            encoding="ascii").splitlines() if l.startswith(date + "|")]
    if len(lines) != len(accepted):
        die(f"ledger applied {len(lines)} != match accepted {len(accepted)}")
    delta = 0
    for line in lines:
        parts = line.split("|")
        delta += int(parts[4]) if parts[3] == "C" else -int(parts[4])
    opening = rows(run / "work/db/account_master.dat", ACCOUNT_WIDTH)
    closing = rows(run / "work/closing/master.dat", ACCOUNT_WIDTH)
    open_total = sum(signed(r[21:22], r[22:35]) for r in opening)
    close_total = sum(signed(r[21:22], r[22:35]) for r in closing)
    if delta != close_total - open_total:
        die("ledger delta != closing - opening")
    print(f"ledger_ok applied={len(lines)} delta={delta}")
    return 0


def cmd_customerday(_args: argparse.Namespace) -> int:
    run, _, _ = env_run()
    closing = rows(run / "work/closing/master.dat", ACCOUNT_WIDTH)
    day = rows(run / "work/report/customer-day.dat", DAY_WIDTH)
    customer = rows(run / "work/customer/customer_v2.dat", 32)
    close_total = sum(signed(r[21:22], r[22:35]) for r in closing)
    day_total = sum(signed(r[DAY_SIGN_OFFSET:DAY_SIGN_OFFSET + 1],
                           r[DAY_TOTAL_OFFSET:DAY_TOTAL_OFFSET + 13])
                   for r in day)
    if day_total != close_total:
        die(f"customer-day total {day_total} != closing {close_total}")
    if len(day) != len(customer):
        die(f"customer-day rows {len(day)} != customer rows {len(customer)}")
    counted = sum(int(r[DAY_COUNT_OFFSET:DAY_COUNT_OFFSET + 6]) for r in day)
    if counted != len(closing):
        die(f"customer-day account count {counted} != accounts {len(closing)}")
    report = (run / "work/report/daily-report.txt").read_text(encoding="ascii")
    if "CONTROL|" not in report:
        die("daily report missing CONTROL line")
    print(f"customerday_ok customers={len(day)} accounts={counted} "
          f"total={day_total}")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="report.py")
    sub = parser.add_subparsers(dest="command", required=True)
    for name, func in (("counts", cmd_counts), ("amounts", cmd_amounts),
                       ("ledger", cmd_ledger), ("customerday", cmd_customerday)):
        sub.add_parser(name).set_defaults(func=func)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except OSError as error:
        print(f"report: system error: {error}", file=sys.stderr)
        raise SystemExit(12)
