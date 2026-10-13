#!/usr/bin/env python3
"""Capstone DB layer for module 12 -- 12 logical tables on a crash-safe store.

This is the graduation system's own store.  It keeps the module 10 file
*conventions* (append-only idempotency ledger, commit marker, per-day frozen
snapshot, atomic replace+fsync) but widens the schema the capstone needs:
the customer table stores the CAP-CUSTOMER-FEED v2 layout (32 bytes), an
independent versioned layout whose classification extension (A/B/C/D ->
A1..D1) is real end to end while the canonical 27 byte CUSTOMER v1 (byte 27
= record status) stays unchanged.  Ten further logical tables make the
reject/control/publish/calendar state auditable.

Logical tables (name -> physical store)
---------------------------------------
  1  customer              db/customer.table            (v2, 32 bytes)
  2  account               db/account.table             (v1, 47 bytes)
  3  transaction_ledger    db/ledger.dat                (value columns)
  4  batch_run             db/run/<date>.table
  5  batch_commit          db/commit/<date>.json
  6  customer_snapshot     db/snapshots/<date>/customer_snapshot.dat
  7  account_snapshot      db/snapshots/<date>/account_master.dat
  8  reject_log            db/reject_log.dat
  9  control_total         db/control_total.dat
  10 publish_registry      db/publish_registry.dat
  11 idempotency_key       db/ledger.dat                (key columns)
  12 business_calendar     db/business_calendar.dat

HONESTY NOTICE: the DEFAULT teaching route is this offline file checkpoint
store; on this route no real PostgreSQL/Embedded-SQL pipeline is used and every
evidence record must state "DB layer = offline file checkpoint; real DB NOT
verified".  A separate REAL-DB route exists (scripts/real-db.sh): it reuses the
canonical module 10 harness and the module 08 ESQL programs to commit balances
+ idempotency ledger in one transaction, verified by an independent psql
connection, and reports UNVERIFIED when the environment is absent.

CRASH SAFETY: the idempotency ledger is written FIRST (write-ahead, source of
truth); balances are derived from the frozen opening snapshot plus the ledger,
so a crash between the two writes is healed by re-deriving the balances, never
by re-posting the transactions.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

ACCOUNT_WIDTH = 47
# Enterprise customer feed widths.  The feed is the independent,
# versioned CAP-CUSTOMER-FEED layout (31 B v1 / 32 B v2), which embeds
# the canonical 27 byte CUSTOMER v1 (byte 27 = record status); the
# customer classification is a separate field and is NOT the status byte.
CUSTOMER_V1 = 31
CUSTOMER_V2 = 32
TX_WIDTH = 55
CRASH_RC = 97

TABLES = [
    "customer", "account", "transaction_ledger", "batch_run",
    "batch_commit", "customer_snapshot", "account_snapshot",
    "reject_log", "control_total", "publish_registry",
    "idempotency_key", "business_calendar",
]


def die(code: int, message: str) -> "NoReturn":  # type: ignore[name-defined]
    print(f"capdb.py: {message}", file=sys.stderr)
    raise SystemExit(code)


def digest_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def digest_file(path: Path) -> str:
    return digest_bytes(path.read_bytes())


def fsync_dir(path: Path) -> None:
    fd = os.open(path, os.O_RDONLY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)
    try:
        os.write(fd, data)
        os.fsync(fd)
    finally:
        os.close(fd)
    os.replace(tmp, path)
    fsync_dir(path.parent)


def read_records(path: Path, width: int) -> list[bytes]:
    data = path.read_bytes()
    if data == b"":
        return []
    if not data.endswith(b"\n"):
        die(12, f"{path} missing final LF")
    rows = data[:-1].split(b"\n")
    for row in rows:
        if len(row) != width or b"\r" in row:
            die(12, f"{path} record width != {width}")
    return rows


def read_customer_records(path: Path) -> list[bytes]:
    """Accept an enterprise v1 (31 B) or v2 (32 B) file; return v2 rows.

    v1 -> v2 upgrade widens the classification at byte 28 (1 char, an
    A/B/C/D code) to the 2 char sub-coded form "<code>1" at bytes 28-29
    and sets layout_version (bytes 30-32) to "002".  Byte 27 (record
    status A/D) and every earlier byte are copied unchanged.
    """
    data = path.read_bytes()
    if data == b"":
        return []
    if not data.endswith(b"\n"):
        die(12, f"{path} missing final LF")
    rows = data[:-1].split(b"\n")
    out: list[bytes] = []
    for row in rows:
        if b"\r" in row:
            die(12, f"{path} contains CR")
        if len(row) == CUSTOMER_V2:
            out.append(row)
        elif len(row) == CUSTOMER_V1:
            out.append(row[:28] + b"1" + b"002")
        else:
            die(12, f"{path} customer width {len(row)} not 31/32")
    return out


def signed_value(sign: bytes, digits: bytes) -> int:
    value = int(digits.decode("ascii"))
    return -value if sign == b"-" else value


def format_signed(value: int) -> bytes:
    sign = b"-" if value < 0 else b"+"
    return sign + f"{abs(value):013d}".encode("ascii")


def load_ledger(db: Path) -> list[str]:
    path = db / "ledger.dat"
    if not path.exists():
        return []
    return path.read_text(encoding="ascii").splitlines()


def ledger_index(lines: list[str]) -> dict[tuple[str, str], str]:
    index: dict[tuple[str, str], str] = {}
    for line in lines:
        parts = line.split("|")
        if len(parts) != 6:
            die(12, "ledger row malformed")
        index[(parts[0], parts[1])] = line
    return index


def load_balances_file(path: Path) -> dict[str, tuple[bytes, int]]:
    balances: dict[str, tuple[bytes, int]] = {}
    for row in read_records(path, ACCOUNT_WIDTH):
        balances[row[:10].decode("ascii")] = (row, signed_value(row[21:22],
                                                               row[22:35]))
    return balances


def load_balances(db: Path) -> dict[str, tuple[bytes, int]]:
    return load_balances_file(db / "account.table")


def balances_bytes(balances: dict[str, tuple[bytes, int]]) -> bytes:
    rows = [balances[a][0][:21] + format_signed(balances[a][1])
            + balances[a][0][35:] for a in sorted(balances)]
    return b"".join(r + b"\n" for r in rows)


def write_balances(db: Path, balances: dict[str, tuple[bytes, int]]) -> None:
    atomic_write(db / "account.table", balances_bytes(balances))


def ledger_deltas(db: Path, date: str) -> dict[str, int]:
    """Per-account deltas recorded in the authoritative idempotency ledger."""
    deltas: dict[str, int] = {}
    for line in load_ledger(db):
        parts = line.split("|")
        if len(parts) != 6:
            die(12, "ledger row malformed")
        day, _txid, acct, direction, amount, _commit = parts
        if day != date:
            continue
        value = int(amount)
        deltas[acct] = deltas.get(acct, 0) + \
            (value if direction == "C" else -value)
    return deltas


def derive_balances(db: Path, date: str
                    ) -> "dict[str, tuple[bytes, int]] | None":
    """Rebuild the date's closing balances from the frozen opening snapshot
    plus the committed ledger rows.

    The ledger is written first and is authoritative, so a crash between the
    ledger and balance writes is healed here instead of re-posting the same
    transactions.  None when no frozen opening snapshot exists.
    """
    snapshot = db / "snapshots" / date / "account_master.dat"
    if not snapshot.exists():
        return None
    balances = load_balances_file(snapshot)
    for acct, delta in ledger_deltas(db, date).items():
        if acct not in balances:
            die(8, f"ledger references account {acct} missing from snapshot")
        row, value = balances[acct]
        balances[acct] = (row, value + delta)
    return balances


def calendar_set(db: Path, date: str) -> None:
    path = db / "business_calendar.dat"
    rows: dict[str, str] = {}
    if path.exists():
        for line in path.read_text(encoding="ascii").splitlines():
            parts = line.split("|")
            if len(parts) == 4:
                rows[parts[0]] = line
    if date not in rows:
        rows[date] = f"{date}|OPEN||"
        atomic_write(path, "".join(rows[k] + "\n"
                                   for k in sorted(rows)).encode("ascii"))


def cmd_tables(_args: argparse.Namespace) -> int:
    for name in TABLES:
        print(name)
    return 0


def cmd_seed(args: argparse.Namespace) -> int:
    db = Path(args.db)
    db.mkdir(parents=True, exist_ok=True)
    account, customer = db / "account.table", db / "customer.table"
    if account.exists() or customer.exists():
        if not (account.exists() and customer.exists()):
            die(12, "half-seeded DB store")
        read_records(account, ACCOUNT_WIDTH)
        read_customer_records(customer)
        return 0
    if not args.account or not args.customer:
        die(12, "seed requires --account and --customer")
    rows = read_records(Path(args.account), ACCOUNT_WIDTH)
    cust = read_customer_records(Path(args.customer))
    atomic_write(account, b"".join(r + b"\n" for r in rows))
    atomic_write(customer, b"".join(r + b"\n" for r in cust))
    if args.business_date:
        calendar_set(db, args.business_date)
        run = db / "run" / f"{args.business_date}.table"
        if not run.exists():
            atomic_write(run, (f"date|{args.business_date}|run_id|"
                               f"{args.run_id or 'seed'}|layout|"
                               f"{args.layout or 'v1'}|phase|seeded|rc|0\n")
                         .encode("ascii"))
    print(json.dumps({"tables": len(TABLES), "customers": len(cust),
                      "accounts": len(rows)}, sort_keys=True))
    return 0


def cmd_snapshot(args: argparse.Namespace) -> int:
    db = Path(args.db)
    date = args.business_date
    calendar_set(db, date)
    snap = db / "snapshots" / date
    account_src, customer_src = db / "account.table", db / "customer.table"
    if not account_src.exists() or not customer_src.exists():
        die(12, "DB store not seeded")
    existing = snap / "dbsnapshot.json"
    if existing.exists():
        meta = json.loads(existing.read_text(encoding="ascii"))
        if meta.get("business_date") != date:
            die(12, "frozen snapshot date mismatch")
        for name, key in (("account_master.dat", "account_sha256"),
                          ("customer_snapshot.dat", "customer_sha256")):
            path = snap / name
            if not path.exists() or digest_file(path) != meta.get(key):
                die(12, f"frozen snapshot {name} checksum mismatch")
        print(json.dumps(meta))
        return 0
    account_rows = read_records(account_src, ACCOUNT_WIDTH)
    customer_rows = read_customer_records(customer_src)
    account_snap = b"".join(r + b"\n" for r in account_rows)
    customer_snap = b"".join(r + b"\n" for r in customer_rows)
    atomic_write(snap / "account_master.dat", account_snap)
    atomic_write(snap / "customer_snapshot.dat", customer_snap)
    meta = {
        "engine": "offline-file-checkpoint",
        "real_db_verified": False,
        "business_date": date,
        "run_id": args.run_id,
        "cutoff": date + "T00:00:00",
        "account_count": len(account_rows),
        "customer_count": len(customer_rows),
        "account_sha256": digest_bytes(account_snap),
        "customer_sha256": digest_bytes(customer_snap),
        "customer_layout": "v2",
    }
    atomic_write(existing, (json.dumps(meta, sort_keys=True) + "\n").encode())
    print(json.dumps(meta))
    return 0


def cmd_status(args: argparse.Namespace) -> int:
    db, date = Path(args.db), args.business_date
    marker = db / "commit" / f"{date}.json"
    lines = load_ledger(db)
    applied = sum(1 for line in lines if line.startswith(date + "|"))
    state = {"business_date": date, "committed": marker.exists(),
             "applied_transactions": applied, "tables": len(TABLES)}
    if marker.exists():
        state["commit"] = json.loads(marker.read_text(encoding="ascii"))
    print(json.dumps(state, sort_keys=True))
    return 0


def cmd_apply(args: argparse.Namespace) -> int:
    db, date = Path(args.db), args.business_date
    accepted = read_records(Path(args.accepted), TX_WIDTH)
    lines = load_ledger(db)
    index = ledger_index(lines)
    new_rows = [r.decode("ascii") for r in accepted
                if (date, r[10:26].decode("ascii")) not in index]
    commit_id = hashlib.sha256(f"{date}|{args.run_id}".encode()).hexdigest()[:16]
    balances = load_balances(db)
    candidate = load_balances_file(Path(args.candidate_master))
    if new_rows:
        deltas: dict[str, int] = {}
        for row in new_rows:
            raw = row.encode("ascii")
            amount = int(raw[41:54])
            delta = amount if raw[40:41] == b"C" else -amount
            deltas[raw[:10].decode("ascii")] = \
                deltas.get(raw[:10].decode("ascii"), 0) + delta
        for acct, delta in deltas.items():
            if acct not in balances:
                die(8, f"apply target account {acct} missing from DB")
            row, value = balances[acct]
            balances[acct] = (row, value + delta)
        for acct, (_, expected) in candidate.items():
            if acct not in balances:
                die(8, f"candidate account {acct} missing from DB")
            if balances[acct][1] != expected:
                die(8, f"DB closing != candidate for {acct} "
                       f"({balances[acct][1]} vs {expected})")
    if args.inject == "before":
        die(CRASH_RC, "injected crash before DB commit")
    # Write-ahead commit: the idempotency ledger is written first and is the
    # source of truth.  Balances are derived from the frozen opening snapshot
    # plus the ledger, so the two writes have no window where balances are
    # advanced without a ledger record; a crash between them is healed by
    # re-deriving the balances, never by re-posting the transactions.
    if new_rows:
        appended = lines + [
            f"{date}|{r[10:26]}|{r[:10]}|{r[40:41]}|{r[41:54]}|{commit_id}"
            for r in new_rows]
        atomic_write(db / "ledger.dat",
                     ("\n".join(appended) + "\n").encode("ascii"))

    if args.inject == "ledger":
        die(CRASH_RC, "injected crash after ledger write, before balances")

    healed = derive_balances(db, date)
    if healed is not None:
        for acct, (_, expected) in candidate.items():
            if acct not in healed:
                die(8, f"candidate account {acct} missing from snapshot")
            if healed[acct][1] != expected:
                die(8, f"ledger-derived closing != candidate for {acct} "
                       f"({healed[acct][1]} vs {expected})")
        balances = healed
        atomic_write(db / "account.table", balances_bytes(balances))
    elif new_rows:
        write_balances(db, balances)

    if args.inject == "mid":
        die(CRASH_RC, "injected crash after ledger/balances, before marker")
    if not new_rows and healed is None:
        for acct, (_, expected) in candidate.items():
            if acct not in balances or balances[acct][1] != expected:
                die(8, f"DB already applied but balances differ for {acct}")
    marker = db / "commit" / f"{date}.json"
    meta = {"business_date": date, "commit_id": commit_id, "run_id": args.run_id,
            "new_transactions": len(new_rows),
            "applied_transactions": len(index) + len(new_rows),
            "ledger_sha256": digest_file(db / "ledger.dat")
            if (db / "ledger.dat").exists() else digest_bytes(b"")}
    atomic_write(marker, (json.dumps(meta, sort_keys=True) + "\n").encode())
    run = db / "run" / f"{date}.table"
    with run.open("a", encoding="ascii") as handle:
        handle.write(f"date|{date}|run_id|{args.run_id}|layout|{args.layout}|"
                     f"phase|applied|rc|0\n")
    if args.inject == "after":
        die(CRASH_RC, "injected crash after DB commit")
    print(json.dumps({"commit_id": commit_id, "new_transactions": len(new_rows),
                      "applied_transactions": meta["applied_transactions"]},
                     sort_keys=True))
    return 0


def cmd_record_reject(args: argparse.Namespace) -> int:
    path = Path(args.db) / "reject_log.dat"
    count = 0
    text = Path(args.rejects).read_text(encoding="ascii")
    for raw in text.splitlines():
        if not raw.strip():
            continue
        key = raw[10:26] if len(raw) >= 26 else raw[:16]
        reason = raw[56:].strip() if len(raw) > 56 else "UNKNOWN"
        with path.open("a", encoding="ascii") as handle:
            handle.write(f"{args.business_date}|{args.stage}|{key}|{reason}\n")
        count += 1
    print(json.dumps({"reject_rows": count}, sort_keys=True))
    return 0


def cmd_record_control(args: argparse.Namespace) -> int:
    payload = "|".join(f"{k}={v}" for k, v in sorted(args.pairs.items()))
    path = Path(args.db) / "control_total.dat"
    with path.open("a", encoding="ascii") as handle:
        handle.write(f"{args.business_date}|{args.run_id}|{payload}\n")
    print(json.dumps({"control_recorded": True}, sort_keys=True))
    return 0


def cmd_record_publish(args: argparse.Namespace) -> int:
    manifest = Path(args.manifest)
    files = len(json.loads(manifest.read_text(encoding="ascii")).get("files", {}))
    path = Path(args.db) / "publish_registry.dat"
    with path.open("a", encoding="ascii") as handle:
        handle.write(f"{args.business_date}|{args.run_id}|"
                     f"{digest_file(manifest)}|{files}|{args.published}\n")
    print(json.dumps({"registered": True, "files": files}, sort_keys=True))
    return 0


def cmd_calendar(args: argparse.Namespace) -> int:
    calendar_set(Path(args.db), args.business_date)
    for line in (Path(args.db) / "business_calendar.dat").read_text(
            encoding="ascii").splitlines():
        if line.startswith(args.business_date + "|"):
            print(line)
    return 0


def cmd_idempotency(args: argparse.Namespace) -> int:
    keys = [line.split("|")[1] for line in load_ledger(Path(args.db))
            if line.startswith(args.business_date + "|")]
    print(json.dumps({"business_date": args.business_date, "applied_keys": keys,
                      "count": len(keys)}, sort_keys=True))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="capdb.py")
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("tables"); p.set_defaults(func=cmd_tables)
    p = sub.add_parser("seed")
    p.add_argument("--db", required=True); p.add_argument("--account")
    p.add_argument("--customer"); p.add_argument("--business-date")
    p.add_argument("--run-id"); p.add_argument("--layout", default="v1")
    p.set_defaults(func=cmd_seed)
    p = sub.add_parser("snapshot")
    p.add_argument("--db", required=True)
    p.add_argument("--business-date", required=True)
    p.add_argument("--run-id", required=True); p.set_defaults(func=cmd_snapshot)
    p = sub.add_parser("status")
    p.add_argument("--db", required=True)
    p.add_argument("--business-date", required=True); p.set_defaults(func=cmd_status)
    p = sub.add_parser("apply")
    p.add_argument("--db", required=True)
    p.add_argument("--business-date", required=True)
    p.add_argument("--run-id", required=True)
    p.add_argument("--accepted", required=True)
    p.add_argument("--candidate-master", required=True)
    p.add_argument("--layout", default="v1")
    p.add_argument("--inject",
                   choices=["", "before", "ledger", "mid", "after"],
                   default="")
    p.set_defaults(func=cmd_apply)
    p = sub.add_parser("record-reject")
    p.add_argument("--db", required=True)
    p.add_argument("--business-date", required=True)
    p.add_argument("--stage", required=True)
    p.add_argument("--rejects", required=True); p.set_defaults(func=cmd_record_reject)
    p = sub.add_parser("record-control")
    p.add_argument("--db", required=True)
    p.add_argument("--business-date", required=True)
    p.add_argument("--run-id", required=True)
    p.add_argument("--pair", action="append", default=[]); p.set_defaults(func=cmd_record_control)
    p = sub.add_parser("record-publish")
    p.add_argument("--db", required=True)
    p.add_argument("--business-date", required=True)
    p.add_argument("--run-id", required=True)
    p.add_argument("--manifest", required=True)
    p.add_argument("--published", required=True); p.set_defaults(func=cmd_record_publish)
    p = sub.add_parser("calendar")
    p.add_argument("--db", required=True)
    p.add_argument("--business-date", required=True); p.set_defaults(func=cmd_calendar)
    p = sub.add_parser("idempotency")
    p.add_argument("--db", required=True)
    p.add_argument("--business-date", required=True); p.set_defaults(func=cmd_idempotency)
    return parser


def main(argv: list[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command == "record-control":
        pairs: dict[str, str] = {}
        for item in args.pair:
            key, sep, value = item.partition("=")
            if not sep:
                die(12, f"bad --pair '{item}'")
            pairs[key] = value
        args.pairs = pairs
    try:
        return args.func(args)
    except OSError as error:
        return die(12, f"system error: {error}")  # type: ignore[func-returns-value]


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
