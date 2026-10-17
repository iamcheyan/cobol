# 06 File Processing (6 hours)

Recommended: 6 hours, after Module 05. Covers outline 06.1 SELECT/FD/SD/OPEN/READ/WRITE/CLOSE/FILE STATUS/EOF; 06.2 fixed-byte records vs LINE SEQUENTIAL, LF excluded from logical width, and length-error detection; 06.3 missing/empty files, short/long lines, invalid numbers, duplicate IDs, unknown status, and input control totals; 06.4 reading experiments on relative/indexed-file REWRITE/DELETE and locks, with applicability limits.

Business requirement: nightly batch **JOB002 length and business validation** must read the upstream ACCOUNT v1 master file (47-byte fixed records), classify each row as accepted/rejected with a field-level reason, record file status, report input control totals, and produce a **valid, sorted** ACCOUNT v1 file for sequential matching in Module 07. Your deliverable is the validation program `FILEVAL.COB`.

## 1. Input, format, and assumptions

- Input is an ASCII ACCOUNT v1 file terminated by LF. Each logical record is **47 bytes** (**excluding LF**): positions 1–10 `account_id`, 11–18 `customer_id`, 19–21 `currency`, 22 `balance_sign`, 23–35 `opening_balance`, 36 `account_status`, 37–44 `business_date`, 45–47 `layout_version`.
- Reuse the frozen interface `curriculum/bank/copybooks/ACCOUNT-V1.CPY`; do not modify it in this module.
- Assumptions: the file is sorted by `account_id` ascending; the business date is an argument and must match each record's `business_date`; first-release `currency` is `JPY`; `layout_version` must be `001`.
- An empty file (0 bytes) is **allowed** and means zero accounts that day. A missing/unreadable file is a system failure (RC12).
- For fixed-byte input, the program counts 1..47 bytes and recognizes LF itself, allowing it to detect short/long lines, CRLF, and missing final LF.

## 2. Build, run, and reset from a clean checkout

Requires Linux x86-64, GnuCOBOL 3.2 (`cobc -info` reports the BDB indexed backend), Bash, GNU coreutils, and Python 3 (acceptance only). macOS/WSL are unverified. **Do not** use `-std=cobol85`.

```bash
lab=curriculum/modules/06-files
bash "$lab/scripts/build.sh" /tmp/fileval
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/valid.dat" \
  /tmp/bank-fileval-normal 20261009
bash "$lab/scripts/check.sh"
bash "$lab/scripts/reset.sh" /tmp/bank-fileval-normal
```

`run.sh` accepts only a new output directory that does not exist. It writes to a private stage first and publishes the complete result only after validation. Derived files in the output directory: `accepted.dat`, `rejected.dat`, `report.txt`, `filestatus.log`, `run.txt`, `compiler.txt`, `source.sha256`, `inputs.sha256`, `outputs.sha256`, and `account.input.dat` (input snapshot). It does not overwrite fixture originals. `reset.sh` only deletes a marked course output directory outside the repository.

## 3. Expected output, RC, counts, and balance

```text
ACCT|<id>|ACCEPT|<A|C|F>|<sign><18 digits>
ACCT|<id>|REJECT|<reason>
CONTROL|BUSINESS-DATE=<YYYYMMDD>|READ=n|ACCEPT=n|REJECT=n|BALANCE=<sign><18 digits>
```

`accepted.dat` contains the original 47-byte valid records; `rejected.dat` contains the original 47 bytes + `|` + reason. `filestatus.log` records `OPEN|ACCOUNT|00` and `EOF|ACCOUNT|10`. RC policy:

| RC | Meaning | Output policy |
|---:|---|---|
| 0 | No business rejections; read = accepted + rejected | Publish |
| 4 | Field-level business rejections | Publish checked results with rejection details |
| 8 | Contract error: length, CRLF, missing final LF, descending order, invalid layout, wrong business date | Fail whole batch; do not publish |
| 12 | File/permission/system failure (including missing input, FILE STATUS 35) | Fail whole batch; do not publish |

Field-level rejection reasons (**fixed priority**):

| Reason | Trigger |
|---|---|
| `BAD-ACCOUNT-ID` | `account_id` is not numeric |
| `DUPLICATE-ID` | Numeric ID equals the preceding record (descending order is RC8) |
| `BAD-CUSTOMER-ID` | `customer_id` is not numeric |
| `UNKNOWN-CURRENCY` | `currency` ≠ `JPY` |
| `BAD-SIGN` | `balance_sign` is not in `{+,-}` |
| `BAD-BALANCE` | `opening_balance` is not numeric |
| `BAD-DATE` | `business_date` is not numeric or not a valid calendar date |
| `DATE-MISMATCH` | Date is valid but differs from the job business date |
| `UNKNOWN-STATUS` | `account_status` is not in `{A,C,F}` |

**Control totals**: `READ = ACCEPT + REJECT`; `BALANCE` is the sum of signed opening balances for accepted records (exact 18-digit decimal). Rejected records are excluded from `BALANCE`. `expected/` is independently determined from hand calculations; `check.py` independently rebuilds accepted/rejected byte for byte from fixtures.

## 4. What to modify and interfaces to preserve

Implement input, validation, classification, and the three output files in `starter/FILEVAL.COB`. **Do not break** the 47-byte ACCOUNT v1 layout, business-date argument semantics, RC conventions, reason-code spelling, or the `TRANSACTION v1` contract. Reference: [`instructor/modules/06-files/FILEVAL.COB`](../../../instructor/modules/06-files/FILEVAL.COB).

## 5. Deliberately induce and recover from faults (reproducible)

1. Copy `fixtures/normal/valid.dat` to a temporary directory and remove the final LF: RC8 `MISSING-FINAL-LF`, no publication.
2. Change a record's `currency` to `USD`: RC4 `UNKNOWN-CURRENCY`; other rows continue normally.
3. Change a record's `business_date` to `20261008`: RC4 `DATE-MISMATCH`.
4. Change `layout_version` to `002`: RC8 `BAD-LAYOUT-VERSION`, no publication.
5. Swap two records: RC8 `UNSORTED-INPUT`.

Investigation order: inspect stderr reason code and RC, compare `report.txt` with each input row, then run `sha256sum -c inputs.sha256` to verify the input snapshot is unchanged; on failure, confirm no output directory was published.

## 6. Plugin workflow and terminal alternative

- Plugin: use `:CobolGotoCopybook` to inspect the 47-byte `ACCOUNT-V1.CPY`; `:CobolCalcRecord` for field bytes; `gd` to jump to a paragraph; use the ruler to check Area A/B.
- Terminal alternative: `rg -n 'FILE STATUS|EOF|TEST-DATE|SEARCH'`, `awk '{print length($0)}'`, and `od -An -tc` to inspect LF/CRLF and raw bytes. Both workflows should achieve the same business goal.

## 7. Acceptance evidence and failure criteria

Submit source, normal-case evidence, at least one RC4, one RC8 (no publication), and one RC12 (missing file), input SHA256, read = accepted + rejected conservation, `BALANCE` conservation, and `filestatus.log`. Template: [evidence/README.md](evidence/README.md). **Failure criteria**: RC/reason mismatch, output published for a failed case, original fixture modified, or `filestatus.log` inconsistent with the contract.

## 8. 06.2 / 06.4 reading experiments (measured on this machine)

- [`scripts/line-seq-probe.COB`](scripts/line-seq-probe.COB): the same 5-byte logical record is 6 raw bytes (including LF) when written as `LINE SEQUENTIAL` and 5 bytes with fixed `SEQUENTIAL`; reading the line file byte by byte exposes `X'0A'`. This demonstrates that **LF exists but is not part of logical width**, and that the fixed byte-by-byte model exposes it.
- [`scripts/indexed-probe.COB`](scripts/indexed-probe.COB): BDB indexed-file `WRITE/READ/REWRITE/DELETE` and status codes (including `41` for reopening in the same process).
- [`scripts/indexed-hold-probe.COB`](scripts/indexed-hold-probe.COB): a holder that pauses on stdin after `OPEN I-O`, for a **real two-process lock-contention experiment** (not a reopen in one process).
- [`scripts/relative-probe.COB`](scripts/relative-probe.COB): relative-file `WRITE/READ/REWRITE/DELETE` using `RELATIVE KEY`.
- [`scripts/sort-sd-probe.COB`](scripts/sort-sd-probe.COB): pairs an `SD SORT-WORK` sort description with `SORT … ASCENDING KEY … USING/GIVING` to sort unsorted `LINE SEQUENTIAL` input (the 06.1 SD/SORT declaration; not Module 07 matching algorithms).

Measured status codes and **applicability limits** are in [DESIGN.md](DESIGN.md), section 5. Key findings (measured here, not inferred from documentation):

- Reopening the same file in one process returns `41`; **this does not establish behavior across two processes**.
- When two processes open the same BDB indexed file `I-O` simultaneously, **both receive `00`** (`indexed-hold-probe` is run concurrently by `check.py::check_cross_process_lock`) → the default GnuCOBOL/BDB handle layer **does not provide cross-process mutual exclusion**.
- Therefore concurrency consistency must be protected by an external lock at the JOB layer. This lesson's `run.sh` uses an `output.lock` directory for single-instance protection; `check.py::check_protection` starts two `run.sh` processes and asserts exactly one `RC0`, the other `RC12` with stderr `Run locked`, and clean result/lock directories. 06.4 is intended to teach this boundary.

## 9. Outline requirements ↔ runnable practice map

Every row points to real, runnable source/fixtures asserted by `check.sh`.

| Outline requirement | Source | Input | Student change/fault | expected / check | Evidence |
|---|---|---|---|---|---|
| 06.1 SELECT/FD/OPEN/READ/WRITE/CLOSE/FILE STATUS/EOF | `instructor/.../FILEVAL.COB` | `fixtures/normal/valid.dat` | Remove final LF | `filestatus.log`, `expected/normal-valid.txt`; `run_case` | `evidence/README.md` |
| 06.1 SD (sort description) | [`scripts/sort-sd-probe.COB`](scripts/sort-sd-probe.COB) | Temporary unsorted `in.dat` | Change `ASCENDING` to `DESCENDING` | `check_line_sequential_and_sd`: `ALICE/BOB/CAROL` | `check_probes` |
| 06.2 fixed vs LINE SEQUENTIAL | [`scripts/line-seq-probe.COB`](scripts/line-seq-probe.COB) | Temporary `line.dat`/`fixed.dat` | Rewrite to read as `LINE SEQUENTIAL` | `LINE-RAW-BYTES=06` vs `FIXED-RAW-BYTES=05` | `check_probes` |
| 06.2 length-error detection | `FILEVAL.COB` byte-by-byte read | `fixtures/invalid/{short,long}-record.dat`, `no-trailing-lf.dat`, `crlf.dat` | Shorten/lengthen/add CR | RC8, no publication; `run_case` | `evidence/README.md` |
| 06.3 missing/empty file/invalid number/duplicate ID/unknown status/control totals | `FILEVAL.COB` | `fixtures/boundary`, `invalid` | Missing file → RC12; empty file → RC0 | `expected/*.txt`; `run_case` + `verify-publish.py` | Same |
| 06.4 indexed-file WRITE/READ/REWRITE/DELETE | [`scripts/indexed-probe.COB`](scripts/indexed-probe.COB) | Temporary `ix.dat` | Duplicate/missing key | `DUPLICATE=22`, `MISSING=23`, `REOPEN=41` | `check_probes` |
| 06.4 relative file | [`scripts/relative-probe.COB`](scripts/relative-probe.COB) | Temporary `rel.dat` | Out-of-range key 9 | `READ9=23` | `check_probes` |
| 06.4 two-process lock contention and applicability | [`scripts/indexed-hold-probe.COB`](scripts/indexed-hold-probe.COB) + `run.sh` `.lock` | Two concurrent holders / two `run.sh` processes | Remove `.lock` from `run.sh` | Both processes `HOLD-OPEN=00`; JOB lock gives `RC0`/`RC12 Run locked` | `check_cross_process_lock`, `check_protection` |
