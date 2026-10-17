# Module 05 design: CUSTOMER v1 cleansing contract

## 1. Interface and byte layout

CUSTOMER v1 = 27 bytes, ASCII, LF-terminated; LF is excluded from logical width. Fields match `copybooks/CUSTOMER-V1.CPY`:

| Position | Length | COBOL name | Rule |
|---:|---:|---|---|
| 1–8 | 8 | CUST-ID | 8 digits, preserve leading zeroes; cleansing requires ascending order |
| 9–18 | 10 | CUST-NAME | ASCII, right-padded with spaces, required |
| 19–26 | 8 | CUST-BALANCE | Numeric, 0 ≤ value ≤ 50,000,000 |
| 27 | 1 | CUST-STATUS | May be lowercase/uppercase in input; normalize to `A`/`D` |

This module does **not modify** `curriculum/bank/copybooks/ACCOUNT-V1.CPY` (47B) or
`TRANSACTION-V1.CPY` (55B); the cleansed customer file uses the same business-date argument as those interfaces.

## 2. Read model (why byte by byte)

The program uses `ORGANIZATION IS SEQUENTIAL` and `01 C-BYTE PIC X` to read one byte at a time and recognize LF itself:

- `X'0A'` ends a logical record; the number of bytes before LF must be 1..27.
- Fewer than 27 bytes → `SHORT-RECORD`; after 27 bytes, a non-LF byte → `LONG-RECORD`; `X'0D'` → `CRLF-NOT-ALLOWED`; EOF with unterminated bytes → `MISSING-FINAL-LF`.
- All four are file-contract errors, RC8.

`LINE SEQUENTIAL` strips line endings for the caller and cannot expose overlong records via logical width, so this module deliberately avoids it. Module 06 compares the byte behavior of both modes with fixtures.

## 3. Processing states and order

```text
OPEN INPUT/OUTPUT → initialize status table
  loop: READ-RECORD → PROCESS-RECORD
PROCESS-RECORD:
  1. Structural validation (length/CRLF) already completed during read
  2. id numeric? no → MISSING-ID; yes → descending? RC8; same as previous? DUPLICATE-ID; otherwise save PREV-ID
  3. if REASON remains empty → name non-empty after removing spaces? otherwise MISSING-NAME
  4. if REASON remains empty → amount numeric? otherwise BAD-AMOUNT; > limit? AMOUNT-RANGE
  5. if REASON remains empty → INSPECT status to uppercase → SEARCH ALL table {A,D}; no match → UNKNOWN-STATUS
  6. empty REASON → write accepted.dat and add amount; otherwise write rejected.dat
CLOSE → check READ = ACCEPT + REJECT → print CONTROL
```

`SEARCH ALL` scans `STATUS-TABLE`, declared with `ASCENDING KEY` and loaded in A<D order to satisfy binary-search preconditions. An unsorted counterexample is in `scripts/search-all-probe.COB`.

## 4. Rejection priority (business policy)

Numeric IDs are checked for duplication before name/amount/status. When a record violates multiple rules, use the first matching reason:

1. `MISSING-ID` → 2. `DUPLICATE-ID` → 3. `MISSING-NAME` → 4. `BAD-AMOUNT` /
   `AMOUNT-RANGE` → 5. `UNKNOWN-STATUS`.

`UNSORTED-INPUT` (numeric ID lower than previous) and length errors are **contract errors, RC8**, not per-record business rejections.

## 5. Output and RC

| Artifact | Contents |
|---|---|
| `accepted.dat` | Normalized 27B records (uppercase status), LF-terminated |
| `rejected.dat` | Original 27B + `\|` + reason, LF-terminated |
| `report.txt` | Per-record `CUST|...` rows + final `CONTROL|...` |
| `filestatus`/`compiler.txt`/`source.sha256` | Run and source evidence |

RC: 0 no rejection; 4 business rejection; 8 contract error (length/CRLF/missing LF/descending/bad business date); 12 system failure.

## 6. Hand-calculated example (`fixtures/invalid/mixed.dat`)

| Record | Key fields | Decision | Reason |
|---:|---|---|---|
| 1 | id 00000001, name "  Alice", bal 00000050, status `a` | ACCEPT A | status `a`→`A`∈{A,D}; amount 50≤limit |
| 2 | id 00000002, name all spaces | REJECT MISSING-NAME | Required value is empty |
| 3 | id 00000003, bal 50000001, status `D` | REJECT AMOUNT-RANGE | 50000001 > 50,000,000 |
| 4 | id 00000004, bal `00000XYZ` | REJECT BAD-AMOUNT | Not numeric |
| 5 | id 00000005, status `Q` | REJECT UNKNOWN-STATUS | `Q`∉{A,D} |
| 6 | id 00000005 (duplicate), all other fields valid | REJECT DUPLICATE-ID | Same ID as preceding record |

6 records read = 1 accepted + 5 rejected; `AMOUNT` = 50 (only record 1 counts). All `expected/*.txt` files are hand-calculated from this table and the same rules, then checked against the reference implementation.

## 7. Boundaries and limitations

- Empty file (0 bytes) is valid: READ=0, RC0.
- The 50,000,000 limit is a synthetic exercise policy; real systems must use their field catalog and must not silently inherit it.
- ASCII and integer minor units only; no decimal conversion. Multibyte/EBCDIC is a separate exercise.
- Verified platform: Linux x86-64, GnuCOBOL 3.2 (local BDB backend). Other platforms are unverified.
- A runtime `libcob: warning` (libxml version notice) may appear as environmental noise unrelated to business RC.

## 8. Control-flow semantics (05.1 micro-experiment)

In fixed-format COBOL, a paragraph/section ends at the next paragraph header, not at a blank line or period:

- `PERFORM 2000-FIRST` runs only that paragraph and implicitly returns at its boundary; it does **not** fall through into 3000-SECOND.
- `PERFORM 2000-FIRST THRU 3000-SECOND` executes continuously from 2000-FIRST through the `EXIT` (or `EXIT PARAGRAPH`) in 3000-SECOND. This defines the scope and is also an easy place to create fall-through.
- `PERFORM VARYING I FROM 1 BY 1 UNTIL …` tests `UNTIL` before each iteration; `PERFORM n TIMES … END-PERFORM` is an inline loop, TEST BEFORE by default.

These behaviors are measured by `scripts/control-flow-probe.COB`; `check.py::check_control_flow` locks down its line-by-line output.
