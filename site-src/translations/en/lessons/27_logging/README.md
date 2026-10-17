---
_translated_from: lessons/27_logging/README.md
_translated_by: site-src/translation agent
---

# Lesson 27: Logging — Write What Happened Overnight to a File That Will Be There in the Morning

The screen output of an overnight batch is gone by the next day. This lesson adds a separate `batch.log` to the validation flow from Lesson 26. It records the batch start, every record read, every business rejection, every system failure, and the batch end, one fixed `KEY=VALUE` event per line. The next day, the on-call operator can use this file alone to answer “did it finish, which record failed, and should it be rerun?”

## The Business Setting

At 2:40 a.m. on Wednesday, the on-call phone rings. The overnight end-of-day validation job finished with exit code `1`. But its screen is long gone: the terminal window closed with the job, and every line printed during that run has vanished by morning.

The first questions are not “what is wrong with the code?” They are three more practical ones: **did this batch finish? Which record had a problem? Is it worth rerunning?** If the program only prints to the screen, the only option is to feed it the entire input again and watch a rerun. But the rerun overwrites the previous result files, so you erase the evidence yourself. It is almost inevitable that a decision made at 3 a.m. this way will be wrong.

That is why real jobs open an **independent log file** outside the screen. It needs to answer: the batch started (`BATCH_START`); which record was read (`RECORD_READ NO=004 ACCOUNT=A00004`); which record was rejected as a business matter and why (`BUSINESS_REJECT ... REASON=BAD_AMOUNT`); whether there was a system failure (`SYSTEM_ERROR`); and how many records were accepted and rejected (`BATCH_END INPUT=005 ACCEPTED=002 REJECTED=003`). The on-call operator does not need to read the source code; they need these lines.

There is one uncomfortable detail this lesson must make clear: a log is also a file, and it must be opened, written, and closed. **If it fails, it cannot report its own failure in its own file.** That may sound circular, but it is real. The “Log Format and Lifecycle” section below shows exactly where this boundary lies.

(This is an educational scenario. The institution, times, and record counts exist only to explain the problem and do not represent real data from a real institution.)

## Why Learn This Now

In Lesson 26, you learned to distinguish a “business rejection” from a “system failure”: bad records go to `rejected.txt`, and a real I/O failure stops processing and returns a nonzero code. The classification is correct, but the evidence remains in only two places: the screen and two result files.

Neither gives you the whole story. `rejected.txt` contains only the account number and reason (`A00002|BAD_AMOUNT`), **not the record number**, so you cannot tell which input line it came from. The two result files have **no batch boundary**, so you cannot tell whether the run ended normally or stopped halfway through. A system failure leaves no record at all. The screen is even less durable; it does not survive the night.

You might say, “Why not redirect the program’s output to a file and call that a log?” That does preserve the text, but what it preserves is a sentence for a person to read: `拒否口座=A00002 REASON=BAD_AMOUNT`. Fields are separated by spaces, and there is no record number. The other use of a log is **machine reading**: scheduler and on-call scripts need to find `REJECTED=003` directly, instead of guessing which part of a sentence is a number with a regular expression. So the format must be agreed in advance: one event per line, `KEY=VALUE`, and a fixed field order.

There is one more distinction to remember: result files are **deliverables**, while a log is a **process record**. `accepted.txt` is delivered to downstream posting; `batch.log` is kept for people and schedulers to investigate. Neither can replace the other.

## What This Knowledge Point Is and What Problem It Solves

**What it is.** Add a channel through which the program can “speak”: write the batch start, each record read, every business rejection, every system failure, and the batch end to a **separate file**, one event per line in a fixed `KEY=VALUE` format. The tools are the same ones used earlier in this course: `SELECT` + `OPEN OUTPUT` + `WRITE`. The difference is that the records are not business data; they describe “what happened overnight.”

**What business problem it solves.** It moves facts from memory and the screen onto disk in a form machines can read too. It addresses three concrete questions: did the job finish (`BATCH_END` counts for input/accepted/rejected); which record was bad (`NO=` record number + `ACCOUNT=` account number + `REASON=` reason); and should it be rerun (`SYSTEM_ERROR` flag).

There is one side effect you need to understand: **the log is a file too**. It has its own OPEN/WRITE/CLOSE status, and it can fail to open, write, or close. It **cannot record its own failure in itself**; those three failures can only be reported on the screen and through the exit code. This is an inherent boundary of a logging system, not something omitted from this lesson. See “Log Format and Lifecycle” for where each failure occurs.

**When not to use it this way, and what happens if it is misused.** Misusing a business log costs more than getting the syntax wrong:

- **Treating a log as a result file.** Downstream jobs need accepted transaction details from `accepted.txt`; the log is not a deliverable. Conversely, reconciling business data from log contents confuses the process with its product.
- **Expecting it to include all the features of a production logging system.** The batch ID is hard-coded as `TRAINING-001`; there is no timestamp or run ID, no redaction, no retention period, and no access control. If logs from two days are placed together, you cannot tell which run is which from the file alone. Those features must be added before using this file for accountability.
- **Assuming “there is a `BATCH_END`, so everything is fine.”** `BATCH_END` is written **before** the log is closed. Its presence does not prove that the log closed successfully or that the log and result files were delivered atomically. A rerun uses `OPEN OUTPUT` and overwrites the entire previous record of what happened.

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you can:

- Write the batch start, record reads, business rejections, system failures, and batch end to a separate log file.
- Locate an input record using its record number, account number, and rejection reason.
- Record business events and file I/O failures as `BUSINESS_REJECT` and `SYSTEM_ERROR`, respectively.
- Check the log’s own OPEN/WRITE/CLOSE status and explain why the log cannot record its own failures.
- Compare the counts at the end of the log with standard output and result files to decide whether the batch finished completely.

Limits: the log uses a fixed educational `KEY=VALUE` format, and the batch ID is `TRAINING-001`. It has no timestamp, run ID, environment, input signature, or operator context; it does not redact data or provide retention or access controls. There is **no** guarantee of atomic delivery between log and result files, and this lesson does not implement reruns.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not add `-std=cobol85`); source is fixed format.
- Linux terminal; no database or extra tools are required.
- `SELECT` uses relative file names. The program reads and writes four files in the current working directory: it reads `transactions.txt` and writes `accepted.txt`, `rejected.txt`, and `batch.log`.
- All three outputs use `OPEN OUTPUT`, which overwrites files of the same name on every run. This lesson therefore copies the input into `build/`, runs there, and writes the outputs there too. The repository ignores `build/`; remove everything afterward with `rm -rf build`.

## Log Format and Lifecycle

The log is line-oriented `KEY=VALUE` text, with one event per line. A successful run writes these events in order:

| Event | When it is written | Key fields |
|---|---|---|
| `EVENT=BATCH_START` | After the log opens successfully and before business files are opened | `ID=TRAINING-001` |
| `EVENT=RECORD_READ` | After an input record is read successfully | `NO=` record number starting at `001`; `ACCOUNT=` account number |
| `EVENT=RECORD_ACCEPTED` | After writing an accepted record succeeds | `NO=`, `ACCOUNT=` |
| `EVENT=BUSINESS_REJECT` | After writing a rejected record succeeds | `NO=`, `ACCOUNT=`, `REASON=` |
| `EVENT=SYSTEM_ERROR` | When an input or business-output file operation fails, if the log can still be written | `OP=`, `STATUS=` |
| `EVENT=BATCH_END` | After data files close and before the log closes | `INPUT=`, `ACCEPTED=`, `REJECTED=`, `SYSTEM_ERROR=` |

Remember one ordering decision: **the log opens before the business input is read**. If the log cannot open, the batch never starts. This prevents business data from being changed without recording what happened.

Each line is assembled with `STRING ... DELIMITED BY SIZE`; before assembling one, the program clears `WS-LOG-MESSAGE` so trailing characters from a longer previous event do not remain (`WS-LOG-MESSAGE` is `PIC X(100)`, enough for the longest event in this lesson, which is 66 characters).

**The log cannot record its own failure.** There are three failure points:

- **OPEN failure:** not even the first line can be written, so the failure can only be reported through standard output and the exit code. This path was tested in this lesson by making `batch.log` a directory; see the failure paths below.
- **WRITE failure:** the program stops processing later records and does not try to append to the log again. The failure can only be reported through standard output and the exit code. **This path was not injected in this lesson**; the behavior is supported only by the source code (see “Evidence Sources and Verification Scope”).
- **CLOSE failure:** this occurs after `BATCH_END` and can only be reported through standard output and process status. It was also **not injected**.

## Business Events and System Events

| Category | Typical case | Result files | Log event | Exit code |
|---|---|---|---|---|
| Business rejection | Bad width (`BAD_WIDTH`), nonnumeric amount (`BAD_AMOUNT`), zero amount (`ZERO_AMOUNT`) | Write to `rejected.txt` | `BUSINESS_REJECT` | `0` |
| System failure | OPEN, READ, WRITE, or CLOSE failure for input/output/log | Completeness not guaranteed | `SYSTEM_ERROR` (if the log can be written) | `1` |

A business rejection is a completed processing result: the batch ends normally and returns `0`. A system failure stops further reads and returns `1`. A file event counts as successful only when the corresponding WRITE status is `00`; this ensures that the `ACCEPTED`/`REJECTED` counts in the log match the actual line counts in the result files.

## Count Invariants and Checkable Results

| Invariant | In this lesson | Meaning |
|---|---|---|
| `INPUT = ACCEPTED + REJECTED` | `005 = 002 + 003` | Every record read has one destination |
| `ACCEPTED` = line count of `accepted.txt` | `002` = 2 lines | Log count matches the output |
| `REJECTED` = line count of `rejected.txt` | `003` = 3 lines | Same check for rejections |

The workflow is self-consistent only when all three—the standard output, log, and result files—agree.

## Run and Observe

**Input:** `transactions.txt` in this lesson’s directory (5 lines, each `account number|amount in cents`). Copy it into `build/`; the program runs there and writes three files there.

**Commands and what they do:**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                    # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_27 lesson.cob      # 编译，可执行文件也放进 build/
cp transactions.txt build/                       # 输入副本放进同一个工作目录
(cd build && ./lesson_27)                        # 在 build/ 里运行，输出落在那里
echo $?                                          # 查看退出码
diff build/batch.log expected-batch.log          # 与预期日志逐行比对
rm -rf build                                     # 一次清掉全部产物
```

**Expected results (normal path):**

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x` exit code | `0`, no compiler diagnostics |
| Standard output | 7 lines, shown below |
| Process exit code | `0` |
| Generated files | `build/accepted.txt` (2 lines), `build/rejected.txt` (3 lines), `build/batch.log` (12 lines) |

```text
受理口座=A00001
拒否口座=A00002 REASON=BAD_AMOUNT
拒否口座=A00003 REASON=ZERO_AMOUNT
受理口座=A00004
拒否口座=A00005 REASON=BAD_WIDTH
集計 入力=005 受理=002 拒否=003
システムエラー=N
```

`build/batch.log` should **match every line** in [`expected-batch.log`](./expected-batch.log) (verify with the `diff` above):

```text
EVENT=BATCH_START ID=TRAINING-001
EVENT=RECORD_READ NO=001 ACCOUNT=A00001
EVENT=RECORD_ACCEPTED NO=001 ACCOUNT=A00001
EVENT=RECORD_READ NO=002 ACCOUNT=A00002
EVENT=BUSINESS_REJECT NO=002 ACCOUNT=A00002 REASON=BAD_AMOUNT
EVENT=RECORD_READ NO=003 ACCOUNT=A00003
EVENT=BUSINESS_REJECT NO=003 ACCOUNT=A00003 REASON=ZERO_AMOUNT
EVENT=RECORD_READ NO=004 ACCOUNT=A00004
EVENT=RECORD_ACCEPTED NO=004 ACCOUNT=A00004
EVENT=RECORD_READ NO=005 ACCOUNT=A00005
EVENT=BUSINESS_REJECT NO=005 ACCOUNT=A00005 REASON=BAD_WIDTH
EVENT=BATCH_END INPUT=005 ACCEPTED=002 REJECTED=003 SYSTEM_ERROR=N
```

`build/accepted.txt` contains `A00001|00125` and `A00004|00999`; `build/rejected.txt` contains `A00002|BAD_AMOUNT`, `A00003|ZERO_AMOUNT`, and `A00005|BAD_WIDTH`.

**Output label glossary (actual label → meaning):** `受理口座` = accepted account; `拒否口座` = rejected account, with `REASON=` giving the reason (`BAD_WIDTH`/`BAD_AMOUNT`/`ZERO_AMOUNT`); `集計 入力/受理/拒否` = input/accepted/rejected counts; `システムエラー` = system-error flag (`N` means none, `Y` means one occurred). Log event names and field names are English interface markers: `EVENT=BATCH_START`/`RECORD_READ`/`RECORD_ACCEPTED`/`BUSINESS_REJECT`/`SYSTEM_ERROR`/`BATCH_END`; meanings of `ID`/`NO`/`ACCOUNT`/`REASON`/`OP`/`STATUS`/`INPUT`/`ACCEPTED`/`REJECTED`/`SYSTEM_ERROR` are given in the event table above.

**Failure paths (both tested):**

- **Input missing:** delete `transactions.txt` from `build/` and run. Standard output starts with `エラー=OPEN_INPUT STATUS=35`; `集計` counts are all `000`, `システムエラー=Y`, and the exit code is `1`. The log still contains three lines: `BATCH_START`, `SYSTEM_ERROR OP=OPEN_INPUT STATUS=35`, and `BATCH_END ... SYSTEM_ERROR=Y`. The input never opened successfully, so `INPUT=000`. `SYSTEM_ERROR=Y` in `BATCH_END` prevents “no records” from being mistaken for a successful empty batch.
- **Log cannot open:** make `batch.log` a directory in `build/` and run. Standard output is `エラー=ログOPEN 状態=37` / `集計 入力=000 受理=000 拒否=000` / `システムエラー=Y`, with exit code `1`. The business files are **not opened at all**: if the log cannot be started, the night’s work does not begin.

**Evidence sources and verification scope:** all three paths above were run in this workspace with GnuCOBOL 3.2.0. The executable and three output files were kept in the `build/` working directory; the lesson directory contains only source files and fixtures.

| Scenario | Clean starting state | Expected and observed |
|---|---|---|
| Normal path | Empty `build/`, with `transactions.txt` copied into it | Syntax check/compile exit code `0`; 7 stdout lines; exit code `0`; `accepted.txt` 2 lines, `rejected.txt` 3 lines, `batch.log` 12 lines; `diff batch.log expected-batch.log` has no differences. Matches |
| Input missing | No `transactions.txt` in `build/` (remove previous result files first) | Exit code `1`; 3 stdout lines (error + all-`000` summary + `システムエラー=Y`); exactly 3 log lines: `BATCH_START`, `SYSTEM_ERROR OP=OPEN_INPUT STATUS=35`, `BATCH_END ... SYSTEM_ERROR=Y`. Matches |
| Log cannot open | Make `batch.log` a directory in `build/`, with the input copy present | Exit code `1`; stdout has `エラー=ログOPEN 状態=37`, an all-`000` summary, and `システムエラー=Y`; neither `accepted.txt` nor `rejected.txt` is created. Matches |

**Not verified (not presented as a conclusion):**

- **Log WRITE/CLOSE failures were not injected.** Making `WRITE`/`CLOSE` return something other than `00` requires a failure in the underlying write operation. This lesson has no reliable way to inject one, and none was tested. Therefore “WRITE failure → print status → stop later records → return 1” and “CLOSE failure → print status → set error flag → return 1” are currently supported only by the source code.
- **`FILE STATUS = "00"` does not mean the data has reached disk.** The code has no flush operation, so status `00` only says that the write call was accepted. This is an inference from the source, not separately tested here; Lesson 16 has observed verification notes about this kind of buffering boundary.
- Log OPEN failure was tested (the “Log cannot open” row above). The only READ-related failure this lesson can trigger is failure to open the input; an error during reading was not injected either.

**Environment detail actually observed:** running the executable in this workspace prints `Warning: program compiled against libxml 212 using older 209` on standard error. This is a linked-library version warning from the environment, not business output; its source component has not been identified.

## Modification Exercise

Do both tasks in the `build/` working directory; do not change the repository fixture. Start with a clean `build/` (`mkdir -p build`, compile, and `cp transactions.txt build/`):

1. Change `A00002|00X50` in the input to `A00002|00150`. Confirm that the record changes from a business rejection to acceptance, its log event changes from `BUSINESS_REJECT` to `RECORD_ACCEPTED`, and the counts in `BATCH_END` change.
2. Delete `build/transactions.txt`, run the program, and check the exit code and the order of the `BATCH_START`, `SYSTEM_ERROR`, and `BATCH_END` events in `build/batch.log`.

Before finishing, check the count invariant (`INPUT = ACCEPTED + REJECTED`, and each count matches the line count in its result file). The full exercise and expected results are in [`exercise.md`](./exercise.md); the reference answer is in [`answer.md`](./answer.md).

## Transfer Exercise

Add a business rejection rule for “duplicate account number” and write both the first record number and the duplicate record number to the log. Then design a multi-batch input plan in which every run has a unique batch ID. Explain how to avoid mistaking `BATCH_END` for proof that all outputs were delivered atomically. Do not log complete customer privacy data, and do not omit the ending status of a failed batch. The prompt is in [`exercise.md`](./exercise.md); no answer is provided.

## Follow the Real Workflow

In a complete overnight pipeline, this lesson’s log sits between validation and delivery:

1. **Lesson 26 is upstream.** Its validation program reads transactions one at a time, routes bad records to `rejected.txt`, and stops with a nonzero exit code on a real I/O failure. It already distinguishes business rejections from system failures, but leaves no trace overnight. This lesson gives it a “diary.”
2. **This lesson’s step.** Validation results still go to two result files, while each event from the same run is written to `batch.log` in a fixed format. There is no second program: the log is written as part of the same batch, at the cost of one extra `OPEN OUTPUT` and several `WRITE`s.
3. **Who looks at it overnight.** The scheduler recognizes only the exit code. The on-call operator checks that first, then reads `batch.log`: is the last line `BATCH_END`, do the counts make sense, and is there a `SYSTEM_ERROR`? The screen output is already gone; the log is the only evidence left.
4. **Who looks at it during the day.** Reconciliation compares `INPUT=005` in `BATCH_END` with the upstream file’s line count. The review team uses `NO=` to find rejected records in the input (a record number is useful here; an account number alone does not identify the input line).
5. **Lesson 28 follows.** It turns validation, logging, and result reporting into a repeatable project with multiple programs and Copybooks, and checks the log line by line against `expected-batch.log`. Lessons 31 and 32 extend the same “batch + counts + failure evidence” approach to reconciliation between files and SQLite, adding events such as database connections and synchronization results.

In short, this lesson is the **only place in this chain that leaves a written record of the process**. Result files prove what the output was; only the log proves whether processing completed and where it stopped.

## What Happens When This Code Goes into Production

- **Who schedules it:** the overnight batch scheduler, after the upstream transaction file is ready. It recognizes the executable path and exit code; it does not look at the screen or read the log.
- **Who reads the log:** the on-call operator who was called in. They check the exit code first, then the `BATCH_END` line and `SYSTEM_ERROR`. How clearly the log is written determines how long they will be awake.
- **Who is called when something goes wrong:** someone is alerted when the exit code is nonzero. If the exit code is `0` but counts do not match the upstream file, reconciliation will ask about it the next day. That case is more troublesome because there is no alert.
- **How the next system receives it:** downstream programs rarely consume the log; it serves people and schedulers. The business deliverables are still `accepted.txt` and `rejected.txt`, which go to the modular project and capstone in later lessons.
- **The likeliest first-month incident:** treating the log as immutable evidence. `batch.log` is recreated with `OPEN OUTPUT`, so a rerun erases the previous run’s evidence. This lesson has no run ID or timestamp, so logs from different days—or two runs on the same day—look identical. Someone may compare a log from a morning rerun with the afternoon’s result files and find that the counts do not match. The incident makes no noise, but it wastes a lot of time.
- **What it does not do yet:** unique run IDs, timestamps, log retention and access controls, redaction, reruns, and rules for delivering logs and result files (what comes first, and how to recover if interrupted). None are implemented. Add them before relying on this as a production audit trail.

## References

- [GnuCOBOL Programmer’s Guide: LINE SEQUENTIAL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#ORGANIZATION-LINE-SEQUENTIAL)
- [GnuCOBOL Programmer’s Guide: STRING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#STRING)
- [GnuCOBOL Programmer’s Guide: FILE STATUS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SELECT)
- [Course directory](../DIRECTORY.md)
- Repository course home: [README.md](../../README.md)
