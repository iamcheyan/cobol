---
_translated_from: lessons/28_modular-batch-project/README.md
_translated_by: site-src/translation agent
---

# Lesson 28: Modular Integration — Turn the Batch into a Reproducibly Buildable Project

This lesson does not teach new syntax. It shows how to **assemble the parts** from the previous lessons into a project: the main program handles flow and counts; posting and reporting are separate subprograms; all three share interfaces from Copybooks; and a `build.sh` script fixes syntax checking, separate compilation, linking, running, and cleanup into four actions. The outcome is simple: nobody needs to remember the compile order, and changing a shared declaration triggers a full rebuild.

## The Business Setting

It is Thursday at 4 p.m. The team lead comes over: clearing needs another field in the account record, it must go live tonight, and the downstream report depends on it.

You open the project and find that the record definition is not in the main program but in a `.CPY` file. You feel relieved: “I only need to change it in one place.”

But more than one program uses that declaration. The main program uses it, as do the posting module and the report module. If you take a shortcut and recompile only the main program, then link it with yesterday’s `post_transaction_28.o` and `report_account_28.o`, those two old object files still expect the balance at its **old byte offset**. The linker will not stop you. It checks names and call shapes, not whether both sides have the same understanding of the same memory. The program runs, the exit code is still `0`, and the account balance is wrong.

That is the problem this lesson addresses. The hardest part is that **nothing reports an error**: no compiler error, no file status code, and the account report’s numbers may still look plausible. When someone finally notices the incorrect balance, all you have is an executable. Which object files were used to build it, and in what order? Nobody recorded the compile order, so there is no answer that night.

(Educational demonstration: the roles, time, and amounts here explain the problem and are not real data from an institution.)

## What This Knowledge Point Is and What Problem It Solves

**What it is.** In plain language, divide a large program that “does everything” into three parts: the main program manages flow and counts; a posting subprogram applies business rules; and a report subprogram only reads and displays the results. The parts no longer rely on a verbal agreement about parameter order. They put field declarations in a Copybook and all `COPY` the same definition. Then add one entry-point script that fixes compilation and running as four commands. In technical terms, this is a modular project with a main program, called subprograms, and shared Copybooks. At build time, each module produces an object file, and only the main program is compiled with `-x` to create the executable.

**What business problem it solves.**

- **One definition for each interface.** Change a field width or order once, and all three modules use the same declaration. The real saving is not typing time; it is preventing incidents such as “I changed it but forgot to tell someone.”
- **The script records the build order instead of relying on memory.** A new colleague, an on-call operator woken at night, and you three months later all run the same command. A fixed entry point is what lets you say that this run used the same build path as the previous one.
- **Responsibilities are clearly divided.** Only the posting module can change the balance; only the main program can change counts; the report module reads only. When something goes wrong, it is faster to ask “who owns this part?” than search hundreds of lines.

**When not to split it this way, and what can go wrong.**

- Splitting modules before the logic has settled freezes changing rules into interfaces. Every later change requires a full rebuild and may slow you down. The single-file programs in Lessons 01–22 are the right choice when the design is still simple.
- Do not expect the compiler to protect you. Obvious mismatches such as field names or parameter counts may be caught at compile or link time. But `cobc` does not check a changed field width when only one module is recompiled; it can simply produce incorrect results. The actual guardrail is **one shared interface definition plus a full rebuild every time**.
- Do not mistake `build.sh` for a production build system. It does not pin the compiler version, record the ABI, version artifacts, perform incremental builds, or derive a dependency graph. A production environment needs more (see “What Happens When This Code Goes into Production” at the end).

## Why Learn This Now

You learned `CALL` in Lesson 24, parameter direction with `USING` in Lesson 25, shared declarations in Lesson 23, separating business rejections from system failures in Lesson 26, and batch logging in Lesson 27. You already know all those pieces.

So what is left for this lesson? Not syntax, but **the discipline that organizes those pieces**. In Lessons 23–27, Copybooks, subprograms, and logging were demonstrated in single-file programs or minimal scripts. You could compile them any way you liked, and a compile mistake showed up immediately. Real projects do not give you that luxury:

- There may be three or more modules, so you must record which one to compile first and which one comes next.
- Interfaces are shared, so changing one affects every consumer. There must be a clear answer to “does this require a full rebuild?” without having to ask someone.
- Syntax must be checked before running, and the generated artifacts must be easy to clean up afterward. Otherwise, the directory fills with partial products from previous runs, and nobody can be sure which one is being executed.

You might think this is just a shell script. It is, but it enforces a discipline: **one fixed entry point, one interface definition, and one reproducible build path.**

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you can:

- Put shared records and status fields in Copybooks so the main program and subprograms compile from the same declarations.
- Split batch control, posting rules, and reporting into three program units and explain which state each one owns.
- Pass mutable records with `CALL ... USING BY REFERENCE` and explain who writes each status field and who maintains counts.
- Use `build.sh check|build|run|clean` for syntax checks, module compilation, linking, execution, and cleanup.
- Compare standard output and the log line by line with `expected-output.txt` and `expected-batch.log`.

Limits: the sample transactions are hard-coded in the main program, and no external input file is read. The build script is for a local, single-machine workflow; it does not pin the compiler version, ABI, or artifact version. File input is covered in Lessons 15–22, logging and error classification in Lessons 26 and 27, and database batches in Lessons 29–32.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not add `-std=cobol85`); source is fixed format.
- Linux terminal + `bash`; `build.sh` needs `cobc` on `PATH` (you can set `COBC` to use another compiler command).
- The build directory defaults to the lesson’s `build/` (override it with `BUILD_DIR`). The repository ignores `build/`; `./build.sh clean` removes it. The program runs inside the build directory, so `batch.log` and the object files are placed there.

## Project Contents

| File | Responsibility |
|---|---|
| [`lesson.cob`](./lesson.cob) | Main program: opens the log, initializes the account, prepares five sample transactions, `CALL`s the posting module, summarizes statuses, and writes the log |
| [`post_transaction_28.cob`](./post_transaction_28.cob) | Posting module `POST-TRANSACTION28`: validates account number and type, updates the caller’s balance on success, and returns a result in the status field |
| [`report_account_28.cob`](./report_account_28.cob) | Report module `REPORT-ACCOUNT28`: reads the final account and batch counts and displays them |
| `copybooks/ACCOUNT-REC.CPY` | Account record: account number `X(10)`, customer number `X(8)`, balance `9(7)V99` (27 bytes total) |
| `copybooks/TRANSACTION-REC.CPY` | Transaction record: account number `X(10)`, type `X`, amount `9(7)V99` (20 bytes total) |
| `copybooks/POST-STATUS.CPY` | Posting result status `X(12)`: `POSTED`, `INSUFFICIENT`, `BAD_TYPE`, `NO_ACCOUNT` |
| `copybooks/BATCH-COUNTS.CPY` | Batch counts: `POSTED-COUNT` and `REJECTED-COUNT` (each `9(3)`) |
| [`build.sh`](./build.sh) | Entry point for building and running (`check` / `build` / `run` / `clean`) |

All interfaces live under `copybooks/`, and each of the three programs `COPY`s only the ones it needs. Why use four Copybooks instead of one large one? Each file describes the shape of **one** interface: the account record, transaction record, posting status, or batch counts. The impact of changing a definition is easy to see by checking which programs use it.

- The account record is 27 bytes = `X(10)` + `X(8)` + `9(7)V99`; the main program, posting module, and report module all use it.
- The transaction record is 20 bytes = `X(10)` + `X(1)` + `9(7)V99`; the main program and posting module use it.
- Status `X(12)` is long enough for the longest value, `INSUFFICIENT`; the main program and posting module use it.
- The two counts are `9(3)`, so they display as `002`, `003`; the main program and report module use them.

The `V` in `9(7)V99` is an **implied decimal point** and takes no bytes. The 27- and 20-byte record widths count only the nine digits. Amounts are always passed under this decimal-field contract; they do not use platform-dependent binary layouts such as `BINARY-LONG`. Every module sees the balance as the same sequence of decimal digits.

## The Four `build.sh` Actions

```sh
./build.sh check    # 组合语法检查，不生成任何产物
./build.sh build    # 编译两个子程序为 .o，再链接出 build/lesson_28
./build.sh run      # 构建后在 build/ 里运行，输出与 batch.log 都落在 build/
echo $?             # 查看退出码
./build.sh clean    # 删除 build/（可执行文件、目标文件与日志）
```

Here is what each action does:

- **`check`** runs `cobc -I copybooks -fsyntax-only` over all three source files. It creates no files; it answers only “can these files be parsed?”
- **`build`** runs `check` first, compiles the two subprograms separately to `.o` files, then uses `-x` to link the main program and both object files into `build/lesson_28`.
- **`run`** runs `build`, changes into `build/`, and starts the executable. `batch.log` uses a relative file name, so it is written to the **runtime working directory**, `build/`.
- **`clean`** runs `rm -rf build`, removing the executable, both `.o` files, and the log.

A few details can cause problems if left unstated:

- `build` recompiles all three source files from scratch every time. That is the value of this guardrail: when you use the script, you cannot accidentally combine a new main program with yesterday’s old `.o` files.
- An invalid action name (for example, `./build.sh unknown`) prints usage and returns `64`.
- If `cobc` is not on `PATH`, or `COBC` names a command that does not exist, the script returns `127`.

## A Walk Through the Five Transactions

The account starts with a balance of `1000.00`. The five sample transactions are: deposit `125.50`, withdrawal `25.25`, overdrawn withdrawal `2000.00`, unknown type `X`, and a deposit for nonexistent account `A000000099`. Only the first two are successful:

| No. | Type | Amount | Result status | Reason |
|---:|---|---:|---|---|
| 1 | `D` | 125.50 | `POSTED` | Deposit succeeded |
| 2 | `C` | 25.25 | `POSTED` | Sufficient balance |
| 3 | `C` | 2000.00 | `INSUFFICIENT` | Exceeds current balance; balance is unchanged |
| 4 | `X` | 1.00 | `BAD_TYPE` | Type is not `D` or `C` |
| 5 | `D` | 1.00 | `NO_ACCOUNT` | Account number does not match the master record |

Count invariant: `記帳 + 拒否 = 5`, which is `2 + 3 = 5` in this lesson. The balance can also be checked by hand: `1000.00 + 125.50 − 25.25 = 1100.25`.

It is worth repeating the **nature** of the three rejection codes, because they are easy to mistake for “the program is broken”: `INSUFFICIENT`, `BAD_TYPE`, and `NO_ACCOUNT` are **business outcomes**, not build or file-system failures. The overdraft returns `INSUFFICIENT` without changing the balance; the unknown type returns `BAD_TYPE`; the mismatched account number returns `NO_ACCOUNT`. The batch finishes normally with exit code `0`.

## Source Reading Path

It is quicker to read in the order “how does data flow, and who changes each status?” than to go line by line from the top:

1. `0000-MAIN` ([`lesson.cob`](./lesson.cob#L31), lines 31–53): opens the log first. Only if it opens successfully and there is no I/O failure does the program `INITIALIZE` the account and counts, run five transactions, `CALL "REPORT-ACCOUNT28"`, write `BATCH_END`, and close the log. If `WS-IO-ERROR` or `WS-UNKNOWN-STATUS` is `Y`, it sets `RETURN-CODE` to `1`.
2. `1000-INITIALIZE-BATCH` (lines 54–58): account `A000000001`, customer `C0001001`, balance `1000.00`. This is the only source of data in the lesson; the samples are hard-coded here and in the five setup paragraphs from 1100 through 1500.
3. `2000-CALL-POSTER` (lines 84–98): the common exit path for each transaction. It first clears `WS-POST-STATUS` to spaces; otherwise, the previous transaction’s status remains in the `X(12)` field. Then it calls `CALL "POST-TRANSACTION28" USING BY REFERENCE` with three items: account record, transaction record, and status.
4. `2100-REPORT-RESULT` (lines 99–114): `EVALUATE` routes by status and updates the counts. `POSTED` increments `記帳`; the three rejection codes increment `拒否`; `WHEN OTHER` records an unknown status and makes the exit code nonzero. For display, `FUNCTION TRIM(... TRAILING)` removes trailing spaces from `X(12)`; otherwise you would see a string of spaces after `POSTED`.
5. [`post_transaction_28.cob`](./post_transaction_28.cob#L15) (lines 15–38): compare account numbers first; a mismatch returns `NO_ACCOUNT`. If they match, check the type: `D` adds to the balance, `C` checks the balance, and anything else returns `BAD_TYPE`. **Only this module can change the balance**; it does not touch counts or logging.
6. [`report_account_28.cob`](./report_account_28.cob#L13) (lines 13–20): reads the account and counts and displays two lines. This is what a read-only consumer should look like.
7. `1050-RUN-TRANSACTIONS` (lines 115–128): runs the five transactions in order, checking `WS-IO-ERROR` before each. If a log write fails, it stops; later transactions are not posted.

## Run and Observe

**Input:** none from outside. The five sample transactions are written into the main program.

**Commands and what they do:** the four actions from the previous section. Two details that are easy to miss: `check` produces no artifacts, and `run` rebuilds before running.

**Expected results:**

| Observation | Expected value |
|---|---|
| `./build.sh check` exit code | `0`, no diagnostics |
| `./build.sh build` exit code | `0`, no compiler warnings |
| `./build.sh run` exit code | `0` |
| Standard output | 12 lines, matching [`expected-output.txt`](./expected-output.txt) line by line |
| `build/batch.log` | 7 lines, matching [`expected-batch.log`](./expected-batch.log) line by line |
| Generated files | `build/lesson_28`, two `.o` files, `build/batch.log` |

```text
呼出=過帳 口座=A000000001 TYPE=D 金額=0000125.50
呼出=戻り 状態=POSTED
呼出=過帳 口座=A000000001 TYPE=C 金額=0000025.25
呼出=戻り 状態=POSTED
呼出=過帳 口座=A000000001 TYPE=C 金額=0002000.00
呼出=戻り 状態=INSUFFICIENT
呼出=過帳 口座=A000000001 TYPE=X 金額=0000001.00
呼出=戻り 状態=BAD_TYPE
呼出=過帳 口座=A000000099 TYPE=D 金額=0000001.00
呼出=戻り 状態=NO_ACCOUNT
口座=A000000001 CUSTOMER=C0001001 BALANCE=0001100.25
集計 記帳=002 拒否=003
```

**Output glossary (actual label → meaning):** `呼出=過帳` = issue a posting call (`口座` account number, `TYPE` type, `金額` amount); `呼出=戻り 状態` = status returned by the call; `口座`/`CUSTOMER`/`BALANCE` = final account report; `集計 記帳=.. 拒否=..` = posting/rejection count summary.

**`build/batch.log`:**

```text
EVENT=BATCH_START ID=TRAINING-001
EVENT=TRANSACTION NO=001 ACCOUNT=A000000001 TYPE=D STATUS=POSTED
EVENT=TRANSACTION NO=002 ACCOUNT=A000000001 TYPE=C STATUS=POSTED
EVENT=TRANSACTION NO=003 ACCOUNT=A000000001 TYPE=C STATUS=INSUFFICIENT
EVENT=TRANSACTION NO=004 ACCOUNT=A000000001 TYPE=X STATUS=BAD_TYPE
EVENT=TRANSACTION NO=005 ACCOUNT=A000000099 TYPE=D STATUS=NO_ACCOUNT
EVENT=BATCH_END POSTED=002 REJECTED=003 IO_ERROR=N
```

Count the lines in standard output and the log independently. The screen has 5 transactions × 2 lines + 1 account report line + 1 count line = 12 lines. The log has `BATCH_START` + 5 transaction events + `BATCH_END` = 7 lines. The status for `NO=003` in the log must match `INSUFFICIENT` on the fourth screen line (`呼出=戻り`). If they differ, the counts or log were not derived from the same status value; that is a bug.

### Evidence Sources and Verification Scope

| Scenario | Clean starting state | Expected | Actual command and observation | Conclusion |
|---|---|---|---|---|
| Normal path | No `build/` after `./build.sh clean` | All three exit codes `0`; 12 stdout lines; 7 log lines | Run `./build.sh check`, `build`, `run`, then `diff` both expected files | No differences; matches |
| Invalid argument | None | Returns `64` and prints usage | `./build.sh unknown` | Matches |
| Compiler command missing | None | Returns `127` | `COBC=no-such-cobc-xyz ./build.sh check` | Matches |
| Log cannot open | Make `batch.log` a directory in `build/` and run | Exit code `1`; posting module is not called | Standard output contains only `エラー=ログOPEN 状態=37` | Matches |
| Exercise 1 | Original source; change `2000.00` in `1300-POST-OVERDRAFT` to `1000.00` | Balance `0000100.25`, `記帳=003 拒否=002` | Run `./build.sh run` and check that log `NO=003` becomes `POSTED` | Matches |
| Exercise 2 | Original source; change type `"X"` in `1400-POST-UNKNOWN-TYPE` to `"D"` | Balance `0001101.25`, `記帳=003 拒否=002` | Run `./build.sh run` and check log `NO=004 ... TYPE=D STATUS=POSTED` | Matches |

**Not verified (not presented as a conclusion):**

- **The standard-error line `Warning: program compiled against libxml 212 using older 209`.** This is a linked-library version warning from the runtime environment, not business output. It was not investigated because the component that causes it has not been identified and it is not needed to check the lesson’s results; actual program output is on standard output, with exit code `0`.
- **Log WRITE/CLOSE failure behavior is supported only by the source; it was not run.** A stable test needs a target that allows `OPEN` but rejects `WRITE`. This lesson has no such fixture, so the behavior is documented from the code only.
- **The unknown-status branch for a posting module result cannot be reached in the sample.** The subprogram writes only four literal statuses, and no external input can produce a fifth. Thus the behavior “count as rejected and set a nonzero exit code” is also supported only by the source.
- **“Recompiling only the main program after changing a Copybook can post incorrectly” is a risk description, not an observed result in this lesson.** The script performs a full rebuild every time; no comparison was made by deliberately keeping old `.o` files and manually compiling only the main program. Treat this as a production incident to understand, not a measured result.

## Build Errors and Log Errors

- If the log cannot be opened, the main program reports `エラー=ログOPEN 状態=37`, exits with `1`, and **does not call the posting subprogram** (observed).
- If log WRITE or CLOSE fails, the code sets a system-error flag and returns `1` (per source; not injected).
- `BATCH_END` is written **before** the log is closed. If log CLOSE fails afterward, its last line may still say `IO_ERROR=N`; use standard output and the exit code in that case (per source).
- A log OPEN failure cannot be written to the log itself, so it can only be reported through standard output and the exit code. This is an inherent boundary of logging, not an implementation defect (observed).
- If the posting module returns an unknown status, the main program counts it as rejected and sets a nonzero exit code (per source; unreachable in the sample).

## Modification Exercises

Start from the original source for both changes. Rerun `./build.sh run` so the subprograms are recompiled and the main program is relinked:

1. Change the amount in `1300-POST-OVERDRAFT` from `2000.00` to `1000.00`. The withdrawal succeeds, the balance becomes `0000100.25`, the counts become `記帳=003 拒否=002`, and the status for log `NO=003` changes from `INSUFFICIENT` to `POSTED`.
2. Change the type in `1400-POST-UNKNOWN-TYPE` from `"X"` to `"D"`. The unknown-type rejection becomes a valid deposit, the balance becomes `0001101.25`, and the counts are also `記帳=003 拒否=002`. The type and status in log `NO=004` become `TYPE=D STATUS=POSTED`.

You changed the source and ran the script for both exercises, so you can see the purpose of a full rebuild: if you skip it, the source you edited and the executable you ran do not match. The complete prompts and expected results are in [`exercise.md`](./exercise.md); the reference answer is in [`answer.md`](./answer.md).

## Transfer Exercise

Change the sample transactions to file input, and move “read / EOF / bad-record classification” into a separate module. Keep the account, transaction, and status Copybooks as the only interface definitions. Explain how to ensure that all affected modules are recompiled and linked after a Copybook change. Do not disguise a business rejection as a compile failure, and do not redefine record layouts already declared in Copybooks. The prompt is in [`exercise.md`](./exercise.md); no answer is provided.

## Follow the Real Workflow

This lesson sits between “components” and “a project” in a full overnight pipeline:

1. **Upstream is the file batch.** Reading transactions from files and handling EOF and bad records are covered in Lessons [15](../15_sequential-file-read/README.md) through [22](../22_file-processing-practice/README.md). The sample in this lesson is still hard-coded; changing it to file input is the transfer exercise above.
2. **This lesson delivers a project, not just logic.** It produces three things: three compilable modules, one shared interface definition, and one fixed build command. Lesson [29](../29_embedded-sql/README.md) adds a database snapshot at the `lesson.cob` boundary; it depends on the module boundaries and Copybook contract established here.
3. **Logging supports on-call and reconciliation.** Lesson [27](../27_logging/README.md) defines the format and event categories for `batch.log`. This lesson puts each transaction’s status and the batch counts into that same contract so someone can reconcile them against the upstream count the next day.
4. **Keep track of interface changes.** Parameter order, direction, and status values between the main program and its two subprograms were developed across Lessons [23](../23_copybooks/README.md)–[25](../25_using-parameters/README.md). Once they are assembled into a project here, every interface change must rerun `check` and `build`; it is not enough to “change the source and commit it to git.”
5. **Later on,** Lessons [29–31](../29_embedded-sql/README.md) add real SQL, cursors, and file/database synchronization, and [Lesson 32](../32_bank-reconciliation-project/README.md) brings the whole chain together as a complete project.

In short, this lesson does not add a feature; it defines **where all the previous components come from, how to assemble them, and how to rebuild them**.

## What Happens When This Code Goes into Production

- **Who schedules it:** the overnight scheduler recognizes the build artifact path and exit code, not the screen. `build.sh` is for people and CI; the scheduler runs the `lesson_28` executable it produces.
- **Who reads its output and log:** on-call staff check the exit code first and then the final `EVENT=BATCH_END POSTED=.. REJECTED=.. IO_ERROR=..` line in `batch.log`. Remember that `IO_ERROR=N` does not mean everything is fine; the log CLOSE failure above is a counterexample.
- **Who is called when something goes wrong:** someone is called when the exit code is nonzero. First distinguish a “business rejection” (counted as rejected, exit code still `0`) from a “system failure” (log cannot open, write fails, or an unknown status appears). If they are mixed up, someone may be woken in the middle of the night because one customer has insufficient funds.
- **How the next system receives it:** this lesson has no output file; results are only on the screen and in the log. A real workflow must write posting results to a file (starting in [Lesson 16](../16_file-writing/README.md) and [Lesson 22](../22_file-processing-practice/README.md)) or a database (from [Lesson 29](../29_embedded-sql/README.md) onward).
- **The likeliest first-month incident:** the scenario from the opening—only recompiling the main program after changing a shared declaration leaves the old `.o` files using the old layout, and the accounts become wrong silently. A second risk is treating “it compiles locally” as proof that “this build is production-ready.”
- **What it does not do yet:** artifacts have no version; compiler version and options are not pinned; there is no incremental build or dependency graph; logs have no timestamp or unique run ID; reruns are not idempotent; sample transactions are hard-coded.

A production build also needs agreed compiler versions and options, a maintained module list, versioned artifacts and release paths, and the same `check`/`build` workflow in CI. This lesson demonstrates only “a repeatable local build”; none of the rest is implemented. Database batch construction and tooling are covered in Lessons 29–32.

## References

- [GnuCOBOL Programmer’s Guide: COPY](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#COPY)
- [GnuCOBOL Programmer’s Guide: CALL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#CALL)
- [GnuCOBOL Programmer’s Guide: PROCEDURE DIVISION USING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-USING)
- [GnuCOBOL Programmer’s Guide: FILE STATUS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SELECT)
- Repository course home: [README.md](../../README.md)
