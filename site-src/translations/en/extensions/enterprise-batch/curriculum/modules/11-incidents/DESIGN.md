# Module 11 Design: Incident Investigation Framework, Frozen Snapshot, and Maintenance Change

Corresponds to outline 11.1–11.5. This document defines the system under investigation, incident package structure, evidence model, and maintenance change design. Student tasks and acceptance criteria: [README](README.md); instructor root causes: `instructor/modules/11-incidents/`.

## 1. System under investigation: frozen snapshot `system/`

Module 11 includes a **self-contained runnable** snapshot of the bank nightly system, based on the Module 10 JOB001–JOB009 design (canonical source remains the reference implementation in Modules 07/10). The snapshot represents receiving an “unfamiliar system”: incident packages reproduce against it and **do not modify files in Modules 01–10**.

```mermaid
flowchart LR
  J1[JOB001 receive] --> J2[JOB002 validate<br/>M11VAL.COB]
  J2 --> J3[JOB003 sort<br/>system sort + verify]
  J3 --> J4[JOB004 db-snapshot<br/>db.py]
  J4 --> J5[JOB005 match<br/>M11MATCH.COB]
  J5 --> J6[JOB006 db-apply<br/>db.py idempotent]
  J6 --> J7[JOB007 control+cust<br/>control.py + M11CUST.COB]
  J7 --> J8[JOB008 publish<br/>atomic + manifest]
  J8 --> J9[JOB009 complete]
```

| JOB | Input (read-only) | Output/checkpoint | Allowed prerequisite RC | After failure |
|---|---|---|---|---|
| 001 | Receive directory + MANIFEST | `snapshot/` (immutable) + checksums | — | RC8/12 does not proceed to validation |
| 002 | Snapshot + layout contract | `work/validate/` | RC0/4 only | Structural error RC8, business rejection RC4 |
| 003 | Accepted transactions | `work/sorted_tx.dat` + ordering evidence | RC0 only | Temporary space/permission RC12 |
| 004 | Business date + DB store | `work/db/` snapshot | RC0 only | Failure RC12; do not use stale data |
| 005 | Snapshot accounts + ordered transactions | `work/closing/` (candidate, isolated) | RC0/4 | Out-of-order/overflow RC8; candidate not published |
| 006 | Candidate + idempotency key | Ledger + commit | RC0/4 | Check ledger first, then decide recovery |
| 007 | Detail/reject/ledger + customer snapshot | `work/control/`, `work/customer/` | RC0 only | Failure RC8; cannot publish |
| 008 | Reconciled candidate | `publish/<run_id>/` + CURRENT | RC0 only | If committed, recover publication only |
| 009 | Completion evidence | `state/complete.marker` | RC0 only | Status can be queried; do not overwrite original run |

RC semantics are the same as Module 10: `0/4/8/12`; uncontracted subprocess codes map to RC12 at the Shell boundary.

## 2. Incident package structure (11.1–11.4)

Each `INC-2026-00X/`:

```text
INC-2026-00X/student/
  README.md            Symptoms and impact → timeline (no root cause)
  hints.md             Progressive hint ladder
  run.sh               Reproduce using this package alone (--keep-scene preserves scene)
  input/               Copy of original input (may contain bad data; unchanged)
  scene/
    scheduler-status.txt  Scheduler JOB status and RC
    run.env               Parameters (business date/run_id/paths)
    MANIFEST              Input manifest (when upstream control totals are declared)
    console.txt           What the scheduler saw on its console
    logs/                 JOB Logs and nightly.log
    source/               Shell, COBOL, Python source copies
    copybooks/            Frozen v1 interface copies
    db-schema.sql / sql-log.txt / ledger-victim.dat  (for DB contract incidents)
    published-*.txt/.dat  Published artifacts (RC0 defect cases)
```

Instructor side: `instructor/modules/11-incidents/inc-XX/` holds root cause, trigger, progressive hints, misleading clues, evidence, minimal fix, recovery/rerun, prevention, and scoring points; code defect cases also include `fix/` and a RED→GREEN harness. The event ID ↔ instructor number mapping appears only in the instructor package's `INSTRUCTOR.md`.

## 3. Seven event classes and expected behavior (triggers/root causes are in instructor package)

Event IDs are neutral and do not reveal root causes; triggers and root causes are only in the instructor package. The table below gives only the `as_found_rc`/`desired_rc`/`publish_before`/`publish_after` contract, recorded in `expected/incidents.txt`.

| Event | As-found RC | Expected RC | As-found publication |
|---|---:|---:|---|
| INC-2026-001 | 8 | 8 | No |
| INC-2026-002 | 0 (defect) | 8 | **Yes (defect)** |
| INC-2026-003 | 12 | 12 | No |
| INC-2026-004 | 8 | 8 | No |
| INC-2026-005 | 12 | 12 | No |
| INC-2026-006 | 0 (defect) | 8 | **Yes (defect)** |
| INC-2026-007 | 8 | 8 | No |

Fixes for code defect incidents demonstrate RED→GREEN using `instructor/.../tools/red-green.sh`.

## 4. Evidence and scene preservation

- Inputs are immutable: incident package `input/` is an original copy; `run.sh --keep-scene` preserves failed `work/` scene; shared `fixtures/` has `SHA256SUMS`, and `check.py` compares before and after runs, so **runs must not modify fixtures**.
- Fixes must not tamper with bad data or weaken assertions: code defect fixes **add validation** so bad input is blocked with RC8, rather than “making the assertion pass.”
- Recovery principle: verify facts with the idempotent ledger / commit / Manifest / checksums; never infer transaction state from the last line of a Shell log.

## 5. Maintenance change (11.5) design

Requirement: widen `CUSTOMER-CLASSIFICATION` in the **separate, versioned enterprise customer layout** `ENTERPRISE-CLASS` from `PIC X(1)` to `PIC X(2)`, layout `001`→`002`, values such as `A`→`A1`; old files must not be rewritten in place. **Do not** attach this classification to byte 27 of the 27-byte CUSTOMER v1 record (that byte is record status A/D); CUSTOMER v1 remains unchanged. Deliver five investigation documents first, then implement after review.

> **Names and relationship**: the canonical large record in the course is Module 07 L4's `ENTERPRISE-CUSTOMER-V1` (175 fields / 1778 bytes). This module's 23-byte exercise layout deliberately uses the separate name `ENTERPRISE-CLASS-V1` to avoid a same-name/different-layout version drift; both share the semantics of the classification field (`CUSTOMER-CLASSIFICATION` `X(1)`→`X(2)`). This module is a compact exercise projection of that semantic.

Baseline: `maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY` (layout 001, 23B); target: `ENTERPRISE-CLASS-V2` (layout 002, 24B). Detailed design is in `instructor/modules/11-incidents/maintenance/`: `INFLUENCE-INVESTIGATION.md` (impact investigation), `CHANGE-LIST.md`, `CHANGE-PLAN.md`, `TEST-CASES.md`, `EVIDENCE-PLAN.md`; reference implementation `M11CUST2.COB` + `migrate-customer.py` + `check.sh`.

Key byte compatibility: the classification field is at the **end** of the record; V1→V2 adds only one byte, so preceding field offsets do not change. However, the total record length change affects all fixed-length reads, checksums, and downstream slicing.

## 6. Reuse and boundaries

- The snapshot's offline DB/control/publication helpers (`db.py`/`control.py`/`manifest.py`/`verify_publish.py`/`common.sh`) are **copies** from Module 10, included for the incident scene; canonical sources remain in Module 10, and the two do not reference each other, avoiding drift.
- Incident materials are **copies** and do not modify any files in Modules 01–10.
- JCL/JP1 is a reading-only mapping (provided by Module 10); this module makes no claims of mainframe execution.
- Platform: Linux x86-64 only; real DB is **not connected/verified**; label all DB evidence “DB not verified.”

## 7. System components

The small incident fixtures can be manually recalculated. The snapshot system consists of COBOL, Shell, and Python components; the course focuses on reading an unfamiliar system and investigating problems.
