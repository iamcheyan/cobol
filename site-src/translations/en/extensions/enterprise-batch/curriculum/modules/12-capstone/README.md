# Module 12: Capstone Project — Unfamiliar-Version Banking System

Estimated time: 9 hours. Prerequisites: module 06 (file contracts), 07 (sorting and sequential matching), and 10 (JOB operations).
This module **orchestrates** canonical components from modules 06/07/08/10 into an "unfamiliar-version" nightly batch system. You will reconstruct its architecture, complete the customer classification extension, run four types of business days, and investigate an incident with a **hidden root cause**.

> Platform: verified only on Linux x86-64 (GnuCOBOL 3.2.0, Bash, GNU coreutils, Python 3). macOS/WSL/other architectures are **unverified**.
>
> **DB layer (two paths; do not mix them):**
> 1. **Default teaching path (offline):** `system/lib/capdb.py` uses offline file checkpoints to simulate the database contract for 12 logical tables. Evidence for this path must state "DB layer = offline file checkpoint; real DB unverified"; an offline RC0 must not be presented as real end-to-end verification.
> 2. **Real DB path (R01):** `scripts/real-db.sh` reuses the canonical module 10 harness (Docker + PostgreSQL17 + GixSQL + module 08 ESQL), performs real cursor extraction and **single-transaction** idempotent posting (balance + ledger + `batch_commit` in one transaction), and reconciles with independent psql; permanent regression check: `scripts/check-real-db.sh`. If a real DB is unavailable, it reports `UNVERIFIED` and never claims success.

## 1. Why is this business process needed? What have you been asked to do?

Each night, the bank must receive upstream transactions, validate and sort them, match them against opening account balances, post them idempotently, reconcile control totals, and generate and publish a downstream customer-day report. There is **no atomic commit** across files, the DB, and downstream publishing, so "failure means no publish, reruns do not debit twice, and crashes are recoverable" are hard requirements.

You have been given an **unfamiliar version**: documentation is incomplete and components come from different chapters. The work has four parts: 12.1 reconstruct architecture and dependencies; 12.2 complete the customer classification expansion from 1 to 2 characters and run normal/abnormal/rerun days; 12.3 complete the full nightly flow; 12.4 investigate the hidden-root-cause incident and provide recovery.

## 2. Inputs, sources, formats, and guaranteed assumptions

The receive directory contains `transaction.dat` (TRANSACTION v1, 55B/record + LF), `customer.dat` (enterprise layout CAP-CUSTOMER-FEED v1 31B or v2 32B), `account_seed.dat` (ACCOUNT v1 47B), and `MANIFEST` (business date, layout version, and SHA256 for each file).

Frozen interfaces (`system/copybooks/`): CUSTOMER **v1 27B (byte 27 = record status, only A/D)** / ACCOUNT **v1 47B** / TRANSACTION **v1 55B**. Customer classification belongs to a **separate, versioned** CAP-CUSTOMER-FEED layout: v1 **31B** (classification at byte 28: A/B/C/D), v2 **32B** (classification at bytes 28–29: A1..D1); canonical CUSTOMER v1's 27 bytes remain unchanged. The enterprise layout embeds the first 27 bytes of canonical CUSTOMER v1 byte for byte.

**Naming note:** the small capstone customer feed is named `CAP-CUSTOMER-FEED`; it is **not** the canonical 1778-byte, 175-field `ENTERPRISE-CUSTOMER` large record from modules 04/07, nor the experimental layout from module 11. The three have incompatible physical lengths and fields; they must never share an `ENTERPRISE-CUSTOMER-Vx` name, as that would let version labels hide layout drift. This layout and the canonical large record are different-granularity views of the same business concept: bytes 1–27 here exactly match canonical CUSTOMER v1, and the capstone then appends its own classification and version fields. Maintenance of the actual large enterprise record (150+ field differences) is completed in module 07 L4.

LF is excluded from logical length; data is ASCII; business date is given explicitly as a parameter, never taken from the machine date.

Guaranteed assumptions: upstream delivers the whole file in one layout (mixed layouts are structural errors); duplicate `transaction_id`, short/long records, and invalid numeric values must be detected.

## 3. Build, run, and reset from a clean checkout

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
mod=curriculum/modules/12-capstone

# Optional: build the capstone COBOL separately
bash "$mod/scripts/build.sh" /tmp/capstone-bin

# Normal day (v1)
bash "$mod/scripts/run.sh" --input "$mod/fixtures/normal" \
  --output /tmp/c12-normal --db /tmp/c12-db \
  --business-date 20261010 --layout v1 --run-id n1
echo "rc=$?"            # expected 0

# Abnormal day (business rejections, still published)
bash "$mod/scripts/run.sh" --input "$mod/fixtures/abnormal" \
  --output /tmp/c12-abn --db /tmp/c12-db-abn \
  --business-date 20261010 --layout v1 --run-id a1
echo "rc=$?"            # expected 4

# Field extension day (v2 classification, includes D1 customer)
bash "$mod/scripts/run.sh" --input "$mod/fixtures/extension" \
  --output /tmp/c12-ext --db /tmp/c12-db-ext \
  --business-date 20261010 --layout v2 --run-id e1
echo "rc=$?"            # expected 0

# Rerun day: run normal's same feed against the same DB (new output directory)
bash "$mod/scripts/run.sh" --input "$mod/fixtures/rerun" \
  --output /tmp/c12-rerun --db /tmp/c12-db \
  --business-date 20261010 --layout v1 --run-id r1
echo "rc=$?"            # expected 0; apply shows new_transactions=0, balances unchanged

# Status and reset
bash "$mod/scripts/run.sh" --input "$mod/fixtures/normal" \
  --output /tmp/c12-normal --db /tmp/c12-db --business-date 20261010 \
  --layout v1 --command status
bash "$mod/scripts/reset.sh" /tmp/c12-normal
```

Derived files written: only contents under `--output`. The input directory, fixtures, and DB seed are **never overwritten**; an existing output directory is rejected with RC12.

## 4. Expected output, RCs, counts, and amounts (independent reconciliation)

`normal`: 3 accounts (opening balances 1000/50/0), all 6 transactions posted.

| Metric | normal | abnormal | extension |
|---|---:|---:|---:|
| received | 6 | 9 | 7 |
| validation accepted/rejected | 6/0 | 5/4 | 7/0 |
| match accepted/rejected | 6/0 | 4/1 | 7/0 |
| opening / credits / debits / closing | 1050/1050/250/**1850** | 1050/900/200/**1750** | 1250/1150/250/**2150** |
| expected RC | 0 | 4 | 0 |

Full values are in `expected/*.control.txt` (counts and amounts), `expected/*.closing.txt` (closing balances), and `expected/*.customerday.txt` (customer-day report). They are calculated by the **independent oracle** in `instructor/modules/12-capstone/tools/gen_course.py`; no course implementation output is copied (see `expected/README.md`).

RCs: normal/rerun/extension=0; abnormal=4; `broken` (duplicate transaction_id)=8 with **no official publish**; system failure=12 with **no official publish**.

## 5. What to modify and which interfaces must remain intact

- Learner starting point: `starter/CUSTV2.COB` (compiles; with a v2 feed it returns RC12 and does not publish). Complete it to support the 32-byte enterprise v2 and 31→32 upgrade.
- **Integrate your work with the full system:** the nightly chain compiles and runs the learner's own `starter/CUSTV2.COB` by default (complete it in place, or set `CAPSTONE_STUDENT_CUSTV2=<your source>` to use an external file). JOB002c's transaction validator likewise defaults to the learner's completed module 10 `starter/BANKVAL.COB` (or override with `CAPSTONE_STUDENT_BANKVAL`). The reference implementation `system/cobol/CUSTV2.COB` exists only in the exercise/instructor repository and **is not shipped in the student package**.
- Must not break: widths and offsets of CUSTOMER v1 27B (byte 27 = status) / ACCOUNT v1 47B / TRANSACTION v1 55B; `work/`, `publish/`, `state/` directory contracts; RC semantics; idempotency key `(business_date, transaction_id)`; `customer-day.dat` 30B layout.
- JOB003/JOB005 reuse module 07 reference implementations (no copying); the learning objective is **integration** (learners must first complete module 07's SORT/MERGE exercises for the capstone chain to sort/match).
- Change package and sequence are in `maintenance/` (impact investigation first, then modification).

## 6. Deliberate breakage and recovery (at least one reproducible failure per experiment)

| Experiment | Breakage | Symptom | Recovery |
|---|---|---|---|
| 12.1 Dependencies | Overwrite a `work/` artifact | Later node semantics are wrong | Rebuild derived files from snapshot |
| 12.2 Layout | Declared layout does not match physical width | JOB002a RC8, no publish | Correct layout/upstream file |
| 12.3 Crash | `--crash-at {before,mid,after}-db-commit / during-publish / after-publish` | Original RC 97; state preserved | Rerun with same run-id; automatic recovery |
| 12.3 Rerun | Same DB and business date, new output directory | RC0; balances/ledger unchanged | — |
| 12.4 Incident | See `incidents/incident-01/` | JOB003 RC8, no publish | Correct the business data and rerun |

## 7. Plugin workflow and terminal-only alternatives

- Plugin: use `gd`/`:CobolGotoDef` to trace dependencies between JOB scripts and COBOL; use `:CobolGotoCopybook` on `COPY "CAP-CUSTOMER-FEED-V2.CPY"` to check the interface; when saving COBOL, use diagnostics to confirm 72-column/Area A/B rules; use the Aerial outline to inspect NIGHTRPT/CUSTV2 structure.
- Terminal alternatives:

```bash
rg -n 'CUSTV2_|NIGHTRPT_|c12_step|duplicate transaction' \
  curriculum/modules/12-capstone
od -An -tc curriculum/modules/12-capstone/fixtures/extension/customer.dat | head
cut -b 11-26 curriculum/modules/12-capstone/fixtures/broken/transaction.dat \
  | sort | uniq -d
```

## 8. Evidence to submit and what counts as failure

Following [evidence/README.md](evidence/README.md), submit original commands and RCs for the four day types, five crash boundaries, and incident investigation. **Failure** includes: any failed JOB producing an official publish; duplicate debit on same-day rerun; inconsistent DB/ledger/files/state after crash recovery; presenting an old `publish/<run_id>` as the current run; treating a system failure as a business rejection; or claiming the real DB was verified.

## Acceptance self-check

```bash
bash curriculum/modules/12-capstone/scripts/check.sh
```

(The instructor grader exists only in the instructor repository and is not shipped in the student package: `instructor/modules/12-capstone/grading/grade.py`.)

`check.sh` covers the four day types, layout guard, idempotent rerun, five crash recovery paths, locks/no-clobber, system failures, control gate, starter, and RED→GREEN.

## System composition

See the [system composition inventory](COMPOSITION.md) for runtime components and dependencies. It classifies runtime dependencies, maintenance investigation dependencies, teaching references, starter code, and generated files according to actual call relationships.
