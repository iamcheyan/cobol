# Incident INC-2026-002: Nightly Batch Succeeded, but the Closing Account Balance Does Not Match the Business Ledger

> Student package. **The root cause is not included.** Investigation deliverables, in order: symptoms and impact → timeline → hypotheses and evidence → minimal reproduction → root cause → fix/rollback → recovery and rerun → prevention. See [hints.md](hints.md) for progressive hints.

## 1. Symptoms and impact

- **All nodes COMPLETE, overall RC0** for the nightly batch on business date `20261009`; it formally published `publish/as-found/`.
- Business review found the closing balance for account `0000000001` was **2000**, while the business ledger expects **1500**. Closing balances for accounts `0000000002` (150) and `0000000003` (25) match expectations.
- Impact: **an incorrect result has already been published downstream**, which is more dangerous than no publication. Downstream posting based on it would create an actual discrepancy.

## 2. Timeline

| Time (UTC) | Event |
|---|---|
| 01:02:xx | JOB001–JOB009 all COMPLETE rc=0 |
| — | JOB006 wrote the DB ledger and commit; JOB008 published `publish/as-found/` |
| Afterward | Independent business recalculation found a 500 closing-balance difference for account 0000000001 |

Original scene: `scene/console.txt`, `scene/logs/nightly.log`, `scene/logs/JOB006.log`, `scene/ledger-victim.dat`, `scene/published-control-report.txt`, and `scene/scheduler-status.txt`.

## 3. Package inventory

| Material | Location |
|---|---|
| Scheduler status | `scene/scheduler-status.txt` |
| Run parameters | `scene/run.env` |
| Original receive manifests | `scene/MANIFEST`, `input/MANIFEST` |
| Original inputs (unchanged) | `input/transaction.dat`, `input/account_seed.dat`, `input/customer_seed.dat` |
| JOB logs | `scene/logs/nightly.log`, `scene/logs/JOB0*.log` |
| DB ledger scene (offline checkpoint) | `scene/ledger-victim.dat`, `scene/db-account.table` |
| DB contract (DDL / SQL Log) | `scene/db-schema.sql`, `scene/sql-log.txt` |
| Published results | `scene/published-control-report.txt`, `scene/published-closing-master.dat` |
| Relevant source | `scene/source/db.py`, `scene/source/control.py`, `scene/source/M11MATCH.COB` |
| Copybooks (frozen interfaces) | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| Reproduction script | `run.sh` |

> DB note: this course snapshot is **not connected to real PostgreSQL**; `lib/db.py` is an offline file checkpoint, and `db-schema.sql` records the contract declared upstream (including a UNIQUE constraint). Any claim that a “real DB has been verified” is unverified.

## 4. Reproduce

```bash
bash INC-2026-002/student/run.sh /tmp/INC-2026-002-scene /tmp/INC-2026-002-db
echo "rc=$?"                 # original RC reproduced
cat /tmp/INC-2026-002-db/ledger.dat
cat /tmp/INC-2026-002-scene/work/control/control.txt
```

## 5. Investigation tasks

1. Reproduce and confirm the original RC and the fact that a result was published.
2. Starting from `input/transaction.dat`, independently calculate the closing balance of account `0000000001`, compare it with `scene/published-closing-master.dat`, and identify the source of the difference.
3. Compare the unique key declared in `scene/db-schema.sql` with the actual contents of `scene/ledger-victim.dat`: what does the contract require, and what actually happened? Did the program implement this contract?
4. Explain why the internal conservation check (JOB007 comparing the streams with each other) **cannot** detect this difference.
5. Provide a minimal fix, recovery/rerun plan (given that the result was published and committed, how should it be corrected? Is a business correction run and a new business version needed?), and prevention measures.

## 6. Hint ladder

See [hints.md](hints.md).

## 7. Plugin and terminal alternatives

```bash
cut -b1-26 INC-2026-002/student/input/transaction.dat | sort | uniq -d
sort INC-2026-002/student/scene/ledger-victim.dat | cut -d'|' -f1,2 | uniq -d
rg -n 'ledger_index|new_rows|in index|UNIQUE' \
   INC-2026-002/student/scene/source/db.py \
   INC-2026-002/student/scene/db-schema.sql
```
