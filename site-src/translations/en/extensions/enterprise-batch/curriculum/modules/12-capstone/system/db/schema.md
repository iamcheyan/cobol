# Capstone DB Schema: 12 Logical Tables

See `system/lib/capdb.py` for the physical implementation. The DB layer is an **offline file checkpoint**, not a real database (real PostgreSQL/Embedded-SQL is not integrated or verified).

| # | Logical table | Physical storage | Primary/unique key | Description |
|---:|---|---|---|---|
| 1 | customer | `customer.table` | customer_id | CAP-CUSTOMER-FEED v2, 32B (31B v1 automatically upgraded) |
| 2 | account | `account.table` | account_id | ACCOUNT v1, 47B |
| 3 | transaction_ledger | `ledger.dat` (value column) | (business_date, transaction_id) | Posted transactions |
| 4 | batch_run | `run/<date>.table` | (date, run_id, phase) | JOB run records |
| 5 | batch_commit | `commit/<date>.json` | business_date | Commit identifier and ledger hash |
| 6 | customer_snapshot | `snapshots/<date>/customer_snapshot.dat` | customer_id | Frozen view for the day |
| 7 | account_snapshot | `snapshots/<date>/account_master.dat` | account_id | Frozen view for the day |
| 8 | reject_log | `reject_log.dat` | (date, stage, key) | Validation/reconciliation rejects |
| 9 | control_total | `control_total.dat` | (date, run_id) | Conservation evidence |
| 10 | publish_registry | `publish_registry.dat` | (date, run_id) | Publication registry |
| 11 | idempotency_key | `ledger.dat` (key column) | (business_date, transaction_id) | Idempotency key |
| 12 | business_calendar | `business_calendar.dat` | date | Business calendar |

Transaction boundary: `capdb.py apply` writes balances and ledger first (`fsync` + `rename`), then writes the commit marker within a single process. After a crash, it determines the state by “reading the ledger/commit marker first”; it never infers state from the last log line.
