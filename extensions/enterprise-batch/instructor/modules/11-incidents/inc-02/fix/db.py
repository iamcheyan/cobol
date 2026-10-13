#!/usr/bin/env python3
"""Offline DB checkpoint store for module 10 (JOB004 / JOB006).

=====================================================================
HONESTY NOTICE - READ BEFORE JUDGING DB BEHAVIOUR
---------------------------------------------------------------------
This is NOT a real database and the course did NOT verify any real
Embedded SQL / PostgreSQL path for module 10.  The GixSQL/PostgreSQL
toolchain validated under curriculum/validation/database/ was NOT
wired into these jobs.  This module emulates, with crash-safe flat
files, the *contract* a real DB would have to provide:

  * a customer/account snapshot frozen per business date
  * an append-only idempotency ledger keyed by (business_date,
    transaction_id) - the single source of truth for "was this
    transaction already applied?"
  * a commit marker recording the committed closing balances
  * atomic replace + fsync so a torn write cannot half-commit

Every job log and evidence record must therefore state:
    "DB layer = offline file checkpoint; real DB NOT verified".
Do not present green results here as proof that a real DB pipeline
works.
=====================================================================
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

ACCOUNT_WIDTH = 47
CUSTOMER_WIDTH = 27
TX_WIDTH = 55

# Crash-injection convention mirrored from jobs/nightly.sh.
CRASH_RC = 97


def die(code: int, message: str) -> "NoReturn":  # type: ignore[name-defined]
    print(f"db.py: {message}", file=sys.stderr)
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
    """Write path via temp file + fsync + rename (single-file atomicity)."""
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


def signed_value(sign: bytes, digits: bytes) -> int:
    value = int(digits.decode("ascii"))
    return -value if sign == b"-" else value


def format_signed(value: int) -> bytes:
    sign = b"-" if value < 0 else b"+"
    return sign + f"{abs(value):013d}".encode("ascii")


def ledger_path(db: Path) -> Path:
    return db / "ledger.dat"


def load_ledger(db: Path) -> list[str]:
    path = ledger_path(db)
    if not path.exists():
        return []
    return path.read_text(encoding="ascii").splitlines()


def ledger_index(lines: list[str]) -> dict[tuple[str, str], str]:
    index: dict[tuple[str, str], str] = {}
    for line in lines:
        parts = line.split("|")
        if len(parts) != 6:
            die(12, "ledger.dat row malformed")
        index[(parts[0], parts[1])] = line
    return index


def load_balances_file(path: Path) -> dict[str, tuple[bytes, int]]:
    records = read_records(path, ACCOUNT_WIDTH)
    balances: dict[str, tuple[bytes, int]] = {}
    for row in records:
        acct = row[:10].decode("ascii")
        balances[acct] = (row, signed_value(row[21:22], row[22:35]))
    return balances


def load_balances(db: Path) -> dict[str, tuple[bytes, int]]:
    return load_balances_file(db / "account.table")


def write_balances(db: Path, balances: dict[str, tuple[bytes, int]]) -> None:
    rows = []
    for acct in sorted(balances):
        row, value = balances[acct]
        rows.append(row[:21] + format_signed(value) + row[35:])
    atomic_write(db / "account.table", b"".join(r + b"\n" for r in rows))


def cmd_seed(args: argparse.Namespace) -> int:
    db = Path(args.db)
    db.mkdir(parents=True, exist_ok=True)
    account = db / "account.table"
    customer = db / "customer.table"
    if account.exists() or customer.exists():
        if not (account.exists() and customer.exists()):
            die(12, "half-seeded DB store")
        read_records(account, ACCOUNT_WIDTH)
        return 0
    for key, target, width in (("--account", account, ACCOUNT_WIDTH),
                               ("--customer", customer, CUSTOMER_WIDTH)):
        source = getattr(args, key[2:].replace("-", "_"))
        if not source:
            die(12, f"{key} required to seed an empty DB")
        rows = read_records(Path(source), width)
        atomic_write(target, b"".join(r + b"\n" for r in rows))
    return 0


def cmd_snapshot(args: argparse.Namespace) -> int:
    db = Path(args.db)
    date = args.business_date
    snap_dir = db / "snapshots" / date
    account_src = db / "account.table"
    customer_src = db / "customer.table"
    if not account_src.exists() or not customer_src.exists():
        die(12, "DB store not seeded")
    account_rows = read_records(account_src, ACCOUNT_WIDTH)
    customer_rows = read_records(customer_src, CUSTOMER_WIDTH)
    snap_dir.mkdir(parents=True, exist_ok=True)
    existing = snap_dir / "dbsnapshot.json"
    if existing.exists():
        # The day's opening snapshot is immutable: reusing it must not be
        # invalidated by this same day's own postings (JOB006 updates the
        # live account.table).  Verify the frozen files instead.
        meta = json.loads(existing.read_text(encoding="ascii"))
        if meta.get("business_date") != date:
            die(12, "frozen snapshot date mismatch")
        for name, key in (("account_master.dat", "account_sha256"),
                          ("customer_snapshot.dat", "customer_sha256")):
            path = snap_dir / name
            if not path.exists() or digest_file(path) != meta.get(key):
                die(12, f"frozen snapshot {name} checksum mismatch")
        print(json.dumps(meta))
        return 0
    account_snap = b"".join(r + b"\n" for r in account_rows)
    customer_snap = b"".join(r + b"\n" for r in customer_rows)
    account_hash = digest_bytes(account_snap)
    atomic_write(snap_dir / "account_master.dat", account_snap)
    atomic_write(snap_dir / "customer_snapshot.dat", customer_snap)
    meta = {
        "engine": "offline-file-checkpoint",
        "real_db_verified": False,
        "business_date": date,
        "run_id": args.run_id,
        "cutoff": date + "T00:00:00",
        "account_count": len(account_rows),
        "customer_count": len(customer_rows),
        "account_sha256": account_hash,
        "customer_sha256": digest_bytes(customer_snap),
    }
    atomic_write(existing, (json.dumps(meta, sort_keys=True) + "\n").encode())
    print(json.dumps(meta))
    return 0


def cmd_status(args: argparse.Namespace) -> int:
    db = Path(args.db)
    date = args.business_date
    marker = db / "commit" / f"{date}.json"
    lines = load_ledger(db)
    applied = sum(1 for line in lines if line.startswith(date + "|"))
    state = {
        "business_date": date,
        "committed": marker.exists(),
        "applied_transactions": applied,
    }
    if marker.exists():
        state["commit"] = json.loads(marker.read_text(encoding="ascii"))
    print(json.dumps(state, sort_keys=True))
    return 0


def cmd_apply(args: argparse.Namespace) -> int:
    db = Path(args.db)
    date = args.business_date
    accepted = read_records(Path(args.accepted), TX_WIDTH)
    ledger_lines = load_ledger(db)
    index = ledger_index(ledger_lines)
    new_rows: list[str] = []
    seen: set[tuple[str, str]] = set()
    for row in accepted:
        txid = row[10:26].decode("ascii")
        key = (date, txid)
        # The ledger contract declares UNIQUE(business_date,
        # transaction_id).  A duplicate delivered inside one batch is a
        # unique-constraint violation and must fail the run; a key that is
        # already in the ledger is a legitimate idempotent rerun and is
        # skipped without re-applying.
        if key in seen:
            die(8, f"unique constraint violation on "
                   f"(business_date, transaction_id)=({date},{txid})")
        if key in index:
            continue
        seen.add(key)
        new_rows.append(row.decode("ascii"))
    commit_id = hashlib.sha256(
        f"{date}|{args.run_id}".encode()).hexdigest()[:16]

    balances = load_balances(db)
    candidate = load_balances_file(Path(args.candidate_master))

    if new_rows:
        deltas: dict[str, int] = {}
        for row in new_rows:
            raw = row.encode("ascii")
            acct = raw[:10].decode("ascii")
            amount = int(raw[41:54])
            delta = amount if raw[40:41] == b"C" else -amount
            deltas[acct] = deltas.get(acct, 0) + delta
        for acct, delta in deltas.items():
            if acct not in balances:
                die(8, f"apply target account {acct} missing from DB")
            row, value = balances[acct]
            balances[acct] = (row, value + delta)
        for acct, (_, expected) in candidate.items():
            if acct not in balances:
                die(8, f"candidate account {acct} missing from DB")
            if balances[acct][1] != expected:
                die(8, f"DB closing != candidate for account {acct} "
                       f"({balances[acct][1]} vs {expected})")

    if args.inject == "before":
        die(CRASH_RC, "injected crash before DB commit")

    if new_rows:
        appended = ledger_lines + [
            f"{date}|{row[10:26]}|{row[:10]}|{row[40:41]}|{row[41:54]}|"
            f"{commit_id}" for row in new_rows]
        write_balances(db, balances)
        atomic_write(ledger_path(db),
                     ("\n".join(appended) + "\n").encode("ascii"))
    elif not args.candidate_master:
        die(12, "apply needs candidate master")

    if args.inject == "mid":
        die(CRASH_RC, "injected crash after ledger write, before marker")

    # Idempotent rerun / recovery: verify DB balances equal candidate.
    if not new_rows:
        for acct, (_, expected) in candidate.items():
            if acct not in balances:
                die(8, f"candidate account {acct} missing from DB")
            if balances[acct][1] != expected:
                die(8, f"DB already applied but balances differ for {acct}")

    marker = db / "commit" / f"{date}.json"
    marker.parent.mkdir(parents=True, exist_ok=True)
    meta = {
        "business_date": date,
        "commit_id": commit_id,
        "run_id": args.run_id,
        "new_transactions": len(new_rows),
        "applied_transactions": len(index) + len(new_rows),
        "ledger_sha256": digest_file(ledger_path(db))
        if ledger_path(db).exists() else digest_bytes(b""),
    }
    atomic_write(marker, (json.dumps(meta, sort_keys=True) + "\n").encode())

    if args.inject == "after":
        die(CRASH_RC, "injected crash after DB commit")

    print(json.dumps({"commit_id": commit_id, "new_transactions": len(new_rows),
                      "applied_transactions": meta["applied_transactions"]}))
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="db.py")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("seed")
    p.add_argument("--db", required=True)
    p.add_argument("--account")
    p.add_argument("--customer")
    p.set_defaults(func=cmd_seed)

    p = sub.add_parser("snapshot")
    p.add_argument("--db", required=True)
    p.add_argument("--business-date", required=True)
    p.add_argument("--run-id", required=True)
    p.set_defaults(func=cmd_snapshot)

    p = sub.add_parser("status")
    p.add_argument("--db", required=True)
    p.add_argument("--business-date", required=True)
    p.set_defaults(func=cmd_status)

    p = sub.add_parser("apply")
    p.add_argument("--db", required=True)
    p.add_argument("--business-date", required=True)
    p.add_argument("--run-id", required=True)
    p.add_argument("--accepted", required=True)
    p.add_argument("--candidate-master", required=True)
    p.add_argument("--inject", choices=["", "before", "mid", "after"],
                   default="")
    p.set_defaults(func=cmd_apply)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except OSError as error:
        return die(12, f"system error: {error}")  # type: ignore[func-returns-value]


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
