---
_translated_from: lessons/26_error-handling/README.md
_translated_by: site-src/translation agent
---

# Lesson 26: Error Handling — Use `FILE STATUS` to Distinguish Business Rejections, EOF, and System Failures

A bank’s end-of-day batch may be missing its entire input file, contain malformed records, or be unable to write to the output directory. This lesson adds error classification to the file workflow from Lessons 15–25: read transactions one at a time, route bad records to a reject file and continue, but stop on a genuine file I/O failure, close files that were opened, and return a nonzero code. The result is evidence that can be checked to answer “which records were rejected, and did this batch count as a failure?” It can be reused by Lesson 27’s logging and the project skeletons in Lessons 28 and 32.

## The Business Setting

At 2:15 a.m., the scheduler starts this job on schedule. The upstream system’s export of the day’s transaction details is already in the shared directory. The program reads them one line at a time, writes records with invalid amount fields to a reject file, and writes the rest to an accepted file. No one is at the console during this time, and nobody is watching it run.

When the review team arrives in the morning, their first task is to open the reject list. It contains `A00002|00X50`: the third character of the amount is the letter `X`. This is not a system failure; someone mistyped a letter while entering the record. The transaction can be held for today while a teller calls the customer to verify it. Last night’s batch can still be posted as usual. This is a **business rejection**: a person will handle it the next day, so the exit code should remain 0.

Now consider a different day. The disk is full, or the upstream file was never exported. If the program merely prints “bad record found” and exits with code 0, the scheduler treats it as successful: the review team receives an incomplete list, and a downstream posting job proceeds with an accepted file missing most of its records. The real alert never fires; by the time reconciliation finds a discrepancy, it may be the next day or even the day after. This is a **system failure**: the exit code must be nonzero so the on-call operator is alerted.

The boundary this lesson draws determines two things: **who gets called in the middle of the night** and **how much manual work is needed the next day**. If the two cases are mixed up, either false alarms wake people every night or a real failure is waved away as “bad data.” (This is an educational scenario. The institution, times, and record counts exist only to explain the problem and do not represent real data from a real institution.)

## Why Learn This Now

In Lessons 15–25, you learned to open, read, and write sequential files; split fields at fixed widths; sort and match records; share record definitions with Copybooks; and pass parameters with `CALL ... USING`. But those lessons assumed that every file operation succeeded. The code often printed only a summary at the end, so it could not answer the question operations care about most: **did this run actually succeed?**

You might think that printing an error with `DISPLAY` is enough. The problem is that nobody sees the screen. At two in the morning nobody is at the console; the scheduler sees the output, but it only recognizes one thing: the process exit code. You can print ten lines saying “error,” but if the exit code is still 0, it will consider the job successful and start the next one.

That leaves three concrete gaps. First, a read error other than EOF does not trigger `AT END`, and the program may keep processing the previous record. Second, bad records and file failures are both reduced to messages, so the scheduler cannot tell them apart. Third, no one reports which files remain open after a failure or whether their results can still be trusted. This lesson fills those gaps with a transaction fixture of 12 bytes per line. Every conclusion can be recomputed from the exit code and result files on the spot; you do not have to take the documentation on trust.

## What This Knowledge Point Is and What Problem It Solves

**What it is.** A way to “check the record” after each file operation: immediately after `OPEN`, `READ`, `WRITE`, or `CLOSE`, inspect the `FILE STATUS` field associated with that file. This two-character status code tells you whether the operation succeeded (`00`), reached the end of the file (`10`), or encountered something else (`35`, `37`, `06`, and so on). Then use the status to decide three things: where the record goes, whether to continue reading, and whether the final exit code should be 0 or 1.

**What business problem it solves.** It separates “there is a problem with this data” from “this batch did not run successfully” into two different paths. A bad record is one transaction that needs manual review; the others continue as usual, and the exit code must stay 0. A file that cannot be opened or fails partway through makes the result untrustworthy, so processing must stop and return nonzero to trigger a rerun or alert an operator. **Where that line is drawn determines who gets called in the middle of the night and how much manual work is needed the next day.** Draw it incorrectly, and either false alarms happen every night or a real failure is silently swallowed.

**When not to use it this way, and what happens if it is misused.** A common mistake is “return nonzero for any error”: one customer entering an incorrect amount raises an alert for the whole batch, and after several unnecessary wake-ups the on-call operator may stop paying attention. That is more dangerous than no alert. The opposite mistake is “if the file opened, everything is fine”: treating a mid-stream read error as a business rejection lets the batch finish successfully even though the data is incomplete. Another assumption is that a `FILE STATUS` of `00` means the data has reached disk. The “Write Failure Boundary” below demonstrates why that is not necessarily true.

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you can:

- Read the `FILE STATUS` field for each file after `OPEN`/`READ`/`WRITE`/`CLOSE` and explain whether each nonzero status is a normal ending or a failure.
- Treat width, delimiter, and amount errors as **business rejections**: write them to `rejected.txt`, continue with later records, and keep the process exit code at 0.
- Treat a missing input file, an output that cannot be opened, or a non-EOF read error as a **system failure**: report the file operation and status, stop further processing, close only files that were successfully opened, and set `RETURN-CODE` to 1.
- Explain why `AT END` covers only status `10` and cannot replace a status check after `READ`.
- Cross-check the invariant `input record count = accepted count + rejected count` against the **line counts** of both result files, confirming that each record has exactly one destination.

Limits: this lesson does **not** provide atomic delivery or idempotent reruns, and a visible disk write failure cannot be injected in this environment (see “Write Failure Boundary” below). Batch IDs, business review of rejected records, logging, and recovery strategies are covered in Lessons 27, 31, and 32, respectively.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (**do not** add `-std=cobol85`); source is fixed format (indicator in column 7, Area A from column 8, Area B from column 12, and program text ending by column 72).
- Linux terminal; no database or extra tools are required.
- `SELECT` uses relative file names. The program reads and writes three files in the **current working directory**: it reads `transactions.txt` and writes `accepted.txt` and `rejected.txt`.
- Both outputs use `OPEN OUTPUT`, which **overwrites a file of the same name on every run**. This lesson therefore runs a copy of the input in `build/` to avoid writing results into the source directory; `build/` is ignored by `lessons/.gitignore`.
- When the executable runs, standard error prints `Warning: program compiled against libxml 212 using older 209`. This is an **environment warning** caused by dynamic library versions in this workspace, not business output, and is unrelated to the program’s `FILE STATUS` checks. Standard output contains only 7 lines of business text.

## Two Kinds of Failure, Two Different Outcomes

The input is a text file of daily transactions, one per line. The program validates each record at fixed widths, routes it to `accepted.txt` or `rejected.txt`, and prints a count summary. All the new capabilities in this lesson concern **the same nonzero outcome having different causes**:

- A business rejection (bad record) affects only the reject file and rejection count; it is **not a batch failure**. Later records are processed as usual and the exit code is 0.
- A system failure (a file cannot be opened, read, written, or closed) means **the batch result is untrustworthy**. Stop processing and return 1 so the scheduler knows that a rerun or manual intervention is needed.
- EOF (status `10`) is a **normal end signal**, neither a rejection nor a failure. An empty file also ends normally with 0 records and exit code 0.

The difference from the previous lesson: Lesson 25 focused on **how to pass parameters**; this lesson focuses on **how to judge the return status of each file operation**. We do not simply `DISPLAY` an error and continue, because that would leave the exit code at 0 and prevent the scheduler from distinguishing “there are rejected records” from “the input file is missing.”

## Input, Rules, and Output Contract

**Input fixture [`transactions.txt`](./transactions.txt):** 5 lines, 62 bytes total. Lines 1–4 are 12 bytes each, and line 5 is 9 bytes; line terminators are not included in the record lengths.

| Record | Fields | Width | Unit/value |
|---|---|---:|---|
| `transactions.txt` (input) | Account number + `\|` + amount | 6 + 1 + 5 = 12 | Amount is 5 digits, in the smallest currency unit (cents) |
| `accepted.txt` (output) | The first 12 input bytes, written back unchanged | 12 | Only records that pass every check |
| `rejected.txt` (output) | Account number + `\|` + reason | 6 + 1 + 12 | Reason is left-aligned and padded on the right with spaces |

Rules and fixture examples, applied one line at a time:

1. **Width:** first remove trailing padding spaces. The actual length must be 12; otherwise use `BAD_WIDTH`.
2. **Delimiter:** column 7 must be `|`; otherwise use `BAD_FORMAT`.
3. **Amount:** columns 8–12 must all be digits; otherwise use `BAD_AMOUNT`. If all digits are `00000`, use `ZERO_AMOUNT`.
4. The checks **short-circuit in order**: if the width is wrong, do not check the delimiter or amount.

| Fixture line | Bytes | Decision | Reason |
|---|---:|---|---|
| `A00001\|00125` | 12 | Accepted | — |
| `A00002\|00X50` | 12 | Rejected | `BAD_AMOUNT` (`X` is not a digit) |
| `A00003\|00000` | 12 | Rejected | `ZERO_AMOUNT` |
| `A00004\|00999` | 12 | Accepted | — |
| `A00005\|50` | 9 | Rejected | `BAD_WIDTH` |

**What counts as a failure (policy boundary):**

| Situation | Observed category | Program behavior | Return code |
|---|---|---|---:|
| Bad record (width/delimiter/amount) | Business rejection | Write to `rejected.txt`, continue reading | 0 |
| Input missing or unreadable | System failure | Report status after `OPEN`; do not open either output | 1 |
| Output path is not writable | System failure | Stop at `OPEN`, close only files already opened; an empty result file may remain if it was created | 1 |
| `READ` returns a status other than `00` or `10` | System failure | Report status and stop the loop | 1 |
| `WRITE`/`CLOSE` status is not `00` | System failure | Do not count that record as accepted; return 1 | 1 |
| `READ` returns `10` (EOF) | Normal ending | Exit the loop and close normally | 0 |

**Assumptions outside the contract:** The physical record limit comes from the `FD`’s `PIC X(20)` buffer, not the 12-byte business width. **Observed:** input lines of 21 bytes or more make `READ` return status `06`; the program treats this as a system failure and returns 1 (the record count does not increase). A 20-byte line with a line terminator can still be read and is rejected by the business width check as `BAD_WIDTH`. But a final line that is exactly 20 bytes and has no line terminator also reports `06` because the runtime cannot tell whether the line was truncated. Thus “bad width” applies only to lines that can be read; an overlong line is not a business rejection. The fixture has no duplicate accounts and the program does not check for duplicates. An empty file is valid input (0 records, return code 0).

## Run and Observe

**Input:** `transactions.txt` in this lesson’s directory (5 lines, 62 bytes). It is copied into `build/`; the program runs there, and result files are written there too.

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                    # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_26 lesson.cob      # 编译，可执行文件也放进 build/
cp transactions.txt build/                       # 输入副本（夹具只读，测试用副本）
(cd build && ./lesson_26)                        # 在 build/ 里运行
echo $?                                          # 查看退出码
rm -rf build                                     # 一次清掉可执行文件、输入副本与结果文件
```

**Expected results (observed):**

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x -Wall` exit code | `0`, no compiler diagnostics |
| Standard output | 7 lines, shown below |
| Standard error | 1 libxml environment warning (not business output) |
| Process exit code | `0` |
| `build/accepted.txt` | 2 lines, 26 bytes |
| `build/rejected.txt` | 3 lines, 54 bytes |

```text
受理口座=A00001
拒否口座=A00002 REASON=BAD_AMOUNT
拒否口座=A00003 REASON=ZERO_AMOUNT
受理口座=A00004
拒否口座=A00005 REASON=BAD_WIDTH
集計 入力=005 受理=002 拒否=003
システムエラー=N
```

**Glossary for key output labels (program output is in Japanese, as established elsewhere in the repository):** `受理口座=` accepted account; `拒否口座=` rejected account; `REASON=` rejection reason; `集計 入力=/受理=/拒否=` summary of input/accepted/rejected counts; `システムエラー=N` means no system failure (`Y` means there was one). Note that error labels mix ASCII and katakana: input-open failure is `エラー=入力OPEN 状態=` (as in Lessons 27 and 31), while the two output-open failures use `エラー=受理出力オープン` and `エラー=拒否出力オープン`.

`build/accepted.txt` (2 lines × 13 bytes = 26 bytes):

```text
A00001|00125
A00004|00999
```

`build/rejected.txt` (content lengths 17 + 18 + 16 bytes, plus line terminators = 54 bytes):

```text
A00002|BAD_AMOUNT
A00003|ZERO_AMOUNT
A00005|BAD_WIDTH
```

**Independent recomputation:** The 5 fixture lines yield two accepted records, `A00001` and `A00004`, whose amounts are numeric and nonzero. The other three are rejected: `A00002` has an `X` in the amount, `A00003` has a zero amount, and `A00005` is only 9 bytes long. Thus `input 005 = accepted 002 + rejected 003`, matching the 2 lines in `accepted.txt`, the 3 lines in `rejected.txt`, and the counts. The rejected lines are only 17/18/16 bytes because `LINE SEQUENTIAL` removes trailing padding spaces when writing a record, making them shorter than the `FD`’s `PIC X(19)` buffer.

**Meanings of `FILE STATUS` values (observed in this lesson):**

| Status | Where it occurs | Meaning | Handling in this lesson |
|---|---|---|---|
| `00` | All operations | Success | Continue along the corresponding branch |
| `10` | `READ` | End of file | Normal ending, return code 0 |
| `35` | `OPEN INPUT` | File does not exist | System failure, return code 1 |
| `37` | `OPEN` | Permission/access denied (input or output) | System failure, return code 1 |
| `06` | `READ` | Physical record error (observed here for input lines of 21+ bytes, or a final 20-byte line without a line terminator) | System failure, return code 1 |

## Source Reading Path

Read [`lesson.cob`](./lesson.cob) in the order “where does the status come from, and where does each case go?” Focus on how each check turns a status code into a decision:

1. `FILE-CONTROL` binds a two-character status field to each file: the input, accepted output, and rejected output use `WS-INPUT-STATUS`, `WS-ACCEPTED-STATUS`, and `WS-REJECTED-STATUS`. Every later checkpoint reads one of these fields. All three `SELECT`s use `LINE SEQUENTIAL` and relative file names.
2. `1000-OPEN-FILES`: open the input first; only after it succeeds, `OPEN OUTPUT` the two result files. Each successful `OPEN` sets its corresponding `WS-*-OPEN` flag. These flags determine which files `8000-CLOSE-FILES` closes.
3. `2000-PROCESS-INPUT`: the loop condition is `WS-END-OF-FILE = "Y" OR WS-SYSTEM-ERROR = "Y"`, so a system failure immediately stops further reads.
4. `2100-READ-ONE-RECORD`: `AT END` marks EOF only. A separate check after `READ` handles any status that is neither `00` nor `10`, prints it, and marks a system failure. This is the branch that `AT END` cannot cover.
5. `3000-VALIDATE-RECORD`: take the account number, delimiter, and amount at offsets 1:6, 7:1, and 8:5; check them in order with short-circuiting. Write only the reason to `WS-REJECT-REASON`; **do not** touch the system-failure flag.
6. `4000-WRITE-ACCEPTED` / `5000-WRITE-REJECTED`: check the respective status after `WRITE`. Only `00` increments the count and runs `DISPLAY`; otherwise mark a system failure. This keeps the counts equal to the actual result-file line counts and avoids reporting a record as written when it was not.
7. `8000-CLOSE-FILES`: close only files whose `WS-*-OPEN` flag is `Y`, then check each `CLOSE` status. A close failure also marks a system failure.
8. `0000-MAIN`: if `WS-SYSTEM-ERROR = "Y"`, `MOVE 1 TO RETURN-CODE`; otherwise leave it at 0. Business rejections never go through this path.

## Write Failure Boundary (Observed Limitation)

The program does check `WRITE` and `CLOSE` statuses, but one point needs to be clear: **a visible write failure cannot be injected with GnuCOBOL 3.2.0/Linux in this workspace.**

After assigning the accepted output directly to `/dev/full` (or symlinking `accepted.txt` to `/dev/full`), both `WRITE` and `CLOSE` still report `00`. The summary shows `システムエラー=N`, the process returns 0, and the two accepted records are silently discarded. So this lesson does **not** describe `/dev/full` as a successful write-failure test, nor claim that status `00` proves data has reached disk. The reproducible failures actually observed here are a missing input file (`35`), input/output open failures (`37`), and an overlong-line read error (`06`). In a deployment environment, use a failure-injection method provided by its file system or runtime, confirm that the runtime reports the failure in `FILE STATUS`, and only then rely on this check logic.

## Lesson 26 Focus and Reproducible Verification Paths

The central question in Lesson 26 is: **how can you observe the exit code and resource cleanup for a rejection, a file failure, and EOF?** The following paths can all be rerun under `build/`; finish each by running `rm -rf build`.

**Scenario 1 · Normal path (including business rejections)**

```sh
mkdir -p build
cobc -x -Wall -o build/lesson_26 lesson.cob
cp transactions.txt build/
(cd build && ./lesson_26); echo "rc=$?"
wc -l -c build/accepted.txt build/rejected.txt
```

Observed: `rc=0`; summary `入力=005 受理=002 拒否=003 システムエラー=N`; result files have 2 lines/26 bytes and 3 lines/54 bytes. **Rejections do not change the exit code**—this is the key difference from “return nonzero for any error.”

**Scenario 2 · File failure: missing input**

```sh
mkdir -p build && cobc -x -Wall -o build/lesson_26 lesson.cob
mkdir -p build/empty && cp build/lesson_26 build/empty/ && (cd build/empty && ./lesson_26); echo "rc=$?"
```

Observed: `エラー=入力OPEN 状態=35`, summary `入力=000 受理=000 拒否=000 システムエラー=Y`, `rc=1`; `build/empty/` contains **only the executable**. Neither output was opened, so no empty result files were left behind.

**Scenario 3 · File failure: output path is not writable**

```sh
mkdir -p build && cobc -x -Wall -o build/lesson_26 lesson.cob && cp transactions.txt build/
mkdir -p build/badacc && cp build/lesson_26 transactions.txt build/badacc/ && (cd build/badacc && mkdir accepted.txt && ./lesson_26); echo "rc=$?"
mkdir -p build/badrej && cp build/lesson_26 transactions.txt build/badrej/ && (cd build/badrej && mkdir rejected.txt && ./lesson_26); echo "rc=$?"
```

Observed: `build/badacc` reports `エラー=受理出力オープン 状態=37`, `rc=1`; cleanup closes only the input file that was actually opened (if `CLOSE` had failed it would print `エラー=入力クローズ`, which did not occur this time), and the rejected output was never opened. `build/badrej` reports `エラー=拒否出力オープン 状態=37`, `rc=1`, but **leaves a zero-byte `accepted.txt`**. This is the residual-output boundary of this lesson: stopping processing does not undo content that has already been opened or written.

**Scenario 4 · EOF (empty input) and an overlong line**

```sh
mkdir -p build && cobc -x -Wall -o build/lesson_26 lesson.cob
mkdir -p build/eof && cp build/lesson_26 build/eof/ && : > build/eof/transactions.txt && (cd build/eof && ./lesson_26); echo "rc=$?"
mkdir -p build/long && cp build/lesson_26 build/long/ && python3 -c "open('build/long/transactions.txt','w').write('A00001|00125'+'X'*20+'\n')" && (cd build/long && ./lesson_26); echo "rc=$?"
```

Observed: on empty input the first `READ` returns `10`; summary `入力=000 受理=000 拒否=000 システムエラー=N`, `rc=0`, and both result files are **0 bytes**—EOF is not an error. The 32-byte line above makes `READ` return `06`; summary `入力=000 受理=000 拒否=000 システムエラー=Y`, `rc=1`, with no increase in the record count. By comparison, a 20-byte line (`'A00001|00125' + 'X'*8 + '\n'`) can still be read, but after trailing spaces are removed its width is not 12, so it is a business rejection: `拒否口座=A00001 REASON=BAD_WIDTH`, `rc=0`. The same applies to 19 bytes.

**Failure injection not tested:** a full disk, a real failure returned by `WRITE`/`CLOSE`, a hardware error during `READ`, and concurrent overwrites of the same output file. These cannot be injected reliably in this environment, so they are not verified and the code alone does not establish that they are classified correctly.

## Follow the Real Workflow

In a complete overnight pipeline, this program does more than one processing step: it sets the **alerting rules** for the whole chain.

1. **At 12:30 a.m.**, the upstream system exports the day’s transactions to a file in the shared directory. Reading them is covered in [Lesson 15](../15_sequential-file-read/README.md), while fixed-width and CSV parsing are covered in [Lessons 17](../17_fixed-length-files/README.md) and [18](../18_csv-processing/README.md).
2. **Around 1 a.m.**, validation and matching finish, and every record has a destination. Sequential matching is covered in [Lesson 20](../20_file-matching/README.md); the complete “read → validate → write” flow is built in [Lesson 22](../22_file-processing-practice/README.md).
3. **This lesson’s step** adds signposts at the branch: bad records go to `rejected.txt` and the exit code remains 0; a file-level problem stops processing, reports a status, and returns 1. It does not change business rules; it separates the two kinds of failure.
4. **Later that night**, a nonzero exit code wakes the on-call operator. They need to learn from the log which file and status code failed; [Lesson 27](../27_logging/README.md) covers how to record that.
5. **The next morning**, the review team handles business rejections from the reject file, and the accepted file goes to downstream posting.
6. **Later lessons** reuse the rule “business rejection does not alert; system failure always alerts” in the modular project of [Lesson 28](../28_modular-batch-project/README.md), file/database synchronization in [Lesson 31](../31_data-synchronization/README.md), and the capstone in [Lesson 32](../32_bank-reconciliation-project/README.md).

In short, this lesson teaches the question every batch must eventually answer: **is there bad data, or did the job fail to finish?**

## What Happens When This Code Goes into Production

- **Who schedules it:** the overnight batch scheduler, after “input file ready.” It recognizes only the executable path and exit code; it does not read the 7 lines printed to the screen.
- **Who reads its “output”:** the on-call operator checks the exit code first and consults the log only when there is a problem (Lesson 27); the review team reads `rejected.txt`, not the screen.
- **Who is called when something goes wrong:** the operator is alerted when `RETURN-CODE=1`. First inspect the status: `35` means the file did not arrive, `37` means permissions or path type are wrong, and `06` means the physical record could not be read. **The most troublesome case is the one that does not alert:** a business rejection correctly returns 0, but if a real write failure is also treated as 0 (see “Write Failure Boundary”), nobody will know.
- **How the next system receives it:** a downstream posting job takes `accepted.txt`; `rejected.txt` goes to manual review. Reconciliation details are in [Lessons 20](../20_file-matching/README.md) and [22](../22_file-processing-practice/README.md), and modular handoff is covered in [Lesson 28](../28_modular-batch-project/README.md).
- **The likeliest first-month incident:** treating “there are rejected records” as a failure, which makes the nonzero alert ring every day until people ignore it. The reverse mistake—silently returning 0 when the input file is missing and calling it “bad data”—means that the whole batch did not run, and the discrepancy is discovered only at reconciliation. That is the costly mistake.

The scheduler can see only the executable’s exit code and a few result files. Therefore, “the input was read but some records were rejected” and “file I/O did not complete” must have different codes: the former returns 0 and leaves a reject file for business review; the latter returns 1 and requires a rerun or manual intervention. This lesson’s artifacts define that contract: `accepted.txt`/`rejected.txt` show each record’s destination, `RETURN-CODE` says whether the batch result is trustworthy, and `WS-*-OPEN` plus the cleanup paragraph show which files were closed after a failure.

A real system also needs batch IDs and input signatures, idempotent recovery after failures, a business review process for rejected records, atomic output delivery (write a temporary file first, then rename it), and disk failure-injection tests. **None of those are implemented here:** stopping processing guarantees only that reading does not continue; it does not undo written content or make reruns safe. See Lessons 20 and 22 for rejection reconciliation, Lesson 27 for logs, Lesson 28 for modular construction, Lesson 31 for file/database synchronization and partial failures, and Lesson 32 for the complete project.

## Modification Exercise (with Answer)

Starting from a clean fixture, change only the copy of the fixture, not `lesson.cob`: change line 2 of `transactions.txt` from `A00002|00X50` to `A00002|00150`, recompile and run, then check the counts and both result files. Expected difference: the record changes from a `BAD_AMOUNT` rejection to acceptance, and the summary changes from `入力=005 受理=002 拒否=003` to `入力=005 受理=003 拒否=002`. `accepted.txt` has 3 lines/39 bytes, `rejected.txt` has 2 lines/36 bytes, and the return code remains 0. The full baseline, commands, and reasoning are in [`exercise.md`](./exercise.md); the reference answer is in [`answer.md`](./answer.md). The starting values and expected results agree in the README, exercise, and answer.

## Transfer Exercise (No Answer)

Choose another business scenario (for example, an insurance claims batch) and design `claims.cob`: the input is 14 bytes per line (claim number + `|` + type + `|` + amount; type may be only `M` or `A`). Decide on the accepted/rejected file layouts, validation order, and fixture. Make the parent directory for the accepted output nonexistent, compare the summary and return code for a “business rule rejection” versus a “file system failure,” and explain why a failure to write the reject file means you cannot continue counting later records as successfully processed. See [`exercise.md`](./exercise.md); no answer is provided.

## Evidence Sources and Verification Status

The following commands were actually run in this workspace (GnuCOBOL 3.2.0, Linux); the expected values above come from these runs, not from inference:

| Command | Observed result |
|---|---|
| `cobc -fsyntax-only lesson.cob` | Exit code 0, no diagnostics |
| `cobc -x -Wall -o build/lesson_26 lesson.cob` | Exit code 0, no diagnostics |
| Normal fixture run | 7 stdout lines, exit code 0, result files with 2 lines/26 bytes and 3 lines/54 bytes |
| Run from an empty directory (input missing) | `エラー=入力OPEN 状態=35`, exit code 1 |
| `chmod 000 transactions.txt` | `エラー=入力OPEN 状態=37`, exit code 1 |
| `mkdir accepted.txt` / `mkdir rejected.txt` | Status `37`, exit code 1; the latter leaves a zero-byte `accepted.txt` |
| Empty input | `入力=000`, exit code 0, result files are 0 bytes |
| 32-byte input line | `エラー=入力読取 状態=06`, exit code 1; a 20-byte line is rejected as `BAD_WIDTH`, exit code 0 |
| Accepted output directed to `/dev/full` | Status remains `00`, exit code 0, data is silently discarded (write failure could not be injected) |

Fixed format was measured in bytes: every executable text line in `lesson.cob` is at most 72 bytes; level `01` fields start in column 8, statements in column 12, and lines with `*` in column 7 are comments. This lesson has no level `05` subordinate fields, so the “level `05` starts in column 11” convention does not apply.

**Not verified:** the failure types listed under “Failure injection not tested” above, and input volumes beyond this repository’s fixture (the count field has three digits, so the miniature fixture supports at most 999 records).

## References

- [GnuCOBOL Programmer’s Guide: FILE STATUS and status codes](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SELECT)
- [GnuCOBOL Programmer’s Guide: AT END / NOT AT END](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#AT-END-_002b-NOT-AT-END)
- [GnuCOBOL Programmer’s Guide: RETURN-CODE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Special-Registers)
- [GnuCOBOL Programmer’s Guide: OPEN, READ, WRITE, CLOSE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#OPEN)
- Repository course home: [README.md](../../README.md)
