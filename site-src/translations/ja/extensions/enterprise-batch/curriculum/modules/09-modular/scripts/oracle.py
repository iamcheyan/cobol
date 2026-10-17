#!/usr/bin/env python3
"""Independent reference model for module 09 (NOT a copy of the COBOL output).

This module re-derives, from the frozen file contracts and the business rules
documented in DESIGN.md, what a correct run must produce: report lines, ledger
master bytes, accepted/rejected customer bytes, the log file and the RC.

It is used two ways:
  * run directly to (re)generate `expected/*.txt` and `expected/cases.json`;
  * imported by `check.py` to compare against the real COBOL reference output,
    so the expected files are never merely the program's own stdout.
"""
from pathlib import Path
import json

LAB = Path(__file__).resolve().parents[1]
FIX = LAB / "fixtures"
EXPECTED = LAB / "expected"
DATE = "20261010"
LIMIT = 9999999999999  # 13 nines

# Cases whose correct result is a business reject (RC4) or clean run (RC0) and
# therefore publish an output directory. RC8 contract cases must not publish.
PUBLISH_RC = {
    "normal": 0, "empty-customers": 0, "no-transactions": 0,
    "max-amount": 0, "all-empty": 0,
    "customer-bad-status": 4, "customer-bad-id": 4, "customer-no-name": 4,
    "zero-amount": 4, "overdraft": 4, "overflow": 4,
    "unknown-direction": 4, "no-account": 4, "frozen-account": 4,
}
CONTRACT_RC = {  # RC8: no output directory may exist
    "bad-layout-version": 8, "short-account": 8,
    "bad-account-date": 8, "unsorted-transactions": 8,
    # global transaction_id uniqueness (BANK-SYSTEM: 重复交易不得再次记账):
    # same account different sequence, and cross-account duplicates are both fatal.
    "dup-global-txid": 8, "dup-cross-account": 8,
}
BOUNDARY = {"empty-customers", "no-transactions", "max-amount", "all-empty"}


class ContractError(Exception):
    pass


def records(blob: bytes, width: int, name: str) -> list[bytes]:
    """Split LF-terminated fixed records; reject short/long/CRLF/EOF issues."""
    if blob == b"":
        return []
    parts = blob.split(b"\n")
    if parts[-1] != b"":
        raise ContractError(f"{name}: missing final LF")
    parts.pop()
    for row in parts:
        if len(row) != width or b"\r" in row:
            raise ContractError(f"{name}: width/LF contract broken")
    return parts


def signed(value: int, digits: int) -> str:
    return ("-" if value < 0 else "+") + f"{abs(value):0{digits}d}"


def log_line(seq: int, severity: str, event: str, message: str) -> str:
    # GnuCOBOL LINE SEQUENTIAL drops trailing spaces of each record, so the
    # independent model does the same for the fixed 67-byte log record.
    return f"{DATE}|{seq:06d}|{severity}|{event:<8}|{message:<40}".rstrip()


def validate_customer(raw: bytes):
    cid = raw[0:8].decode()
    name = raw[8:18].decode()
    status = raw[26:27].decode()
    if not cid.isdigit():
        return 4, "BAD-ID"
    if name.strip() == "":
        return 4, "CUST-NO-NAME"
    if status == "A":
        return 0, "OK"
    if status == "D":
        return 4, "CUST-DISABLED"
    return 4, "CUST-BAD-STATUS"


def validate_account(raw: bytes, date: str):
    aid = raw[0:10].decode()
    if not raw[0:10].decode().isdigit() or not raw[10:18].decode().isdigit():
        raise ContractError("account id/customer not numeric")
    if raw[18:21] != b"JPY":
        raise ContractError("account currency")
    if raw[21:22] not in (b"+", b"-"):
        raise ContractError("account sign")
    if not raw[22:35].decode().isdigit():
        raise ContractError("account opening not numeric")
    if raw[35:36] not in (b"A", b"F", b"C"):
        raise ContractError("account status")
    if raw[36:44].decode() != date:
        raise ContractError("account date")
    if raw[44:47] != b"001":
        raise ContractError("account layout version")
    opening = int(raw[22:35])
    if raw[21:22] == b"-":
        opening = -opening
    return aid, raw[35:36].decode(), opening, raw


def validate_tx(raw: bytes, date: str):
    if not raw[0:10].decode().isdigit():
        raise ContractError("transaction account not numeric")
    if not raw[34:40].decode().isdigit():
        raise ContractError("transaction sequence not numeric")
    if not raw[41:54].decode().isdigit():
        raise ContractError("transaction amount not numeric")
    if raw[26:34].decode() != date:
        raise ContractError("transaction date")
    return raw


def amount_calc(direction: str, amount_text: str, balance: int):
    if not amount_text.isdigit():
        return 4, "AMT-NOT-NUMERIC", balance
    amount = int(amount_text)
    if amount == 0:
        return 4, "ZERO-AMOUNT", balance
    if direction == "C":
        delta = amount
    elif direction == "D":
        delta = -amount
    else:
        return 4, "BAD-DIRECTION", balance
    new = balance + delta
    if new > LIMIT or new < -LIMIT:
        return 4, "OVERFLOW", balance
    if new < 0:
        return 4, "OVERDRAFT", balance
    return 0, "OK", new


def compute(customers: bytes, accounts: bytes, transactions: bytes,
            date: str = DATE):
    report: list[str] = []
    ledger: list[bytes] = []
    valid: list[bytes] = []
    rejected: list[bytes] = []
    log: list[str] = []
    seq = 0

    def emit(severity, event, message):
        nonlocal seq
        seq += 1
        log.append(log_line(seq, severity, event, message))

    emit("I", "JOBSTART", "")

    # ---- customer validation stage ----
    c_read = c_ok = c_rej = 0
    for raw in records(customers, 27, "customer"):
        c_read += 1
        rc, reason = validate_customer(raw)
        cid = raw[0:8].decode()
        name = raw[8:18].decode().strip()
        if rc == 0:
            c_ok += 1
            report.append(f"CUST|{cid}|OK|{name}")
            valid.append(raw + b"\n")
            emit("I", "CUSTVAL", f"{cid} {reason}")
        else:
            c_rej += 1
            report.append(f"CUST|{cid}|REJECT|{reason}")
            rejected.append(raw + b"|" + reason.encode() + b"\n")
            emit("W", "CUSTVAL", f"{cid} {reason}")
    report.append(f"CUST-CONTROL|READ={c_read:012d}|OK={c_ok:012d}"
                  f"|REJECT={c_rej:012d}")

    # ---- posting stage: bounded key-break over sorted account/tx streams ----
    accts = [validate_account(raw, date)
             for raw in records(accounts, 47, "account")]
    for i in range(1, len(accts)):
        if accts[i][0] <= accts[i - 1][0]:
            raise ContractError("account not strictly ascending")
    txs = [validate_tx(raw, date)
           for raw in records(transactions, 55, "transaction")]
    for i in range(1, len(txs)):
        if (txs[i][0:10], txs[i][34:40], txs[i][10:26]) <= \
           (txs[i - 1][0:10], txs[i - 1][34:40], txs[i - 1][10:26]):
            raise ContractError("transaction not strictly ascending")
    # Global business-key uniqueness: a transaction_id may appear only once in
    # the whole job, regardless of account or sequence. Ordered scan is not
    # enough (txids are not globally sorted), so check the set of keys.
    seen_ids: set[str] = set()
    for raw in txs:
        tid = raw[10:26].decode()
        if tid in seen_ids:
            raise ContractError(f"duplicate global transaction_id {tid}")
        seen_ids.add(tid)

    acct_count = notx_count = tx_count = accept_count = reject_count = 0
    opening_total = closing_total = credit_total = debit_total = 0
    biz_reject = c_rej > 0
    idx = 0
    current = None
    balance = 0
    had_tx = False

    def start_account(account):
        nonlocal balance, had_tx, acct_count, opening_total
        aid, status, opening, raw = account
        balance = opening
        had_tx = False
        acct_count += 1
        opening_total += opening
        return aid, status, raw

    def close_account(account):
        nonlocal closing_total, notx_count
        aid, status, raw = account
        if not had_tx:
            notx_count += 1
        report.append(f"ACCT|{aid}|{signed(balance, 13)}")
        ledger.append(raw[0:21] + signed(balance, 13).encode() + raw[35:47] + b"\n")
        closing_total += balance

    for raw in txs:
        tx_count += 1
        aid = raw[0:10].decode()
        txid = raw[10:26].decode()
        direction = raw[40:41].decode()
        amount_text = raw[41:54].decode()
        status = raw[54:55].decode()
        # advance to the smallest account id >= this transaction account id
        while True:
            if current is None:
                if idx >= len(accts):
                    break
                current = start_account(accts[idx])
                idx += 1
            if current[0] < aid:
                close_account(current)
                current = None
                continue
            break
        if current is None or current[0] > aid:
            biz_reject = True
            reject_count += 1
            report.append(f"POST|{aid}|{txid}|REJECT|NO-ACCOUNT")
            emit("W", "TXPOST", f"{txid} REJECT NO-ACCOUNT")
            continue
        aid, acc_status = current[0], current[1]
        had_tx = True
        if status != "N":
            biz_reject = True
            reject_count += 1
            report.append(f"POST|{aid}|{txid}|REJECT|TX-STATUS")
            emit("W", "TXPOST", f"{txid} REJECT TX-STATUS")
            continue
        if acc_status != "A":
            biz_reject = True
            reject_count += 1
            report.append(f"POST|{aid}|{txid}|REJECT|ACCOUNT-STATUS")
            emit("W", "TXPOST", f"{txid} REJECT ACCOUNT-STATUS")
            continue
        rc, reason, new_balance = amount_calc(direction, amount_text, balance)
        if rc == 0:
            balance = new_balance
            amount = int(amount_text)
            if direction == "C":
                credit_total += amount
            else:
                debit_total += amount
            accept_count += 1
            report.append(f"POST|{aid}|{txid}|ACCEPT|{signed(balance, 13)}")
            emit("I", "TXPOST", f"{txid} ACCEPT")
        else:
            biz_reject = True
            reject_count += 1
            report.append(f"POST|{aid}|{txid}|REJECT|{reason}")
            emit("W", "TXPOST", f"{txid} REJECT {reason}")

    if current is not None:
        close_account(current)
        current = None
    while idx < len(accts):
        current = start_account(accts[idx])
        idx += 1
        close_account(current)
        current = None

    report.append(
        f"POST-CONTROL|ACCTS={acct_count:012d}|NOTX={notx_count:012d}"
        f"|TX={tx_count:012d}|ACCEPT={accept_count:012d}"
        f"|REJECT={reject_count:012d}"
        f"|OPENING={signed(opening_total, 18)}|CLOSING={signed(closing_total, 18)}"
        f"|CREDIT={credit_total:018d}|DEBIT={debit_total:018d}")
    if opening_total + credit_total - debit_total != closing_total:
        raise ContractError("global amount conservation failed")
    if tx_count != accept_count + reject_count:
        raise ContractError("transaction conservation failed")

    if biz_reject:
        emit("W", "JOBEND",
             f"ACCEPT={accept_count:012d} REJECT={reject_count:012d}")
    else:
        emit("I", "JOBEND",
             f"ACCEPT={accept_count:012d} REJECT={reject_count:012d}")

    report_text = "".join(line + "\n" for line in report)
    log_text = "".join(line + "\n" for line in log)
    return {
        "rc": 4 if biz_reject else 0,
        "report": report_text,
        "ledger": b"".join(ledger),
        "valid": b"".join(valid),
        "rejected": b"".join(rejected),
        "log": log_text,
    }


def case_dir(case: str) -> Path:
    if case == "normal":
        return FIX / "normal"
    if case in BOUNDARY:
        return FIX / "boundary" / case
    return FIX / "invalid" / case


def main():
    EXPECTED.mkdir(parents=True, exist_ok=True)
    cases = {}
    for case, rc in {**PUBLISH_RC, **CONTRACT_RC}.items():
        spec = case_dir(case)
        result = None
        try:
            result = compute((spec / "customer.dat").read_bytes(),
                             (spec / "account.dat").read_bytes(),
                             (spec / "transaction.dat").read_bytes())
        except ContractError:
            result = None
        if rc in (0, 4):
            assert result is not None and result["rc"] == rc, (case, result and result["rc"])
            (EXPECTED / f"{case}.txt").write_text(result["report"])
        else:
            assert result is None, f"{case} should be a contract error"
        cases[case] = rc
    (EXPECTED / "cases.json").write_text(json.dumps(cases, indent=2) + "\n")
    print(f"PASS: oracle wrote {len(PUBLISH_RC)} expected reports")


if __name__ == "__main__":
    main()
