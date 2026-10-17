# Module 10: Shell / JCL / Scheduler — Nightly JOB Operations

Recommended: 9 hours. Prerequisites: Module 06 (file contracts) and Module 07 (SORT and sequential matching). This module elevates a “program” into a “job”: receive → validate → sort → DB snapshot → match → idempotent application → control totals → publish → complete, and practices RCs, locks, snapshots, Manifests, and recovery at four crash boundaries.

> Platform: actually verified only on Linux x86-64 (GnuCOBOL 3.2, Bash, GNU coreutils, Python 3). macOS/WSL/other architectures are unverified.
>
> **DB layer note (two routes; do not mix them):**
> 1. **Default teaching route (offline)**: JOB004/JOB006 use the crash-safe file checkpoint simulation in `lib/db.py` for database transaction semantics. Evidence must state “DB layer = offline file checkpoint; real DB not verified”; offline RC0 must not be represented as real end-to-end verification.
> 2. **Real DB route (R01)**: `scripts/real-db.sh` uses Docker + PostgreSQL17 + GixSQL, reuses the canonical ESQL programs from module 08 for JOB004 real cursor extraction and JOB006 idempotent application in a single transaction, then checks balances and the ledger using an **independent psql connection**; permanent regression script: `scripts/check-real-db.sh`. If the real DB is unavailable, the script reports `UNVERIFIED` (RC2) and never claims a pass.

## 1. Why Does the Business Need This / What Requirement Were You Given?

Every night, a bank must safely post the day's transactions, reconcile them, and publish them to downstream consumers, while **there is no atomic commit across files, the DB, and downstream publication** (FR-08). Your assignment is an operations requirement: connect 9 JOBs into a nightly flow that ensures **downstream jobs do not run after a prerequisite fails, concurrent starts are rejected, reruns on the same business date do not debit twice, and recovery at all four crash boundaries restores a consistent state**.

## 2. Inputs, Sources, Formats, and Guaranteed Preconditions

The receive directory contains `transaction.dat` (TRANSACTION v1, 55 bytes/record + LF) and `MANIFEST` (business date, layout version, and SHA256 for each file). The DB layer is initially seeded into an offline store directory from `account_seed.dat` (ACCOUNT v1, 47 bytes) and `customer_seed.dat` (CUSTOMER v1, 27 bytes).

Fixed interfaces (canonical definitions are in `curriculum/bank/copybooks/`; module 10 also includes `copybooks/CUSTOMER-V1.CPY`):

- CUSTOMER v1: 27 bytes — id/name/demo_balance/status.
- ACCOUNT v1: 47 bytes — id/customer/currency/sign/balance/status/date/version.
- TRANSACTION v1: 55 bytes — account/txid/date/sequence/direction/amount/status.

Guaranteed: synthetic ASCII data, LF line endings, LF excluded from logical record length, and no default to the machine date for the business date. Duplicate `transaction_id` values, short/long records, and invalid numeric fields are anomalies that must be detected.

## 3. Build, Run, and Reset from a Clean Checkout

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
mod=curriculum/modules/10-jobs

# Build the JOB002 validator (optional; run.sh builds it automatically)
bash "$mod/scripts/build.sh" /tmp/bankval

# Run the full nightly flow (input directory, output directory, DB store, and business date are required)
set +e
bash "$mod/scripts/run.sh" \
  --input  "$mod/fixtures/normal" \
  --output /tmp/bank-night-20261009 \
  --db     /tmp/bank-db \
  --business-date 20261009 \
  --run-id n1
rc=$?
set -e
echo "nightly rc=$rc"      # This fixture is expected to return 4 (includes individual business rejections)

# Inspect state and evidence
bash "$mod/scripts/run.sh" \
  --input "$mod/fixtures/normal" --output /tmp/bank-night-20261009 \
  --db /tmp/bank-db --business-date 20261009 --command status
cat /tmp/bank-night-20261009/work/control/control.txt
python3 "$mod/lib/verify_publish.py" \
  --dir /tmp/bank-night-20261009/publish/n1 --run-id n1 --business-date 20261009

# Reset (accepts only a course run directory containing run.env; rejects repository paths, symlinks, and unmarked directories)
bash "$mod/scripts/reset.sh" /tmp/bank-night-20261009
```

Derived files that may be changed: contents only inside the `--output` directory. **The input directory, fixtures, DB seed, and existing output are never overwritten**; reusing an output directory is rejected with RC12.

## 4. Expected Output, RCs, Counts, and Amounts (Independently Accounted)

`normal` fixture: 3 accounts (opening balances 1000 / 50 / 0), 10 received transactions.

| Metric | Value | Source |
|---|---:|---|
| Received | 10 | Fixture row count |
| JOB002 accepted / rejected | 6 / 4 | Business rules |
| JOB003 sorted | 6 records | accepted |
| JOB005 accepted / rejected (overdraft) | 4 / 2 | Closing-balance rules |
| JOB006 posted to ledger | 4 | Idempotency key |
| Opening/credits/debits/closing totals | 1050 / 600 / 1100 / **550** | Conservation equation |
| Closing balances | acc1 400, acc2 150, acc3 0 | `closing = opening + C − D` |

Full values are in `expected/normal.control.txt` and `expected/normal.closing.txt`. Expected results for this module are calculated by the **independent oracle** in `instructor/modules/10-jobs/tools/gen_course.py` (which reimplements BANKVAL business rules and the 1:N overdraft rule), without copying any course implementation output. `boundary-empty-tx` (RC0, closing = opening 1050) and `boundary-single` (RC0, closing 1150) also have independent expected files.

RCs: `normal`/`boundary-*` return RC4/RC0; the three `invalid-*` cases return RC8 with **no final publication**; system failures (mktemp/permissions/disk/lock) return RC12 with **no final publication**.

## 5. What Must Be Changed, and Which Interfaces Must Not Be Broken

- Learner starting point: `starter/BANKVAL.COB` (compiles, returns RC12, and does not publish). Complete it as a real JOB002 validator. Reference implementation: `instructor/modules/10-jobs/BANKVAL.COB`.
- Must not break: the three fixed record widths and field offsets; the `work/` and `publish/` directory contracts; keys in `control.txt`; return RC semantics (0/4/8/12); idempotency ledger key `(business_date, transaction_id)`.
- JOB003/JOB005 reuse the module 07 reference implementations (do not copy them): the focus is on **integration**, not rewriting the matching algorithm.

## 6. Deliberate Failures and Recovery (At Least One Reproducible Fault per Exercise)

| Exercise | How to break it | Symptom | Recovery |
|---|---|---|---|
| 10.1 Parameters | Omit `--business-date` | Rejected with RC12 | Explicitly pass the business date |
| 10.2 RC | Use the `invalid-short-record` fixture | JOB002 RC8, no publication | Fix the record length |
| 10.2 RC12 | Inject a failing `mktemp` into `PATH` | RC12, no publication, no leftover lock | Restore a normal environment |
| 10.3 Lock | Pre-create `<db>/locks/<date>.lock` (live pid) | Same-date concurrent start gets RC12 | Release the lock |
| 10.3 Snapshot | Tamper with `db/snapshots/<date>/account_master.dat` | JOB004 RC12 | Retrieve again from the DB |
| 10.4 Crash | `--crash-at {before,mid,after}-db-commit / during-publish / after-publish` | RC97, work preserved | Resume automatically with the same run-id |
| 10.4 Rerun | Rerun with the same DB and business date but a new output directory | RC4; balances/ledger unchanged | — |
| 10.5 JCL | Read `lib/jcl/JOBFLOW.jcl` and map it to local nodes | — | Read only; do not claim it is runnable |

```bash
# Run all four (including the additional) crash-boundary recovery experiments in one command; emit raw evidence
bash "$mod/scripts/recovery-lab.sh" /tmp/m10-recovery-lab
```

## 7. Plugin Workflow and Terminal-Only Alternative

- Plugin: use `gd`/`:CobolGotoDef` to locate issues in `lib/db.py` or JOB scripts; for `COPY "ACCOUNT-V1.CPY"`, use `:CobolGotoCopybook` to check the canonical interface; when saving COBOL, use diagnostic underlines to check the 72-column limit and Area A/B.
- Terminal-only alternative (the plugin is not required to complete the work):
  ```bash
  rg -n 'BANKVAL_|--crash-at|ledger|Manifest|complete.marker' curriculum/modules/10-jobs
  od -An -tc curriculum/modules/10-jobs/fixtures/normal/transaction.dat | head
  (cd /tmp/bank-night-20261009/publish/n1 && sha256sum -c MANIFEST.sha256)
  ```

## 8. Evidence to Submit and Failure Conditions

Submit the following according to [evidence/README.md](evidence/README.md): business date, run_id, commands, raw RCs, input/output checksums, control totals, ledger/balance/state at each of the four crash boundaries, before/after rerun comparison, changes made, and regression results.

These count as **failures**: any JOB fails but produces a final publication; a same-business-date rerun causes a duplicate debit; DB/ledger/files/state disagree after crash recovery; an old `publish/<run_id>` or CURRENT is passed off as this run's result; a system failure is recorded as success; or the DB is claimed as real and verified.

Acceptance self-check:

```bash
bash curriculum/modules/10-jobs/scripts/check.sh
```

See `instructor/modules/10-jobs/` for instructor reference implementation, root causes, and RED→GREEN records.
