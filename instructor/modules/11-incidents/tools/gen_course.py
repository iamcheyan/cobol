#!/usr/bin/env python3
"""Generate module 11 incident fixtures and independently accounted
expected files.

The oracle re-implements the frozen v1 contracts (CUSTOMER 27B, ACCOUNT
47B, TRANSACTION 55B), the JOB002 validation rules and the JOB005 1:N
overdraft/orphan rule from the written specification.  It never reads a
course program's output.  Fixed deterministic data only (FR-10).

It also records, for every incident fixture, the DESIRED contract
outcome (correct RC and whether publication must be blocked).  For the
two code-gap incidents (event IDs INC-2026-002 / INC-2026-006, instructor
codes inc-02 / inc-06) the as-found snapshot is defective; the desired
outcome is what the corrected system must produce.
"""
from __future__ import annotations

import hashlib
import shutil
from pathlib import Path

MODULE = Path(__file__).resolve().parents[4] / "curriculum/modules/11-incidents"
FIX = MODULE / "fixtures"
EXPECTED = MODULE / "expected"
DATE = "20261009"


def tx(acct, txid, seq, direction, amount, date=DATE, status="N"):
    assert len(acct) == 10 and len(txid) == 16
    return f"{acct}{txid}{date}{seq:06d}{direction}{amount:013d}{status}"


def account(acct, cust, sign, balance, status="A", date=DATE, ver="001"):
    return f"{acct}{cust}JPY{sign}{abs(balance):013d}{status}{date}{ver}"


def customer(cid, name, balance, status):
    return f"{cid}{name:<10}{balance:08d}{status}"


def enterprise(cid, name, status, klass):
    """Enterprise customer v1 (layout 001, 23 bytes): this is where the
    customer classification lives -- never on CUSTOMER v1 byte 27."""
    return f"001{cid}{status}{name:<10}{klass}"


ACCOUNTS = [
    account("0000000001", "00000001", "+", 1000),
    account("0000000002", "00000001", "+", 50),
    account("0000000003", "00000002", "+", 0),
]
ACCOUNTS_UNSORTED = [ACCOUNTS[2], ACCOUNTS[1], ACCOUNTS[0]]
CUSTOMERS = [
    customer("00000001", "ALICE", 100, "A"),
    customer("00000002", "BOB", 0, "D"),
]
ENTERPRISE_CUSTOMERS = [
    enterprise("00000001", "ALICE", "A", "A"),
    enterprise("00000002", "BOB", "A", "B"),
]

NORMAL_TX = [
    tx("0000000001", "A000000000000001", 1, "C", 500),
    tx("0000000001", "A000000000000002", 2, "D", 200),
    tx("0000000002", "B000000000000001", 1, "C", 100),
    tx("0000000003", "C000000000000001", 1, "C", 25),
]
DUP_TX = [
    tx("0000000001", "A000000000000001", 1, "C", 500),
    tx("0000000001", "A000000000000001", 3, "C", 500),  # duplicate txid
    tx("0000000002", "B000000000000001", 1, "C", 100),
    tx("0000000003", "C000000000000001", 1, "C", 25),
]
WRONG_AMOUNT_TX = [
    tx("0000000001", "A000000000000001", 1, "C", 50),   # keyed 50 != 500
    tx("0000000001", "A000000000000002", 2, "D", 200),
    tx("0000000002", "B000000000000001", 1, "C", 100),
    tx("0000000003", "C000000000000001", 1, "C", 25),
]
BAD_DIGIT_TX = [
    "000000000X" + NORMAL_TX[0][10:],
] + NORMAL_TX[1:]
# INC-2026-007: the first record is one byte short (54 instead of 55), so
# the field layout of that record is misaligned/length-wrong.  The
# Manifest still matches the delivered bytes, so the fault is caught by
# the JOB002 length rule (structural RC8), not by JOB001.
SHORT_RECORD_TX = [NORMAL_TX[0][:54]] + NORMAL_TX[1:]


def validate(records, date):
    accepted, reasons = [], {}
    for row in records:
        if len(row) != 55:
            raise SystemExit("fixture record is not 55 bytes")
        if not row[0:10].isdigit() or not row[26:34].isdigit() \
                or not row[34:40].isdigit() or not row[41:54].isdigit():
            raise SystemExit("fixture has a structural numeric error")
        if row[10:26] == " " * 16:
            raise SystemExit("fixture has a blank transaction id")
        reason = None
        if row[40] not in "CD":
            reason = "BADDIR"
        elif row[54] != "N":
            reason = "BADSTATUS"
        elif row[26:34] != date:
            reason = "BADDATE"
        elif row[41:54] == "0000000000000":
            reason = "BADZERO"
        if reason:
            reasons[reason] = reasons.get(reason, 0) + 1
        else:
            accepted.append(row)
    return accepted, reasons


def match(accepted, accounts):
    """Re-implement the JOB005 1:N rule independently (sorted input)."""
    order = list(accounts)
    opening = {}
    for r in order:
        opening[r[:10]] = (1 if r[21] == "+" else -1) * int(r[22:35])
    closing = dict(opening)
    known = set(opening)
    accepted_out, rejected = [], {}
    for row in sorted(accepted, key=lambda r: (r[:10], r[34:40], r[10:26])):
        acct = row[:10]
        amount = int(row[41:54])
        if acct not in known:
            rejected["ORPHAN"] = rejected.get("ORPHAN", 0) + 1
            continue
        if row[40] == "C":
            closing[acct] += amount
            accepted_out.append(row)
        elif closing[acct] - amount < 0:
            rejected["OVERDRAFT"] = rejected.get("OVERDRAFT", 0) + 1
        else:
            closing[acct] -= amount
            accepted_out.append(row)
    master = []
    for r in order:
        acct = r[:10]
        sign = "-" if closing[acct] < 0 else "+"
        master.append(r[:21] + sign + f"{abs(closing[acct]):013d}" + r[35:])
    return accepted_out, rejected, master, opening, closing


def control_values(records, accounts):
    accepted, _ = validate(records, DATE)
    b_acc, b_rej, master, opening, closing = match(accepted, accounts)
    credits = sum(int(r[41:54]) for r in b_acc if r[40] == "C")
    debits = sum(int(r[41:54]) for r in b_acc if r[40] == "D")
    return {
        "received": len(records),
        "validate_accepted": len(accepted),
        "validate_rejected": len(records) - len(accepted),
        "batch_accepted": len(b_acc),
        "batch_rejected": sum(b_rej.values()),
        "ledger_applied": len(b_acc),
        "accounts": len(accounts),
        "opening_total": sum(opening.values()),
        "credit_total": credits,
        "debit_total": debits,
        "closing_total": sum(closing.values()),
    }, master


def write_fixture(name, records, accounts=None, declared=None,
                  truncated=False, manifest_sha=None):
    accounts = accounts if accounts is not None else ACCOUNTS
    d = FIX / name
    d.mkdir(parents=True, exist_ok=True)
    good = b"".join(r.encode("ascii") + b"\n" for r in records)
    data = b"" if truncated else good
    (d / "transaction.dat").write_bytes(data)
    (d / "account_seed.dat").write_bytes(
        b"".join(a.encode("ascii") + b"\n" for a in accounts))
    (d / "customer_seed.dat").write_bytes(
        b"".join(c.encode("ascii") + b"\n" for c in CUSTOMERS))
    digest = manifest_sha or hashlib.sha256(good).hexdigest()
    manifest = (
        f"business_date={DATE}\n"
        "layout_transaction=001\nlayout_account=001\nlayout_customer=001\n"
        f"file transaction.dat {digest}\n")
    if declared:
        for key, value in declared.items():
            manifest += f"{key}={value}\n"
    (d / "MANIFEST").write_text(manifest, encoding="ascii")
    return d


def main():
    normal_dir = write_fixture("normal", NORMAL_TX)
    write_fixture("INC-2026-001", BAD_DIGIT_TX)
    write_fixture("INC-2026-002", DUP_TX)
    write_fixture("INC-2026-003", NORMAL_TX, truncated=True,
                  manifest_sha=hashlib.sha256(
                      b"".join(r.encode("ascii") + b"\n"
                               for r in NORMAL_TX)).hexdigest())
    write_fixture("INC-2026-004", NORMAL_TX, accounts=ACCOUNTS_UNSORTED)
    write_fixture("INC-2026-006", WRONG_AMOUNT_TX,
                  declared={
                      "control_received": 4,
                      "control_credit_total": 625,
                      "control_debit_total": 200,
                      "control_closing_total": 1475,
                  })
    # INC-2026-007: length/misalignment boundary (short record, JOB002).
    write_fixture("INC-2026-007", SHORT_RECORD_TX)
    # inc-05 uses the normal feed; the fault is the environment.
    if (FIX / "INC-2026-005").exists():
        shutil.rmtree(FIX / "INC-2026-005")
    shutil.copytree(normal_dir, FIX / "INC-2026-005")

    EXPECTED.mkdir(exist_ok=True)
    values, master = control_values(NORMAL_TX, ACCOUNTS)
    (EXPECTED / "normal.control.txt").write_text(
        "".join(f"{k}={v}\n" for k, v in values.items()), encoding="ascii")
    (EXPECTED / "normal.closing.txt").write_text(
        "".join(f"{row[:10]}={row[21:35]}\n" for row in master),
        encoding="ascii")

    # Desired contract behaviour per incident fixture.  publish_before
    # is what the AS-FOUND snapshot does; for the two code-gap incidents
    # that is the defect (it publishes a wrong result at RC0).
    (EXPECTED / "incidents.txt").write_text(
        "# fixture as_found_rc desired_rc publish_before publish_after\n"
        "normal 0 0 yes yes\n"
        "INC-2026-001 8 8 no no\n"
        "INC-2026-002 0 8 yes no\n"
        "INC-2026-003 12 12 no no\n"
        "INC-2026-004 8 8 no no\n"
        "INC-2026-005 12 12 no no\n"
        "INC-2026-006 0 8 yes no\n"
        "INC-2026-007 8 8 no no\n", encoding="ascii")

    # Reference customer status extract (CUSTOMER v1 byte 27 = A/D) and
    # the independent enterprise classification extract (11.5 exercise).
    (EXPECTED / "customer-v1.txt").write_text(
        "STATUS|00000001|A\nSTATUS|00000002|D\n", encoding="ascii")
    (EXPECTED / "enterprise-class-v1.txt").write_text(
        "CLASS|00000001|A\nCLASS|00000002|B\n", encoding="ascii")
    (EXPECTED / "enterprise-class-v2.txt").write_text(
        "CLASS|00000001|A1\nCLASS|00000002|B1\n", encoding="ascii")

    # Enterprise customer v1 fixture (module 11 maintenance 11.5).
    ent = FIX / "enterprise-customer"
    ent.mkdir(parents=True, exist_ok=True)
    (ent / "customer.v1").write_text(
        "".join(r + "\n" for r in ENTERPRISE_CUSTOMERS), encoding="ascii")

    lines = []
    for path in sorted(FIX.rglob("*")):
        if path.is_file() and path.name != "SHA256SUMS":
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            lines.append(f"{digest}  {path.relative_to(FIX)}")
    (FIX / "SHA256SUMS").write_text("\n".join(lines) + "\n", encoding="ascii")
    print("generated module 11 fixtures and expected")
    print("normal control:", values)
    print("normal closing:", [r[21:35] for r in master])


if __name__ == "__main__":
    main()
