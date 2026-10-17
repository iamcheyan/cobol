# Module 04: Complex Data Structures (04.1–04.3)

Estimated time: 5 hours. Prerequisites: Module 02 (01/05/77/88, groups) and Module 03 (byte layouts).
This module covers structures and layouts only; it does not change any frozen contract: CUSTOMER v1=27B, ACCOUNT v1=47B, and TRANSACTION v1=55B remain unchanged. Lesson 04.3 reuses the 175-field enterprise customer record from Module 07.

## 1. Why the business needs this (requirements)

When taking over an unfamiliar batch system, records often contain **alias views** (two ways to interpret the same bytes), **repeating segments** (address lines, phone numbers), and **variable-length segments** (length determined by a count). More troublesome, when a customer classification field grows from 1 to 2 characters, the offsets of **all following fields move**. This module teaches you to understand these structures, produce a traceable field catalog, and answer “which following fields move when one field changes?”

## 2. Inputs, formats, and assumptions

- Lessons 04.1/04.2 read no input: the programs declare structures and print `LENGTH OF` / offset evidence.
- Lesson 04.3 reads a **raw binary** record stream. Each `ENTERPRISE-CUSTOMER-V1` record is 1,778 bytes, with no separators. The canonical Copybook is at `instructor/modules/07/05-large-record/ENTERPRISE-CUSTOMER-V1.CPY` (**reused read-only**).
- [FIELD-CATALOG.csv](FIELD-CATALOG.csv) is a copy of Module 07’s canonical catalog, with 175 named leaf fields. Offsets start at 1; group items take no bytes; no filler is used to make up the count.
- Fixtures are generated deterministically (normal/boundary/invalid) by [scripts/generate-fixtures.py](scripts/generate-fixtures.py); SHA256 values are in [fixtures/SHA256SUMS](fixtures/SHA256SUMS).
- Assumptions: GnuCOBOL 3.2, Linux x86-64, default dialect.

## 3. Build / run / reset (from any starting directory)

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
bash curriculum/modules/04-structures/scripts/run.sh 04.1 /tmp/m04-shape
bash curriculum/modules/04-structures/scripts/run.sh 04.2 /tmp/m04-copy
bash curriculum/modules/04-structures/scripts/run.sh 04.3 /tmp/m04-ent \
     curriculum/modules/04-structures/fixtures/normal/enterprise-2.dat
cat /tmp/m04-ent/report.txt
```

- Lesson 04.3 input size must be an integer multiple of 1,778 bytes; otherwise the runner returns RC8 before publishing anything.
- The output directory must not already exist (no-clobber). Results are published atomically only after all private-stage checks pass. Failures and existing destination directories are rejected (RC12).
- Reset with `bash curriculum/modules/04-structures/scripts/reset.sh /tmp/m04-ent`. The output directory is removed only if its file set is complete and `manifest.sha256` verifies.

Derived files: `report.txt`, `stderr.txt`, `compiler.txt`, `source.sha256`, and `manifest.sha256`; lesson 04.3 also includes the input snapshot `input.dat` and `inputs.sha256`.

## 4. Expected output, RCs, and independent verification

- **04.1 RC0**: `REDEFINES` alias views do not count storage twice (parent group=18 bytes); `66 RENAMES` length is 7; `OCCURS ... INDEXED BY` retrieves values by index; `OCCURS DEPENDING ON` has a `LENGTH OF` that varies with the count (count=3→17, count=7→37). See [expected/04.1-structures.txt](expected/04.1-structures.txt).
- **04.2 RC0**: V1=1,778; V2 (`CUSTOMER-CLASSIFICATION` widened from `X(1)` to `X(2)`) =1,779, a shift of +1. See [expected/04.2-copy-shift.txt](expected/04.2-copy-shift.txt).
- **04.3**: normal/boundary cases return RC0 and print located fields per record; structural errors (length, version, ABI, nonnumeric key) return RC8 and publish nothing. See [expected/04.3-normal.txt](expected/04.3-normal.txt), etc.
- **Independent verification**: `scripts/check.py` generates two probe programs. They measure the offsets of all 175 leaf fields with GnuCOBOL `ADDRESS OF` and compare them with the catalog; they also measure V1/V2 `LENGTH OF` and key-field addresses, proving that widening a field shifts later offsets by +1. Program output is not treated as the answer.
- **Semantic verification before publication**: before publishing, `scripts/run.sh` invokes `scripts/verify.py`. For 04.1/04.2 it independently derives expected reports from structure semantics; for 04.3 it derives each record’s ID/STATUS/SURNAME/CLASS/RISK/SYNC and record count from input bytes using `FIELD-CATALOG.csv` offsets and PICs. Changing only `WS-EXERCISES-DONE` to `'Y'`, a placeholder report, skipped records, or incorrect field values will fail and will not be published. The regression checks are included in `check.py`.

## 5. What to modify and what must remain intact

Complete the TODOs in `starter/M04SHAPE.COB`, `starter/M04COPY.COB`, and `starter/M04ENTERPRISE.COB`, then set each `WS-EXERCISES-DONE` to `'Y'`. Do not break:

- The canonical Module 07 Copybook (reuse read-only; do not create a divergent copy).
- The 175-field catalog and offsets (a field-width change requires a V2 impact investigation; see §6).
- The frozen CUSTOMER/ACCOUNT/TRANSACTION contracts and the 80-column fixed-format rules.

## 6. Deliberate breakage and recovery (reproducible faults)

1. **ODO is not the final group item**: `faults/odo-not-last.COB` is rejected by the compiler (real `cobc` error).
2. **REDEFINES is not adjacent to the redefined item**: `faults/redefines-not-adjacent.COB` is rejected by the compiler.
3. **Cascading offsets after widening a field**: change `CUSTOMER-CLASSIFICATION` from `X(1)` to `X(2)`. Its own offset is unchanged (460), but every field after it moves by +1, and total length changes from 1,778 to 1,779. Never modify V1 files in place; design V2 (layout version 002), reject/convert old files, compare both versions in parallel, and plan a rollback.
4. **Structural errors**: length, version, ABI, and nonnumeric-key errors in `invalid/` all return RC8 and publish nothing.

**Recovery**: fix the structure or implementation and rerun. The runner never overwrites an existing output directory, and V1 fixtures remain unchanged.

## 7. Plugin workflow and terminal-only alternatives

- Plugin: use `gd` to jump to a field definition, `K` to preview a COPY, Aerial to inspect the hierarchy, and `:CobolCalcRecord` to estimate record size. Plugin estimates are not authoritative for final layout.
- Terminal only: `rg -n 'REDEFINES|OCCURS|DEPENDING|COPY REPLACING'`; use `awk -F,` to slice by offsets in `FIELD-CATALOG.csv`; inspect raw records with `od -An -tc`/`xxd`. Either workflow is sufficient.

## 8. Required evidence and failure criteria

Submit: source files and SHA256, compiler version, each lesson’s command and raw RC, comparison of the 175-field catalog with measured `ADDRESS OF` offsets, the offset-shift list after widening V1→V2, evidence of RC8/no publication for structural errors, and `check.sh` output. See [evidence/README.md](evidence/README.md) for the template.

**Failure criteria**: using FILLER to reach the field count; double-counting REDEFINES/OCCURS; treating variable ODO as fixed length; changing a PIC without impact analysis; providing plugin screenshots instead of measured offsets; or submitting only `WS-EXERCISES-DONE='Y'` with placeholder/incorrect reports (the independent semantic check in `run.sh` rejects and does not publish them). Any of these is a failure.
