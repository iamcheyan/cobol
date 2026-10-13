#!/usr/bin/env python3
"""Disk-backed, streaming publication oracle independent of COBOL core."""
from pathlib import Path
import filecmp
import sqlite3
import sys
import tempfile


def records(path: Path, width: int | None = None):
    with path.open("rb") as stream:
        while True:
            raw = stream.readline(258)
            if not raw:
                return
            if not raw.endswith(b"\n") or raw.endswith(b"\r\n"):
                raise ValueError(f"invalid LF framing: {path.name}")
            row = raw[:-1]
            if width is not None and len(row) != width:
                raise ValueError(f"invalid record width: {path.name}")
            if any(byte < 32 or byte > 126 for byte in row):
                raise ValueError(f"non-ASCII record: {path.name}")
            yield row


def signed(raw: bytes, sign: bytes) -> int:
    if len(sign) != 1 or sign not in (b"+", b"-") or not raw.isdigit():
        raise ValueError("invalid signed amount")
    amount = int(raw)
    return -amount if sign == b"-" else amount


def same_stream(actual: Path, expected: Path) -> None:
    if not filecmp.cmp(actual, expected, shallow=False):
        raise ValueError(f"byte-for-byte oracle mismatch: {actual.name}")


def verify(root: Path, business_date: str, l2rc: int, core_rc: int) -> None:
    with tempfile.TemporaryDirectory(prefix="b03-oracle-") as oracle_dir:
        db = sqlite3.connect(Path(oracle_dir) / "oracle.sqlite")
        db.execute("PRAGMA journal_mode=OFF")
        db.execute("PRAGMA temp_store=FILE")
        db.executescript("""
          CREATE TABLE account(id TEXT PRIMARY KEY, cust TEXT, raw BLOB,
            master BLOB, opening INTEGER, closing INTEGER);
          CREATE INDEX account_customer ON account(cust,id);
          CREATE TABLE tx(id TEXT PRIMARY KEY, acct TEXT, cust TEXT, raw BLOB,
            dir TEXT, amount INTEGER);
          CREATE INDEX tx_customer ON tx(cust,acct,id);
          CREATE TABLE snap(cust TEXT PRIMARY KEY, raw BLOB);
          CREATE TABLE prev(cust TEXT PRIMARY KEY, raw BLOB);
          CREATE TABLE decision(cust TEXT PRIMARY KEY, reason TEXT);
        """)
        account_count = tx_count = 0
        total_open = total_close = total_credit = total_debit = 0
        for raw, master in zip(records(root / "account.input.dat", 47),
                               records(root / "l2/master.dat", 47),
                               strict=True):
            if master[:21] != raw[:21] or master[35:] != raw[35:]:
                raise ValueError("nonbalance master bytes changed")
            aid, cust = raw[:10].decode(), raw[10:18].decode()
            opening = signed(raw[22:35], raw[21:22])
            closing = signed(master[22:35], master[21:22])
            db.execute("INSERT INTO account VALUES (?,?,?,?,?,?)",
                       (aid, cust, raw, master, opening, closing))
            total_open += opening
            total_close += closing
            account_count += 1
        for raw in records(root / "l2/accepted.dat", 55):
            aid = raw[:10].decode()
            row = db.execute("SELECT cust FROM account WHERE id=?",
                             (aid,)).fetchone()
            if row is None:
                raise ValueError("accepted tx has no account source")
            direction = raw[40:41].decode()
            if direction not in ("C", "D") or not raw[41:54].isdigit():
                raise ValueError("bad accepted transaction")
            amount = int(raw[41:54])
            db.execute("INSERT INTO tx VALUES (?,?,?,?,?,?)",
                       (raw[10:26].decode(), aid, row[0], raw,
                        direction, amount))
            if direction == "C":
                total_credit += amount
            else:
                total_debit += amount
            tx_count += 1
        for raw in records(root / "customer-snapshot.input.dat", 36):
            db.execute("INSERT INTO snap VALUES (?,?)", (raw[:8].decode(), raw))
        for raw in records(root / "previous-day.input.dat", 39):
            db.execute("INSERT INTO prev VALUES (?,?)", (raw[:8].decode(), raw))
        rejected_count = sum(1 for _ in records(root / "rejected-l2.dat"))
        if (l2rc == 4) != (rejected_count > 0):
            raise ValueError("L2 RC disagrees with rejected records")

        with tempfile.TemporaryDirectory(prefix="b03-expected-") as exp_dir:
            expected = Path(exp_dir)
            paths = {name: expected / name for name in (
                "status", "totals", "isolation", "master", "tx")}
            for path in paths.values():
                path.touch()
            with (paths["status"].open("wb") as status_out,
                  paths["totals"].open("wb") as totals_out,
                  paths["isolation"].open("wb") as isolation_out):
                totals_out.write(
                    b"customer_id,accounts,transactions,opening,credit,debit,closing\n")
                keys = db.execute("""
                  SELECT cust FROM account UNION SELECT cust FROM snap
                  UNION SELECT cust FROM prev ORDER BY cust
                """)
                eligible_accounts = eligible_tx = 0
                isolated_accounts = isolated_tx = 0
                eligible_credit = eligible_debit = 0
                isolated_credit = isolated_debit = 0
                customer_count = eligible_customers = isolated_customers = 0
                has_diff = bool(l2rc or rejected_count)
                for (cust,) in keys:
                    account_rows = db.execute(
                        "SELECT id,raw,master,opening,closing FROM account "
                        "WHERE cust=? ORDER BY id", (cust,))
                    acount = opening = closing = 0
                    for row in account_rows:
                        acount += 1
                        opening += row[3]
                        closing += row[4]
                    tx_rows = db.execute(
                        "SELECT id,acct,raw,dir,amount FROM tx WHERE cust=? "
                        "ORDER BY acct,substr(raw,35,6),id", (cust,))
                    tcount = credit = debit = 0
                    for row in tx_rows:
                        tcount += 1
                        if row[3] == "C":
                            credit += row[4]
                        else:
                            debit += row[4]
                    snap = db.execute("SELECT raw FROM snap WHERE cust=?",
                                      (cust,)).fetchone()
                    prev = db.execute("SELECT raw FROM prev WHERE cust=?",
                                      (cust,)).fetchone()
                    reason = ""
                    if not acount:
                        if snap and prev:
                            reason = "ORPHAN-SNAPSHOT-PREVIOUS"
                        elif snap:
                            reason = "ORPHAN-SNAPSHOT"
                        else:
                            reason = "ORPHAN-PREVIOUS"
                    elif snap is None:
                        reason = "MISSING-SNAPSHOT"
                    elif prev is None:
                        reason = "MISSING-PREVIOUS"
                    elif snap[0][19:20] != b"A":
                        reason = "CUSTOMER-INACTIVE"
                    elif acount != int(prev[0][19:25]):
                        reason = "ACCOUNT-COUNT-CHANGE"
                    elif opening != signed(prev[0][26:39], prev[0][25:26]):
                        reason = "OPENING-MISMATCH"
                    elif acount > int(snap[0][20:23]):
                        reason = "ACCOUNT-LIMIT"
                    elif closing != opening + credit - debit:
                        reason = "CLOSING-MISMATCH"
                    elif closing > int(snap[0][23:36]):
                        reason = "BALANCE-LIMIT"
                    decision = reason or "ELIGIBLE"
                    db.execute("INSERT INTO decision VALUES (?,?)",
                               (cust, reason))
                    status_out.write(f"{cust}|{decision}|\n".encode())
                    totals_out.write(
                        f"{cust},{acount},{tcount},{opening},{credit},{debit},"
                        f"{opening + credit - debit}\n".encode())
                    customer_count += 1
                    if reason:
                        has_diff = True
                        isolated_customers += 1
                        isolated_accounts += acount
                        isolated_tx += tcount
                        isolated_credit += credit
                        isolated_debit += debit
                        for (raw,) in db.execute(
                            "SELECT raw FROM account WHERE cust=? ORDER BY id",
                            (cust,)):
                            isolation_out.write(b"ACCOUNT|" + cust.encode() +
                                b"|" + raw + b"|" + reason.encode() + b"\n")
                        for (raw,) in db.execute(
                            "SELECT raw FROM tx WHERE cust=? "
                            "ORDER BY acct,substr(raw,35,6),id", (cust,)):
                            isolation_out.write(b"TRANSACTION|" + cust.encode() +
                                b"|" + raw + b"|" + reason.encode() + b"\n")
                        if not acount:
                            if snap:
                                isolation_out.write(b"SNAPSHOT|" + cust.encode() +
                                    b"|" + snap[0] + b"|" + reason.encode() + b"\n")
                            if prev:
                                isolation_out.write(b"PREVIOUS|" + cust.encode() +
                                    b"|" + prev[0] + b"|" + reason.encode() + b"\n")
                    else:
                        eligible_customers += 1
                        eligible_accounts += acount
                        eligible_tx += tcount
                        eligible_credit += credit
                        eligible_debit += debit

            with paths["master"].open("wb") as out:
                for (raw,) in db.execute("""
                  SELECT a.master FROM account a JOIN decision d USING(cust)
                  WHERE d.reason='' ORDER BY a.id
                """):
                    out.write(raw + b"\n")
            with paths["tx"].open("wb") as out:
                for (raw,) in db.execute("""
                  SELECT t.raw FROM tx t JOIN decision d USING(cust)
                  WHERE d.reason='' ORDER BY t.acct,substr(t.raw,35,6),t.id
                """):
                    out.write(raw + b"\n")
            pairs = (("customer-status.txt", "status"),
                     ("customer-totals.csv", "totals"),
                     ("isolation.txt", "isolation"),
                     ("eligible-master.dat", "master"),
                     ("eligible-transaction.dat", "tx"))
            for actual, exp in pairs:
                same_stream(root / actual, paths[exp])

        if account_count != eligible_accounts + isolated_accounts:
            raise ValueError("ACCOUNT eligible/isolation conservation failed")
        if tx_count != eligible_tx + isolated_tx:
            raise ValueError("accepted TX eligible/isolation conservation failed")
        if total_credit != eligible_credit + isolated_credit:
            raise ValueError("CREDIT eligible/isolation conservation failed")
        if total_debit != eligible_debit + isolated_debit:
            raise ValueError("DEBIT eligible/isolation conservation failed")
        if total_open + total_credit - total_debit != total_close:
            raise ValueError("global opening + accepted C - D != closing")

        control_raw = root.joinpath("control.txt").read_bytes()
        control = control_raw.rstrip(b" \n")
        parts = control.decode("ascii").split("|")
        if len(parts) != 36 or len(set(parts[::2])) != len(parts[::2]):
            raise ValueError("control labels are missing or duplicated")
        values = dict(zip(parts[::2], parts[1::2], strict=True))
        required = {
            "CUSTOMERS": customer_count,
            "CUSTOMERS-ELIGIBLE": eligible_customers,
            "CUSTOMERS-ISOLATED": isolated_customers,
            "OPENING": total_open,
            "CLOSING": total_close,
            "ACCOUNTS": account_count,
            "ELIGIBLE": eligible_accounts,
            "ISOLATED": isolated_accounts,
            "TX": tx_count,
            "TX-ELIGIBLE": eligible_tx,
            "TX-ISOLATED": isolated_tx,
            "CREDIT": total_credit,
            "DEBIT": total_debit,
            "ELIGIBLE-CREDIT": eligible_credit,
            "ELIGIBLE-DEBIT": eligible_debit,
            "ISOLATED-CREDIT": isolated_credit,
            "ISOLATED-DEBIT": isolated_debit,
            "L2-REJECT": rejected_count,
        }
        for key, value in required.items():
            if values.get(key) != str(value):
                raise ValueError(f"control mismatch: {key}")
        expected_rc = 4 if has_diff else 0
        if core_rc != expected_rc:
            raise ValueError(f"B03 RC mismatch: actual={core_rc} expected={expected_rc}")
        if expected_rc == 0 and (eligible_accounts != account_count or
                                 eligible_tx != tx_count):
            raise ValueError("RC0 must have every account/TX eligible")
        if total_open + total_credit - total_debit != total_close:
            raise ValueError("global monetary controls mismatch")
        db.close()


if __name__ == "__main__":
    try:
        verify(Path(sys.argv[1]), sys.argv[2], int(sys.argv[3]),
               int(sys.argv[4]))
    except Exception as error:
        print(f"B03 VERIFY FAIL: {error}", file=sys.stderr)
        raise SystemExit(12)
    print("PASS: independent disk-backed stream/byte/count/money oracle")
