---
_translated_from: lessons/16_file-writing/README.md
_translated_by: site-src/translation agent
---

# Lesson 16: Writing Accepted and Rejected Result Files — Persisting Output with OPEN OUTPUT and WRITE

When an overnight batch finishes validation, a summary printed in the terminal is not a deliverable. Accepted details must go to the next system for posting; rejected details must enter a manual review queue. This lesson declares a sequential output file for each result stream, uses `OPEN OUTPUT` to create or truncate the files, and writes each record with `WRITE ... FROM`. Each result carries an `A` or `R` destination marker that routes it to `accepted.txt` or `rejected.txt`.

## The Business Setting

It is 1:00 a.m. The nightly batch has finished in the computer room. The validation program processed today’s transactions and split them into two groups: records that can continue go into `accepted.txt`; records that need a person to decide go into `rejected.txt`.

At 7:50 a.m., the review clerk arrives and opens the rejection list first, checking each item—an account mismatch, an unknown transaction code, a negative amount. Each has a corresponding response. At 8:10, the downstream posting program retrieves the accepted file and continues processing. These files have distinct consumers: **one is for the next program, and the other is for a person to review.** They are not logs that can be written and forgotten.

Because people and programs depend on them, one of the most costly incidents is not “one number was calculated incorrectly,” but “the program reported success while the file was empty or only partially written.” A calculation error may be caught during reconciliation. If a file should contain results but does not, the downstream system runs with an empty shell, often unnoticed until the next day.

This lesson answers two questions: when the program runs again the next day, does it replace yesterday’s results or append to them? And when writing is impossible—because the file cannot be opened, permissions are wrong, or a directory occupies the path—how does the program detect it, and what failures can it actually detect?

(The scenario is an educational demonstration. The institution, time, and record count are invented to clarify the problem and do not represent actual data from an institution.)

## Why Learn This Now

In Lesson 15, you learned to open a file and read its lines, while reporting “read to the end” differently from “the file could not be opened.” But that lesson’s result was only on the screen; it disappeared when the process exited and could not be handed over.

You might think, “Why not redirect screen output to a file?” The problem is the word “redirect”: it sends all standard output indiscriminately to one file, mixing accepted and rejected results. It also gives the program no way to answer whether the write succeeded. In a real batch, a result is not just text; it is **a deliverable to hand off**. You must know who receives it, what they receive, and who takes responsibility if they cannot receive it.

This lesson adds the output side. To write a result file, you need to decide how the file is declared, whether repeated runs overwrite or append, how to report a failed write, and whether rows already written before a failure still count. These problems apply to any batch program that writes files, not just COBOL. COBOL puts each choice in view and makes you answer explicitly.

The lesson uses four in-memory results already marked `A` or `R` to demonstrate the issues. Parsing input (fixed-length or CSV) is covered in [Lessons 17](../17_fixed-length-files/README.md) and [18](../18_csv-processing/README.md); those are where you will learn to interpret external records.

## What This Knowledge Point Is and What Problem It Solves

**What it is.** A set of statements for writing results: `SELECT` connects a program file to a real disk path, `FD` declares the size of each record, `FILE STATUS` returns the result of each I/O operation, `OPEN OUTPUT` determines whether to create or replace existing content, and `WRITE ... FROM` copies text from a result area into the FD record area and writes a line. In short, it gives your results a path out of the process.

**What business problem it solves.** It turns “processing results” from screen text into files that others can use. The accepted file is handed to a downstream program; the rejected file goes to a person or review process. Since the files have different consumers, they cannot be mixed. `FILE STATUS` also gives the program a chance to fail when writing did not succeed, instead of letting an empty file pass downstream as a successful result stream.

**When not to use it, and what can go wrong.** A common mistake is treating result files as logs or deciding success by looking only at screen output: the screen may look fine while the files contain no data. Another is assuming that `OPEN OUTPUT` makes reruns idempotent. It does not; it truncates and recreates the file. This lesson does not write to a temporary file and atomically replace the target, and it does not prevent partial results after a failure.

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you can:

- Declare a sequential output file with `SELECT` + `ASSIGN` + `ORGANIZATION IS LINE SEQUENTIAL` + `FILE STATUS`, and identify `PIC X(35)` under `FD` as the source of the 35-byte record width.
- Use `OPEN OUTPUT` to create or truncate a file, explain why this is not append mode, and observe old content being replaced.
- Use `WRITE ... FROM` to copy a record from `WORKING-STORAGE` into the FD record area and write a line, then verify that two records occupy 72 bytes.
- Route records to two files by their `A`/`R` destination markers and reconcile `SUMMARY 受理=02 拒否=02` with the row counts.
- Read `FILE STATUS`: opening failure displays a status and returns 1; according to the source, a write or close failure stops subsequent records, returns 1, and does not roll back rows already written.

Limits: this lesson reads no input files. Its examples are fixed in the program, so there is no “empty input” branch and no parsing or business validation. `A`/`R` are preloaded results, not decisions calculated here. The program does not append, use a temporary-file rename, lock files, check encoding, or write logs or database records. CSV and fixed-length parsing are covered in Lessons 17 and 18; separating business rejections from system failures is covered in [Lesson 26](../26_error-handling/README.md), and logging in [Lesson 27](../27_logging/README.md).

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not add `-std=cobol85`); source is fixed format: indicator in column 7, Area A from column 8, and Area B from column 12.
- **Column 72 is measured in bytes.** On this machine, a 72-character, 172-byte line containing Japanese text in Area B was truncated at byte 72 and `cobc` reported `error: invalid literal`; visible columns are counted in bytes, not characters. The lesson’s `lesson.cob` has 129 lines, with a maximum line length of 71 bytes. Neither program text nor comments extend beyond column 72.
- Linux terminal; no database, additional tools, or third-party libraries required.
- `ASSIGN TO "accepted.txt"` is a **relative file name**, so output goes to the **runtime working directory**. The lesson’s `accepted.txt` and `rejected.txt` are not protected by `.gitignore`, so do not run the program directly in the lesson directory. The commands below start from `lessons/16_file-writing/`, compile into `build/`, and run from there so both output files stay in `build/`.
- The executable and two output files are placed in `build/`, which is ignored by the repository. `rm -rf build` removes them together.

## Business and Knowledge Point

### Why results must be written to files

The screen is a “process”; the files are “products.” Splitting batch results into two files has business meaning: the accepted file continues to a posting/accounting program, while the rejected file goes to a person or review program. The results have already been classified before this lesson (the demonstration data has two accepted and two rejected records). The focus is not **how to decide acceptance**, but how to hand off the decision reliably: which file receives it, whether a rerun disrupts yesterday’s results, and what the job status is when writing fails.

### The 35-byte record layout

Both output files use the same record: 35 characters, five vertical-bar-separated fields, with the destination marker as the final field.

| Position | Width | Field | First sample record |
|---|---:|---|---|
| 1–10 | 10 | Transaction ID `TXN-nnnnnn` | `TXN-000001` |
| 11 | 1 | Separator `|` | `|` |
| 12–21 | 10 | Account number | `0001234567` |
| 22 | 1 | Separator `|` | `|` |
| 23 | 1 | Transaction type | `D` |
| 24 | 1 | Separator `|` | `|` |
| 25–33 | 9 | Amount (display format with two decimal places) | `000125.50` |
| 34 | 1 | Separator `|` | `|` |
| 35 | 1 | Destination marker `A`/`R` | `A` |

These 35 characters are the **physical record width**, not the number of business fields. `WRITE ... FROM` first moves the source text into the FD record area, then writes it. The record area width determines the record width (longer values are truncated; see below). The number of bytes per line in the file also depends on the trailing-space behavior described next, so these values are not always equal.

### Overwrite or append: the choice made by `OPEN OUTPUT`

First, answer the question from the introduction: when you rerun the next day, are yesterday’s results replaced or appended?

Under the same `ASSIGN` name, `OPEN OUTPUT` means “create or truncate and recreate.” If the file does not exist, it is created. If it exists, its length is set to zero before writing. The second and third runs do not append to old contents or leave old trailing rows. This is a common batch choice: a rerun for the same day yields the same result file. But it is **not** an idempotency guarantee: if a run writes fewer rows than the previous one, old rows do not disappear by themselves. (This lesson truncates and recreates the file, so old rows are not retained; append mode is a different open mode and is outside scope.)

### Thirty-five characters in the record area do not always mean 35 bytes in the file

When checking a file’s size, it is tempting to say “35 bytes times 4 rows equals 140 bytes.” There is a detail that changes that calculation.

With this toolchain, `LINE SEQUENTIAL` writes **variable-length lines** and removes trailing spaces from each record. The last character in each of this lesson’s four samples is `A` or `R`, so each 35-character record becomes exactly 35 bytes plus one newline. A local comparison confirmed the boundary: a 35-byte record ending in a space is written as a 34-byte line (`od -c` shows `...| \n`), making the whole file 35 bytes. Do not assume that file size always equals record width multiplied by row count.

### Three uses of `FILE STATUS`

“How does the program know when a write fails?” It checks the status immediately after each I/O operation. Each of the two files has its own `PIC XX` status field, checked after three types of statement:

- After `OPEN OUTPUT`: if status is not `00`, display it, set `RETURN-CODE` to 1, and exit immediately without any `WRITE`. On this machine, a target that is a directory, a read-only file, or in an unwritable directory returned status `37`.
- After `WRITE`: only status `00` increments the count and prints a `書込=...` line. Otherwise the program prints the failure status, sets `WS-WRITE-ERROR` to `Y`, and the loop stops before writing more records.
- After `CLOSE`: status `00` prints `クローズ=... 成功`; failure also sets the error flag, and the final `IF` sets `RETURN-CODE` to 1.

Together these checks define the error policy: **open failure exits immediately; write or close failure stops further records, closes files already open, and returns a nonzero code**. Rows already written are not cleaned up (see “Evidence Sources and Verification Scope”).

### Destination markers come from the table; `WHEN OTHER` is unreachable in the sample

`EVALUATE` recognizes only destination markers `A` and `R`. `WHEN OTHER` prints `書込=FAILED REASON=UNKNOWN_DESTINATION` and sets the error flag. This branch is **unreachable** with the lesson’s sample: all markers are literals loaded by `1000-LOAD-RESULTS`, and external input cannot change them. It is a safeguard for someone modifying the source; if the loader is changed to use a third marker, the program reports a system failure rather than silently treating it as accepted or rejected. That record goes to neither file, so the two write counts will sum to less than the table size (Exercise 1 lets you observe this).

## Input and Rules

**Input:** None. Four sample records are literals in `1000-LOAD-RESULTS` (demonstration data, not real business policy). The program reads no terminal, file, or database input, so every run is identical.

**Output contract:**

| Item | Contract |
|---|---|
| File names | `accepted.txt` (destination `A`), `rejected.txt` (destination `R`) |
| Location | Runtime working directory (relative paths) |
| Organization | `ORGANIZATION IS LINE SEQUENTIAL` |
| Record area | `PIC X(35)` |
| Line ending | One `\n` on Linux; trailing spaces are not written |
| Overwrite behavior | `OPEN OUTPUT` truncates and recreates; it does not append |
| Normal outputs | Two lines in each file, 72 bytes per file |
| Normal exit code | `0`; open failure returns `1` (observed); write/close failures return `1` according to source (write failure status was not injected; see evidence notes) |

**Rules, prerequisites, and who validates them:**

| Rule / prerequisite | Guaranteed by | Checked in this lesson? |
|---|---|---|
| Each record is exactly 35 bytes, with five vertical-bar-separated fields | Literals in `1000-LOAD-RESULTS` | **No** — `PIC X(35)` only fixes width; longer values receive a `-Wtruncate` compile warning and are truncated to 35 |
| Destination marker is only `A` or `R` | Same loader paragraph | Partly — `WHEN OTHER` is a fallback, unreachable with sample data |
| Which file receives a record | `EVALUATE` dispatch on destination marker | Yes |
| Last marker agrees with the file containing the record | No one; a person must keep the two markers in sync | **No** — changing only the routing marker can put a line ending in `|R` into the accepted file |
| Output file can be created and written | Runtime filesystem permissions and file type | Yes; status other than `00` returns `1` |
| Counts include only records actually written | Increment occurs after `FILE STATUS = "00"` | Yes |
| Data has reached the physical disk | Operating system and runtime buffering | **No** — see the `FILE STATUS=00` limitation in “Evidence Sources and Verification Scope” |

## Complete Example Source

See [`lesson.cob`](./lesson.cob) for the complete fixed-format source.

```cobol
      * 输出用相对文件名：写在运行时的当前目录。
      * OPEN OUTPUT 覆盖同名旧文件，本课不追加。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRITE16.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT 受理-FILE
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-受理-STATUS.
           SELECT 拒否-FILE
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-拒否-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD 受理-FILE.
       01 FD-受理-RECORD PIC X(35).
       FD 拒否-FILE.
       01 FD-拒否-RECORD PIC X(35).
       WORKING-STORAGE SECTION.
      * 样例是程序内演示数据，不是读入的真实交易。
       01 WS-RESULT-TABLE.
          05 WS-RESULT-ENTRY OCCURS 4 TIMES.
             10 WS-RESULT-DESTINATION PIC X.
             10 WS-RESULT-TEXT PIC X(35).
       01 WS-RESULT-NUMBER PIC 9 VALUE ZERO.
       01 WS-受理-STATUS PIC XX VALUE SPACES.
       01 WS-拒否-STATUS PIC XX VALUE SPACES.
       01 WS-受理-COUNT PIC 9(2) VALUE ZERO.
       01 WS-拒否-COUNT PIC 9(2) VALUE ZERO.
      * 写/关闭失败即停止并返回 1；已写行不回滚。
       01 WS-WRITE-ERROR PIC X VALUE "N".
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT 受理-FILE
           IF WS-受理-STATUS NOT = "00"
               DISPLAY "オープン=受理 失敗 状態="
                   WS-受理-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "オープン=受理 成功"
           OPEN OUTPUT 拒否-FILE
           IF WS-拒否-STATUS NOT = "00"
               DISPLAY "オープン=拒否 失敗 状態="
                   WS-拒否-STATUS
               CLOSE 受理-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "オープン=拒否 成功"
           PERFORM 1000-LOAD-RESULTS
           PERFORM VARYING WS-RESULT-NUMBER FROM 1 BY 1
               UNTIL WS-RESULT-NUMBER > 4
                   OR WS-WRITE-ERROR = "Y"
               PERFORM 2000-WRITE-ONE-RESULT
           END-PERFORM
           PERFORM 9000-CLOSE-OUTPUTS
           IF WS-WRITE-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       1000-LOAD-RESULTS.
           MOVE "A" TO WS-RESULT-DESTINATION(1)
           MOVE "TXN-000001|0001234567|D|000125.50|A"
               TO WS-RESULT-TEXT(1)
           MOVE "A" TO WS-RESULT-DESTINATION(2)
           MOVE "TXN-000002|0007654321|T|000040.00|A"
               TO WS-RESULT-TEXT(2)
           MOVE "R" TO WS-RESULT-DESTINATION(3)
           MOVE "TXN-000003|0002468101|X|000000.00|R"
               TO WS-RESULT-TEXT(3)
           MOVE "R" TO WS-RESULT-DESTINATION(4)
           MOVE "TXN-000004|0009999999|T|000020.00|R"
               TO WS-RESULT-TEXT(4).
       2000-WRITE-ONE-RESULT.
           EVALUATE WS-RESULT-DESTINATION(WS-RESULT-NUMBER)
               WHEN "A"
                   WRITE FD-受理-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-受理-STATUS = "00"
                       ADD 1 TO WS-受理-COUNT
                       DISPLAY "書込=受理"
                           " 取引=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "書込=受理 失敗 状態="
                           WS-受理-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN "R"
                   WRITE FD-拒否-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-拒否-STATUS = "00"
                       ADD 1 TO WS-拒否-COUNT
                       DISPLAY "書込=拒否"
                           " 取引=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "書込=拒否 失敗 状態="
                           WS-拒否-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
      * 目的地标记只有 A/R；非 A/R 按系统失败处理。
               WHEN OTHER
                   DISPLAY "書込=FAILED REASON=UNKNOWN_DESTINATION"
                   MOVE "Y" TO WS-WRITE-ERROR
           END-EVALUATE.
       9000-CLOSE-OUTPUTS.
           CLOSE 受理-FILE
           IF WS-受理-STATUS = "00"
               DISPLAY "クローズ=受理 成功"
           ELSE
               DISPLAY "クローズ=受理 失敗 状態="
                   WS-受理-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           CLOSE 拒否-FILE
           IF WS-拒否-STATUS = "00"
               DISPLAY "クローズ=拒否 成功"
           ELSE
               DISPLAY "クローズ=拒否 失敗 状態="
                   WS-拒否-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           DISPLAY "SUMMARY 受理=" WS-受理-COUNT
               " 拒否=" WS-拒否-COUNT.
```

The above is all 129 source lines, excluding no program statements, and matches [`lesson.cob`](./lesson.cob) line for line. Comments retain only three business constraints—outputs are relative paths and `OPEN OUTPUT` overwrites, sample data is fixed in the program, and write/close failure stops processing and returns a code—plus the fallback note before `WHEN OTHER`. Per-line translations and repeated explanations have been removed.

## Source Reading Path

1. `SELECT 受理-FILE` / `SELECT 拒否-FILE` (lines 8–15): each `ASSIGN` sets the external file name (relative to the current directory), `ORGANIZATION IS LINE SEQUENTIAL` means one record per line, and `FILE STATUS IS` assigns a separate `PIC XX` status field.
2. `01 FD-受理-RECORD PIC X(35).` under `FD 受理-FILE.` (lines 18–21): the record area width is the physical width of each record (trailing spaces are not written; see the knowledge section).
3. `WS-RESULT-TABLE` (lines 24–27): each of four results has a destination marker and 35-byte text. **This table is the program’s only result source**; no statement recalculates acceptance or rejection from other fields.
4. The first part of `0000-MAIN` (lines 37–53): open the accepted file and check status, then open the rejected file and check status. If the second open fails, close the already-open accepted file before returning 1.
5. `PERFORM VARYING ... UNTIL WS-RESULT-NUMBER > 4 OR WS-WRITE-ERROR = "Y"` (lines 55–59): `4` is the table capacity; the second condition means “stop after a write failure.” Understanding when both conditions are true tells you how the loop exits.
6. `2000-WRITE-ONE-RESULT` (lines 78–110): `EVALUATE` selects a file by marker, `WRITE ... FROM` writes, and the following status check chooses between incrementing the count and printing `書込=...`, or reporting failure and setting the error flag. The transaction ID in `書込=受理 取引=000001` is obtained from characters 5–10 of the record using reference modification `WS-RESULT-TEXT(n)(5:6)`.
7. `9000-CLOSE-OUTPUTS` (lines 111–129): close and check each file, then print two counts in `SUMMARY`. Each count is `PIC 9(2)`, so it displays as `02`.

## Run and Observe

Compile and run from `build/`; the output files stay there and do not pollute the lesson directory:

```sh
mkdir -p build                                  # 输出文件写在这里
cobc -fsyntax-only lesson.cob                             # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_16 lesson.cob      # 编译并生成可执行文件
(cd build && ./lesson_16)                        # 在 build/ 里运行，输出落在该目录
echo $?                                                   # 查看退出码
wc -lc build/accepted.txt build/rejected.txt   # 行数与字节数
cat build/accepted.txt build/rejected.txt      # 两份文件的内容
rm -rf build                                     # 清理可执行文件与两个输出文件
```

Each command demonstrates a different step: `-fsyntax-only` only checks parsing; `-x -Wall -o` creates the executable, and a successful compile returns `0` without diagnostics; the program must run from `build/` for the output to land there; `wc` and `cat` verify row counts, byte counts, and contents; `rm -rf build` removes all generated files. There are no intermediate files to preserve.

**Expected standard output (9 lines):**

```text
オープン=受理 成功
オープン=拒否 成功
書込=受理 取引=000001
書込=受理 取引=000002
書込=拒否 取引=000003
書込=拒否 取引=000004
クローズ=受理 成功
クローズ=拒否 成功
SUMMARY 受理=02 拒否=02
```

**Output guide:** `オープン=` = open; `受理` = accepted; `拒否` = rejected; `書込=` = write; `取引=` = transaction ID; `クローズ=` = close; `失敗 状態=` = failure and status; `SUMMARY 受理=02 拒否=02` = summary of two accepted and two rejected records. Program output follows the repository’s Japanese convention; use the actual output and the English descriptions here to assess behavior.

**Expected results:**

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` return code | `0` |
| `cobc -x -Wall` return code | `0`, no compiler diagnostics |
| Standard output | The 9 lines above |
| Process exit code | `0` |
| `accepted.txt` | 2 lines, 72 bytes |
| `rejected.txt` | 2 lines, 72 bytes |

`accepted.txt`:

```text
TXN-000001|0001234567|D|000125.50|A
TXN-000002|0007654321|T|000040.00|A
```

`rejected.txt`:

```text
TXN-000003|0002468101|X|000000.00|R
TXN-000004|0009999999|T|000020.00|R
```

**Independent check:** Of the four results, two markers are `A` and two are `R`, so each file has two lines. Each line has 35 characters and ends in a non-space, so it occupies `35 + 1 = 36` bytes. Therefore `2 × 36 = 72` bytes per file. The two files contain four lines total, matching the four table entries, and `02 + 02 = 04` in `SUMMARY`; nothing was duplicated or omitted. Compare each ID printed in `書込=` with characters 5–10 of the corresponding file record.

**Observed environment detail:** Running the executable prints `Warning: program compiled against libxml 212 using older 209` to standard error. This is a runtime library version warning, not this program’s business output; the component causing it has not been identified. `cobc -x -Wall` itself emits no diagnostics.

### Evidence Sources and Verification Scope

All conclusions here were run with GnuCOBOL 3.2.0 in this workspace. The executable and output files were placed in `build/`; the lesson directory retained only the four source files.

| Scenario | Clean starting point | Expected and observed |
|---|---|---|
| Normal path | Clean `build/` directory (no same-named files) | Syntax check and compile return `0`, no diagnostics; 9 output lines; exit `0`; each file has 2 lines and 72 bytes; `od -c` shows each line ends in `\n`. Matches. |
| Rerun (overwrite) | First write four bytes, `OLD`, to both files in `build/` | Both become 72 bytes and contain only the four sample records; `OLD` is gone. After two consecutive runs, files remain 72 bytes and standard output is byte-for-byte identical. Nothing is appended. Matches. |
| Open failure 1 | Make `accepted.txt` a directory in `build/` | Prints `オープン=受理 失敗 状態=37`, exit `1`; no output files are created. Matches. |
| Open failure 2 | Make `rejected.txt` a directory in `build/` | Prints `オープン=受理 成功`, then `オープン=拒否 失敗 状態=37`, exit `1`; **the accepted file has already been created as an empty file (0 bytes)**. The lesson does not clean it up. Matches. |
| Open failure 3 | Make the working directory unwritable (`chmod -w`) or make `accepted.txt` read-only (`0444`) | Both cases print `オープン=受理 失敗 状態=37`, exit `1`. Matches. |

**Not verified and known limits (not presented as conclusions):**

- **The write-failure status path was not injected.** To make `WRITE` return non-`00`, the underlying write must fail. With `ulimit -f 0`, the process was terminated by `SIGXFSZ` after the first `WRITE` (exit code `153`); both files were 0 bytes and no final `クローズ=` lines printed. This was process termination by signal, not the program reporting `FILE STATUS`. Thus “write failure → print status → stop later writes → return 1” is supported by source inspection only, not a runtime observation.
- **`FILE STATUS = "00"` does not mean data reached disk.** When `accepted.txt` was a symlink to `/dev/full`, the program still printed all 9 output lines, both `クローズ=... 成功` lines, and exited `0`, even though the device accepted no data. The four records (72 bytes total) did not fill the runtime output buffer, so the flush failure was not reflected in `WRITE` or `CLOSE`. This is a buffering/runtime boundary (possibly related to this toolchain’s buffering and close behavior; not investigated further). Production needs an additional mechanism to guarantee persistence; this lesson does not provide one.
- **There is no input file, and therefore no “empty input” case.** Only the output side can fail here. Empty input, overlong lines, and missing fields belong to Lessons 15, 17, and 18.
- The 35-byte truncation of the record area was observed at compile time: lengthening a sample to 46 characters caused `-Wall` to report `warning: value size exceeds data size [-Wtruncate]`, and only the first 35 bytes were written. Trailing-space removal was verified separately with a 35-byte record ending in a space.

## Walking Through a Real Workflow

Placed into a complete overnight chain, this program sits in the middle-to-later steps:

1. **Around 12:30 a.m.**, the upstream core system exports the day’s transactions to a file in a shared directory. Reading that file is covered in [Lesson 15](../15_sequential-file-read/README.md).
2. **Around 1:00 a.m.**, a validation program classifies records as accepted or rejected. Classification uses conditions from Lesson 04 onward, `EVALUATE` from Lesson 05, and an `OCCURS` table from Lesson 11. This lesson receives those results (the four in-program samples stand in for real data).
3. **This lesson** writes the results to `accepted.txt` and `rejected.txt`. This is where processing results first become files that continue to exist after the process ends.
4. **From 7:50 a.m.**, review staff open the rejection file and handle records requiring a human decision.
5. **At 8:10 a.m.**, the downstream posting program retrieves the accepted file. Starting in [Lesson 22](../22_file-processing-practice/README.md), the course joins input, validation, and output into a full batch; [Lesson 32](../32_bank-reconciliation-project/README.md) is the capstone. Logging and distinguishing business rejections from system failures are covered in [Lessons 27](../27_logging/README.md) and [26](../26_error-handling/README.md).

In short, this is not the end of the chain. It is **the gate that hands off results**. On one side is an in-memory decision; on the other is something another person or program can actually use. It is easy to overlook whether anything got through this gate.

## What Happens If This Code Goes to Production

- **Who schedules it:** An overnight batch scheduler, usually after the validation program finishes and results are ready. It recognizes executable paths and exit codes, not screen output.
- **Who reads its output:** The output is the two files, not the screen. The accepted file goes to a downstream posting/accounting program; the rejected file enters a manual review queue.
- **Who is called if something goes wrong:** A nonzero exit code wakes the on-call operator, who checks the status (for example, `37` for a permissions or file-type problem) and whether an empty shell file was created. More troubling is exit `0` with an empty file (see the `/dev/full` limitation above).
- **How the next system connects:** A downstream posting program consumes the accepted file; Lessons [22](../22_file-processing-practice/README.md), [26](../26_error-handling/README.md), [27](../27_logging/README.md), and [32](../32_bank-reconciliation-project/README.md) also use the `accepted.txt`/`rejected.txt` output path, with record content and widths defined for each interface. [Lesson 17](../17_fixed-length-files/README.md) explains fixed-length output without newlines; [Lesson 18](../18_csv-processing/README.md) parses external input.
- **Most likely first-month incident:** Assuming that a rerun is idempotent. This lesson writes the same four records on every run, which can look idempotent, but that is only the coincidence of overwrite mode and a fixed record count. If one run writes fewer records, old rows do not disappear by themselves.

A real production job also needs agreements about batch- or date-specific file names, append versus overwrite, writing a temporary file and atomically renaming it, cleaning partial output and retry rules, encoding, checksums, and alerts. This lesson implements only “truncate and recreate + nonzero exit code + no rollback”; none of the other controls are included.

## Exercises and References

### Modification Exercises (with answers)

1. **Change routing.** Starting from the original [`lesson.cob`](./lesson.cob), change only two lines for the fourth result in `1000-LOAD-RESULTS`: change `MOVE "R" TO WS-RESULT-DESTINATION(4)` to `MOVE "A"`, and change the final character in the `TXN-000004` result text to `A`. The standard output still has 9 lines, but line 6 becomes `書込=受理 取引=000004` and line 9 becomes `SUMMARY 受理=03 拒否=01`. `accepted.txt` has 3 lines / 108 bytes, `rejected.txt` has 1 line / 36 bytes, and the exit code remains `0`.
2. **Check overwrite and rerun.** In a temporary run directory, first run `printf 'OLD\n' > accepted.txt` and `printf 'OLD\n' > rejected.txt`, then run the unmodified program. Expect the same 9 standard-output lines as the normal path, byte for byte, and exit code `0`. Both files grow from 4 to 72 bytes and contain only the sample records; `OLD` is gone.

Full requirements, baseline, change constraints, commands, expected line-by-line differences, and questions are in [`exercise.md`](./exercise.md). Reference answers cover these two exercises in [`answer.md`](./answer.md).

### Apply It Elsewhere (no answer)

Add a third output route for results that require manual review. Add a third destination marker (for example, `H`), declare a new output file (for example, `review.txt`), add a `WHEN` branch to `EVALUATE`, and add a count to `SUMMARY`. Choose file names, record contents, and widths, then explain how to reconcile each file’s row and byte counts, whether the three counts equal the number of table entries, and whether each record’s trailing marker agrees with its file. See [`exercise.md`](./exercise.md); no answer is provided.

## References

- [GnuCOBOL Programmer’s Guide: ENVIRONMENT DIVISION / FILE-CONTROL (`SELECT`, `ORGANIZATION`, `FILE STATUS` codes)](https://superbol.eu/gnucobol/gnucobpg/chapter5.html#select)
- [GnuCOBOL Programmer’s Guide: LINE SEQUENTIAL](https://superbol.eu/gnucobol/gnucobpg/chapter5.html#organization-line-sequential)
- [GnuCOBOL Programmer’s Guide: OPEN](https://superbol.eu/gnucobol/gnucobpg/chapter7.html#open)
- [GnuCOBOL Programmer’s Guide: WRITE](https://superbol.eu/gnucobol/gnucobpg/chapter7.html#write)
- [Course Directory](../DIRECTORY.md)
- [Repository Course Home](../../README.md)
