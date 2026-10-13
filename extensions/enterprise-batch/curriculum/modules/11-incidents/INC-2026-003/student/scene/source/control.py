#!/usr/bin/env python3
"""JOB007 control-total and daily-report reconciliation (module 10).

Reads the real streams produced by the run and checks conservation.  It
does not change any business data; a mismatch is RC8 and blocks publish.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

ACCOUNT_WIDTH = 47
TX_WIDTH = 55


def load_records(path: Path, width: int) -> list[bytes]:
    data = path.read_bytes()
    if data == b"":
        return []
    if not data.endswith(b"\n"):
        raise ValueError(f"{path} missing final LF")
    rows = data[:-1].split(b"\n")
    for row in rows:
        if len(row) != width:
            raise ValueError(f"{path} record width != {width}")
    return rows


def signed(sign: bytes, digits: bytes) -> int:
    value = int(digits.decode("ascii"))
    return -value if sign == b"-" else value


def parse_validate_control(path: Path) -> dict[str, int]:
    values: dict[str, int] = {}
    for line in path.read_text(encoding="ascii").splitlines():
        for item in line.split("|")[1:]:
            key, _, value = item.partition("=")
            if value.isdigit():
                values[key] = int(value)
    return values


def main() -> int:
    run = Path(os.environ["BANK_RUN_DIR"])
    db = Path(os.environ["BANK_DB_DIR"])
    date = os.environ["BANK_BUSINESS_DATE"]
    vconf = parse_validate_control(run / "work/validate/control.txt")
    validate_accepted = load_records(run / "work/validate/accepted_tx.dat",
                                     TX_WIDTH)
    opening = load_records(run / "work/db/account_master.dat", ACCOUNT_WIDTH)
    closing = load_records(run / "work/closing/master.dat", ACCOUNT_WIDTH)
    accepted = load_records(run / "work/closing/accepted.dat", TX_WIDTH)
    rejected = (run / "work/closing/rejected.dat").read_text(
        encoding="ascii").splitlines()

    problems: list[str] = []
    received = vconf.get("RECEIVED", -1)
    v_acc = vconf.get("ACCEPTED", -1)
    v_rej = vconf.get("REJECTED", -1)
    if received != v_acc + v_rej or received < 0:
        problems.append("JOB002 receive/accepted/rejected not conserved")
    if v_acc != len(validate_accepted):
        problems.append("JOB002 accepted count != accepted_tx records")
    if v_acc != len(accepted) + len(rejected):
        problems.append("JOB002 accepted != match accepted + match rejected")
    if len(opening) != len(closing):
        problems.append("opening/closing account count differ")

    credits = sum(int(r[41:54]) for r in accepted if r[40:41] == b"C")
    debits = sum(int(r[41:54]) for r in accepted if r[40:41] == b"D")
    opening_total = sum(signed(r[21:22], r[22:35]) for r in opening)
    closing_total = sum(signed(r[21:22], r[22:35]) for r in closing)

    by_acct: dict[str, list[int]] = {}
    for r in accepted:
        entry = by_acct.setdefault(r[:10].decode("ascii"), [0, 0])
        value = int(r[41:54])
        entry[0 if r[40:41] == b"C" else 1] += value

    lines = ["business_date=" + date,
             "accounts=%d" % len(opening), "JOB007 control report", ""]
    for row in closing:
        acct = row[:10].decode("ascii")
        open_row = next((r for r in opening if r[:10] == row[:10]), None)
        if open_row is None:
            problems.append(f"account {acct} missing in opening")
            continue
        opening_v = signed(open_row[21:22], open_row[22:35])
        closing_v = signed(row[21:22], row[22:35])
        cr, dr = by_acct.get(acct, [0, 0])
        if opening_v + cr - dr != closing_v:
            problems.append(
                f"account {acct}: {opening_v}+{cr}-{dr} != {closing_v}")
        lines.append(
            f"ACCOUNT|{acct}|OPENING={opening_v}|CREDIT={cr}|"
            f"DEBIT={dr}|CLOSING={closing_v}")

    ledger_lines = []
    lpath = db / "ledger.dat"
    if lpath.exists():
        ledger_lines = [l for l in lpath.read_text(encoding="ascii")
                        .splitlines() if l.startswith(date + "|")]
    if len(ledger_lines) != len(accepted):
        problems.append(
            f"ledger applied {len(ledger_lines)} != match accepted {len(accepted)}")
    ledger_delta = 0
    for line in ledger_lines:
        parts = line.split("|")
        ledger_delta += int(parts[4]) if parts[3] == "C" else -int(parts[4])
    if ledger_delta != closing_total - opening_total:
        problems.append("ledger delta != closing-opening")

    lines.append("")
    lines.append("CONTROL|RECEIVED=%d|VALIDATE_ACCEPTED=%d|"
                 "VALIDATE_REJECTED=%d|MATCH_ACCEPTED=%d|MATCH_REJECTED=%d|"
                 "LEDGER_APPLIED=%d" %
                 (received, v_acc, v_rej, len(accepted), len(rejected),
                  len(ledger_lines)))
    lines.append("CONTROL|ACCOUNTS=%d|OPENING=%d|CREDIT=%d|DEBIT=%d|CLOSING=%d"
                 % (len(opening), opening_total, credits, debits, closing_total))

    out = run / "work/control"
    out.mkdir(parents=True, exist_ok=True)
    (out / "report.txt").write_text("\n".join(lines) + "\n", encoding="ascii")
    (out / "control.txt").write_text(
        "received=%d\nvalidate_accepted=%d\nvalidate_rejected=%d\n"
        "batch_accepted=%d\nbatch_rejected=%d\nledger_applied=%d\n"
        "accounts=%d\nopening_total=%d\ncredit_total=%d\ndebit_total=%d\n"
        "closing_total=%d\n" %
        (received, v_acc, v_rej, len(accepted), len(rejected),
         len(ledger_lines), len(opening), opening_total, credits, debits,
         closing_total), encoding="ascii")

    if problems:
        for problem in problems:
            print("JOB007 FAIL: " + problem, file=sys.stderr)
        return 8
    print("JOB007 PASS: control totals reconciled "
          f"(received={received} applied={len(accepted)})")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as error:
        print(f"JOB007 system error: {error}", file=sys.stderr)
        raise SystemExit(12)
