# Module 08 design: COBOL + real database

This document describes Module 08 schema, amount types, schema version, idempotency keys, and transaction boundaries. Field contracts are frozen by [Bank System Design](../../../docs/curriculum/BANK-SYSTEM.md): CUSTOMER v1 = 27B, ACCOUNT v1 = 47B, TRANSACTION v1 = 55B.

## 1. Toolchain (validated through P1; P1 itself unchanged)

| Component | Version/pin | Notes |
|---|---|---|
| OS image | `debian:13-slim@sha256:a29215f6…` | Same digest as P1 |
| GnuCOBOL | 3.2.0 (Debian package `gnucobol3`) | Default dialect; do not use `-std=cobol85` |
| GixSQL | commit `69e26719ecaca2c31bdf91d7add270b1c0ce2286` | Precompiler `gixpp` + `libgixsql` |
| PostgreSQL | `postgres:17@sha256:e3841145…` | Recommended baseline; course measured only on this version |
| Local patches | `gixsql-cursor-null.patch`, `gixsql-closed-cursor.patch` | Module 08 `db/Dockerfile` directly uses the P1 patches with the same names |

`db/Dockerfile` matches P1 `curriculum/validation/database/Dockerfile`; `scripts/docker-image.sh` copies both patches from the P1 directory to assemble the build context and **does not modify P1 files**. Built image `cobol-course-gixsql:m08` shares layers with P1. `scripts/check.sh` records `p1-patches.sha256` as patch-regression evidence. Measured only on Linux x86-64.

## 2. Logical tables (`db/schema.sql`, schema_version = 001)

Course logical tables: `customer`, `account`, `account_balance`, `transaction_ledger`, `batch_run`, and `batch_commit`, plus `schema_version` and the teaching-only `probe_null`.

| Table | Key columns | Constraints/notes |
|---|---|---|
| `customer` | `customer_id CHAR(8) PK`, `customer_name VARCHAR(10)`, `balance_demo NUMERIC(8,0)`, `status CHAR(1)`, `contact_note VARCHAR(20)`, `business_date CHAR(8)`, `layout_version` | Maps to CUSTOMER v1 27B; `business_date` is snapshot dimension and is not in the 27B file |
| `account` | `account_id CHAR(10) PK`, `customer_id FK`, `currency`, `balance_sign`, `opening_balance NUMERIC(13,0)`, `closing_balance NUMERIC(13,0)`, `account_status`, `business_date`, `layout_version` | Maps to ACCOUNT v1 47B; opening and closing balances are separate |
| `account_balance` | `account_id PK`, `balance NUMERIC(13,0)` | Per-account running balance, for independent reconciliation |
| `transaction_ledger` | `transaction_id CHAR(16)`, `account_id`, `business_date`, `sequence_no`, `direction`, `amount NUMERIC(13,0)`, `status`, `applied_run_id`, **UNIQUE(business_date, transaction_id)** | Maps to TRANSACTION v1 55B; unique business key is the idempotency key |
| `batch_run` | `run_id PK`, `business_date`, `status` | One row per attempt |
| `batch_commit` | `business_date PK`, `run_id`, `applied_count` | One successful commit per business date |

### Amount types

All amounts are integer minor units (initially JPY=1 yen), stored as `NUMERIC(x,0)`, **never floating point**. Text interfaces (47B/55B) contain 13-digit, right-aligned, zero-padded decimal strings. COBOL receives them as `PIC 9(13)` and binds them to DB `NUMERIC(13,0)`. No implicit currency conversion.

### Schema version

The `schema_version` table stores `'001'`. When extracting a snapshot, write both `SCHEMA_VERSION=001` and `LAYOUT_VERSION=001` to metadata; a version mismatch is a structural error (RC8).

## 3. Idempotency keys and reruns

- Transaction idempotency key: `(business_date, transaction_id)`, enforced by the `transaction_ledger` unique constraint.
- Business-date commit key: `batch_commit.business_date` (primary key).
- Rerun behavior: on a second run for the same business date, each transaction hits `23505` (unique violation). After `ROLLBACK TO SAVEPOINT`, the program reads the existing row's `applied_run_id`:
  - Same as this `run_id` → duplicate within this run → **RC8**, roll back the whole batch.
  - Different → posted by a historical run → **SKIP**, do not charge again.
  Re-inserting `batch_commit` also raises `23505`; mark `DAY-ALREADY-COMMITTED` without failing.
- Unknown commit result (caller believes a commit failed after it may have succeeded): retry on an **independent connection** and verify `account.closing_balance`, `transaction_ledger` row count, and `batch_commit` row count remain unchanged, proving transactions were not applied twice.

## 4. Transaction boundaries and faults

- Connection explicitly sets `autocommit=off`; PostgreSQL native cursors require an explicit transaction block.
- Each transaction is wrapped in `SAVEPOINT SP1`: on unique-key conflict, `ROLLBACK TO SAVEPOINT` restores the transaction, then classify the duplicate type. This is the only correct local recovery under PostgreSQL's “statement failure aborts the transaction” behavior.
- `batch_commit` is wrapped in `SAVEPOINT SP2`; on `23505`, roll back locally.
- Normal path ends with `COMMIT WORK`; rollback mode, in-run duplicate, and structural error use `ROLLBACK WORK`.
- Connection failure: an invalid port returns SQLSTATE `08001` (connection class 08) → program RC12.
- Cursor paths distinguish “no data” from “error”: exhausted `FETCH`/`SELECT INTO` yields `02000`; other SQLSTATEs are errors. Constraint error `23514` demonstrates a real error class.

## 5. RC policy

| RC | Meaning | Publish |
|---:|---|---|
| 0 | No business differences / commit succeeded / retry skipped existing work | Yes |
| 4 | Snapshot differs from upstream in business data | Yes (attach difference report) |
| 8 | Structural error / in-run duplicate transaction | No (rollback) |
| 12 | Build, connection, SQL system error, reconciliation, or publication failure | No |

## 6. Known limits (not claimed as validated)

- Linux x86-64 only; macOS/WSL/ARM unverified.
- Error codes are for PostgreSQL 17; `23505`/`23514`/`02000`/`08001` are PostgreSQL semantics and **must not** be mapped directly to host DB2 codes such as `-803`.
- No real network-drop interruption or concurrent lock contention was tested; only invalid-port connection failure and idempotent rerun after commit were tested.
- Snapshot and SAVEPOINT behavior depends on the pinned GixSQL commit plus two local patches; a version change requires revalidation.
