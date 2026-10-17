# 07.6 Boss L4: field-by-field comparison of enterprise customer records

This lesson investigates which named business fields changed between two batches of enterprise customer snapshots. V1 is a separate 1,778-byte fixed binary interface; it does not change CUSTOMER 27-byte, ACCOUNT v1 47-byte, or TRANSACTION v1 55-byte. Recommended: 4 hours. Complete 07.5 first and be familiar with PIC, COMP, COMP-3, sequential files, and RCs.

## Lab steps

```bash
cd curriculum/modules/07-matching/labs/05-large-record
scripts/build.sh /tmp/batchl4
scripts/run.sh fixtures/old.dat fixtures/new.dat /tmp/b04-result
cat /tmp/b04-result/report.txt
(cd /tmp/b04-result && sha256sum -c manifest.sha256)
```

The two files are fixed-record streams without separators; file byte length must be a multiple of 1778. `fixtures/old.dat` contains customers 1 and 3; the new batch contains customers 1, 2, and 3. Customer 2 is NEW-ONLY; customer 1's revision number and classification change; the report provides field IDs. Each FIELD/AUDIT difference row includes run ID, input version, old/new record sequence, masked customer key, field_id, and canonical COBOL field name. Thus different changes to the same field for multiple customers remain attributable to the correct record. Return code 4 means valid business differences, RC0 means no differences, RC8 means input-structure error, and RC12 means build, lock, file, or publication failure. The target must not exist; runs never overwrite it.

## Calculate first, then change the program

Open `FIELD-CATALOG.csv` and manually slice `CUSTOMER_CLASSIFICATION` and `LEGAL_SURNAME` using 1-based offsets. Record old/new customer 1 record numbers and changed fields in `evidence/student-template.md`. Then create a record changing only the trailing `SYNC_STATE` field; it is `IGNORE-AUDIT`, so audit-only count should increase without changing the business-difference RC. Try changing surname case and adding trailing spaces only; under TEXT-NORM these values should be equivalent. Implement the TODO in `starter/BATCHL4.COB` and run with `COURSE_SOURCE=/path/to/BATCHL4.COB`; an incomplete starter must return RC12 and publish nothing.

## Bytes and layout

`DESIGN.md` defines framing, ABI, NULL, comparison rules, and version policy. `copybooks/ENTERPRISE-CUSTOMER-V1.CPY` shows group and leaf fields; the canonical reference Copybook is in `instructor/modules/07/05-large-record/`. GnuCOBOL 3.2/Linux x86-64 measurement shows PIC COMP is big-endian; COMP-5 is not part of this interface. Validate every digit nibble and C/D sign in COMP-3 before converting or comparing; positive and negative zero are numerically equal. Do not inspect binary bytes as ASCII text.

## Change investigation: expand customer classification from one byte to two

This interface keeps V1's one-byte `CUSTOMER_CLASSIFICATION`: A/B/C/D. After investigating all consumers, sort/compare keys, file versions, and recovery paths, design a separate V2: field width PIC X(2), layout version 002, mapping A1/B1/C1/D1. Do not rewrite V1 files in place. Explain whether old batches are rejected or converted, parallel comparison, cutover, and rollback. `RECORD_STATUS` has a different meaning and cannot serve as classification.

## Tooling paths

Plugin users can open the Copybook and BATCHL4, use `gd` to jump to fields, `K` to preview COPY, and Aerial to inspect hierarchy. Terminal-only alternative: `rg -n 'CUSTOMER-CLASSIFICATION|COPY|READ|PERFORM' instructor/modules/07/05-large-record curriculum/modules/07-matching/labs/05-large-record`, then use `awk`/Python to slice offsets from the catalog; no Neovim plugin is needed.

Initialize a new learner directory with `scripts/init-workspace.sh /tmp/b04-work`. `scripts/reset.sh /tmp/b04-work` deletes only `output/` when the file set is complete and input/result hashes verify. A lock, unknown file, modification, or symlink causes refusal; source and other learner files are preserved. Full acceptance entry point is `bash scripts/check.sh`, including actual per-field offset checks and the comparison-semantics matrix.
