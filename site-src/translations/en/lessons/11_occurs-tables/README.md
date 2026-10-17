---
_translated_from: lessons/11_occurs-tables/README.md
_translated_by: site-src/translation agent
---

# Lesson 11: Fixed-Size OCCURS Tables — Number a Small Batch in Memory and Process It by Subscript

Daytime batch jobs often handle a small set of items on their own: adjustment entries for the day, rates to apply, or accounts to review. The set is small enough to load into memory and must be revisited by item number throughout the day. In this lesson, `OCCURS` declares a fixed four-entry transaction table. We load it using explicit subscripts, read it entry by entry with `PERFORM VARYING`, then report the processed count and ending balance. This is the same in-memory table used for indexed traversal in [Lesson 12](../12_indexed-by/README.md) and keyed lookup in [Lesson 13](../13_search-tables/README.md).

## The Business Setting

At 7:40 a.m., the payment clearing team's daytime mini-batch is starting. There are only a few accounts to handle today: four entries, small enough to fit on a note.

Small batches like this appear throughout business systems: codes to release today, rates to apply, or accounts that need extra review. They differ from the tens of thousands of transactions in an overnight file in one clear way: **the whole set is small enough to keep in hand, and the items need to be revisited by number during the day**. You may need to report what the third item is, then later use that same number to decide whether to post it.

The natural approach is to place all four entries in four fixed memory slots at startup and number them. When you need one, ask for its slot by number instead of searching the list again.

The trouble is hidden in the word “slot.” **You choose the number of slots** (this lesson fixes it at four), **the load code determines how many are filled**, and **a third number controls how far the loop traverses**. These numbers are maintained separately, and few people check that they agree. If they do not, COBOL will not stop you: the program quietly reads bytes next to the table and prints something that looks like data—perhaps a `5` in the amount and an unrecognizable byte in the transaction code. This time it might not enter the posting branch, so the balance still looks right. With a different compiler layout or field order, those neighboring bytes could happen to form a `C`, and the amount would be posted without anyone knowing.

The four transactions and initial balance of `1000.00` in this lesson are **demonstration data** written in the program. They do not represent real accounts at any institution. These values will first come from a file starting in [Lesson 15](../15_sequential-file-read/README.md).

## Why Learn This Now

You may think that [Lesson 06](../06_perform-loops/README.md) already taught you to repeat code, and [Lesson 09](../09_group-items/README.md) taught you to group a transaction code and amount into one record. What is missing?

A **container whose entries can be addressed by number**.

In the loop from Lesson 06, there was no way to say “the nth transaction.” A set of variable names can hold only one record. To select the second or third transaction, you would need a separate branch in `EVALUATE` for each one. That is scaffolding, not how a real batch is written. A real batch needs to say “get the entry in slot n,” and earlier lessons have not introduced that slot.

`OCCURS` supplies the container: **repeat the same structure n times, with a number for each occurrence**. Now “which transaction?” becomes a computable number, and traversal gets a standard form: start at 1, increment the number after each entry, and stop at the last slot.

It also makes a second fact explicit: **the table’s capacity is now a number written in the source**. A reviewer can see at once that capacity is four without counting variable names. The byte-size calculation in the next lesson and the bounds exercise in this lesson both start from that number.

## What This Concept Is and What Problem It Solves

**What it is.** Put `OCCURS n TIMES` on a group item to repeat that group n times. Refer to each occurrence by the number in parentheses (the subscript); `WS-TXN-AMOUNT(2)` means “the amount in slot 2.” Subscripts start at 1 and run through the declared capacity.

**Without it.** You would have to give similar data a row of similar names—`WS-AMT-1`, `WS-AMT-2`, `WS-AMT-3`, and so on—and write a chain of `IF` branches to traverse them. Changing the capacity from four to five would require edits everywhere those names are used. This is what “you would have to copy the same code many times” means here: not duplicating the business logic, but duplicating a whole set of names and branches.

**The business problem it solves.** Small in-memory batches, such as daily rates, codes to validate, or accounts to review, can be loaded as a whole and revisited by number. Once loaded into a table, the program can traverse and use them without rebuilding the list each time.

**When not to use it, and what goes wrong.** Keep two boundaries in mind:

- The table has a **fixed size**. A declaration of four entries gives you four slots; a fifth entry will not fit, and forcing it in overwrites other storage. If real input may exceed capacity, process it in batches or read it record by record from a file instead of nudging the capacity upward. [Lessons 21](../21_sort/README.md) and [22](../22_file-processing-practice/README.md) explain why you should not load an entire file into an `OCCURS` table.
- An out-of-range subscript is **not reported by default**. If any of the three numbers disagree, trouble follows: with capacity four and a loop bound of five, the program gives no warning and treats the fifth slot—actually memory immediately after the table—as data. Misuse can cost more in business than a syntax error: a syntax error alerts you that night; a bad out-of-range read may not be discovered until reconciliation the next day. Exercise 3 has you observe this directly (capacity 4, bound 5).

## Capabilities and Limits After This Lesson

After this lesson, you can:

- Declare n occurrences with `OCCURS n TIMES` on a group item and calculate the table’s total byte size.
- Read or write a selected occurrence using an ordinary numeric subscript such as `WS-TXN-AMOUNT(2)`, and explain why subscripts start at 1.
- Traverse through the last entry with `PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1 UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE`, and explain why the exit condition does not skip entry 4.
- Distinguish table capacity, number of entries loaded, and traversal bound, and explain how changing only the traversal bound causes an out-of-bounds read.

Limits: this lesson does not declare an `INDEXED BY` index, perform a `SEARCH`, sort, load from a file, or validate subscript ranges. The four transactions and initial balance are program constants. Indexes are covered in Lesson 12, keyed lookup in Lesson 13, and file loading from Lesson 15 onward.

## Runtime Environment

- GnuCOBOL 3.2.0 using the default dialect (without `-std=cobol85`); source is fixed format.
- Linux terminal; no database, extra tools, or third-party libraries are required.
- The program does not read or write business data files; its executable is created under `build/` or a temporary directory.

## Looking Inside the Table

### In Memory, the Table Is One Contiguous Block

[`lesson.cob`](./lesson.cob) places `OCCURS` on group item `WS-TRANSACTION-ENTRY`, so its two subordinate items repeat together four times:

```text
01 WS-TRANSACTION-TABLE
   05 WS-TRANSACTION-ENTRY OCCURS 4 TIMES
      10 WS-TXN-CODE      PIC X          1 字节
      10 WS-TXN-AMOUNT    PIC 9(5)V99    7 字节
```

Do not picture “four scattered variables.” The table occupies **one contiguous block of 32 bytes**: each slot is 1 + 7 = 8 bytes, and the four slots are adjacent with no padding. The generated header from `cobc -C lesson.cob` declares it as `static cob_u8_t b_17[32]`, matching the hand calculation.

A subscript means “which slot,” counting from 1. `WS-TXN-AMOUNT(3)` refers to seven bytes starting at table offset (3−1)×8 + 1 (offsets counted from 0), expressed in generated code as `b_17 + 1 + 8LL * (3 - 1)`. Once you understand this, it is clear that an off-by-one subscript reads someone else’s storage.

### A Declaration Reserves Space; It Does Not Load Data

`OCCURS 4 TIMES` does one thing: reserves four slots. It does not fill them with examples, sort them, or build an index. Their contents depend entirely on the `MOVE` statements in `1000-LOAD-TABLE`. That is why this lesson has a separate loading paragraph: declaring a table does not put data in it.

### Fixed Format Still Follows the Same Rules

Column 7 is reserved for the comment indicator `*` (there are three comment lines in this lesson). Divisions, paragraph names, and level 01 entries start in column 8 (Area A); statements start in column 12 (Area B). Byte measurement shows the longest line is 65 bytes, so no line reaches column 72 or the compiler-ignored columns 73–80.

## Inputs and Rules

- **Input:** No external input. The four transactions and initial `WS-ACCOUNT-BALANCE` of `1000.00` are program constants, written in the `MOVE` statements in `1000-LOAD-TABLE` and the `VALUE` clause; they are not read from a file or database.
- **Posting rules:** Code `C` adds the amount to the balance, `D` subtracts it, and other codes display “unknown code ignored” without changing the balance. `EVALUATE ... WHEN OTHER` handles the other codes. There is no code-table validation, so do not read this output as proof that the code passed business validation.
- **Counting rule:** `WS-PROCESSED-COUNT` increments for each occurrence processed, whether or not its transaction code is accepted.
- **Checks not performed:** The program does not check whether `WS-LAST-SAMPLE` exceeds capacity 4 or whether a slot was actually loaded. It relies on capacity, load statements, and traversal bound agreeing. See Exercise 3 under “Modification Exercises” for what happens when they do not.

## Run and Observe

Run these commands from this lesson’s directory (the build and run pattern is the same as in [Lesson 01](../01_hello-cobol/README.md)):

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                   # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_11 lesson.cob     # 编译并生成可执行文件
./build/lesson_11                               # 运行程序，输出写到标准输出
echo $?                                         # 查看上一条命令的退出码
rm -rf build                                    # 清除生成的可执行文件
```

A reminder: `-fsyntax-only` checks only the syntax path. Passing it **does not mean** the program runs correctly; the ten lines below appear only after compilation and execution. This lesson has no input file, so the result is the same from any working directory.

**Expected stdout (measured in this workspace):**

| Lines | Content | Meaning |
|---|---|---|
| 1, 3, 5, 7 | Four lines such as `明細=01 コード=C 金額=00125.50` | Current occurrence number, transaction code, and amount |
| 2, 4, 6, 8 | `処理=入金` / `処理=出金` / `処理=未知コードを無視` | Branch taken for the code: credit, debit, or ignore |
| 9 | `処理件数=004` | Number of table entries processed |
| 10 | `最終残高=0001105.40` | Ending balance |

The output text follows the repository’s established Japanese: `明細` means detail sequence, `コード` transaction code, `金額` amount, `処理` action, `処理件数` processed count, and `最終残高` ending balance.

The balance can be checked independently: `1000.00 + 125.50 − 40.10 + 20.00 = 1105.40`. The third entry’s code `X` and amount `25.00` do not affect the balance, but it still counts as processed.

**Exit codes:** Syntax checking, compilation, and execution each return `0`. At runtime, stderr contains `Warning: program compiled against libxml 212 using older 209`. This is an environment warning caused by local library-version differences, not business output from this program; [Lesson 01](../01_hello-cobol/README.md) encountered the same warning.

## Follow the Data Through the Source

Read in the order data is written and then read:

1. `0000-MAIN` calls the load, processing, and summary paragraphs in order.
2. `1000-LOAD-TABLE` uses literal subscripts 1, 2, 3, and 4 to specify the slot for each transaction. In a real system this step would fill slots while reading a file (Lesson 15); here it is written out explicitly.
3. `2000-PROCESS-TABLE` uses `PERFORM VARYING` to increment `WS-SAMPLE-INDEX` from 1 and exits when `WS-SAMPLE-INDEX > WS-LAST-SAMPLE`. Entry 4 is processed because `4 > 4` is false; the loop does not proceed to entry 5. This is where the bound takes effect.
4. `2100-PROCESS-ENTRY` appends `(WS-SAMPLE-INDEX)` to each field name to read the current slot’s transaction code and amount. The parenthesized `WS-SAMPLE-INDEX` is an **ordinary numeric field**, not a table index. A table index (`INDEXED BY`) is introduced in Lesson 12; do not confuse the two.
5. `9000-REPORT` prints the processed count and ending balance. Both values were accumulated one slot at a time in the loop; the table is not scanned again to calculate them.

One final detail: `2100-PROCESS-ENTRY` takes no parameters. It reads the slot at the “current subscript,” so it is meaningful only when called inside the loop. If someone performs it on its own, it reads the subscript left behind by the previous loop.

## Modification Exercises

Start each of the three exercises independently from the original [`lesson.cob`](./lesson.cob); do not combine them. Requirements and constraints are in [`exercise.md`](./exercise.md), with reference answers in [`answer.md`](./answer.md).

1. Change the fourth amount from `20.00` to `35.00`. Check which output lines change, which stay the same, and why the ending balance changes.
2. Expand both capacity and `WS-LAST-SAMPLE` to 5, load a fifth entry with code `C` and amount `10.00`, and confirm all five entries are processed. Capacity, number loaded, and traversal bound must all be 5.
3. Observe the boundary: keep capacity at 4 and change only the initial value of `WS-LAST-SAMPLE` to 5. Does the compiler report an error? What does the program print for entry 5? Explain why increasing only the traversal bound is dangerous in a batch job.

Exercise 3 is the central point of this lesson: it lets you see “reads from the wrong place without an error” for yourself.

## Apply It Elsewhere

Create a fixed-capacity table for five accounts (account number `PIC X(10)` + balance `PIC 9(7)V99`), load at least three entries, traverse from the first through the last loaded entry using an ordinary numeric subscript, and print each account number and balance. Finally, report the processed count and total balance. When changing capacity, adjust the traversal bound too. State the capacity, number loaded, and traversal bound, and explain the difference between loaded and unfilled slots. Use only this lesson’s `OCCURS` and ordinary numeric subscripts; do not use `INDEXED BY`, `SEARCH`, files, or databases. No answer is provided; see [`exercise.md`](./exercise.md) for the assignment.

## Walk Through a Real Workflow

Placed into a complete daytime pipeline, this table fits into the following sequence:

1. **The list arrives.** An upstream system prepares the entries to handle separately today. In this lesson, four `MOVE` statements are hard-coded; from [Lesson 15](../15_sequential-file-read/README.md), this becomes a loop that opens a file, reads a record, and fills a slot.
2. **Load the batch into memory.** `1000-LOAD-TABLE` puts each entry in its numbered slot. A real system must first ensure that the list does not exceed capacity. If it does, process batches or stop with an error; never force extra entries into the table.
3. **Process each slot by subscript.** `2000-PROCESS-TABLE` advances from slot 1 to the last slot. `2100-PROCESS-ENTRY` handles the current entry: prints its detail, applies the transaction-code posting rule, and increments the count.
4. **Report two numbers.** `9000-REPORT` prints `処理件数` and `最終残高`. The first is reconciled with the upstream count the next day; the second with the balance. [Lesson 27](../27_logging/README.md) writes them to a log, and [Lesson 16](../16_file-writing/README.md) writes details to a result file for downstream processing.
5. **Hand off to the next system.** Downstream receives a result file or database records, not this in-memory table. The table exists for one run and disappears afterward, so the run must finish all required calculations and reporting.

Later lessons cover each step: file loading in Lesson 15, file output in Lesson 16, logging in Lesson 27, and databases from Lesson 29 onward.

## What Happens If This Code Goes to Production

- **Who schedules it:** A daytime or overnight batch scheduler, usually after a check that the input list is ready. This lesson hard-codes the list; Lesson 15 is where it begins reading a file.
- **Who reads the output:** Operators check the exit code first. Reconciliation staff check `処理件数` and `最終残高` the next day. These are the first figures compared with upstream; a count mismatch or a one-cent balance difference needs investigation that night.
- **Who is called when something goes wrong:** The main risk is not a crash but **a silent wrong result**. An out-of-range subscript does not produce a nonzero exit code. Operators see no alert, and the issue may surface only when next-day reconciliation finds a balance discrepancy—after a full night has passed. This lesson deliberately demonstrates the failure because a silent read is far harder to investigate than an immediate failure.
- **How the next system connects:** This lesson prints results to the terminal. A real pipeline writes details to a result file for downstream use (Lesson 16) or to a database (from Lesson 29).
- **The most likely first-month incident:** Capacity, loaded count, and traversal bound are maintained as three separate numbers. Someone increases the bound “to process a few more,” sees no problem with four test entries, and produces a wrong balance on launch day.

To be clear, this lesson provides “a fixed-size table and a minimal example that makes three numbers easy to compare,” not a production-ready batch. A real system still needs a source for capacity (rather than a hard-coded 4), range checks for each subscript, and a way to distinguish load failure from a partly filled table. The lesson makes capacity, loaded count, and traversal bound explicit precisely so you can see that they must agree.

Later lessons build on this table: [Lesson 12](../12_indexed-by/README.md) traverses a loaded account table with `INDEXED BY`; [Lesson 13](../13_search-tables/README.md) uses `SEARCH`/`SEARCH ALL` on a similar ordered table to match transaction account numbers to account master records; and [Lesson 14](../14_data-structures-practice/README.md) combines in-memory accounts and transactions. From Lesson 15, records are loaded one at a time from a file; [Lesson 16](../16_file-writing/README.md) places result rows in a table before writing them; [Lesson 18](../18_csv-processing/README.md) stores parsed CSV fields in an `OCCURS` table by subscript. [Lessons 21](../21_sort/README.md) and [22](../22_file-processing-practice/README.md) explain why an entire file should not be loaded into an `OCCURS` table.

## Evidence Sources

- Syntax check, compilation (`-Wall`), execution, and exit codes were run in this workspace: all three exit codes were `0`, compilation produced no diagnostics, and stdout matched the table above. Repeating the run after a comment change left output byte-for-byte unchanged.
- Runtime stderr contains only the libxml warning described above.
- The 32-byte table and 8-byte entries were confirmed from C generated by `cobc -C lesson.cob` (`static cob_u8_t b_17[32]` and address calculation `b_17 + 8LL * (subscript - 1)`), matching the manual calculation from `PIC X` = 1 byte and `PIC 9(5)V99` = 7 bytes.
- The out-of-range case was observed directly: with capacity 4 and `WS-LAST-SAMPLE` set to 5, compilation and execution both succeed (exit code `0`). Entry 5 prints `コード=0`, `金額=5`, followed by four nonprinting NUL bytes and `.00`. These are working-storage bytes next to the table, and the balance and count cannot be trusted. The exact bytes depend on compiler layout and are not portable; the default build does not enable subscript range checking.
- Modification exercises 1 (`35.00`), 2 (expand to five entries), and 3 (out-of-range observation) were rerun using temporary copies in this lesson directory; their output matched [`answer.md`](./answer.md).
- **Not verified:** The commands in this lesson do not use GnuCOBOL subscript-checking options such as `-fsubscript-check`; behavior with those options has not been tested.

## References

- [GnuCOBOL Programmer’s Guide: Table Handling](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Table-Handling)
- [GnuCOBOL Programmer’s Guide: Table References (subscripting)](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Table-References)
- [GnuCOBOL Programmer’s Guide: PERFORM (including VARYING)](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PERFORM)
- Course home in this repository: [README.md](../../README.md)
