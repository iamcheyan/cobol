# Module 10 Design: Nightly JOB Orchestration, RCs, and Recovery

Corresponds to outline 10.1–10.5. This file defines dependencies, RC policy, locks/snapshots/Manifests, and the recovery checklist; learner tasks and acceptance criteria are in [README](README.md), and instructor root causes and answers are in `instructor/modules/10-jobs/`.

## 1. JOB Dependencies and RC Policy

```mermaid
flowchart LR
  J1[JOB001 Receive] --> J2[JOB002 Validate] --> J3[JOB003 SORT]
  J3 --> J4[JOB004 DB Snapshot] --> J5[JOB005 Match/Balance] --> J6[JOB006 Idempotent Apply]
  J6 --> J7[JOB007 Control Totals] --> J8[JOB008 Publish] --> J9[JOB009 Complete]
```

| JOB | Input (read-only) | Output/checkpoint | Allowed preceding RCs | After failure |
|---|---|---|---|---|
| 001 | Receive directory + MANIFEST | `snapshot/` (immutable) + checksums | — | RC8/12 does not proceed to validation |
| 002 | Snapshot + layout contract | `work/validate/` (accepted/rejected/control) | RC0 only | Structural error RC8; business rejection RC4 |
| 003 | Accepted transactions | `work/sorted_tx.dat` + ordering evidence | RC0 only | Temporary space etc. RC12; no final artifact |
| 004 | Business date + DB store | `work/db/` snapshot (version/cutoff) | RC0 only | Connection/validation failure RC12; do not pass off stale data |
| 005 | Snapshot accounts + sorted transactions | `work/closing/` (candidate, isolated) | RC0, RC4 (business rejects) | Candidate is not published |
| 006 | Candidate + idempotency keys | Ledger + commit marker | RC0, RC4 | Check ledger first, then decide whether to recover |
| 007 | Details/rejections/ledger | `work/control/` (reconciliation evidence) | RC0 only | Failure RC8; cannot publish |
| 008 | Reconciled candidate | `publish/<run_id>/` + CURRENT | RC0 only | If committed, recover publication only |
| 009 | Completion evidence | `state/complete.marker` + next-day preparation | RC0 only | State is inspectable; do not overwrite the original run |

RC semantics (course convention, not exit codes of any real product):

| RC | Meaning | Continue? | Publish as final? |
|---:|---|---|---|
| 0 | Normal | Yes | Yes |
| 4 | Contract-permitted warning (individual business rejections) | Yes | Yes, after JOB007 reconciliation |
| 8 | Business/contract error (length, ordering, or conservation mismatch) | No | No |
| 12 | System error (permissions/disk/mktemp/lock/unexpected child process code) | No | No |

Child process exit codes other than 0/4/8/12 (including signals) are always mapped to RC12 at the Shell boundary and recorded; they are never disguised as business rejections (BANK-SYSTEM §6).

## 2. Configuration, Parameters, and Business Date

- Parameter precedence: **CLI > `--config` file > allowlisted `BANK_*` environment variables > built-in defaults**.
- Environment variables are only for agreed configuration: `BANK_INPUT／BANK_OUTPUT／BANK_DB_DIR／BANK_BUSINESS_DATE／BANK_RUN_ID／BANK_COURSE_SOURCE／BANK_CRASH_AT`.
- The business date must be explicitly supplied as a parameter; do not use the machine's current date. Invalid Gregorian dates are rejected at entry with RC8.
- All scripts `export LC_ALL=C` and do not depend on the caller's locale.
- Temporary directories: each JOB works in its own run directory; the sort node uses `mktemp -d` and creates it in the parent directory. Failure maps to RC12.

**POSIX sh vs. Bash (10.1)**: Scripts in this module use Bash features (`[[ ]]`, `${var:-}`, no arrays but requiring `pipefail`, `set -E`, and `local`), so the shebang is `#!/usr/bin/env bash` and `set -Eeuo pipefail` is explicit. POSIX `sh` does not have `pipefail`, `[[`, `local`, or `BASH_SOURCE`; porting to `dash` requires using `set -e`, `[ ]`, `cd -- "$(dirname -- "$0")"` at each stage, and capturing intermediate exit codes with `mktemp` yourself. The course is verified only on Bash; a POSIX sh port is an extension exercise and is not claimed to be verified.

## 3. Locks, Input Snapshots, and Atomic Publication

- **Output lock**: `<output>.lock` (acquired atomically with `mkdir`).
- **Business-date lock**: `<db>/locks/<business_date>.lock`, containing the holder's pid. If the process is alive, a concurrent start on the same date is rejected with RC12; if the pid is dead, the stale lock is reclaimed and recorded.
- **Input snapshot**: JOB001 verifies SHA256 against MANIFEST, then copies into `snapshot/`. All subsequent JOBs read only the snapshot and never write to the original receive directory. JOB004 freezes that date's opening account/customer view in `db/snapshots/<date>/`; *the day's own applications do not rewrite this frozen view*. Only the frozen files' own checksums are verified (tamper protection).
- **Atomic publication**: JOB008 stages first in `work/publish/<run_id>/` → generates and verifies `manifest.json`／`MANIFEST.sha256` → switches to `publish/<run_id>/` using `mv -T -n` → only then moves the `publish/CURRENT` pointer. Both the publication directory and CURRENT carry the run_id; JOB009 writes the completion marker only after confirming CURRENT == this run_id, so an old result cannot masquerade as this run's result.
- **Manifest fields**: `run_id、business_date、engine、real_db_verified=false、files{name: sha256}`, plus the corresponding `MANIFEST.sha256`.

## 4. DB Layer: Offline File Checkpoints (Default) + Real DB Route (R01)

**Default teaching route**: `lib/db.py` simulates database semantics with crash-safe flat files: the idempotency ledger `ledger.dat` (key = business date + transaction ID) is written **first** (write-ahead, single source of truth); the account table `account.table` is **derived/self-healing** from “frozen opening snapshot + ledger”; the commit marker is `db/commit/<date>.json`. Each file is written using a temporary file + `fsync` + `rename`. Since the ledger is written first and balances can be derived, there is no longer a dangerous window where “balance changed but ledger has no record”; rerunning after a crash at any persistence boundary applies each transaction only once. Offline evidence must still state “DB not verified.”

**Real DB route (R01)**: `scripts/real-db.sh` uses Docker + PostgreSQL17 + GixSQL and reuses the canonical ESQL programs from module 08: JOB004 extracts the customer view with a real cursor (`SNAPSHOT.COB`, checked byte-for-byte against the frozen feed); JOB006 uses `APPLY.COB` to commit the idempotency ledger + balances + `batch_commit` in **one transaction** (duplicate business keys trigger a unique constraint → skip or rollback). Balance/ledger/commit row counts are read back using an **independent psql connection**. Regression script `scripts/check-real-db.sh` covers initial commit, retry after unknown commit outcome (ALREADY-APPLIED without duplicate application), concurrent retry, and rollback atomicity; if the real DB is unavailable, it reports `UNVERIFIED`.

## 5. Idempotency and Reruns

- Idempotency key: `(business_date, transaction_id)`.
- Before applying transactions, JOB006 runs `db.py status` to read the ledger; transactions with existing keys are not accumulated again.
- Account balances are updated by “adding accepted transaction deltas”; on rerun there are no new keys → balances do not change (no duplicate debit).
- Candidate closing balances are independently cross-checked against updated balances; a mismatch → RC8 and no publication.
- Three rerun types: resume a failed stage (continue via marker), rebuild derived files from the frozen snapshot, business correction run (requires a new business version and is outside this module's scope).

## 6. Four Required Crash Boundaries and Recovery Checklist

Injection: `run.sh --crash-at POINT` (RC97 and preserve work); rerun with the same `--run-id/--output/--db` to recover automatically.

| Boundary | Injection point | Facts after crash | Recovery action | Consistency criterion |
|---|---|---|---|---|
| Before DB commit | `db.py apply --inject before` | No new ledger rows, no commit | Resume JOB006 and apply normally | Ledger = accepted transaction count; balances = candidate |
| After commit, before publish | `db.py apply --inject after` | Ledger/balances/commit written | Resume JOB007/008 | Same as above, and publication directory created |
| During publication | After JOB008 staging, before switch | Staging only; no `publish/<run_id>` | Stage and publish again | CURRENT == run_id |
| After publish, before completion marker | nightly after JOB008 | Published; no completion marker | Resume JOB009 | Completion marker complete |
| (Additional) During commit | `db.py apply --inject mid` | Ledger written, no commit marker | Check ledger first, then resume | No duplicate debit |

Recovery principle: **verify facts using the idempotency ledger/commit identifier/Manifest/checksums; never infer transaction state from the last line of the Shell log**. If committed but not published, recover publication only.

## 7. JOB Node Mapping

The top-level 9 JOBs expand into traceable processing nodes:

| Node | Step | Node | Step |
|---|---|---|---|
| 001a | Receive MANIFEST | 006a | Read ledger (check first) |
| 001b | Verify input SHA256 | 006b | Idempotent application |
| 001c | Freeze input snapshot | 006c | Write commit marker |
| 002a | Length/structure validation | 007a | Transaction-count conservation |
| 002b | Numeric field validation | 007b | Amount conservation |
| 002c | Business-rule validation | 007c | Ledger cross-check |
| 002d | Rejection report + control totals | 007d | Generate daily report |
| 003a | Build/validate | 008a | Stage artifacts |
| 003b | SORT | 008b | Verify Manifest |
| 003c | Verify ordering | 008c | Atomic switch |
| 004a | DB reachability/version | 008d | Update CURRENT |
| 004b | Freeze customer snapshot | 009a | Confirm run_id consistency |
| 004c | Freeze account snapshot | 009b | Completion marker |
| 005a | Key Break/balance | 009c | Next-day preparation |
| 005b | Accepted/rejected classification | | |
| 005c | Isolated candidate + report | | |

## 8. Reuse and Boundaries

- JOB003 reuses module 07 SORT reference implementation (`instructor/modules/07/.../SORTTX.COB` via its runner); JOB005 reuses module 07 L2 (`BATCHL2.COB` via its runner). This module does not copy these programs, avoiding drift between chapters.
- JCL/JP1 are **reading mappings only**: `lib/jcl/JOBFLOW.jcl` and `lib/jp1/JOBFLOW.jp1` are illustrative and have never been submitted or loaded on z/OS/JES2 or JP1/AJS; no platform runnability is claimed.
- Platform: actually verified only on Linux x86-64; macOS/WSL/other architectures are unverified.
