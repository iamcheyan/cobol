#!/usr/bin/env python3
"""Generate module 10 fixtures and independently accounted expected files.

The oracle here re-implements the BANKVAL business rules and the 1:N
overdraft rule from the written contracts.  It never reads any course
implementation output.  Fixed, deterministic data only (FR-10).
"""
from __future__ import annotations

import hashlib
from pathlib import Path

MODULE = Path(__file__).resolve().parents[4] / "curriculum/modules/10-jobs"
FIX = MODULE / "fixtures"
EXPECTED = MODULE / "expected"
DATE = "20261009"


def tx(acct, txid, date, seq, direction, amount, status):
    assert len(txid) == 16 and len(acct) == 10
    return f"{acct}{txid}{date}{seq:06d}{direction}{amount:013d}{status}"


def account(acct, cust, sign, balance, status, date=DATE, ver="001"):
    return f"{acct}{cust}JPY{sign}{abs(balance):013d}{status}{date}{ver}"


def customer(cid, name, balance, status):
    return f"{cid}{name:<10}{balance:08d}{status}"


ACCOUNTS = [
    account("0000000001", "00000001", "+", 1000, "A"),
    account("0000000002", "00000001", "+", 50, "A"),
    account("0000000003", "00000002", "+", 0, "A"),
]
CUSTOMERS = [
    customer("00000001", "ALICE", 100, "A"),
    customer("00000002", "BOB", 0, "A"),
]

NORMAL_TX = [
    tx("0000000001", "A000000000000001", DATE, 1, "C", 500, "N"),
    tx("0000000001", "A000000000000002", DATE, 2, "D", 200, "N"),
    tx("0000000001", "A000000000000003", DATE, 3, "D", 900, "N"),
    tx("0000000001", "A000000000000004", DATE, 4, "D", 1400, "N"),  # overdraft
    tx("0000000002", "B000000000000001", DATE, 1, "C", 100, "N"),
    tx("0000000003", "C000000000000001", DATE, 1, "D", 100, "N"),  # overdraft
    tx("0000000001", "D000000000000001", DATE, 5, "C", 300, "X"),  # badstatus
    tx("0000000002", "E000000000000001", DATE, 2, "X", 100, "N"),  # baddir
    tx("0000000003", "F000000000000001", "20261008", 2, "C", 100, "N"),  # baddate
    tx("0000000002", "G000000000000001", DATE, 3, "C", 0, "N"),  # badzero
]


def validate(records, date):
    """Re-implement BANKVAL business rules independently."""
    accepted, rejected = [], {}
    reasons = {"BADDIR": 0, "BADSTATUS": 0, "BADDATE": 0, "BADZERO": 0}
    for row in records:
        if len(row) != 55:
            raise SystemExit("structural error in fixture")
        if not row[0:10].isdigit() or not row[26:34].isdigit() \
                or not row[34:40].isdigit() or not row[41:54].isdigit():
            raise SystemExit("non-numeric key in fixture")
        if row[40] not in "CD":
            reason = "BADDIR"
        elif row[54] != "N":
            reason = "BADSTATUS"
        elif row[26:34] != date:
            reason = "BADDATE"
        elif row[41:54] == "0000000000000":
            reason = "BADZERO"
        else:
            accepted.append(row)
            continue
        reasons[reason] += 1
        rejected[row[10:26]] = reason
    return accepted, reasons


def match(accepted, accounts):
    """Re-implement the 1:N overdraft rule independently."""
    opening = {r[:10]: (1 if r[21] == "+" else -1) * int(r[22:35])
               for r in accounts}
    order = {r[:10]: r for r in accounts}
    closing = dict(opening)
    batch_accepted, batch_rejected = [], []
    for row in sorted(accepted, key=lambda r: (r[:10], r[34:40], r[10:26])):
        acct = row[:10]
        amount = int(row[41:54])
        if row[40] == "C":
            closing[acct] += amount
            batch_accepted.append(row)
        else:
            if closing[acct] - amount < 0:
                batch_rejected.append(row)
            else:
                closing[acct] -= amount
                batch_accepted.append(row)
    master = []
    for row in accounts:
        acct = row[:10]
        sign = "-" if closing[acct] < 0 else "+"
        master.append(row[:21] + sign + f"{abs(closing[acct]):013d}" + row[35:])
    del order
    return batch_accepted, batch_rejected, master, opening, closing


def control_values(records, accounts, date):
    accepted, reasons = validate(records, date)
    b_acc, b_rej, master, opening, closing = match(accepted, accounts)
    credits = sum(int(r[41:54]) for r in b_acc if r[40] == "C")
    debits = sum(int(r[41:54]) for r in b_acc if r[40] == "D")
    return {
        "received": len(records),
        "validate_accepted": len(accepted),
        "validate_rejected": len(records) - len(accepted),
        "batch_accepted": len(b_acc),
        "batch_rejected": len(b_rej),
        "ledger_applied": len(b_acc),
        "accounts": len(accounts),
        "opening_total": sum(opening.values()),
        "credit_total": credits,
        "debit_total": debits,
        "closing_total": sum(closing.values()),
    }, master


def write_fixture(name, records):
    d = FIX / name
    d.mkdir(parents=True, exist_ok=True)
    data = b"".join(r.encode("ascii") + b"\n" for r in records)
    (d / "transaction.dat").write_bytes(data)
    (d / "account_seed.dat").write_bytes(
        b"".join(a.encode("ascii") + b"\n" for a in ACCOUNTS))
    (d / "customer_seed.dat").write_bytes(
        b"".join(c.encode("ascii") + b"\n" for c in CUSTOMERS))
    digest = hashlib.sha256(data).hexdigest()
    (d / "MANIFEST").write_text(
        f"business_date={DATE}\n"
        "layout_transaction=001\nlayout_account=001\nlayout_customer=001\n"
        f"file transaction.dat {digest}\n", encoding="ascii")
    return d


def main():
    write_fixture("normal", NORMAL_TX)
    write_fixture("boundary-empty-tx", [])
    write_fixture("boundary-single", [
        tx("0000000002", "H000000000000001", DATE, 1, "C", 100, "N")])
    (FIX / "invalid-short-record").mkdir(parents=True, exist_ok=True)
    write_fixture("invalid-short-record",
                  [NORMAL_TX[0][:54]])
    write_fixture("invalid-long-record", [NORMAL_TX[0] + "X"])
    bad = "000000000X" + NORMAL_TX[0][10:]
    write_fixture("invalid-bad-digit", [bad])

    EXPECTED.mkdir(exist_ok=True)
    for case in ("normal", "boundary-empty-tx", "boundary-single"):
        d = FIX / case
        records = (d / "transaction.dat").read_text(
            encoding="ascii").splitlines()
        values, master = control_values(records, ACCOUNTS, DATE)
        (EXPECTED / f"{case}.control.txt").write_text(
            "".join(f"{k}={v}\n" for k, v in values.items()),
            encoding="ascii")
        (EXPECTED / f"{case}.closing.txt").write_text(
            "".join(f"{row[:10]}={row[21:35]}\n" for row in master),
            encoding="ascii")
    # Which fixtures must fail structurally, and with which RC.
    (EXPECTED / "invalid.txt").write_text(
        "invalid-short-record=8\ninvalid-long-record=8\n"
        "invalid-bad-digit=8\n", encoding="ascii")
    # Fixture checksum manifest (relative paths, as `sha256sum -c` wants).
    lines = []
    for path in sorted(FIX.rglob("*")):
        if path.is_file() and path.name != "SHA256SUMS":
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            lines.append(f"{digest}  {path.relative_to(FIX)}")
    (FIX / "SHA256SUMS").write_text("\n".join(lines) + "\n", encoding="ascii")
    print("generated fixtures and expected under", MODULE)


if __name__ == "__main__":
    main()
