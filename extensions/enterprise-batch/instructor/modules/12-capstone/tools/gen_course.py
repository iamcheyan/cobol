#!/usr/bin/env python3
"""Generate module 12 capstone fixtures and independently accounted expected.

The oracle re-implements the BANKVAL business rules and the module 07 L2
(1:N) overdraft rule from the written contracts.  It NEVER reads any course
implementation output and NEVER imports the module 10 generator.  Fixed,
deterministic data only (FR-10).

Business date: 20261010.
"""
from __future__ import annotations

import hashlib
from pathlib import Path

MODULE = Path(__file__).resolve().parents[4] / "curriculum/modules/12-capstone"
FIX = MODULE / "fixtures"
EXPECTED = MODULE / "expected"
DATE = "20261010"


def account(acct, cust, balance, status="A", date=DATE, ver="001"):
    sign = "-" if balance < 0 else "+"
    return f"{acct}{cust}JPY{sign}{abs(balance):013d}{status}{date}{ver}"


def enterprise_v1(cid, name, demo, status, classification):
    """31 B enterprise v1: embeds canonical CUSTOMER v1 (byte 27 = status)."""
    assert len(cid) == 8 and len(status) == 1 and status in "AD"
    assert len(classification) == 1 and classification in "ABCD"
    return f"{cid}{name:<10}{demo:08d}{status}{classification}001"


def enterprise_v2(cid, name, demo, status, classification):
    """32 B enterprise v2: A/B/C/D classification widened to A1..D1."""
    assert len(cid) == 8 and len(status) == 1 and status in "AD"
    assert len(classification) == 2 and classification[0] in "ABCD" \
        and classification[1].isdigit()
    return f"{cid}{name:<10}{demo:08d}{status}{classification}002"


def tx(acct, txid, seq, direction, amount, status="N", date=DATE):
    assert len(acct) == 10 and len(txid) == 16
    return f"{acct}{txid}{date}{seq:06d}{direction}{amount:013d}{status}"


# --- shared master data -------------------------------------------------------
ACCOUNTS_3 = [
    account("0000000001", "00000001", 1000),
    account("0000000002", "00000001", 50),
    account("0000000003", "00000002", 0),
]
ACCOUNTS_4 = ACCOUNTS_3 + [account("0000000004", "00000003", 200)]

CUSTOMERS_V1 = [
    enterprise_v1("00000001", "ALICE", 100, "A", "A"),
    enterprise_v1("00000002", "BOB", 0, "A", "A"),
]
CUSTOMERS_V2 = [
    enterprise_v2("00000001", "ALICE", 100, "A", "A1"),
    enterprise_v2("00000002", "BOB", 0, "A", "A1"),
    enterprise_v2("00000003", "CAROL", 0, "D", "D1"),
]

# --- transaction sets ---------------------------------------------------------
CLEAN_6 = [
    tx("0000000001", "A000000000000001", 1, "C", 500),
    tx("0000000001", "A000000000000002", 2, "D", 200),
    tx("0000000002", "B000000000000001", 1, "C", 100),
    tx("0000000003", "C000000000000001", 1, "C", 300),
    tx("0000000001", "A000000000000003", 3, "C", 150),
    tx("0000000002", "B000000000000002", 2, "D", 50),
]
ABNORMAL = [
    tx("0000000001", "A000000000000001", 1, "C", 500),
    tx("0000000001", "A000000000000002", 2, "D", 200),
    tx("0000000002", "B000000000000001", 1, "C", 100),
    tx("0000000003", "C000000000000001", 1, "C", 300),
    tx("0000000003", "C000000000000002", 2, "D", 500),   # overdraft -> reject
    tx("0000000001", "D000000000000001", 4, "C", 300, "X"),   # bad status
    tx("0000000002", "E000000000000001", 3, "X", 100),        # bad direction
    tx("0000000003", "F000000000000001", 3, "C", 100, "N", "20261009"),
    tx("0000000002", "G000000000000001", 4, "C", 0),          # bad zero
]
EXTENSION = CLEAN_6 + [tx("0000000004", "E000000000000001", 1, "C", 100)]
BROKEN = CLEAN_6 + [tx("0000000001", "A000000000000001", 9, "C", 100)]


# --- independent rules --------------------------------------------------------
def validate(records, date):
    accepted, reasons = [], {"BADDIR": 0, "BADSTATUS": 0, "BADDATE": 0,
                             "BADZERO": 0}
    for row in records:
        if len(row) != 55:
            raise SystemExit("fixture structural error")
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
    return accepted, reasons


def match(accepted, accounts):
    opening = {r[:10]: (1 if r[21] == "+" else -1) * int(r[22:35])
               for r in accounts}
    closing = dict(opening)
    batch_accepted, batch_rejected = [], []
    for row in sorted(accepted, key=lambda r: (r[:10], r[34:40], r[10:26])):
        acct, amount = row[:10], int(row[41:54])
        if row[40] == "C":
            closing[acct] += amount
            batch_accepted.append(row)
        elif closing[acct] - amount < 0:
            batch_rejected.append(row)
        else:
            closing[acct] -= amount
            batch_accepted.append(row)
    master = []
    for r in accounts:
        acct = r[:10]
        sign = "-" if closing[acct] < 0 else "+"
        master.append(r[:21] + sign + f"{abs(closing[acct]):013d}" + r[35:])
    return batch_accepted, batch_rejected, master, opening, closing


def control(records, accounts, date):
    accepted, _ = validate(records, date)
    b_acc, b_rej, master, opening, closing = match(accepted, accounts)
    credits = sum(int(r[41:54]) for r in b_acc if r[40] == "C")
    debits = sum(int(r[41:54]) for r in b_acc if r[40] == "D")
    return {
        "received": len(records),
        "validate_accepted": len(accepted),
        "validate_rejected": len(records) - len(accepted),
        "match_accepted": len(b_acc),
        "match_rejected": len(b_rej),
        "ledger_applied": len(b_acc),
        "accounts": len(accounts),
        "opening_total": sum(opening.values()),
        "credit_total": credits,
        "debit_total": debits,
        "closing_total": sum(closing.values()),
    }, master, opening, closing


def customer_day(accounts, customers, totals):
    acct_to_cust = {a[:10]: a[10:18] for a in accounts}
    rows = {}
    for acct in accounts:
        cid = acct[10:18]
        rows.setdefault(cid, [0, 0])
        rows[cid][0] += 1
    for acct, value in totals.items():
        cid = acct_to_cust[acct]
        rows.setdefault(cid, [0, 0])
        rows[cid][1] += value
    out = []
    for c in customers:
        cid = c[:8]
        if len(c) == 31:          # enterprise v1: class at byte 28
            cls = c[27] + "1"     # A/B/C/D -> A1..D1
        else:                     # enterprise v2: class at bytes 28-29
            cls = c[27:29]
        count, total = rows.get(cid, [0, 0])
        sign = "-" if total < 0 else "+"
        out.append(f"{cid}|{cls}|{count:06d}|{sign}{abs(total):013d}")
    return out


def write_case(name, records, accounts, customers, rc, layout):
    d = FIX / name
    d.mkdir(parents=True, exist_ok=True)
    tx_data = b"".join(r.encode() + b"\n" for r in records)
    acc_data = b"".join(r.encode() + b"\n" for r in accounts)
    cus_data = b"".join(r.encode() + b"\n" for r in customers)
    (d / "transaction.dat").write_bytes(tx_data)
    (d / "account_seed.dat").write_bytes(acc_data)
    (d / "customer.dat").write_bytes(cus_data)
    (d / "customer_seed.dat").write_bytes(cus_data)
    layout_customer = "001" if layout == "v1" else "002"
    (d / "MANIFEST").write_text(
        f"business_date={DATE}\n"
        "layout_transaction=001\nlayout_account=001\n"
        f"layout_customer={layout_customer}\n"
        f"file transaction.dat {hashlib.sha256(tx_data).hexdigest()}\n"
        f"file customer.dat {hashlib.sha256(cus_data).hexdigest()}\n"
        f"file account_seed.dat {hashlib.sha256(acc_data).hexdigest()}\n",
        encoding="ascii")
    (EXPECTED / f"{name}.rc").write_text(f"{rc}\n", encoding="ascii")
    if rc == 8:
        return
    values, master, opening, closing = control(records, accounts, DATE)
    (EXPECTED / f"{name}.control.txt").write_text(
        "".join(f"{k}={v}\n" for k, v in values.items()), encoding="ascii")
    (EXPECTED / f"{name}.closing.txt").write_text(
        "".join(f"{row[:10]}={row[21:35]}\n" for row in master),
        encoding="ascii")
    (EXPECTED / f"{name}.customerday.txt").write_text(
        "".join(r + "\n" for r in customer_day(accounts, customers, closing)),
        encoding="ascii")


def main():
    FIX.mkdir(exist_ok=True)
    EXPECTED.mkdir(exist_ok=True)
    write_case("normal", CLEAN_6, ACCOUNTS_3, CUSTOMERS_V1, 0, "v1")
    write_case("abnormal", ABNORMAL, ACCOUNTS_3, CUSTOMERS_V1, 4, "v1")
    write_case("rerun", CLEAN_6, ACCOUNTS_3, CUSTOMERS_V1, 0, "v1")
    write_case("extension", EXTENSION, ACCOUNTS_4, CUSTOMERS_V2, 0, "v2")
    write_case("broken", BROKEN, ACCOUNTS_3, CUSTOMERS_V1, 8, "v1")
    lines = []
    for path in sorted(FIX.rglob("*")):
        if path.is_file() and path.name != "SHA256SUMS":
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            lines.append(f"{digest}  {path.relative_to(FIX)}")
    (FIX / "SHA256SUMS").write_text("\n".join(lines) + "\n", encoding="ascii")
    print("generated fixtures and expected under", MODULE)


if __name__ == "__main__":
    main()
