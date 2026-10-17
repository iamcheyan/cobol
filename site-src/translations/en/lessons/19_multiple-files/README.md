# Lesson 19: Reading the Master and Transactions Together—Two Input Streams, Two Independent EOFs

Real batch jobs rarely read just one file: the account master and the day's transactions must advance together, even though they often have different numbers of rows. The file that finishes first must not stop the other one. In this lesson, open two sequential files at the same time, maintain separate file statuses, EOF flags, and record counts, and continue reading all four transactions after the master reaches end of file. This prepares the input-stream handling needed for the key-based sequential matching in Lesson 20.

## The Business Scenario

At 10:40 p.m. on the last business day of the month, online transactions have stopped (the institution, time, and scale are invented for this lesson; these are not real data from an actual institution). The first step in your reconciliation process is simple: read both the **account master** and **today's transactions** files. The master says “what these accounts look like now,” and the transaction file says “which accounts had activity today.” Calculating balances and comparing accounts comes later; for now, you have one job: advance both data streams all the way through.

The two files naturally have different numbers of rows. The master might have hundreds of thousands of rows, with every account that has ever been opened; there might be only tens of thousands of transactions for the day, and accounts with no activity today will not appear at all. So each file has its own answer, at its own point in time, to the question “have we finished reading?” The master may be only halfway through when the transactions are done, or the reverse may happen.

The most common beginner mistake here is to make the two files share one “finished reading” flag, or even one reading paragraph. Everything appears to run normally: no error, exit code still `0`, and the final summary still prints.

But read the two numbers in that summary and something is wrong: there were 120,000 transactions today, yet the summary shows only 60,000. Nothing vanished; the file that finished first simply stopped the other one too, and the run ended “successfully.” This kind of incident produces no error or warning. Someone has to read those two counts to notice it. That is why this lesson keeps each file's EOF, status, and count separate from start to finish.

## Why Learn This Now

By Lesson 15, you could open a sequential file and use `AT END` to read to the end of it. With only one stream, a single EOF flag was enough.

But real batch jobs rarely read just one file. The master is the “reference,” and the transactions are “what happened today”; both must be present at the same time. That introduces a new problem Lesson 15 did not cover: **when one file finishes reading has nothing to do with when the other one finishes.**

You might think: why not write two loops, read the master to the end, then read the transactions? That is not equivalent. If the next step is to examine two records together (which is exactly what Lesson 20 does), you must advance the streams together. You have to control which record the master is on and which record the transactions are on.

There is another, subtler trap: `AT END` recognizes only one state, “read reached the end of the file normally” (status code `10`). If a read fails for another reason, its status is not `10`, and the `AT END` branch will not run. If you rely on it alone to decide whether reading is finished, the program will think data remains and continue with the previous, stale record—silently wrong. So this lesson is not just about “opening another file”; it also covers checking the status after `READ` thoroughly.

## What This Concept Is and What Problem It Solves

**What is the concept?** In one sentence: **advance two (or more) sequential files independently.** Every file has its own `FILE STATUS`, EOF flag, record count, and reading logic. On each loop iteration, read from every file that has not finished; stop only after all of them have reached the end.

**What problem does it solve in business?** “One reference data set + one data set of today's activity” is one of the most common batch input patterns: an account master with today's transactions, a product master with today's orders, or customer records with today's account-opening applications. Managing each input independently gives you three things:

- Different row counts do not hold one another back: the master and transaction counts are tracked separately.
- Counts are the first numbers to check during reconciliation—`账户记录数=003 交易记录数=004` is evidence of whether everything was read.
- If something goes wrong, you can identify **which file and which status code**, instead of saying only “read failed.”

**When should you not write it this way?** If both files always advance together and have a one-to-one record correspondence (for example, one is a line-by-line copy of the other), sharing a loop is not necessarily wrong. But if you **cannot guarantee** that both sides have the same number of rows, keep their statuses, EOF flags, and counts separate. The fixtures in this lesson deliberately have 3 rows versus 4. For the streams to be paired by a business key, wait for sequential matching in [Lesson 20](../20_file-matching/README.md); this lesson makes only the “both streams are present” step reliable.

## What You Can Do After This Lesson and Its Boundaries

After this lesson, you can:

- Declare and `OPEN INPUT` two sequential files in one program, each with its own `FILE STATUS` field.
- Maintain separate EOF flags and successful-read counts for each input, and explain why they cannot be shared.
- Interleave the advancement of two streams in one loop: after one reaches EOF, continue reading the other to completion.
- Distinguish how normal EOF (`10`), an open failure (`35`), other read errors, and close errors are handled, and what return code each produces.
- Check the result: three master records and four transactions, with all four transactions appearing after the master reaches EOF.

Boundary: the program only reads and echoes each whole line. It **does not parse fields, match by account number, calculate amounts, or generate an output file**; sequential matching is covered in Lesson 20. The fixtures guarantee the file-format contract (field separators and widths); this lesson does not validate it. Missing and empty files are treated as failures or zero-record cases, respectively; there is no retry or recovery mechanism.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not add `-std=cobol85`); source is fixed format.
- Linux terminal; this lesson requires no database or additional tools.
- The input fixtures must be present first. Since the `SELECT` entries use relative filenames, **run from this lesson's directory**.
- Syntax checking and compilation create the executable under `build/`; the program writes no data files.

## Input Files

| Fixture | Records | Example line | Description |
|---|---:|---|---|
| [`accounts.txt`](./accounts.txt) | 3 | `MASTER\|0001234567\|C0001042\|0001000.00` | Account master, line-sequential text |
| [`transactions.txt`](./transactions.txt) | 4 | `TXN-000001\|D\|0001234567\|125.50` | Today's transactions, line-sequential text |

Both are line-sequential text files: one physical line is one record, with fields separated by `|`. This lesson does not interpret the fields; it displays each line exactly as read. Both `FD` record areas are `PIC X(100)`, and the longest line in these fixtures is 34 bytes, well below that limit, so records will not be truncated and two lines will not be joined into one.

## How to Advance Both Streams Together

The program's structure comes down to one sentence: **keep reading while any file still has unread records.**

1. Open the master first. If its `FILE STATUS` is not `00`, report the error and exit; in this lesson, a missing file is a failure with status `35`.
2. Open the transaction file next. There is an additional step compared with Lesson 15: if it cannot be opened, **close the already-open master file** before exiting, or that resource is left open.
3. Enter the loop. On each iteration, check which stream has not reached EOF: call its own read paragraph if it has not, and skip it if it has. The two read paragraphs (`1000-READ-ACCOUNT` and `2000-READ-TRANSACTION`) each manage one file and do not touch the other's flag or count.
4. On a successful read (status `00`), do only two things: increment **that file's own** count and display the whole line. Master lines begin with `账户主档：`; transaction lines begin with `交易：`.
5. On reaching the end of a file (status `10`), set only **that file's own** EOF flag. This is not an error and does not increase its count—that is what a normal end of file means.
6. If `READ` returns any other status, display which file and status, set the I/O error flag, leave the loop, close both files, and finish with a nonzero code.
7. The loop exits when both EOF flags are `Y`, or when an I/O error occurs.

We mentioned the trap with `AT END` earlier, but it bears repeating because it is the key point of this lesson: **it covers only file status `10`** and cannot catch other nonzero statuses. That is why both read paragraphs explicitly check the status field after `READ`—only then can the program distinguish “reached EOF” from “read failed.”

## File Status, Failures, and Limitations

| Situation | Observed file status | Program behavior / return code |
|---|---|---|
| Normal end of file | `10` | Set that file's EOF; do not count a record; return code remains `0` |
| Missing input file | `35` (OPEN) | Output `... 文件打开失败 STATUS=35`; return code `1` |
| Other nonzero status during reading | Other status code | Output `读取...失败 STATUS=xx`; stop reading, close files, return code `1` |
| Close error | Not `00` | Output `关闭时...异常`; return code `1` |

- Both inputs are required: `SELECT` does not specify `OPTIONAL`, so a missing file causes failure.
- A READ error stops processing immediately, after which the program attempts to close both files; this lesson does not retry or resume from a checkpoint.
- This lesson does not validate business dates or record formats, or compare the contents of the two files. It does not perform file matching—keep that distinction clear.

## Run and Observe

**Input:** `accounts.txt` and `transactions.txt` in this lesson's directory. The program opens them by relative path, so first `cd` to the lesson directory.

**Commands and what they do:**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                  # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_19 lesson.cob    # 编译并生成可执行文件
./build/lesson_19                              # 运行，读取当前目录下的两个夹具
echo $?                                        # 查看退出码
rm -rf build                                   # 清理生成的可执行文件
```

**Expected results:**

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x` exit code | `0`, no compiler diagnostics |
| Standard output | 9 lines, shown in the code block below |
| Process exit code | `0` |
| Business files generated | None (this lesson only reads files) |

```text
账户与交易文件已打开
账户主档：MASTER|0001234567|C0001042|0001000.00
交易：TXN-000001|D|0001234567|125.50
账户主档：MASTER|0002468101|C0002042|0000020.00
交易：TXN-000002|T|0001234567|0007654321|40.00
账户主档：MASTER|0007654321|C0003042|0000250.75
交易：TXN-000003|D|0002468101|75.00
交易：TXN-000004|T|0007654321|0009999999|20.00
关闭完成 账户记录数=003 交易记录数=004
```

**Independently checkable:** The `accounts.txt` fixture has 3 lines and `transactions.txt` has 4, so the summary must be `账户记录数=003` and `交易记录数=004`, for a total of 7 echoed records. After line 5, no more master records appear (the master has reached EOF), while transactions continue printing through the fourth record. That is the effect of independent EOF flags. Count the output lines yourself to confirm that the two counts do not interfere with each other.

**Evidence and items not verified:**

- The three commands above, the 9 output lines, and the exit code were run in this workspace. The missing-file path with `STATUS=35` was also tested for each missing master and transaction file; both runs exited with code `1`. The results agree with this document.
- The two modification exercises were rerun using temporary copies of the fixtures in this lesson's directory, and the results match [`answer.md`](./answer.md) (`003/002` and `000/004`, exit code `0`).
- **Unverified item (still pending):** Running the executable in this workspace also writes `Warning: program compiled against libxml 212 using older 209` to standard error. This is a linked-library version warning from the runtime environment, not program business output. **Why it was not verified:** the component that produces it has not been identified, and it is not needed to check this lesson's business results.
- **Two paths also not tested:** The lines for “other nonzero status during reading” and “close error” are based on the checks in the source and GnuCOBOL file-status semantics. No reliable way to inject these errors was found, so these are not presented as tested results. To exercise these paths, see the error-injection exercises in [Lesson 26](../26_error-handling/README.md).

## Modification Exercises

Make both changes only to **fixture copies in a temporary directory**; do not modify the repository's `accounts.txt` or `transactions.txt`:

1. Delete the last two records from the copy of `transactions.txt`, leaving only the first two. Confirm that all three master records are still read and the transaction count is two.
2. Empty the copy of `accounts.txt` while keeping all four transactions. Confirm that the empty master reaches EOF on the first `READ` and the remaining transactions are still read one by one.

See [`exercise.md`](./exercise.md) for the full problems and expected results, and [`answer.md`](./answer.md) for reference answers.

## Take It Further

Add a customer-status file and read it along with the master and transaction files. Maintain separate EOF flags and counts for all three inputs; prepare fixtures with three, two, and one records, and confirm that the other streams continue advancing when any one stream finishes first. Design a read-error message format that identifies the filename and status code. Do not add account matching, sorting, or database access. See [`exercise.md`](./exercise.md) for the problem; no answer is provided.

## Walk Through a Real Workflow

Here is where this lesson fits in the month-end reconciliation chain:

1. An upstream process places the **account master** and **today's transactions** files in the batch directory (a real system also has an earlier “all files arrived” check, which is outside this lesson).
2. Your program opens both files at once and advances each independently, then reports `关闭完成 账户记录数=003 交易记录数=004`. This step guarantees that both streams were present and read in full.
3. These counts are for operations and reconciliation staff to review (Lesson 27 turns them into formal logs). **If they do not match the counts reported upstream, investigate that night.** This lesson uses only 3 rows versus 4 so you can count them by hand.
4. After both streams have been read, [Lesson 20](../20_file-matching/README.md) pairs them by account number. After matching three master records and four transactions, invariants such as “matched count + master-only count = total master count” must hold, with nothing omitted.
5. The matching results then go through the output logic from [Lesson 16](../16_file-writing/README.md) to become a result file, and [Lesson 22](../22_file-processing-practice/README.md) connects the entire chain into an end-to-end batch job.

In other words, this lesson produces no business result. It makes the reliable handling of “both input streams in hand” possible. Every reconciliation step that follows stands on this foundation.

## What Would Happen If This Code Went into Production

- **Who schedules it:** a night batch scheduler, usually after the “files ready” check. If either the master or transactions file is missing, the program fails at the first step; this lesson prints `STATUS=35` and exits with `1` (formal error classification comes in Lesson 26).
- **Who reads its output:** operations staff first check the exit code, then the two counts on the final `关闭完成 ...` line. **If the counts are wrong, investigate that night**, because the program does not discover on its own that “half a file is missing.”
- **Who is called when something goes wrong:** if a file's read status is neither `00` nor `10`, the program prints the filename and status code, then exits nonzero. Operations staff use that line to determine which input is damaged.
- **How the next system picks it up:** this lesson hands off only the fact that “both streams were read to the end.” Key-based pairing is in [Lesson 20](../20_file-matching/README.md), writing the results is in [Lesson 16](../16_file-writing/README.md), error routing and resource cleanup are in [Lesson 26](../26_error-handling/README.md), and logging is in [Lesson 27](../27_logging/README.md).
- **The most likely incident in the first month:** someone takes the shortcut of sharing one EOF flag or read paragraph between the two files. **This mistake produces no error and still exits with code 0; it just silently processes half the data.** It is hard to see with the 7 fixture records and becomes visible only on a night when the real files differ greatly in size. This lesson puts the 3-to-4 difference up front so you can encounter the pitfall early.
- **What it does not do yet:** it does not parse fields (it echoes each whole line unchanged), match by account number, calculate amounts, or write a result file; it has no retry or checkpoint resume. So it is **not** a reconciliation batch that can go straight into production.

## References

- [GnuCOBOL Programmer’s Guide: SELECT and FILE STATUS](https://superbol.eu/gnucobpg/chapter5.html#select)
- [GnuCOBOL Programmer’s Guide: LINE SEQUENTIAL](https://superbol.eu/gnucobpg/chapter5.html#organization-line-sequential)
- [GnuCOBOL Programmer’s Guide: AT END handling for READ](https://superbol.eu/gnucobpg/chapter7.html#at-end-not-at-end)
- [GnuCOBOL Programmer’s Guide: Sequential READ](https://superbol.eu/gnucobpg/chapter7.html#sequential-read)
- Repository course home: [README.md](../../README.md)
