# Module 04 Design: Complex Structures and Layout Offsets

This design reuses the canonical Module 07 Copybook read-only. It does not modify existing files such as 07/tasks/docs/Makefile, nor change CUSTOMER v1=27B, ACCOUNT v1=47B, or TRANSACTION v1=55B.

## Structure semantics (04.1)

- **REDEFINES**: alias views and the item they redefine share the same storage; they **do not count storage twice**. The design uses `01 WRAP` / `05 PAYLOAD` (8+7+3=18B) / `05 PAYLOAD-RAW REDEFINES PAYLOAD PIC X(18)`, so `LENGTH OF WRAP = 18` (not 36). See the measured 04.1 report.
- **66 RENAMES**: gives a new group name to a contiguous set of fields. Its length is the sum of the renamed fields (example: 3+4=7).
- **OCCURS ... INDEXED BY**: fixed-length repeated items with an index; use `SET idx TO n` to read by ordinal position instead of hard-coding subscript arithmetic.
- **OCCURS DEPENDING ON (ODO)**: the number of repeated items is determined by a count field, and **must be the final item in its group**. In this configuration, `LENGTH OF` the group item returns its **runtime length**: count=3 → 2+3×5=17; count=7 → 2+7×5=37. This measured result is a key finding of the module and differs from the assumption of a compile-time fixed length.

## COPY and layout versioning (04.2)

- Load V1 with `COPY 'ENTERPRISE-CUSTOMER-V1.CPY'`, then derive V2 by widening only this field with `COPY ... REPLACING ==CUSTOMER-CLASSIFICATION PIC X(1)== BY ==... PIC X(2)==`. The two 01 groups share names, so qualify every reference with `OF ENT-V1` / `OF ENT-V2`.
- Result: the offset of `CUSTOMER-CLASSIFICATION` itself remains unchanged (1-based offset 460), while **every later field moves by +1**; total length changes from 1,778 to 1,779. This is a minimal reproducible experiment showing which later offsets move when one field changes.
- Reference modification: use `WS-ID(1:4)` and `WS-ID(5:6)` to select substrings from fixed-length fields.
- Layout-version policy: V1 is frozen. A width change requires a new version (`LAYOUT-VERSION=002`), rejection or conversion of old files, parallel comparison, cutover, and rollback. Never rewrite existing files in place.

## 175-field record and field location (04.3)

- Record unit: 1,778 bytes, fields tightly packed in Copybook order, with no alignment padding, separators, or LF.
- Outer boundary: file size must be an integer multiple of 1,778, or RC8/no publication. GnuCOBOL fixed-length reads may silently pad with spaces and return 00, so FILE STATUS alone is insufficient. The program also validates `LAYOUT-VERSION=001`, `BINARY-ABI-CODE=GCOB32BE`, and a 10-digit `CUSTOMER-ID`.
- Catalog: `FIELD-CATALOG.csv` (175 leaves, each with offset/length/unit/comparison rule) is a canonical copy from Module 07. **Measured verification** uses `scripts/check.py` and `ADDRESS OF` for every field; total `LENGTH OF` does not substitute for per-leaf evidence.
- Field-location exercise: 04.3 prints `CUSTOMER-ID`/`RECORD-STATUS`/`LEGAL-SURNAME`/`CUSTOMER-CLASSIFICATION`/`RISK-SCORE`/`SYNC-STATE`. Learners first calculate slices from the catalog, then compare.

## Output contract

- 04.1: `LESSON,04.1` + `REDEFINES,<key>,<val>` / `RENAMES,...` / `OCCURS,...` / `ODO,...`.
- 04.2: `LESSON,04.2` + `LEN,V1/V2,<n>` / `SHIFT,V2-V1,<n>` / `CLASSIFICATION,...` / `REFMOD,...`.
- 04.3: `LESSON,04.3` + `LAYOUT,...` + per-record `REC,<n>,ID,<id>` and `  STATUS/`SURNAME/`CLASS/RISK/`SYNC` lines + `RECORDS,<n>`.

Line order is fixed; the checker compares output byte for byte.

## RC and publication

| Situation | RC | Published |
|---|---:|---|
| 04.1 / 04.2 normal | 0 | Yes |
| 04.3 normal/boundary (including empty file, single record) | 0 | Yes |
| 04.3 length mismatch/version/ABI/nonnumeric key | 8 | No |
| Build/lock/output/verification failure | 12 | No |

## Measurement basis and environment

- Compiler: GnuCOBOL 3.2.0, Linux x86-64, default dialect.
- Per-field `ADDRESS OF`: all 175 leaf offsets match the catalog; total record length is 1,778.
- V1/V2 probe: `S2-S1` (`SYNC-STATE` offset delta) = 1; `LENGTH OF` delta = 1; `CUSTOMER-CLASSIFICATION` has the same offset in both versions = 460.
- Runtime `Warning: program compiled against libxml ...` is environmental noise and is recorded in `stderr.txt`.

## Limitations

- Measured only on Linux x86-64 / GnuCOBOL 3.2; other compilers/byte orders require a separate ABI version.
- 04.3 checks structure, length/version/key only; it does not compare all Module 07 business domains (that is in scope for 07.6).
- ODO `LENGTH OF` behavior was measured on this compiler; retest on another compiler rather than assuming it is the same.
