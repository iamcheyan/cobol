# Lesson 20: Matching Files in Account-Number Order—One Merge Scan, Three Record Classes

Once the account master and today's transactions have each been sorted by account number, reconciliation comes down to one thing: match the records on both sides. This lesson scans two ordered files from beginning to end using the same account key, classifies every record as “matched,” “account only (master only),” or “transaction only,” and counts each class. It then uses two count equations to prove that nothing was missed. This scan is the engine behind all the reconciliation batches that follow.

## The Business Scenario

At the reconciliation team's morning meeting, people always ask the same question: how many records matched yesterday, and how many did not? The answer requires three numbers: how many matched, how many appeared only in the master, and how many appeared only in the transactions. If you can give those three numbers on the spot, you have accounted for the batch; if you cannot, you have to go back and review every detail from the beginning.

Let's zoom in. On your desk are two files: an end-of-day account master snapshot exported yesterday (3 lines in this demonstration, tens of thousands of accounts in a real scenario), and yesterday's transaction stream from branches and mobile banking (4 lines in the demonstration). Your task is to determine how the records on both sides correspond: which accounts had activity, which accounts appear only in the master, and which transactions have no account at all. The times and record counts below are invented teaching examples, not data from an actual institution.

This sounds simple. The hard part is “missing.” People who have done reconciliation for a while will tell you that a real discrepancy is not frightening by itself: it is visible, and someone will eventually handle it. **What is frightening is a discrepancy that goes undetected**: a transaction with no account is quietly skipped, the report still looks balanced, and only when a customer asks “where did this money go?” do you discover that the whole batch result must be recalculated. So the acceptance criterion for this work is not “the program ran”; it is “I can prove that it missed nothing.” That may sound abstract, but it boils down to two arithmetic equations. This lesson shows how to use them to support the result for an entire batch.

A note about scale: the fixtures in this lesson have only 3 master rows and 4 transaction rows, deliberately small enough to check every branch by hand. Real batches may be tens of thousands of times larger, but the algorithm scans once, reading, comparing, and classifying one record at a time; memory use does not grow with the files.

## Why Learn This Now

You might wonder: didn't I already read the account master and transaction file together in the previous lesson? Both files can be open at once, each handles its own EOF, and it runs. What is missing?

The **relationship** is missing. Lesson 19 solved the problem of “neither stream stopping the other”: both data streams advance side by side without interfering. But they remain two parallel streams. Which transaction should correspond to each master record? Lesson 19 did not answer that, because it did not yet compare the records.

If you try to force the Lesson 19 approach to do this, you get stuck immediately: one side has 3 rows and the other 4. How do you know whether row 2 should pair with row 2 or row 3? Row numbers do not matter here; the **account number is the key** that determines the pairing. This lesson teaches a sequential merge scan based on key comparisons. It scans both files once and also classifies where every unmatched record belongs.

Why does this lesson matter? Bank reconciliation, insurance-claim reconciliation, payment-channel reconciliation, and comparing ERP inventory with a physical count all amount to “scan two data sets sorted by the same key and merge them.” Once you know this operation, you can use it in every reconciliation batch that follows.

## What This Concept Is and What Problem It Solves

**What is the concept?** In plain language: two people each have a list sorted by the same number column. They look only at the top row of their own list and compare the numbers. Whoever has the smaller number moves that row forward, because the other list cannot contain it: even its current smallest number is larger, and every number after that will be larger still. If the numbers are equal, both rows move forward as a pair. Continue until both lists are exhausted. In the industry this is called a **sequential merge scan**; in COBOL, it is the two `READ` paragraphs in this lesson plus an `EVALUATE TRUE`.

The terminology is useful, but the three direct consequences are what you need to remember:

1. **Each record is read only once.** There is no need to load the whole master into memory, so it can be much larger than memory. That is why we do not search through a large `OCCURS` table.
2. **Each comparison advances one side or both sides.** The result depends entirely on which current key is larger, not on row numbers or record counts.
3. **Unmatched records do not disappear.** They go into the “master only” or “transaction only” bucket, which is the source of every discrepancy report in the later project.

**What problem does it solve in business?** It turns the manual work of “matching both sides of the ledger” into one controlled scan and gives you a way to demonstrate that nothing is missing. There are three parts:

- **Classification:** matched, master-only, and transaction-only records each get their own detail line. Reconciliation staff can use the “transaction only” list to investigate why an account is absent from the master, and the “master only” list to see which accounts had no activity today.
- **Counts:** the number of records in each class is a one-line summary for the team lead and the logs.
- **Invariants:** `匹配 + 仅主档 = 主档记录数`, and `匹配 + 仅交易 = 交易记录数`. Both equations must hold to show that the scan neither skipped nor counted any record twice. This is more important than the two points above: it makes “I missed nothing” something you can verify with a calculator rather than a promise.

**When should you not use it, and what happens if it is used incorrectly?** This algorithm has two hard prerequisites: both files must **really be sorted in ascending key order**, and keys must be **unique**. It compares only as it moves forward and never looks back. Search the whole program: nowhere does it compare a current key with the “previous key.” So it will not notice unsorted input or duplicates, and it will not report an error. It still prints a result and exits with code `0`, but the result cannot be trusted:

- Unsorted file → the reasoning behind “the smaller key goes first” is invalid. When a record smaller than earlier ones appears, the matching record on the other side may already have moved past it, so there is no second chance to pair them.
- Duplicate key → this lesson has not defined how multiple records for one account should be classified.

This lesson **did not run injection experiments** for these cases (its scope is how to scan when the prerequisites hold), so do not treat the descriptions here as expected output. To address them, rely on an upstream contract and sorting step (Lesson 21 `SORT`) to enforce the prerequisites, or stop them in a validation stage (Lesson 26 onward). This lesson states these two conditions as prerequisites, but the program **does not validate** them; they are listed explicitly below.

## What You Can Do After This Lesson and Its Boundaries

After this lesson, you can:

- Compare the current master and transaction values using the same sort key and explain which side advances in each branch.
- Classify records in one sequential scan as “matched,” “master only,” and “transaction only,” and count each class separately.
- After one side reaches EOF early, classify all remaining records on the other side into the corresponding one-sided class.
- Verify there are no omissions using count invariants: `匹配 + 仅主档 = 主档记录数`, and `匹配 + 仅交易 = 交易记录数`.
- Explain that ascending order, unique keys, and equal-length character keys are algorithm prerequisites, and why sequential merge does not need to load the entire file into memory.

Boundary: the program compares keys and displays pairing details; it does not total amounts, update balances, or write result files. Both fixtures have already been sorted externally and have unique account numbers; the program **does not validate** these conditions (Lesson 21 creates sorted input with `SORT`; formal rejection strategies are covered in Lesson 26). Records use fixed-width fields concatenated together; see Lesson 17 for field parsing and width checks.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not add `-std=cobol85`); source is fixed format.
- Linux terminal; this lesson requires no database or additional tools.
- `SELECT` uses relative filenames, so **run from this lesson's directory**. Syntax checking and compilation create the executable under `build/`; the program writes no data files.

## Input Record Layout

Both fixtures are line-sequential text files sorted in ascending account-number order. Each line consists of fixed-width fields concatenated directly, with no separators; the line ending separates physical lines and is not part of the `FD` record fields.

| File | Fields | Length | Example line |
|---|---|---:|---|
| [`accounts.txt`](./accounts.txt) | Account number `X(10)` + customer number `X(8)` + balance `9(7)V99` | 10 + 8 + 9 = 27 | `A000000001C0001001000100000` |
| [`transactions.txt`](./transactions.txt) | Account number `X(10)` + type `X(1)` + amount `9(7)V99` | 10 + 1 + 9 = 20 | `A000000001D000012550` |

Amounts use `PIC 9(7)V99`; `V` is an implied decimal point. The nine digits `000012550` represent `125.50`, and `000004000` represent `40.00`; the field contains no decimal-point character. This lesson only displays balances and amounts; it **does not perform any amount calculations**. So however nicely the amounts are displayed, that still does not mean the books have been reconciled.

There are 3 master rows and 4 transaction rows; account-number keys are equal-length text (all 10 characters). The account numbers contain the letter `A`, so they can only be compared as characters, not by numeric value. Because they are all 10 characters and share a prefix, “ascending character order” and “ascending numeric order” mean the same thing here. If the two sides ever have different lengths, the comparison semantics change. That is a fixture contract to maintain, not something the program guarantees for you.

## Sequential Matching Algorithm

Return to the image of two people comparing lists. The program first reads one record from each file, then compares only the two current keys in each iteration:

1. Master key is smaller: there is no corresponding transaction. Output `口座のみ` (master only) and advance only the master.
2. Transaction key is smaller: there is no corresponding account. Output `取引のみ` (transaction only) and advance only the transaction.
3. The keys are equal: output `一致` (matched) and advance both sides.
4. One side reaches EOF: classify all records remaining on the other side into its corresponding one-sided class. This check comes before key comparison: at the end, the remaining records have nothing to compare against, so they all go into the one-sided bucket.
5. Both sides reach EOF: finish the scan and output the three counts.

Comparison uses character ordering (`<` / `>` / equal keys go through `WHEN OTHER`). Each record is read at most once, and working storage does not grow with file length. That is the advantage of sequential merge over “load the whole file into memory and search,” and the reason it can handle hundreds of thousands of rows.

## Count Invariants: How to Prove Nothing Was Missed

The fixtures have 3 master rows and 4 transaction rows; the expected classes are 2 matched, 1 master only, and 2 transaction only.

| Invariant | Substituting this lesson's values | Meaning |
|---|---|---|
| `匹配 + 仅主档 = 主档记录数` | `2 + 1 = 3` | Every master record was classified once; none was missed |
| `匹配 + 仅交易 = 交易记录数` | `2 + 2 = 4` | Every transaction was classified once; none was missed |

When both equations hold, you can confirm that the scan neither skipped a record nor counted the same record twice. These equations can be checked independently in the pipeline; they do not depend on what the program claims. Do not treat them as decoration: their purpose is to let anyone confirm “nothing was missed” at a glance. An equation that is displayed but never checked is more dangerous than no equation, because it can make people believe they verified the result.

## Correctness Prerequisites and File Errors

| Prerequisite | Who guarantees it | Validated in this lesson? |
|---|---|---|
| Both files are sorted in **ascending key order** | Upstream process / sorting step (Lesson 21 `SORT`) | **No**; unsorted input invalidates the merge result |
| **No duplicate** account numbers | Upstream interface contract | **No**; this lesson does not handle duplicate master rows or multiple transactions for one account |
| Keys are equal-length characters with consistent comparison rules | Fixture design | No; comparison semantics change when lengths differ |
| `FD` width matches the actual line length | Fixtures | Master: 27 characters; transactions: 20. A mismatch can cause bytes to be read incorrectly. |

**Unverified cases (and why):** This lesson neither implements detection nor runs injection experiments for unsorted input or duplicate keys, because its scope is “how to scan when the prerequisites hold.” Detection and rejection policies belong to Lesson 26 and later. So here we can say only that “the result cannot be trusted,” not “the program will report this error.” Do not invent output and present it as expected behavior.

File errors: if either input fails to `OPEN`, matching does not start (if the second `OPEN` fails, the already-open master is closed). `AT END` handles status `10`; other `READ` or `CLOSE` statuses are reported and return a nonzero code. This workspace was tested: when an input file is missing, `OPEN` reports `STATUS=35` and the process exits with code `1`; no matching results are printed. This lesson has no retry or recovery.

## Run and Observe

**Input:** `accounts.txt` (3 lines) and `transactions.txt` (4 lines) in this lesson's directory. The program opens them by relative path, so first `cd` to the lesson directory.

**Commands and what they do:**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                  # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_20 lesson.cob    # 编译并生成可执行文件
./build/lesson_20                              # 运行，读取当前目录下的两个夹具
echo $?                                        # 查看退出码
rm -rf build                                   # 清理生成的可执行文件
```

**Expected results:**

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x` exit code | `0`, no compiler diagnostics |
| Standard output | 7 lines, shown in the code block below |
| Process exit code | `0` |
| Business files generated | None (this lesson only reads files) |

```text
口座と取引を開きました
一致 口座番号=A000000001 顧客番号=C0001001 残高=0001000.00 種別=D 金額=0000125.50
口座のみ 口座番号=A000000003 顧客番号=C0001003 残高=0000002.00
取引のみ 口座番号=A000000004 種別=D 金額=0000075.00
一致 口座番号=A000000005 顧客番号=C0001005 残高=0000250.75 種別=T 金額=0000040.00
取引のみ 口座番号=A000000006 種別=D 金額=0000020.00
照合件数=002 口座のみ=001 取引のみ=002
```

**Output field glossary (Japanese output → meaning):** `口座と取引を開きました` = account and transaction files opened; `一致` = matched; `口座のみ` = master only; `取引のみ` = transaction only; `口座番号` = account number; `顧客番号` = customer number; `残高` = balance; `種別` = transaction type; `金額` = amount; `照合件数` = matched record count; `口座のみ` / `取引のみ` = master-only / transaction-only counts.

The “master only” line contains only master fields (no `種別` or `金額`), while a “transaction only” line contains only transaction fields (no `顧客番号` or `残高`). That matches the file each record came from. Check this while reading the output so you do not mistake one class for another.

You can trace the seven output lines against the fixtures: `A000000001` appears on both sides and is matched; `A000000003` appears only in the master and is classified as master only; `A000000004` is the reverse and is transaction only; `A000000005` is matched; and `A000000006` appears only in the transactions. The final `002 / 001 / 002` satisfies both invariants above (`2 + 1 = 3` and `2 + 2 = 4`).

**Environment detail actually observed:** Running the executable in this workspace writes `Warning: program compiled against libxml 212 using older 209` to standard error. This is a linked-library version warning from the runtime environment, not program business output; its triggering component has not been identified. Do not count it as part of the reconciliation result.

## Modification Exercises

Make both changes only to **fixture copies in a temporary directory**; do not modify the repository's `accounts.txt` or `transactions.txt`:

1. Delete the row for account `A000000004` from the copy of `transactions.txt`. Confirm the result of comparing master key `A000000003` with the next transaction key `A000000005`, and record the counts for all three classes.
2. Starting from the original fixtures, change the `A000000004` key in the transaction file to `A000000003` and the amount to `000005000` (keep the line 20 characters long and the file in ascending order). Confirm that this transaction matches master record `A000000003` and that both streams advance.

The first exercise lets you see the branch where “the smaller key on one side means it is absent from the other.” The second turns a one-sided record into a match so you can see how all three counts change. Check the invariants after both runs.

See [`exercise.md`](./exercise.md) for the full problems and expected results, and [`answer.md`](./answer.md) for reference answers.

## Take It Further

Add a duplicate account key to each input and add a record that violates ascending order to each. Extend the program to detect duplicate and descending keys, state the rejection policy you choose, and create fixtures to verify matching, unmatched, duplicate, and unsorted cases. Do not load both complete files into an `OCCURS` table or call `SORT`. See [`exercise.md`](./exercise.md) for the problem; no answer is provided.

This exercise directly attacks the “unverified cases” in this lesson: since unsorted and duplicate records do not produce errors, you must decide when to reject them and whether the batch should count as failed after rejection. That is exactly what Lesson 26 covers systematically.

## Walk Through a Real Workflow

This lesson sits in the middle of a reconciliation day's processing chain:

1. **At the end of the previous day**, the core system exports an account master snapshot (fixed-length records; Lesson 17 covers checking widths and offsets).
2. **The next morning**, the transaction stream from the previous day is delivered as a file. Lesson 19 covers how to maintain EOF independently as these two data sets are read.
3. **Upstream sorts both files first.** In a real system, this may happen during export or by using `SORT` in the batch (Lesson 21).
4. **This lesson's scan** begins: one merge pass classifies records as matched, master only, or transaction only, then reports three counts. This is the first time in the chain that “both sides of the ledger are matched.”
5. **Results go downstream:** writing unmatched records into a list, writing matches to a result file, and putting control counts in the batch report are covered in Lesson 22 (file-processing practice) and Lesson 27 (logging). Lesson 31 covers writing reconciliation results back to a database.
6. **The final stop** is the bank reconciliation project in Lesson 32, where this scan is connected into a complete “validate → sort → match → write → update” batch.

So the few dozen lines you are writing now are not just an exercise; they are the heart of the capstone project.

## What Would Happen If This Code Went into Production

- **Who schedules it:** a night or early-morning batch scheduler, usually after checking that both input files are ready. It looks only at the exit code: `0` allows the next step; non-`0` raises an alert.
- **Who reads its output:** operations staff first check the three numbers `照合件数 / 口座のみ / 取引のみ`, then check the invariants. If the numbers do not add up, they must inspect the details that night.
- **Who is called:** if many accounts that should have matched appear as “transaction only,” the first thing to investigate is whether upstream sent an unsorted file. That is the production incident this lesson does not validate for, but that is easiest to encounter.
- **How the next system picks it up:** classification details become an unmatched-record list and result file (Lesson 22), counts go into logs (Lesson 27), and differences are written back to a database (Lesson 31).
- **The most likely incident in the first month:** treating “it ran and exited with code 0” as “the accounts reconciled.” This program **does not validate ascending order or unique keys, reconcile amounts, or write result files**; it only classifies records by key pairing. That is why it leaves these checks for you to perform.

To be clear, real master-file reconciliation requires prior agreement on key encoding, sort order, duplicate-key policy, missing-record classification, and amount storage before scan results are meaningful. This lesson makes no claims of regulatory, audit, or financial-compliance assurance, and has no rerun, idempotency, or atomic-delivery design.

## References

- [GnuCOBOL Programmer’s Guide: ORGANIZATION SEQUENTIAL](https://superbol.eu/gnucobpg/chapter5.html#organization-sequential)
- [GnuCOBOL Programmer’s Guide: LINE SEQUENTIAL](https://superbol.eu/gnucobpg/chapter5.html#organization-line-sequential)
- [GnuCOBOL Programmer’s Guide: Sequential READ and AT END](https://superbol.eu/gnucobpg/chapter7.html#sequential-read)
- Repository course home: [README.md](../../README.md)
