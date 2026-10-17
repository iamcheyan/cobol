# 01 COBOL and Legacy Systems (3 hours)

Recommended time: 3 hours, including reading, experiments, and evidence preparation. Prerequisites: use a terminal, edit text, and understand variables, conditions, and loops. No mainframe or database experience is required. Only Linux x86-64 has been verified; macOS/WSL/ARM are unverified.

## 1. Business context: Why banks need overnight batch processing

This simulated bank accepts customer requests through **online** channels during the day, where each transaction is visible immediately. At night it runs **batch** processing, handling the day's frozen input at close of business and producing next-day opening balances, rejection details, exception lists, and downstream files. Online processing emphasizes **low latency and individual transactions**; batch processing emphasizes **replayability, reconciliation, and processing a batch at a time**.

Your assignment: as a developer newly responsible for this legacy system, establish the environment and understand the whole system well enough to answer “Is this a program or a JOB?”, “Where does input come from and where does output go?”, and “What happens when a JOB fails?” You will compile and run the code and diagnose a failed build. This module produces **environment evidence**, a **minimal bank batch entry point**, and a **source-to-executable relationship diagram** for later modules to extend using real account and transaction data.

Key distinctions to explain:

- **Program**: a compilable, executable COBOL unit responsible for a defined data-processing task.
- **JOB**: runtime orchestration combining parameters, input snapshots, work directories, locks, validation, publication, logs, and return codes. Here `scripts/run.sh` plays the JOB and `BANK-ENTRY.COB` the Program.
- **Business date**: explicitly supplied as a parameter; never default to the machine's current date.
- **RC 0/4/8/12**: course convention: 0 success, 4 permitted business warning, 8 business/contract error, 12 system error.

Initial system diagram (expanded in later modules):

```mermaid
flowchart LR
  ONL[Online transactions] --> TX[Transaction input]
  TX --> J001[JOB001 Receive and validate]
  J001 --> J002[JOB002 Validate and cleanse]
  J002 --> J005[JOB005 Match / post]
  J005 --> J008[JOB008 Publish downstream files]
  J008 --> RPT[Daily report / rejection details]
```

## 2. Input source, format, and guarantees

Input is `ACCOUNT v1` (the **frozen interface** defined in section 2 of [bank system design](../../../docs/curriculum/BANK-SYSTEM.md)), **47 bytes per record**, ASCII, each record followed by `LF`; `LF` is excluded from the record length. See [DESIGN](DESIGN.md) for field offsets, encoding, and valid values. The JOB parameter supplies the business date (default here: `20261009`). The upstream guarantee is only that it supplies the account snapshot for this business date. This JOB must still validate length, character set, and ordering; do not trust them by default.

## 3. Build, run, and reset from a clean checkout

Requires Linux x86-64, GnuCOBOL 3.2, Bash, coreutils, and Python 3 (acceptance driver only). The reference implementation is in `instructor/modules/01-foundations/`; `starter/` compiles but is unimplemented (returns RC12). All output goes to a **new** output directory and does not overwrite inputs or existing output.

> **Student bundle (without `instructor/`) behavior**: the public repository includes the reference implementation, which `run.sh` compiles by default, so the `normal` example below returns RC0. A student bundle made with `package-student.sh` **does not include** `instructor/`; `run.sh`/`build.sh` then compile your `starter/BANK-ENTRY.COB` by default. `build.sh` still returns RC0 (the starter compiles), while `run.sh` returns RC12 and publishes nothing until you complete the TODOs. To verify another source (such as your own completed copy), set `COURSE_SOURCE=/path/to/BANK-ENTRY.COB`.

```bash
lab=curriculum/modules/01-foundations
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/account.dat" /tmp/bank-m01-run 20261009
rc=$?
set -e
test "$rc" -eq 0
diff -u "$lab/expected/normal.control.txt" /tmp/bank-m01-run/control.txt
bash "$lab/scripts/check.sh"            # end-to-end acceptance of all contracts
```

```bash
bash "$lab/scripts/build.sh" /tmp/bankentry   # compile the exercise only
bash "$lab/scripts/env-report.sh"             # environment and source-to-executable evidence
bash "$lab/scripts/reset.sh" /tmp/bank-m01-run # reset (marked output directories only)
```

Derived files overwritten during execution: `control.txt`, `accepted.dat`, `rejected.dat`, `inputs.sha256`, `outputs.sha256`, `run.txt`, `compiler.txt`, and `source.sha256` in the new output directory. Source fixtures and `expected/` are never modified. `reset.sh` only deletes directories containing the `run.txt/inputs.sha256/outputs.sha256/control.txt` markers and outside the repository.

## 4. Expected output, RC, record counts, and independent reconciliation

`control.txt` is a fixed-width sample (12-digit fixed-width counts, consistent with module 07):

```text
JOB|BANK-ENTRY|V1
BUSINESS-DATE|20261009
CONTROL|READ=000000000003|ACCEPTED=000000000003|REJECTED=000000000000
```

| Fixture | RC | READ | ACCEPTED | REJECTED | Meaning |
|---:|---:|---:|---:|---:|---|
| normal | 0 | 3 | 3 | 0 | A/F/C are all valid |
| empty | 0 | 0 | 0 | 0 | Empty file is permitted by contract |
| single | 0 | 1 | 1 | 0 | Final record |
| unknown-status | 4 | 1 | 0 | 1 | Reject status Z individually; still publish |
| 9 structural fixtures | 8 | — | — | — | Length/LF/CR/account/layout/date/order; do not publish |

Expected values are manually reconciled from the ACCOUNT v1 contract, **not** copied from program output. See [expected/README.md](expected/README.md) for the calculation. `check.py` compares the control report byte-for-byte and independently derives `accepted.dat`/`rejected.dat` from the raw fixtures; the runner's `verify-publish.py` independently recalculates them too. Any disagreement fails.

> This is the “environment and entry point” foundation; it does **not** do amount arithmetic (amount semantics begin with `balance_demo` in module 02, and account balances begin with the account model). The control report therefore reconciles read/accepted/rejected counts only, with no amount column. Amount reconciliation is first tested during posting in module 07.

## 5. What to change and which interfaces must remain intact

Entry code: `starter/BANK-ENTRY.COB` (TODOs are in the file); reference: `instructor/modules/01-foundations/BANK-ENTRY.COB` (present only in the public repository, absent from student bundles). Set `COURSE_SOURCE` to your completed copy for `run.sh`/`check.sh` to verify it. Interfaces that must not be broken:

- ACCOUNT v1's 47-byte layout and field offsets (read-only in this module; do not redefine it);
- `control.txt` line format and 12-digit fixed-width counts;
- runner CLI contract `run.sh INPUT NEW_OUTPUT YYYYMMDD` and RC convention.

## 6. Deliberately break conditions, investigate, and recover

At least one reproducible failure per lesson:

- **01.1 Invalid business date**: `bash scripts/run.sh fixtures/boundary/empty.dat /tmp/x 20260230` → JOB validation (`TEST-DATE-YYYYMMDD`) fails, RC8, no output. Determine whether the error is “date format/calendar” or “record date differs from business date”; they are distinct errors.
- **01.2 Build failure**: `experiments/build-failure/BROKEN-PERFORM.COB` (undefined paragraph) and `BROKEN-AREA.COB` (statement starts in Area A). `cobc -fsyntax-only` returns nonzero; use compiler line/column diagnostics to locate the cause.
- **01.3 Column truncation**: in `experiments/columns/TRUNC-BAD.COB.src`, a digit in column 73 of a `COMPUTE` line is silently ignored by the compiler: `111110` becomes `11111`, changing the result from `111111` to `11112`. See `TRUNC-GOOD.COB` for recovery (place the literal within columns 12–72).

Investigation principle: preserve the original fixture and RC first, use compiler/runner diagnostics to locate the cause, then verify a minimal fix. Never “fix” a problem by modifying fixtures or weakening assertions.

## 7. Plugin path and terminal-only alternatives

- **Plugin path**: use the fixed-format ruler to confirm columns 7/8/12/72; place the cursor on any source line and inspect Winbar Area A/B hints and the red overflow diagnostic at column 72; use `:CobolGotoDef` to jump to a `PERFORM` target paragraph.
- **Terminal alternative**: `awk '{print NR, length($0)}' file` checks for lines beyond 72 columns; `rg -n 'PERFORM|DIVISION|SECTION' file` shows structure; `cobc -fsyntax-only file` triggers diagnostics. Plugin estimates are not authoritative for byte layouts.

## 8. Evidence to submit and failure criteria

Submit using [evidence/README.md](evidence/README.md): environment evidence (`cobc -V`, `uname`, `file`/`ldd` output), run commands and raw RCs for normal/empty/single/unknown-status, control reports, one RC8/no-publication example, before/after column-truncation results, and input SHA256. **Failure criteria**: `check.py` or `verify-publish.py` disagrees with assertions; an RC8 fixture produced an output directory; source fixture SHA256 changed; or current program output was used as expected output.

## Lesson tasks and plugin/terminal equivalents

### Lesson 01.1 Business date, online vs overnight batch, Program vs JOB

- Read and explain the system diagram; explain why the business date must be explicit (run `env-report.sh` and inspect `business_date` in `run.txt`).
- **Hands-on change**: change the `run.sh` business date to `20240229` (leap day) and `20260230` (invalid date), then predict and verify the RC.
- **Reproducible failure**: omit the third argument → usage error RC12; supply an invalid calendar date → RC8.
- **Plugin/terminal**: use Winbar to show the current paragraph; use `sed -n` in the terminal to inspect `run.txt`.

### Lesson 01.2 GNUCOBOL compile/link/runtime/build directory

- Run `env-report.sh` and diagram `BANK-ENTRY.COB → cobc → C → cc → bankentry(ELF) → libcob` (see [DESIGN](DESIGN.md)).
- **Hands-on change**: compile `starter/BANK-ENTRY.COB`, first have it return RC12, then complete the TODOs so `normal` passes (compare with the `instructor` reference implementation).
- **Reproducible failure**: compile `experiments/build-failure/BROKEN-PERFORM.COB` and `BROKEN-AREA.COB`; locate the failing line from diagnostics and explain the reason.
- **Plugin/terminal**: use plugin diagnostic underlines; in the terminal use `cobc -fsyntax-only`.

### Lesson 01.3 DIVISION/SECTION/Paragraph, periods and scope; fixed/free format

- In the reference source, identify the four DIVISIONs, the `1000-MAIN` paragraph, and the period boundaries of each paragraph.
- **Hands-on change**: compare `experiments/columns/FIXED.COB` and `FREE.COB` (same logic, two formats) and confirm identical output; then copy `TRUNC-BAD.COB.src` to `.COB`, compile/run, and explain why the result is `11112`; repair it with `TRUNC-GOOD.COB` to get `111111`.
- **Reproducible failure**: deliberately extend a line beyond column 72 and observe silent compiler truncation (no error, wrong result).
- **Plugin/terminal**: use the ruler and overflow warning in the plugin; use `awk` for column width and `cobc` to compile and verify.

Reference implementation, root causes, hint ladder, and grading notes: `instructor/modules/01-foundations/`.
