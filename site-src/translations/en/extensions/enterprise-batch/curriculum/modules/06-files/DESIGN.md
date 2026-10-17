# Module 06 design: ACCOUNT v1 file contract and status semantics

## 1. Interface and byte layout

ACCOUNT v1 = 47 bytes, ASCII, LF-terminated; LF is excluded from logical width. Fields match `curriculum/bank/copybooks/ACCOUNT-V1.CPY`:

| Position | Length | COBOL name | Rule |
|---:|---:|---|---|
| 1–10 | 10 | ACCOUNT-ID | Numeric, ascending, unique |
| 11–18 | 8 | CUSTOMER-ID | Numeric, references a customer |
| 19–21 | 3 | ACCOUNT-CURRENCY | Initially `JPY` |
| 22 | 1 | BALANCE-SIGN | `+` / `-` |
| 23–35 | 13 | OPENING-BALANCE | Numeric integer in minor units |
| 36 | 1 | ACCOUNT-STATUS | `A` active / `F` frozen / `C` closed |
| 37–44 | 8 | ACCOUNT-DATE | `YYYYMMDD`, must equal job business date |
| 45–47 | 3 | ACCOUNT-LAYOUT | `001` |

`TRANSACTION v1` (55B) is not modified in this module; it exists here as a contract for downstream Module 07.

## 2. Reading model (why byte by byte)

`FILEVAL.COB` uses `ORGANIZATION IS SEQUENTIAL`, `01 A-BYTE PIC X`, and reads one byte at a time, recognizing `X'0A'` itself:

- Logical record length must be 1..47 bytes. Shorter → `SHORT-RECORD`; after 47 bytes, any non-LF byte → `LONG-RECORD`; `X'0D'` → `CRLF-NOT-ALLOWED`; EOF with unterminated bytes → `MISSING-FINAL-LF`.
- All of these are file-contract errors, RC8.
- `LINE SEQUENTIAL` strips line endings, so it cannot expose whether LF is valid through logical width. Module 06.2 measures the byte difference with `scripts/line-seq-probe.COB` (see section 5).

## 3. Processing states and order

```text
OPEN INPUT/OUTPUT/LOG → load status table {A,C,F}
  loop: READ-RECORD (structural validation) → PROCESS-RECORD
  1. layout ≠ 001 → RC8
  2. nonnumeric id → BAD-ACCOUNT-ID; numeric id → check descending (RC8) / duplicate (DUPLICATE-ID)
  3. if REASON is empty → nonnumeric customer_id? BAD-CUSTOMER-ID
  4. → currency ≠ JPY? UNKNOWN-CURRENCY
  5. → sign ∉ {+,-}? BAD-SIGN
  6. → nonnumeric balance? BAD-BALANCE
  7. → nonnumeric/invalid-calendar date? BAD-DATE; otherwise ≠ business date? DATE-MISMATCH
  8. → status SEARCH ALL {A,C,F}; not found → UNKNOWN-STATUS
  9. empty reason → write accepted and add signed balance; else write rejected
CLOSE → READ = ACCEPT + REJECT → print CONTROL, write filestatus.log
```

## 4. Rejection priority and RC

1. `BAD-ACCOUNT-ID` → 2. `DUPLICATE-ID` → 3. `BAD-CUSTOMER-ID` →
4. `UNKNOWN-CURRENCY` → 5. `BAD-SIGN` → 6. `BAD-BALANCE` → 7. `BAD-DATE` /
`DATE-MISMATCH` → 8. `UNKNOWN-STATUS`.

`UNSORTED-INPUT` and length/line-ending/layout errors are **contract errors, RC8**, not per-record business rejections.

| RC | Meaning |
|---:|---|
| 0 | No business rejection; read = accepted + rejected |
| 4 | Field-level business rejection; still publish |
| 8 | Contract error (length/CRLF/missing LF/descending/layout/invalid business date); do not publish |
| 12 | File/permission/system failure (including missing file, FILE STATUS 35); do not publish |

## 5. Measured FILE STATUS and indexed/relative files (local machine)

Environment: Linux x86-64, GnuCOBOL 3.2.0, `cobc -info` → `indexed file handler : BDB`. Each result below was produced by actually running a `scripts/*-probe.COB` program (raw RC and status appear in evidence).

### 5.1 Sequential files (core of this module)

| Operation | Status | Meaning |
|---|---|---|
| `OPEN INPUT` existing file | `00` | Success |
| Read end of file | `10` | EOF (at end) |
| `OPEN INPUT` missing file | `35` | File not found → RC12 |
| First read of empty file | `10` | Valid, zero records |

Pairing an `SD` (Sort Description) with `SORT … USING/GIVING` is demonstrated in `scripts/sort-sd-probe.COB` (06.1 declaration exercise; matching algorithms belong to Module 07).

### 5.2 LINE SEQUENTIAL vs fixed-width bytes

| Method | Raw file bytes | Logical record width |
|---|---:|---|
| Write `HELLO` as `LINE SEQUENTIAL` | 6 (`HELLO\n`) | 5 (LF hidden) |
| Write `HELLO` as fixed `SEQUENTIAL` | 5 | 5 |

Reading the line file byte by byte exposes `X'0A'`, proving LF exists but is excluded from logical width.

### 5.3 Indexed files (BDB)

| Operation | Status |
|---|---|
| `OPEN OUTPUT` create | `00` |
| `WRITE` new key | `00` |
| `WRITE` duplicate key | `22` (duplicate key) |
| `READ KEY` hit | `00` |
| `REWRITE` | `00` |
| `READ KEY` missing | `23` (record not found) |
| `DELETE` existing row | `00` |
| `READ` after delete | `23` |
| `OPEN INPUT` again on an already open file in same process | `41` (already open) |
| `OPEN INPUT` missing file | `35` |

### 5.4 Relative files

| Operation | Status |
|---|---|
| `OPEN OUTPUT` create | `00` |
| `WRITE` (`RELATIVE KEY` 1, 2) | `00` |
| `WRITE` duplicate key again | `22` |
| `READ` hit | `00` |
| `REWRITE` | `00` |
| `READ` out-of-range key (9) / key 0 | `23` |
| `DELETE` | `00` |
| `READ` after delete | `23` |

### 5.5 Applicability limits (important)

- **No cross-process mutual exclusion by default (measured locally, not inferred from documentation)**: `scripts/indexed-hold-probe.COB` has two processes simultaneously `OPEN I-O` the same BDB indexed file; **both receive `00`** (`check.py::check_cross_process_lock` runs them concurrently). A repeated `OPEN` in one process returning `41` **does not establish** two-process behavior; the results cannot be inferred from one another. GnuCOBOL/BDB does not exclusively lock the whole file by default, so concurrency consistency must be enforced by an external lock at the JOB layer. This lesson's `run.sh` uses an `output.lock` directory for single-instance protection (`check_protection` starts two `run.sh` processes: one `RC0`, the other `RC12` with stderr `Run locked`). These protections serve different purposes and are not interchangeable.
- Indexed/relative files are only **reading experiments** in this module and temporary ledgers in Module 07; the primary validation flow remains sequential and does not use DB JOINs, Python, or full-file arrays.

## 6. Hand-calculated example (`fixtures/invalid/mixed.dat`)

| Record | Key fields | Decision |
|---:|---|---|
| 1 | id1, JPY, +, 1000, A, 20261009 | ACCEPT +1000 |
| 2 | id2, USD | REJECT UNKNOWN-CURRENCY |
| 3 | id3, `*` sign | REJECT BAD-SIGN |
| 4 | id4, status `Z` | REJECT UNKNOWN-STATUS |
| 5 | id5, date 20261008 | REJECT DATE-MISMATCH |
| 6 | id6, JPY, +, 100, A | ACCEPT +100 |

6 records read = 2 accepted + 4 rejected; BALANCE = 1000 + 100 = 1100. `normal/valid.dat`:
+1000 + +50 − 500 = **550**.

## 7. Boundaries and limitations

- Empty file is valid (READ=0, RC0); missing file returns RC12 and is not published.
- `BALANCE` is a signed, exact 18-digit decimal; each row has 13 digits. No decimal conversion is performed.
- ASCII and integer amounts in one currency only; multibyte/EBCDIC is a separate exercise.
- Verified platform: Linux x86-64, GnuCOBOL 3.2 (BDB). Other platforms are unverified.
- Runtime `libcob: warning` (libxml version notice) is environmental noise unrelated to business RC.
