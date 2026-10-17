# Module 11: Incident Investigation and Maintenance (11.1–11.5)

Recommended: 9 hours. Prerequisites: Module 06 (file contracts), 07 (SORT/sequential matching), and 10 (JOB operations).
This module takes you from “it runs” to “you can investigate, fix, and prove”: you receive a **frozen snapshot of a bank night system** (`system/`) and must follow an incident investigation process to identify root causes, make minimal fixes, rerun recovery, and complete a maintenance change to the **enterprise customer classification** field (investigate before changing; use a separate, versioned enterprise customer layout; never alter record status at byte 27 of the 27-byte CUSTOMER v1 record).

> Platform: verified only on **Linux x86-64** (GnuCOBOL 3.2, Bash 5, GNU coreutils, Python 3.13). macOS/WSL/other architectures are **unverified**.
>
> **DB layer note**: This module is **not** connected to a real PostgreSQL database. JOB004/JOB006 use the offline file checkpoint in `system/lib/db.py` to simulate database transaction semantics and unique-key contracts. All DB-related evidence must be marked “**DB not verified**”; do not use it to claim that a real database pipeline works.

## 1. Why the business needs this / what request you receive

When a bank nightly batch fails, on-call staff must **preserve the scene first, then locate the cause**: build a timeline from scheduler status, JOB Logs, RCs, and input manifests; distinguish “not published” from “incorrect results published”; identify root cause; make a minimal fix and prove the recovered data is consistent. This module provides seven **reproducible incident scenes** (11.1–11.4), plus a maintenance investigation for a field expansion (11.5).

## 2. Inputs, sources, formats, and guaranteed assumptions

The system under investigation is `system/` (a frozen snapshot from Module 10's nightly flow, containing a real COBOL validator/matcher and an offline DB checkpoint). Fixed interfaces (canonical definitions in `curriculum/bank/copybooks/` and `system/copybooks/`):

- **CUSTOMER v1: 27 bytes** — id(8)/name(10)/balance_demo(8)/**status**(1, A active/D inactive).
- **ACCOUNT v1: 47 bytes** — id(10)/customer(8)/currency(3)/sign(1)/balance(13)/status(1)/date(8)/version(3).
- **TRANSACTION v1: 55 bytes** — account(10)/txid(16)/date(8)/sequence(6)/direction(1)/amount(13)/status(1).

> **Record status ≠ customer classification**: byte 27 of CUSTOMER v1 is **record status** (A/D). The “customer classification” to be widened in the 11.5 maintenance lesson is **not** that byte; it belongs to the separate, versioned enterprise customer layout `maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY`. This exercise layout deliberately uses a separate name (distinct from Module 07 L4's canonical large record `ENTERPRISE-CUSTOMER-V1`, 1778 bytes/175 fields) to avoid version drift between layouts with the same name. Both share the `CUSTOMER-CLASSIFICATION` semantics. See the canonical description in `curriculum/bank/README.md` and `../../../docs/curriculum/BANK-SYSTEM.md` §2.

Guaranteed: synthetic ASCII data, LF line endings (LF does not count toward logical length), business date is not assumed to be the machine date, and one LF follows each logical record. Short/long records, invalid numerics, duplicate transaction IDs, out-of-order data, 0-byte files, resource failures, and mismatched control totals are all anomalies that **must be detected**.

## 3. Build, run, and reset from a clean checkout

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"

# Normal nightly flow (RC0, no rejects)
bash curriculum/modules/11-incidents/scripts/run.sh \
  --input  curriculum/modules/11-incidents/fixtures/normal \
  --output /tmp/m11-night --db /tmp/m11-db \
  --business-date 20261009 --run-id demo
echo "rc=$?"     # expected 0

# Preserve a failed scene for investigation
bash curriculum/modules/11-incidents/scripts/run.sh \
  --input  curriculum/modules/11-incidents/fixtures/INC-2026-004 \
  --output /tmp/m11-incident --db /tmp/m11-db2 \
  --business-date 20261009 --run-id demo --keep-scene
echo "rc=$?"     # expected 8

# Status and reset
bash curriculum/modules/11-incidents/scripts/run.sh \
  --input curriculum/modules/11-incidents/fixtures/normal \
  --output /tmp/m11-night --db /tmp/m11-db --business-date 20261009 \
  --command status
bash curriculum/modules/11-incidents/scripts/reset.sh /tmp/m11-night
```

Derived files covered: only content inside the `--output` directory. **Input fixtures, `system/` source, shared `fixtures/`, and existing output are never overwritten**; repeated/non-course output directories are rejected with RC12.

## 4. Expected output, RC, counts, and amounts (independently calculated)

The `.author tool` is `instructor/modules/11-incidents/tools/gen_course.py`; it **reimplements** the frozen contract's business rules to generate `expected/` and does not read any course program output.

`normal` fixture: 3 accounts (opening balances 1000 / 50 / 0), 4 transactions.

| Metric | Value | Source |
|---|---:|---|
| Received | 4 | Fixture rows |
| Validation accepted / rejected | 4 / 0 | Business rules |
| Match accepted / rejected | 4 / 0 | `closing = opening + C − D` |
| Ledger postings | 4 | Idempotency key |
| Opening/credits/debits/closing totals | 1050 / 625 / 200 / **1475** | Conservation equation |
| Closing balances | acc1 1300, acc2 150, acc3 25 | `closing = opening + C − D` |

Full values: `expected/normal.control.txt` and `expected/normal.closing.txt`; expected incident behavior: `expected/incidents.txt`; customer **status** extract: `expected/customer-v1.txt`; enterprise customer **classification** v1/v2 extracts: `expected/enterprise-class-v1.txt` / `enterprise-class-v2.txt`.

RC convention: `0` normal; `4` contract-allowed Warning (per-transaction business rejects); `8` business/contract exception; `12` system failure. **A failed step never publishes** (`publish/<run_id>` is not created).

## 5. What to modify and which interfaces must remain intact

- Seven incidents use neutral event IDs (`INC-2026-001`…`INC-2026-007`), each in its own `INC-2026-00X/`: investigate first using `INC-2026-00X/student/README.md`. Root causes, minimal fixes, and the event ID ↔ instructor number mapping are in the instructor package `instructor/modules/11-incidents/INSTRUCTOR.md` (teacher only / reveal hints as needed).
- Maintenance changes are under `maintenance/`: first submit five deliverables, including an impact investigation report, then implement after review (for the separate, versioned enterprise customer layout; reference implementation and evidence are in `instructor/modules/11-incidents/maintenance/`, starting skeleton `starter/M11CUST2.COB`).
- **Must not break**: the three frozen record widths and offsets (byte 27 of CUSTOMER v1 remains record status A/D); the `work/` and `publish/` directory contracts; keys in `control.txt`; RC 0/4/8/12 semantics; idempotent ledger key `(business_date, transaction_id)`; downstream row format `STATUS|<id>|<status>`.

## 6. Seven reproducible failures (neutral event IDs; symptoms only, root causes in instructor package)

Event IDs and directory names are neutral identifiers and **do not disclose root causes**; each package provides only symptoms, timeline, logs, and existing system source for students to investigate. Root causes, tiered hints, and mapping to instructor numbers are in `instructor/modules/11-incidents/INSTRUCTOR.md`.

| Event | Directory | Symptom (symptoms only; no root cause) | Original RC |
|---|---|---|---:|
| Event 001 | `INC-2026-001/` | Validation node aborted; no publication for the day | 8 |
| Event 002 | `INC-2026-002/` | Batch succeeded but published a balance inconsistent with the business ledger | 0 (defect) |
| Event 003 | `INC-2026-003/` | Receive node aborted; no publication | 12 |
| Event 004 | `INC-2026-004/` | Match node aborted; candidate not generated | 8 |
| Event 005 | `INC-2026-005/` | Sort node aborted; no publication | 12 |
| Event 006 | `INC-2026-006/` | Batch succeeded but control totals do not match the upstream declaration | 0 (defect) |
| Event 007 | `INC-2026-007/` | Validation node aborted; no publication for the day | 8 |

Each package can be reproduced from its own `student/` directory alone (`student/run.sh`) and includes scheduler status, JOB Logs, Shell/source, Copybooks, original input, parameters/Manifest, and DB seed or SQL Log. Incident investigation deliverable order: **symptoms and impact → timeline → hypotheses and evidence → minimal reproduction → root cause → fix/rollback → recovery and rerun → prevention**.

## 7. Plugin operations and terminal-only alternatives

- Plugin: use `gd`/`:CobolGotoDef` to jump to paragraphs, `K`/`:CobolPreview` to preview Copybooks, Aerial outline to browse `system/`; when saving COBOL, use diagnostics to check the 72-column limit and Area A/B.
- Terminal-only alternatives (the exercise can be completed without the plugin):
  ```bash
  rg -n 'WS-STRUCT|out of order|ledger_index|declared' \
     curriculum/modules/11-incidents/system
  od -An -tc curriculum/modules/11-incidents/fixtures/normal/transaction.dat
  sort -c -k1.1,1.10 curriculum/modules/11-incidents/fixtures/INC-2026-004/account_seed.dat
  ```

## 8. Evidence to submit and failure criteria

Submit according to [evidence/README.md](evidence/README.md): reproduction command, original RC, timeline, root cause, minimal fix, recovery/rerun for each event; the five maintenance deliverables and regression evidence.

Failure includes: treating RC0 as proof of business correctness; “fixing” an incident by tampering with original input or weakening assertions; producing a formal publication after a failure; classifying a system failure as a business rejection; claiming a real DB has been verified; modifying PIC before investigation; overwriting or rewriting an original V1 file.

Acceptance self-check:

```bash
bash curriculum/modules/11-incidents/scripts/check.sh
```

(The instructor maintenance reference check exists only in the instructor repository and is not distributed with the student package: `instructor/modules/11-incidents/maintenance/check.sh`.)

Instructor root causes, reference implementation, and RED→GREEN record: `instructor/modules/11-incidents/INSTRUCTOR.md`.
