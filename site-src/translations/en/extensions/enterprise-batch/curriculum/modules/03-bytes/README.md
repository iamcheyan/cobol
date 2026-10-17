# Module 03 Low-Level Data Representation (03.1–03.3)

Recommended time: 5 hours. Prerequisite: module 02 (`PIC`, `V`, implied decimals, `S`). This module explains what bytes an amount actually occupies in memory/files; it does not change any bank interface. Frozen contracts remain unchanged: CUSTOMER v1=27B, ACCOUNT v1=47B, TRANSACTION v1=55B (see [BANK-SYSTEM](../../../docs/curriculum/BANK-SYSTEM.md)).

This module expands the P1 byte experiment ([validation/layout](../../validation/layout/README.md)) into a full course: declared digits versus physical bytes, ABI/endianness/runtime Data Exception, and invalid Packed data and misaligned parsing.

## 1. Why the business needs this (requirement)

Overnight bank batch processing must interoperate with legacy mainframe files. Amounts in these files are not text; they are bytes in `DISPLAY`, `COMP` (binary), or `COMP-3` (Packed Decimal) format. On-call developers must be able to answer, without looking at source code: how much a raw byte sequence represents, whether there is an implied decimal, where the sign is stored, how many bytes it uses, and whether it changes on another machine. A mistake can treat Packed `0x0C` as a string character or interpret big-endian binary as little-endian, shifting the amount while **RC remains 0**. This module builds a verifiable view of bytes and a parser that “rejects invalid amounts first; never includes them in arithmetic.”

## 2. Input source, format, and assumptions

- The reference implementation of `M03BYTES` is provided in this repository (`instructor/modules/03-bytes/M03BYTES.COB`); the student starting code is `starter/M03BYTES.COB`.
- Lessons 03.1/03.2 read no input: the program writes amounts as raw bytes for Hex Dump comparison.
- Lesson 03.3 reads a **raw binary** file: fixed 7-byte records of `PIC S9(11)V99 COMP-3` (13 digit nibbles + 1 sign nibble = 14 nibbles = 7 bytes, no LF, no alignment padding).
- Assumptions: verified only with GnuCOBOL 3.2, Linux x86-64, and the default dialect (`COMP-3` and `FUNCTION TRIM` are GNU extensions; **do not** use `-std=cobol85`, see §6). Synthetic data is ASCII.
- Fixtures: `fixtures/normal/`, `fixtures/boundary/`, `fixtures/invalid/`; SHA256 values are in [fixtures/SHA256SUMS](fixtures/SHA256SUMS), and are generated deterministically by [scripts/generate-fixtures.py](scripts/generate-fixtures.py).

## 3. Build / run / reset (from any starting directory)

`scripts/*` can run from any cwd and support paths containing spaces. The output directory must **not exist** (no-clobber).

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
bash curriculum/modules/03-bytes/scripts/run.sh 03.1 /tmp/m03-l1
bash curriculum/modules/03-bytes/scripts/run.sh 03.2 /tmp/m03-l2
bash curriculum/modules/03-bytes/scripts/run.sh 03.3 /tmp/m03-l3 \
     curriculum/modules/03-bytes/fixtures/normal/mixed-valid.dat
cat /tmp/m03-l3/report.txt
```

- Lesson 03.3 input size must be a multiple of 7 bytes; otherwise the runner returns RC8 and **publishes no output**.
- The runner creates artifacts in a private stage directory and atomically renames it to the output directory only after every check passes. Failures and existing destination directories are rejected (RC12). This does **not** overwrite repository fixtures or other experiments.
- Reset: `bash curriculum/modules/03-bytes/scripts/reset.sh /tmp/m03-l3` deletes the output directory only if the file set is complete and `manifest.sha256` verifies.

Derived artifacts (inside output directory): `report.txt` (stdout), `stderr.txt`, `compiler.txt`, `source.sha256`, `manifest.sha256`; 03.1 also has `abi.bin`, 03.2 has `amounts.bin`, and 03.3 has input snapshot `input.dat` and `inputs.sha256`.

## 4. Expected output, RC, and independent reconciliation

- **03.1 RC0**: declared logical digits versus physical `LENGTH OF` bytes; COMP big-endian, COMP-5 native little-endian. See [expected/03.1-declare.txt](expected/03.1-declare.txt). The first 8 bytes of `abi.bin` must be `01 02 03 04 04 03 02 01` (big-endian COMP / little-endian COMP-5).
- **03.2 RC0**: raw DISPLAY / SIGN SEPARATE / COMP-3 / integer-cents COMP bytes for amounts `12345.67` and `-12345.67`; see [expected/03.2-hexdump.txt](expected/03.2-hexdump.txt). `amounts.bin` is 59 bytes total.
- **03.3**: each record reports an `OK` decoded value or `REJECT` reason; RC0 when `REJECTED=0`, RC4 when there are rejections (the report is still published because the parsing verdict itself is the deliverable).
- Independent reconciliation: `scripts/check.py` contains an independent Python reference model (validates each nibble, C/D signs, inserts the implied decimal point, decodes big-endian integers). It recalculates all hex values and each 03.3 record, then compares both to `expected/` and to compiled COBOL output. See [expected/README.md](expected/README.md) for the reconciliation method.
- **Semantic verification before publication**: before publication, `scripts/run.sh` calls `scripts/verify.py` (sharing the independent model with `check.py`). It recalculates the expected `report.txt` and `abi.bin`/`amounts.bin` from raw input bytes and compares each item. Merely changing the completion flag to `'Y'`, placeholder `TODO` output, skipped records, incorrect amount/sign, or incorrect record count fails and **does not publish** (see §6 failure injections). Corresponding regressions are included in `check.py`.

## 5. What to change and what must remain intact

Modify the 03.1/03.2/03.3 TODO sections in `starter/M03BYTES.COB`, then set `WS-EXERCISES-DONE` to `'Y'`. Do not break:

- Existing CUSTOMER v1=27B / ACCOUNT v1=47B / TRANSACTION v1=55B interfaces;
- Field order in this module's output reports (the checker compares line by line);
- Fixed-format 80-column rules (Area A/B, no tabs, valid code no longer than 72 columns).

## 6. Deliberately break conditions and recovery (reproducible failures)

1. **Invalid Packed digit nibble**: `fixtures/invalid/bad-digit-nibble.dat` contains `0xA`; the program must reject each nibble before arithmetic, output `DIGIT-NOT-0-9`, and return RC4.
2. **Invalid sign nibble**: final nibble `0xF` in `bad-sign-nibble.dat` → `BAD-SIGN-NIBBLE`, RC4.
3. **Misalignment / wrong length**: `truncated.dat` (6B) and `trailing-byte.dat` (8B) are not multiples of 7 → runner returns RC8, publishes nothing. This is an outer raw-byte boundary: fixed-length GnuCOBOL reads may silently pad `PIC X` and return `00` (`FILE STATUS`), so status alone is insufficient.
4. **Strict 85 dialect**: `cobc -std=cobol85 -fsyntax-only M03BYTES.COB` fails on `COMP-3`, demonstrating why AGENTS/§6 forbids this option. `check.py` asserts that it fails.
5. **Negative zero trap**: `-0.00` (sign D) and `+0.00` (sign C) have different bytes but both represent zero; the parser accepts C and D separately. Do not reject either because “the value is zero.”
6. **Host Data Exception versus actual GnuCOBOL behavior** (measured in this environment): placing nonnumeric bytes in `PIC 9` and doing arithmetic usually raises a data exception on an IBM mainframe (ABEND `S0C7`); this local GnuCOBOL 3.2 **does not report an error** and calculates garbage values (`ABC`→124, `XYZ`→901, RC0). Therefore this module requires “validate each nibble first, then do arithmetic”; do not rely on the runtime to catch invalid digits.

**Recovery**: invalid 03.3 records are “parsed successfully but rejected,” so the report is still published; only misaligned length causes RC8 with no publication. Fix the input or parser and rerun. The runner never overwrites an existing output directory.

## 7. Plugin path and terminal-only alternatives

- Plugin (`cobol.nvim`): use the fine-line ruler to confirm Area A/B and column 72; `:CobolCalcRecord` is only an estimate and **must not** be treated as authoritative byte layout; use `gd` to jump to fields and `K` to preview.
- Terminal equivalent: `xxd -g1 amounts.bin`, `od -An -tx1`, and `sed -n`/`awk` for column checks; use `LENGTH OF`, `ADDRESS OF`, and raw bytes as the final authority. Either workflow must be sufficient to complete this module independently.

## 8. Evidence and failure criteria

Submit source and SHA256, compiler/ABI versions, raw command and RC for each lesson, Hex Dump and explanation table, nibble-by-nibble verdict for invalid Packed data, explanation of why misaligned length is RC8 with no publication, and `check.sh` output. Template: [evidence/README.md](evidence/README.md).

**Failure criteria**: submitting a DISPLAY text screenshot without raw bytes; scanning Packed/binary data as strings; allowing invalid data into arithmetic before validation; using strict `-std=cobol85` to hide GNU extensions; or submitting placeholder/incorrect output after changing only `WS-EXERCISES-DONE` to `'Y'` (the runner's independent semantic validation rejects it and does not publish). Any of these is a failure.
