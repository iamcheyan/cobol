#!/usr/bin/env python3
"""Deterministic fixture generator for module 09.

All bank file layouts are frozen v1 contracts (CUSTOMER 27B, ACCOUNT 47B,
TRANSACTION 55B) exactly as documented in docs/curriculum/BANK-SYSTEM.md.
Run from any directory:  python3 generate-fixtures.py
It rewrites fixtures/*.dat and fixtures/SHA256SUMS in place.
"""
from pathlib import Path
import hashlib

LAB = Path(__file__).resolve().parents[1]
FIX = LAB / "fixtures"
DATE = "20261010"


def cust(cid, name, bal, status):
    return f"{cid:8}{name:<10}{bal:08d}{status}"


def acct(aid, cid, sign, opening, status, date=DATE, cur="JPY", layout="001"):
    return f"{aid:10}{cid:8}{cur:3}{sign}{opening:013d}{status}{date:8}{layout:3}"


def tx(tid, aid, seq, direction, amount, status="N", date=DATE):
    return f"{aid:10}{tid:16}{date:8}{seq:06d}{direction}{amount:013d}{status}"


BASE_C = [cust("00000001", "ALICE", 100, "A"),
          cust("00000002", "BOB", 200, "A")]
BASE_A = [acct("0000000001", "00000001", "+", 1000, "A"),
          acct("0000000002", "00000002", "+", 500, "A")]
BASE_T = [tx("TX00000000000001", "0000000001", 1, "C", 500),
          tx("TX00000000000002", "0000000001", 2, "D", 200),
          tx("TX00000000000003", "0000000002", 1, "C", 100)]

MAX = "9999999999999"

CASES = {
    # ---- normal ----
    "normal": dict(customers=BASE_C, accounts=BASE_A, transactions=BASE_T),

    # ---- boundary ----
    "empty-customers": dict(customers=[], accounts=BASE_A, transactions=BASE_T),
    "no-transactions": dict(customers=BASE_C, accounts=BASE_A, transactions=[]),
    "max-amount": dict(
        customers=[cust("00000001", "MAXCUST", 0, "A")],
        accounts=[acct("0000000001", "00000001", "+", 0, "A"),
                  acct("0000000002", "00000001", "+", int(MAX), "A")],
        transactions=[tx("TX00000000000001", "0000000001", 1, "C", int(MAX)),
                      tx("TX00000000000002", "0000000002", 1, "D", 1)]),
    "all-empty": dict(customers=[], accounts=[], transactions=[]),

    # ---- invalid: RC4 business rejections (published) ----
    "customer-bad-status": dict(
        customers=[cust("00000001", "ALICE", 100, "Z")], accounts=[], transactions=[]),
    "customer-bad-id": dict(
        customers=[cust("ABCD0001", "ALICE", 100, "A")], accounts=[], transactions=[]),
    "customer-no-name": dict(
        customers=[cust("00000001", "          ", 100, "A")],
        accounts=[], transactions=[]),
    "zero-amount": dict(
        customers=BASE_C, accounts=[BASE_A[0]],
        transactions=[tx("TX00000000000001", "0000000001", 1, "C", 0)]),
    "overdraft": dict(
        customers=BASE_C, accounts=[BASE_A[0]],
        transactions=[tx("TX00000000000001", "0000000001", 1, "D", 2000)]),
    "overflow": dict(
        customers=BASE_C, accounts=[acct("0000000001", "00000001", "+", int(MAX), "A")],
        transactions=[tx("TX00000000000001", "0000000001", 1, "C", 1)]),
    "unknown-direction": dict(
        customers=BASE_C, accounts=[BASE_A[0]],
        transactions=[tx("TX00000000000001", "0000000001", 1, "X", 100)]),
    "no-account": dict(
        customers=BASE_C, accounts=[BASE_A[0]],
        transactions=[tx("TX00000000000001", "0000000099", 1, "C", 100)]),
    "frozen-account": dict(
        customers=BASE_C, accounts=[acct("0000000001", "00000001", "+", 1000, "F")],
        transactions=[tx("TX00000000000001", "0000000001", 1, "C", 100)]),

    # ---- invalid: RC8 contract errors (no publish) ----
    "bad-layout-version": dict(
        customers=BASE_C, accounts=[acct("0000000001", "00000001", "+", 1000, "A",
                                         layout="002")],
        transactions=[]),
    "short-account": dict(
        customers=BASE_C, accounts=[acct("0000000001", "00000001", "+", 1000, "A")[:46]],
        transactions=[]),
    "bad-account-date": dict(
        customers=BASE_C, accounts=[acct("0000000001", "00000001", "+", 1000, "A",
                                         date="20261011")],
        transactions=[]),
    "unsorted-transactions": dict(
        customers=BASE_C, accounts=BASE_A,
        transactions=[BASE_T[2], BASE_T[0], BASE_T[1]]),
    # Global transaction_id duplicates: the per-file (account, sequence, id)
    # order stays strictly ascending, so only a *global* uniqueness check
    # catches these. BANK-SYSTEM: 重复交易不得再次记账 → RC8, no publish.
    "dup-global-txid": dict(
        customers=BASE_C, accounts=BASE_A,
        transactions=[
            tx("TX00000000000001", "0000000001", 1, "C", 500),
            tx("TX00000000000001", "0000000001", 2, "D", 200)]),
    "dup-cross-account": dict(
        customers=BASE_C, accounts=BASE_A,
        transactions=[
            tx("TX00000000000001", "0000000001", 1, "C", 500),
            tx("TX00000000000001", "0000000002", 1, "C", 100)]),
}

# Fixtures live under fixtures/normal (the primary case, files directly),
# fixtures/boundary/<case>/ and fixtures/invalid/<case>/ per AUTHORING-STANDARD.
BOUNDARY = {"empty-customers", "no-transactions", "max-amount", "all-empty"}


def case_dir(name):
    if name == "normal":
        return FIX / "normal"
    if name in BOUNDARY:
        return FIX / "boundary" / name
    return FIX / "invalid" / name


def write_case(name, spec):
    out = case_dir(name)
    out.mkdir(parents=True, exist_ok=True)
    for key, filename in (("customers", "customer.dat"),
                          ("accounts", "account.dat"),
                          ("transactions", "transaction.dat")):
        rows = spec[key]
        data = "".join(row + "\n" for row in rows).encode("ascii")
        (out / filename).write_bytes(data)


def main():
    FIX.mkdir(parents=True, exist_ok=True)
    for name, spec in CASES.items():
        write_case(name, spec)
    files = sorted(p for p in FIX.rglob("*") if p.is_file()
                   and p.name != "SHA256SUMS")
    lines = []
    for path in files:
        rel = path.relative_to(FIX).as_posix()
        lines.append(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {rel}")
    (FIX / "SHA256SUMS").write_text("".join(line + "\n" for line in lines))
    print(f"PASS: wrote {len(CASES)} cases and SHA256SUMS")


if __name__ == "__main__":
    main()
