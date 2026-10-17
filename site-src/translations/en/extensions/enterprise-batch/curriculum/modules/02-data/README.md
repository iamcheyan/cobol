# 02 Data Definitions and Customer Records (4 hours)

Recommended time: 4 hours. Prerequisite: module 01 (environment, compilation, fixed-format column rules). Only Linux x86-64 has been verified; macOS/WSL/ARM are unverified.

## 1. Business context: Why customer master data is modeled separately

The bank's overnight workflow processes accounts and transactions, but first it needs trusted **customer master data**: who is in the system, their name, and whether they are active or inactive. Accounts and transactions both refer to customer IDs. Your assignment is to establish a **field catalog and contract** for CUSTOMER v1, write a minimal loader that validates the customer file, rejects invalid records under business rules, and reconciles totals; and use a small experiment to explain `PIC` logical digits versus stored bytes, implied decimals, `MOVE` category conversion, truncation, and padding. This is the upstream foundation for the later account model (ACCOUNT v1) and JOBs.

## 2. Input source, format, and guarantees

Input is `CUSTOMER v1` (**frozen contract, 27 bytes per record**), aligned with section 2 of [bank system design](../../../docs/curriculum/BANK-SYSTEM.md). The module provides the actual Copybook at [copybooks/CUSTOMER-V1.CPY](copybooks/CUSTOMER-V1.CPY). The file is ASCII and LF-terminated; `LF` is excluded from the record length. Names are restricted to ASCII so character count is not confused with byte count. Upstream guarantees only that it supplies the current day's customer snapshot; this JOB must independently validate length, characters, ordering, and required fields.

> Regarding “classification”: byte 27 of CUSTOMER v1 contains only `customer_status` (`A`/`D`); this is **status, not customer classification**. The v1 layout has **no** customer-classification field. “Customer classification” in BANK-SYSTEM is a customer DB attribute. The module 11 “one digit to two digits” maintenance **must not** rewrite this byte. First define a separate, versioned enterprise customer layout (reuse or align with module 07 L4's `ENTERPRISE-CUSTOMER-V1`; see [curriculum/bank/README.md](../../bank/README.md)), preserve the 27-byte teaching interface, and explain how the two relate before migrating to v2. `balance_demo` is this module's experimental amount (in cents, unsigned), **not** the final ledger. In the account model, the balance moves into ACCOUNT v1 (47 bytes); see [DESIGN](DESIGN.md) for the reason and steps.

## 3. Build, run, and reset from a clean checkout

Requires Linux x86-64, GnuCOBOL 3.2, Bash, coreutils, and Python 3 (acceptance driver only). The reference implementation is in `instructor/modules/02-data/`; `starter/` compiles but is unimplemented (RC12). All output goes to a **new** output directory.

```bash
lab=curriculum/modules/02-data
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/customer.dat" /tmp/bank-m02-run
rc=$?
set -e
test "$rc" -eq 0
diff -u "$lab/expected/normal.control.txt" /tmp/bank-m02-run/control.txt
bash "$lab/scripts/check.sh"     # end-to-end contract acceptance (including MOVE/type/layout experiments)
```

```bash
bash "$lab/scripts/build.sh" /tmp/custload     # compile the exercise only
bash "$lab/scripts/reset.sh" /tmp/bank-m02-run # reset (marked output directories only)
```

Derived files overwritten during execution: `control.txt`, `accepted.dat`, `rejected.dat`, `inputs.sha256`, `outputs.sha256`, `run.txt`, `compiler.txt`, and `source.sha256` in the new output directory. Source fixtures and `expected/` are never modified.

## 4. Expected output, RC, counts, amounts, and independent reconciliation

`control.txt` (12-digit fixed-width counts and 18-digit fixed-width balance total):

```text
JOB|CUSTLOAD|V1
CONTROL|READ=000000000003|ACCEPTED=000000000003|REJECTED=000000000000|BALANCE-TOTAL=000000000010012394
```

| Fixture | RC | READ | ACCEPTED | REJECTED | Balance total | Meaning |
|---:|---:|---:|---:|---:|---:|---|
| normal | 0 | 3 | 3 | 0 | 10012394 | All valid |
| empty | 0 | 0 | 0 | 0 | 0 | Empty file permitted by contract |
| single | 0 | 1 | 1 | 0 | 500 | Final record |
| max-balance | 0 | 1 | 1 | 0 | 99999999 | 8-digit maximum |
| name-full | 0 | 1 | 1 | 0 | 1000 | Name exactly 10 characters |
| name-missing | 4 | 1 | 0 | 1 | 0 | Name contains only spaces |
| bad-amount | 4 | 1 | 0 | 1 | 0 | Balance contains non-digits |
| unknown-status | 4 | 1 | 0 | 1 | 0 | Status is not A/D |
| 7 structural fixtures | 8 | — | — | — | — | Length/LF/CR/ID/order; do not publish |

See [expected/README.md](expected/README.md) for independent reconciliation. `check.py` compares the control report byte-for-byte and independently derives `accepted.dat`/`rejected.dat` from raw fixtures; the runner's `verify-publish.py` independently recalculates them again.

## 5. What to change and which interfaces must remain intact

Entry point: `starter/CUSTLOAD.COB` (TODOs are in the file); reference: `instructor/modules/02-data/CUSTLOAD.COB`. Do not break CUSTOMER v1's 27-byte layout or field offsets, the `control.txt` line format and 12/18-digit fixed widths, the runner contract `run.sh INPUT NEW_OUTPUT`, or the RC convention.

## 6. Deliberately break conditions, investigate, and recover

- **02.1 Confusing bits and bytes**: treat `customer_id` as numeric `PIC 9(8)` and try `COMPUTE`, or misinterpret a 10-character name as something other than 10 bytes; use `LENGTH OF` to inspect actual storage. Copy `CUSTOMER-V1.CPY`, change one `PIC`, and rebuild to see how length changes.
- **02.2 MOVE truncation/padding/category conversion**: run `experiments/move/MOVELAB.COB` (see section 7), compare `MOVE 12345 TO WS-T1 (PIC 9(3))` result `345` with the expected output; moving `12345.67` to `9(3)V99` yields `345.67`. Explain high-order truncation and the implied decimal.
- **02.3 Offset error**: compile `experiments/layout/LENGTH-PROBE.COB`; using `copybooks/` gives `CUSTOMER-RECORD=27`, while `experiments/layout/` (where the name is **deliberately misstated** as `X(11)`) gives `CUSTOMER-RECORD=28` and `NAME-LENGTH=11`. This is an **incorrect layout demonstration, not the contract**. It shows how changing one `PIC` shifts every later field offset; any real layout change requires impact investigation, versioning, and preservation of the old interface. Restore by changing back to `X(10)`.

Investigation principle: preserve the original fixture and RC, inspect `FILE-STATUS`/length diagnostics first, then locate field offsets. Do not “fix” by weakening assertions.

## 7. Plugin path and terminal-only alternatives

- **Plugin path**: use `:CobolGotoCopybook` to open the canonical interface referenced by `COPY "CUSTOMER-V1.CPY"`; use Aerial/outline to inspect 01/05 hierarchy; use PIC byte hints to confirm `PIC X(10)`=10B and `PIC 9(8)`=8B.
- **Terminal alternative**: use `awk '{print length($0)}'` to check record widths; `od -An -tc` to confirm LF; compile `MOVELAB.COB` with `cobc` to produce the MOVE experiment table; use `rg -n 'PIC|COPY|VALUE|88|77' file` to inspect data declarations. Plugin estimates are not authoritative for byte layouts.

## 8. Evidence to submit and failure criteria

Submit using [evidence/README.md](evidence/README.md): field catalog; run commands and raw RCs for normal/boundary/error cases; control reports; MOVE table and type experiment (`TYPESLAB`) results with explanations; one RC8/no-publication example; and input SHA256. **Failure criteria**: `check.py` disagrees with assertions; an RC8 fixture produced an output directory; source fixture SHA256 changed; current program output was used as expected output; or CUSTOMER v1's 27-byte layout was changed.

## Lesson tasks and plugin/terminal equivalents

### Lesson 02.1 PIC X/A/9, 01/05/77/78/88, VALUE, group and elementary items

- Identify 01 group and 05 elementary items in [copybooks/CUSTOMER-V1.CPY](copybooks/CUSTOMER-V1.CPY) and `experiments/layout/LENGTH-PROBE.COB`.
- **Runnable experiment**: `experiments/types/TYPESLAB.COB` reads `fixtures/types/typeinput.dat`, and compares `PIC X(5)` with `PIC A(5)` using a `78 WS-LIMIT` constant, `77 WS-COUNT`, `88 CLS-ALPHA/CLS-MIXED` condition names, and 01/05 groups. `check.py` compares byte-for-byte with `expected/typeslab.txt`. Key finding: moving X data containing digits to `PIC A` does **not** automatically reject it (record 2 is classified `M`); validate with `IS ALPHABETIC` yourself. Moving a numeric item to `PIC A` does not compile (reproducible failure).
- **Hands-on change**: add `77 WS-FLAG PIC X VALUE 'N'.` and `88 FLAG-IS-N VALUE 'N'.` to `starter/CUSTLOAD.COB`; trigger it with `SET FLAG-IS-N TO TRUE`. Explain that `VALUE` only sets an initial value.
- **Reproducible failure**: mistreat `customer_id` as `PIC 9(8)` and leading zeroes disappear in numeric comparisons; use `LENGTH OF` and hex output to prove that actual storage is still 8-byte ASCII.
- **Plugin/terminal**: inspect hierarchy and PIC hints with the plugin; use `rg -n 'PIC|VALUE|88|77'` in the terminal.

### Lesson 02.2 S/V, amount range, implied decimals, MOVE category conversion, truncation, and padding

- Run `experiments/move/MOVELAB.COB` (`check.py` compares byte-for-byte with `expected/movelab.txt`). Cases A–I demonstrate: displaying implied decimals with `9(3)V99`; moving to integer `9(5)` and dropping the fraction; numeric-to-alphanumeric conversion; alphanumeric padding; leading separate sign display; alphanumeric truncation; high-order integer truncation; and implied decimal places in `9(3)V99`.
- **Hands-on change**: add a `PIC S9(5)V99` case for `-1234.56` and predict the output.
- **Reproducible failure**: `MOVE 12345 TO PIC 9(3)` → `345` (high-order digits are truncated; no rounding).
- **Plugin/terminal**: use PIC byte hints in the plugin; run MOVELAB and `od` in the terminal.

### Lesson 02.3 Customer Record v1: ID, name, status, and field catalog

- Build a field catalog (see [DESIGN](DESIGN.md)) explaining leading zeroes in `customer_id`, right-space padding in `customer_name`, `balance_demo` in cents, and `customer_status` values `A`/`D`. CUSTOMER v1 **has no customer-classification field**; byte 27 is status only.
- **Hands-on change**: complete TODOs in `starter/CUSTLOAD.COB` so normal passes and counts reconcile.
- **Reproducible failure (non-contract demonstration)**: the incorrect Copybook in `experiments/layout/` deliberately changes the name to `X(11)`, making the record 28 bytes. Reproduce with `LENGTH-PROBE` and explain how a single PIC change moves later offsets. This is **not** the v1 contract and not a 27-to-28 migration.
- **Plugin/terminal**: use `:CobolGotoCopybook` in the plugin; use `od -An -tc` and `LENGTH-PROBE` in the terminal.

Reference implementation, root causes, hint ladder, and grading notes: `instructor/modules/02-data/`.
