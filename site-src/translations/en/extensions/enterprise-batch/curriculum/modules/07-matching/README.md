# Module 07: Enterprise Batch core algorithms (12 hours)

Module 07 is the processing core of the enterprise overnight bank batch and the benchmark for course difficulty and acceptance criteria. It connects Module 06 file contracts, Module 10 JOB orchestration, and Module 11 incident investigation through a shared reconciliation/sorting model: SORT and MERGE produce **provably ordered** inputs; L1 classifies 1:1 matches; L2 handles 1:N key breaks, balances, and reversals; L3 aggregates customer-day data across multiple streams/N:N; L4 compares 150+ fields one by one. **Core sorting, matching, balance processing, and field-by-field comparison must use COBOL sequential reads and bounded state**. Python is only for data generation, an independent oracle, and JOB gates; do not replace the taught algorithms with SQL JOINs or full-file arrays.

## Lessons and lab units

| Lesson | Lab unit | Topic |
|---|---|---|
| 07.1 | [labs/02-sort-merge/01-sort](labs/02-sort-merge/01-sort/README.md) | SD SORT, INPUT/OUTPUT PROCEDURE, real work files, and temporary-space failures |
| 07.2 | [labs/02-sort-merge/02-merge](labs/02-sort-merge/02-merge/README.md) | MERGE of at least two sorted streams, sort keys, and same-key ordering |
| 07.3 | [labs/01-one-to-one](labs/01-one-to-one/README.md) | Boss L1: 1:1, three output categories, dual-EOF combinations |
| 07.4 | [labs/03-one-to-many](labs/03-one-to-many/README.md) | Boss L2: 1:N key break, balance conservation, rejection, reversal with original-transaction reference |
| 07.5 | [labs/04-many-to-many](labs/04-many-to-many/README.md) | Boss L3: Master/transaction/snapshot/previous-day four streams, business N:N customer-day aggregation |
| 07.6 | [labs/05-large-record](labs/05-large-record/README.md) | Boss L4: 175 named fields, field catalog, field-by-field RAW/TEXT-NORM/NUMERIC/IGNORE comparison |

Related practice route (one bank model, frozen interfaces throughout):

```text
Module 06 validated output ──unsorted transactions──▶ 07.1 SORT ──sorted──▶ 07.2 MERGE (multiway)
             │                                                               │
             ▼                                                               ▼
ACCOUNT/TRANSACTION v1 ──▶ 07.3 L1 classification ──▶ 07.4 L2 balance/reversal ──accepted──▶ 07.5 L3 customer-day aggregate
                                                                                                           │
                                      Enterprise customer binary snapshot (1778B/175 fields) ─────────────▶ 07.6 L4 field-level diff
```

- `common/` for 07.1/07.2 freezes the bridge from normal SORT/MERGE streams into L2, including zero-amount bridge RC4 and byte-level expected outputs.
- The official 07.5 runner feeds raw ACCOUNT/TRANSACTION/REVERSAL-LINK through real L2, then aggregates customers from accepted records. It does not fabricate accepted transactions or apply them twice.
- 07.6 uses an independent enterprise-customer binary snapshot, decoupled from file matching and focused on field-level comparison.

## Frozen contracts (do not silently change)

- CUSTOMER v1 = 27 bytes; ACCOUNT v1 = 47 bytes; TRANSACTION v1 = 55 bytes (see [bank/copybooks](../../bank/copybooks/) and [BANK-SYSTEM.md](../../../docs/curriculum/BANK-SYSTEM.md)).
- Full transaction sort key = `(account_id, sequence_no, transaction_id)`; preserve all 55 raw bytes and terminate output with LF.
- RC policy: 0 normal; 4 business rejection/difference with checked results published; 8 fatal data error with no publication; 12 system error with no publication.
- Reversals use a separately versioned REVERSAL-LINK interface; do not reinterpret the 55-byte transaction fields.
- Enterprise customer records with 150+ fields are 1,778-byte fixed binary; see [labs/05-large-record/FIELD-CATALOG.csv](labs/05-large-record/FIELD-CATALOG.csv).

## Run from a clean checkout

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
bash curriculum/modules/07-matching/check.sh        # quick acceptance entry point for all Module 07 labs
bash curriculum/check.sh                            # repository-level entry point, including Module 07 and all baselines
python3 curriculum/modules/07-matching/labs/05-large-record/scripts/pressure.py   # L4 full large-record pipeline pressure
```

Every lab supports arbitrary starting directories and paths containing spaces. The runner isolates a candidate, verifies it independently, and publishes without clobbering; on failure it does not leave official output or remove another process's lock. Student starters are separate from instructor references, available at [instructor/modules/07](../../../instructor/modules/07/).

## Student package

`bash curriculum/scripts/package-student.sh <target-directory>` creates a repeatable, content-stable student practice package that excludes `instructor/`, instructor root causes, and answer snapshots. Run/check commands work directly from the package. To view answers, use `instructor/` in the full teaching repository.

## Acceptance criteria

- SORT/MERGE use real SD/RELEASE/RETURN and MERGE USING; descending input, duplicate global IDs, and byte-level field errors are rejected.
- L1 covers dual EOF and conservation of the three output counts; L2 covers same-key accumulation, ordering, duplicate transactions, overflow, reversal, and two-level amount conservation; L3 covers four-stream cardinality, status consumption, snapshot date/version and customer-level split conservation; L4 covers the 175-field catalog and an independent difference inventory with no misses or false positives.
- Memory and disk use are bounded: sequential algorithm workspace does not grow linearly with total file size or same-key group size; real SORT spill and resource failure have separate evidence.
- Each lab has normal/boundary/invalid fixtures, independent expected results, starter, reference implementation, fault exercises, and a student evidence template.
- Plugin routes (outline, paragraph navigation, Copybook preview, PIC estimation) are paired with terminal alternatives.

The primary agent's independent acceptance record is in [tasks/enterprise-cobol-review.md](../../../tasks/enterprise-cobol-review.md).
