---
_translated_from: lessons/17_fixed-length-files/README.md
_translated_by: site-src/translation agent
---
# Lesson 17: Fixed-Length Account Master — 27 Bytes per Record, with Field Positions as the Interface

Account master files exported by core systems and mainframes often look like this: they have no line breaks, and field positions themselves define the fields. This lesson reads the three account records in [`accounts.dat`](./accounts.dat) one at a time according to `RECORD CONTAINS 27 CHARACTERS`, rearranges the fields into “customer ID + account number + balance,” and writes them as another 27-byte file, `balances.dat`. It then reconciles “width, offset, and record count” using the total file size—because with this kind of file, nobody tells you when they do not add up.

## The Business Situation

At 3:30 on Wednesday afternoon, Mr. Li from the accounting team drops a file named `ACCTMST.20261014` in the shared directory and leaves with one sentence: “The core system’s account master export. A multiple of 27.”

You take a look. The file is indeed 81 bytes. But unlike the transaction file you handled last week, **it does not contain a single line break**. `cat` shows one long run of characters, and `wc -l` dutifully reports `0`. You try to use `awk` to split it into columns, but to `awk` the entire file is just “one column,” because its view of the world is that newlines separate records.

The interface document Mr. Li left is one page with just three lines:

```text
1-10   账户号
11-18  客户号
19-27  余额（隐含两位小数）
```

That document is the contract. It is not a “suggestion” or “roughly right”: which of the 27 bytes belongs to whom is the only agreement between you and the upstream core system you cannot open.

Here is why that page matters: **if the width is off by even one byte, you will not get an error message**. Suppose the upstream system exports one extra byte one day (or somebody opens the file in an editor and saves it “as lines”). Every field from the affected column onward shifts to the right. The program still opens the file, reads the records, prints a report, and exits with code `0`; every amount in the report is wrong, and the log is perfectly clean.

That is what this lesson addresses: making width, offsets, and byte counts things that can be checked against one another.

## Why Learn This Now

First, be clear about what your current tools can do. In [Lessons 15 and 16](../15_sequential-file-read/README.md), you learned to open a sequential file, `READ` records one by one, finish with `AT END`, and `WRITE` results. But those were **line-sequential files**: each record ends with a newline, line lengths come from the file contents, and the compiler handles record boundaries for you.

You might think, “Then I just write less code. How is that a step backward?”

The problem is those words “for you.” A fixed-length file has no newlines, so the compiler has no basis for guessing the boundaries. It can only follow your declarations exactly: `RECORD CONTAINS 27 CHARACTERS` says 27, and `PIC X(10)` says the account number occupies 10 bytes. If the declarations are wrong, it will not complain; it will split the file the way you told it to, and hand you the mis-split data all the same.

So what this lesson really teaches is not “one more syntax rule.” It teaches **what evidence you need to show that you got it right after record boundaries move from the file contents into your declarations**. The answer is three things that corroborate one another: record width, field offsets, and total file size. You have described the interface correctly only when all three agree.

The multi-file reading, key matching, and end-to-end file batches in Lessons 19–22 all depend on this. If you read the account master incorrectly, none of the later matching results can be trusted.

## What This Concept Is and What Problem It Solves

**What it is.** Record length is fixed in the program: `ORGANIZATION IS SEQUENTIAL` together with `RECORD CONTAINS 27 CHARACTERS` fixes “one record is 27 bytes”; `PIC X(10)`, `PIC X(8)`, and `PIC 9(7)V99` fix each field’s position in the record. Every `READ` consumes exactly 27 bytes, then splits the fields according to the positions you declared. There are no separators in the file; byte 28 is the start of the next record.

**What business problem it solves.** It lets “an account master hundreds of gigabytes in size” coexist with “an interface document a person can read”:

- Offsets in a fixed-length record are constants that can be calculated. The program can stream through a large file sequentially without building an index or scanning for separators. That was essential in the mainframe era, and it still applies when reading files exported by core systems today.
- Once field positions are written into the document, “bytes 19 through 27 are the balance” becomes part of the interface itself. If the upstream layout changes, that line must change too, making a mismatch between the two sides easy to spot.
- The cost is that it **does not protect itself**. With a CSV, a missing comma may be immediately obvious. With fixed-length data, a one-byte shift may not surface until someone looks at a report and asks, “Why is this amount wrong?”

**When not to use it.** CSV is a better fit when people need to open the file, when it is exchanged between organizations, or when field lengths vary (Lesson 18). Use a database when you need conditional queries or transactions (starting in Lesson 29). Fixed-length files are for interfaces between machines where lengths are fixed and the volume is large enough to require sequential streaming. This lesson does not cover finer interface agreements such as character encoding or on-disk numeric representation; they belong in the same interface document but are outside this lesson’s scope.

## Capabilities and Limits After This Lesson

After completing this lesson, you can:

- Declare a fixed-length file with no line breaks using `ORGANIZATION IS SEQUENTIAL` and `RECORD CONTAINS 27 CHARACTERS`, and explain how it differs from `LINE SEQUENTIAL`.
- Explain the FD record layout by byte offset (account number 1–10, customer ID 11–18, balance 19–27), and calculate that `PIC 9(7)V99` for the balance occupies 9 digit bytes.
- Read fixed-length records one by one with `READ ... AT END`, distinguishing “read a record” from “reached the end of the file.”
- Rearrange fields by name with `MOVE`, write a 27-byte output record with `WRITE`, and explain why the output field order can differ from the input.
- Reconcile the input and output byte counts three ways with `wc -c`, `od -c`, and `3 × 27 = 81`, confirming that record count, width, and offsets are consistent.

Limit: the program checks whether the input/output files open, write, and close successfully, but it **does not validate** that the input file’s total byte count is a multiple of 27. An input with an incomplete final record or stray line breaks is silently misread (see “Limits and Failure Cases” below for measured behavior). Business validation and record rejection begin in [Lesson 18](../18_csv-processing/README.md); system failures and return-code categories are covered in [Lesson 26](../26_error-handling/README.md); sorting, matching, and an integrated batch are covered in Lessons 21 and 22.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not add `-std=cobol85`); source is fixed format.
- Linux terminal; no database, extra tools, or third-party libraries are needed.
- Input fixture [`accounts.dat`](./accounts.dat): three 27-byte records, 81 bytes total, with no line breaks between records.
- `ASSIGN TO "accounts.dat"` uses a relative file name, so the runtime directory must contain it. Copy the fixture into a temporary directory before running to avoid leaving output files in the lesson directory.

## Fixed-Length Records vs. Line-Sequential Records

| Comparison | Line sequential (`LINE SEQUENTIAL`, Lessons 15 and 16) | Fixed length (`ORGANIZATION IS SEQUENTIAL`, this lesson) |
|---|---|---|
| Record boundary | Defined by a newline byte | Defined by the width declared in `RECORD CONTAINS` |
| Record length | May vary from line to line | The same for every record |
| Record count | Counted by lines | Inferred from total file bytes ÷ record width |
| Text editor | Can be saved normally | Inserts newline bytes and damages field offsets |

Because records have no separators, `cat` joins the entire file into one line, and `wc -l` reports `0` lines. To inspect its layout, look at the bytes, for example with `od -An -c -w27 accounts.dat`, which displays exactly one record per line.

The easiest mistake here is opening the file in an editor. “I’ll just take a look and save it while I’m here.” The editor writes newline bytes between records, turning an 81-byte file into an 84-byte file. When the program splits it into 27-byte chunks, the newlines are read as field contents, shifting every field starting with the first record.

The reverse does not work either: do not expect line-sequential input to make the file “readable.” In a temporary variant where the only change is switching the input organization from `ORGANIZATION IS SEQUENTIAL` to `LINE SEQUENTIAL`, reading the same 81-byte fixture (with the rest of the program unchanged), the 27-byte record area cannot hold a whole line. All three `READ`s return status `06` (record area too short), and one extra record containing leftover data is read at the end. After widening the record area to `PIC X(100)`, the entire file is read as **one** 81-byte record, and the three accounts can no longer be separated. So you cannot work around a fixed-length interface by changing the file organization; both sides of the exchange must agree on “no separators, split at this width.” That is why this lesson declares `ORGANIZATION IS SEQUENTIAL` and defines the FD for 27 bytes.

## Input Contract and Record Layout

The input record layout is shown below (`V` is an implied decimal point and occupies no physical byte):

| Byte positions | Length | Field declaration | First record |
|---:|---:|---|---|
| 1–10 | 10 | `05 FD-ACCOUNT-NUMBER PIC X(10)` | `0001234567` |
| 11–18 | 8 | `05 FD-CUSTOMER-ID PIC X(8)` | `C0001042` |
| 19–27 | 9 | `05 FD-ACCOUNT-BALANCE PIC 9(7)V99` | `000100000` |

The balance’s 9 digit bytes represent a 7-digit integer and 2 decimal places, so `000100000` is read as `1000.00`. The account numbers, customer IDs, and balances for the three records are:

| Record | Account number | Customer ID | Balance digits | Balance |
|---:|---|---|---|---:|
| 1 | `0001234567` | `C0001042` | `000100000` | 1000.00 |
| 2 | `0002468101` | `C0002042` | `000002000` | 20.00 |
| 3 | `0007654321` | `C0003042` | `000025075` | 250.75 |

The output file `balances.dat` also uses 27-byte records, but the first two fields are swapped, putting the customer ID first:

| Byte positions | Length | Field declaration | First output record |
|---|---:|---|---|
| 1–8 | 8 | `05 FD-OUT-CUSTOMER-ID PIC X(8)` | `C0001042` |
| 9–18 | 10 | `05 FD-OUT-ACCOUNT-NUMBER PIC X(10)` | `0001234567` |
| 19–27 | 9 | `05 FD-OUT-BALANCE PIC 9(7)V99` | `000100000` |

Why change the order? Part of the reason is teaching: you can see that `MOVE` transfers fields by name and that the order on disk follows the declarations; these are independent. The other part is real life: the sender and receiver commonly arrange fields in the order convenient to each of them. The order can differ as long as the widths have been agreed. Rearranging fields does not change any byte widths; it only changes which byte positions contain each field, so the byte counts still reconcile. The input is `3 × 27 = 81` bytes, and the output is `3 × 27 = 81` bytes. Both widths are determined jointly by `RECORD CONTAINS 27 CHARACTERS` and the field `PIC` clauses.

**Input contract (guaranteed by upstream; not validated by the program):**

- The total file size must be a multiple of 27; the final record must not be incomplete.
- No newline bytes or other separators may appear between records.
- The balance field must consist of 9 digit bytes. This lesson does not perform business validation on the balance (negative values, upper/lower bounds, and currency rules are not checked).

**Empty and missing files:** An empty `accounts.dat` of length 0 opens successfully. The first `READ` immediately takes `AT END`, the count is `00`, `balances.dat` is 0 bytes, and the exit code is 0. If the file does not exist, `OPEN INPUT` fails; the program prints the status code and exits with code 1 without creating an output file.

**Counter width:** `WS-RECORD-COUNT` is `PIC 9(2)`, so it can represent only `00`–`99`. The three-record fixture is far below the limit. In a measured run with 100 records (2700 bytes), `balances.dat` is still the correct 2700 bytes, but `クローズ完了 件数=` displays `00`. If the count may reach three digits, the counter must be widened.

## A Path Through the Source

See the complete source in [`lesson.cob`](./lesson.cob). Read it in data-flow order; the four paragraphs have these responsibilities:

| Paragraph | Responsibility | Key statements |
|---|---|---|
| `0000-MAIN` | Open input and output, check status, process the loop, close files, and choose the return code | `OPEN`, `PERFORM UNTIL`, `STOP RUN` |
| `1000-READ-AND-WRITE` | Read the next 27-byte record; set the end flag in `AT END` | `READ ... AT END` |
| `1100-WRITE-BALANCE-RECORD` | Rearrange the three fields by name, write a 27-byte record, and count it | `MOVE`, `WRITE` |
| `9000-CLOSE-FILES` | Close both files and check close status | `CLOSE` |

There are three points worth pausing to look at:

1. `FD-ACCOUNT-RECORD` is a shared 27-byte **record area**. Each `READ` overwrites this area with a new record, so you must move the data out immediately after reading it. `1100-WRITE-BALANCE-RECORD` is deliberately in the same loop iteration as `READ` so that the next `READ` cannot overwrite data that has not yet been moved. This is one of the most common mistakes in this kind of program.
2. The two fields declared with `FILE STATUS IS` are refreshed after each file operation. The program checks and displays their status after `OPEN`, `WRITE`, and `CLOSE`. `READ` uses only the `AT END` phrase to detect the end and does not inspect other read statuses (the measured results and reason for this are described in the next section).
3. `WS-END-OF-FILE` means `AT END` was reached; `WS-IO-ERROR` means a write or close failed. The loop ends if either is `"Y"`. If `WS-IO-ERROR` is `"Y"`, the program eventually exits with `RETURN-CODE = 1` so it does not hand off an incomplete result as a success. `件数` increases only when `WRITE` status is `"00"`, so it counts **successfully written records**, not records read.

### Fixed-Format Check (by Byte)

The fixed-format column rules apply to this lesson too: column 7 is the indicator area, Area A starts at column 8, Area B at column 12, and program text must not go beyond column 72. Code lines in this lesson start in only three places: column 8 (`DIVISION`, `FD`, level `01` fields, and paragraph names), column 11 (level `05` fields, indented consistently this way across this repository), and column 12 or later (statements and their continuations). All 11 comment lines put `*` in column 7, following the convention used throughout the repository.

`cobc` 3.2.0 measures column positions in UTF-8 source files by **byte**, so Chinese comments must also be measured in bytes. Run these three commands to check this lesson’s source (`LC_ALL=C` makes `awk` count bytes; the first two skip comment lines whose column 7 is `*` and inspect only code that is actually compiled):

```sh
LC_ALL=C awk '/^      \*/ {next} {if (length($0)>72) print "over72", NR, length($0)}' lesson.cob
LC_ALL=C awk '/^      \*/ {next} {i=match($0,/[^ ]/); if (i>0 && i<12 && i!=8 && i!=11) print "bad column", NR, i}' lesson.cob
LC_ALL=C awk '{if (length($0)>m) {m=length($0); n=NR}} END {print "max bytes", m, "line", n}' lesson.cob
```

Measured result: the first two commands produce no output—no compiled code line passes column 72, and no line starts in columns 1–7, 9, or 10. The third prints `max bytes 98 line 19`. Line 19 is the longest Chinese comment in this lesson (98 bytes). Comments are not compiled, and the compiler does not report comments extending beyond column 72, so the measurement is recorded as is. Excluding comments, the longest code line is `max bytes 72 line 96`: the `DISPLAY` statements on lines 96 and 102 containing Japanese literals are exactly 72 bytes, so even one more character would have to be removed.

Two easy traps: in UTF-8 source, `cobc` 3.2.0 counts columns in bytes. If Chinese or Japanese text in a **string literal** makes a line longer than 72 bytes, the compiler truncates it (in a measured test, adding two bytes after the literal on line 96 made `cobc` report `continuation character expected` and `invalid literal: ... missing terminating " character`). Chinese in comments is not subject to this constraint, though this lesson still keeps comments near the readable 72-byte range. Also, `cobc -fsyntax-only` does **not** report a case such as “a level `05` starts in column 11”: a level number may legally start in Area A (columns 8–11), and this repository consistently places level `05` fields in column 11. Check column positions with the commands above rather than expecting the compiler to report them.

## Run and Observe

The program binds input and output using relative file names. Enter the lesson directory first, or put `accounts.dat` and the executable in the same directory. The following commands place both the compiled executable and runtime output in a temporary directory, keeping the lesson directory clean:

```sh
cd lessons/17_fixed-length-files
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob                          # 只做语法检查，不生成可执行文件
cobc -x -Wall -o "$scratch_dir/lesson_17" lesson.cob   # 编译并生成可执行文件
cp accounts.dat "$scratch_dir/"                        # 夹具复制到运行目录
(cd "$scratch_dir" && ./lesson_17)                     # 运行程序，业务输出写到标准输出
wc -c "$scratch_dir/balances.dat"                      # 核对输出文件字节数
od -An -c -w27 "$scratch_dir/balances.dat"             # 按 27 字节一行查看输出记录
```

Each command has a separate job: `-fsyntax-only` only proves the syntax can be parsed; `-x -Wall` actually creates the executable and reports compiler warnings; `cp` puts the fixture in the runtime directory (`ASSIGN` uses a relative file name); `(cd ... && ./lesson_17)` runs the program and writes business output to standard output; `wc -c` and `od` check output byte count and record layout; `trap`/`rm -rf` clean up. You can compile directly in the lesson directory, but do not leave the executable or `balances.dat` there, and do not delete or overwrite `accounts.dat`.

**Expected standard output:**

```text
ファイルを開きました
出力 口座番号=0001234567 顧客番号=C0001042 残高=0001000.00
出力 口座番号=0002468101 顧客番号=C0002042 残高=0000020.00
出力 口座番号=0007654321 顧客番号=C0003042 残高=0000250.75
クローズ完了 件数=03
```

**Chinese translation of the Japanese output:** `ファイルを開きました` = both the input and output files have been opened; `出力 口座番号=… 顧客番号=… 残高=…` = the account number, customer ID, and balance for each written record; `クローズ完了 件数=03` = close completed; 3 records were written. The balance appears as `0001000.00` because that is the display format for `PIC 9(7)V99`: 7 integer digits padded with leading zeroes, a decimal point, and 2 fractional digits.

**Expected output file:** `balances.dat` is 81 bytes total, or `3 × 27`. Grouped into 27-byte records, it looks like the following three lines (the file contains no newline bytes; line breaks here are only for viewing):

```text
C00010420001234567000100000
C00020420002468101000002000
C00030420007654321000025075
```

**Expected exit code and file status codes:**

| Observation | Expected value |
|---|---|
| Exit code from `cobc -fsyntax-only` | `0` |
| Exit code from `cobc -x -Wall` | `0`, no compiler diagnostics |
| Program standard output | The 5 lines above |
| Process exit code | `0` |
| `wc -c balances.dat` | `81` |
| `OPEN INPUT` status (`WS-ACCOUNT-STATUS`) | `00` |
| `OPEN OUTPUT` / `WRITE` / `CLOSE` status | `00` (otherwise, prints `STATUS=` and exits with 1) |
| `WS-END-OF-FILE` | `"Y"` after all records have been read |

### Limits and Failure Cases

The following results were observed in this workspace using the lesson source and actual input files (the input was assembled as needed; the program itself was not changed):

| Input file size in bytes | Observed behavior | Exit code |
|---:|---|---:|
| 81 (normal fixture, 3 records) | Count `03`, `balances.dat` is 81 bytes | 0 |
| 0 (empty file) | Opens successfully; first `READ` reaches `AT END`; count `00`; `balances.dat` is 0 bytes | 0 |
| 54 (2 complete records) | Count `02`, output is 54 bytes | 0 |
| 28 (1 complete record + 1 trailing byte) | Still reports count `02`: the second record begins with that single byte; the remaining bytes contain leftover data from the previous record. Output is 54 bytes | 0 |
| 82 (3 complete records + trailing newline) | Reports count `04`; record 4 is misaligned. Output is 108 bytes | 0 |
| 84 (text editor saved with a newline after each record) | Reports count `04`; all fields are misaligned (the account number contains newline and adjacent-record characters). Output is 108 bytes | 0 |
| File missing (or program run from another directory) | `入力ファイルを開けません STATUS=35`; no output file is created | 1 |
| Output directory is not writable | `出力ファイルを開けません STATUS=37`; input file is closed; no output file is created | 1 |

Pay attention to the “Exit code” column: among the six input cases, the 28-, 82-, and 84-byte files are bad, yet **none makes the program report an error**. The common invariant in the examples above is that the number of records read equals `⌈file size in bytes ÷ 27⌉`, and output size equals `record count × 27`.

**The program does not treat a malformed layout as an error.** With an incomplete final record, GnuCOBOL 3.2.0 still returns status `00`; bytes that were not overwritten retain leftover data from the previous record. It also does not recognize files containing newlines. “The total number of bytes is a multiple of 27” is therefore an upstream precondition, not something this lesson validates. To actively report this kind of problem, you need an additional length check and failure policy (Lesson 26).

### Evidence and Scope

- Verified: the syntax check and compilation shown above (no `-Wall` diagnostics), normal execution, empty file, missing input file, unwritable output directory, and observed behavior and byte counts for inputs of 27/54/28/82/84 bytes. Results from `wc -c`, `wc -l`, `od -An -c -w27`, and `cmp` agree with the text.
- Environment detail: running the executable prints `Warning: program compiled against libxml 212 using older 209` to standard error. This warning comes from a local linked-library version difference; it is not business output from this program and does not affect the exit code.
- Not verified: `WRITE`-failure and `CLOSE`-failure branches (they require a full disk or a close failure, and this lesson did not construct such an environment). Sorting, multiple-file, and database behavior are out of scope.

## Modification Exercise

Starting from the original [`lesson.cob`](./lesson.cob) for this lesson, change the declaration order of the output FD fields to account number, customer ID, and balance, so the output layout matches the input layout. Leave all three `MOVE` statements and every `PIC` width unchanged.

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_17 lesson.cob
cp accounts.dat build/
(cd build && ./lesson_17)
wc -c build/balances.dat
cmp accounts.dat build/balances.dat
rm -rf build
```

Expected difference: standard output remains the same 5 baseline lines (the field names have not changed); `balances.dat` is still 81 bytes, but each record is now “account number + customer ID + balance digits,” making it byte-for-byte identical to `accounts.dat`. `cmp` prints nothing and exits with code 0. The location of the change, the complete byte comparison, and the reason are in [`answer.md`](./answer.md); the full exercise is in [`exercise.md`](./exercise.md).

## Apply What You Learned

Design an interface for a 32-byte fixed-length customer record: an 8-byte customer ID, a 20-byte name, and a 4-byte status. Concatenate two records byte by byte (do not insert line breaks), then use the same `READ`/`MOVE`/`WRITE` approach to read and output each customer ID and status. Submit a field-offset table, total input file size, actual runtime output, and an explanation of how line terminators damage fixed-length boundaries. Continue to use fixed-length records and `PIC` declarations; do not switch to `LINE SEQUENTIAL` or introduce a database. See [`exercise.md`](./exercise.md); no answer is provided.

## Follow a Real Workflow

In an overnight processing chain, this lesson’s output fits into the following sequence:

1. **Afternoon to evening:** the core system exports the account master as `ACCTMST.<date>` into a shared directory. The file name includes a date, the contents have no line breaks, and the size is a multiple of 27—just as Mr. Li’s document specified.
2. **The night batch begins:** this program reads the master and writes each account’s current balance to fixed-width `balances.dat`. (A production version would also take a date parameter, log activity, and validate the file length; this lesson does none of those. See the next section.) Why is the output fixed length too? Downstream reporting and comparison programs read by record offsets and do not understand commas.
3. **The day’s transactions are processed next:** [Lesson 18](../18_csv-processing/README.md) processes the CSV transaction file, [Lesson 19](../19_multiple-files/README.md) advances the master and transaction input streams together, and [Lesson 20](../20_file-matching/README.md) performs a sequential match by account number to compare “master balance” with “master + today’s transactions.”
4. **If both the master and transactions are unsorted,** insert a sort step ([Lesson 21](../21_sort/README.md)). Together, these steps form the end-to-end file batch in [Lesson 22](../22_file-processing-practice/README.md).
5. **A person ultimately decides whether the books balance:** [Lesson 27](../27_logging/README.md) writes counts and differences to a log; [Lessons 29 and 30](../29_embedded-sql/README.md) retrieve account snapshots from a database; [Lesson 31](../31_data-synchronization/README.md) writes reconciliation results back to the database and creates a difference file; the flow culminates in the complete reconciliation project in [Lesson 32](../32_bank-reconciliation-project/README.md).

One link in the chain deserves a separate mention: [Lesson 23](../23_copybooks/README.md) extracts this 27-byte layout into a Copybook. Why extract it? By Lessons 19 and 20, several programs read the same layout. If each one defines it independently, someone may change a `PIC` width one day and update only some of the programs. That would be the same kind of field-shift incident described here, and it could take a long time to find.

## What Happens If This Code Goes into Production

- **Who schedules it:** the overnight batch scheduler. The program does not check the length, so production generally needs an outer “file readiness check” (for example, confirm the file size is divisible by 27) to stop obviously malformed input before opening it.
- **Who checks the output:** the on-call operator first checks the exit code; the reconciliation operator compares `クローズ完了 件数=` with the record count supplied upstream. **If the counts differ, investigate that night.** This is the only check the program proactively reports.
- **How the next system consumes it:** later matching, reporting, and database-loading programs read `balances.dat` by fixed offsets. Once its layout is in production, it is an external interface. Changing the width is an interface change and must be agreed as a version change.
- **The most likely incident in the first month:** someone opens the master “for a quick look” in an editor and saves it again. The file grows from 81 to 84 bytes, the program still finishes, the count becomes `04`, and the report gains a misaligned account. That is why this lesson practices the 82- and 84-byte cases: **no error message does not mean nothing went wrong**.
- **What it still lacks:** it does not validate file length or business data; the `WRITE`/`CLOSE` failure branches are unverified; the counter has only two digits. Before production use, these all need work: length checks and failure routing are in Lesson 26, logging is in Lesson 27. This lesson proves only that “width ⇄ offset ⇄ total byte count” is consistent for a small file; it does not claim complete production-grade assurance.

## References

- [GnuCOBOL Programmer's Guide: ORGANIZATION SEQUENTIAL](https://superbol.eu/gnucobpg/chapter5.html#organization-sequential)
- [GnuCOBOL Programmer's Guide: FD and RECORD clauses](https://superbol.eu/gnucobpg/chapter6.html#fileasort-description)
- [GnuCOBOL Programmer's Guide: Sequential READ](https://superbol.eu/gnucobpg/chapter7.html#sequential-read)
- [GnuCOBOL Programmer's Guide: WRITE](https://superbol.eu/gnucobpg/chapter7.html#write)
- Repository course home: [README.md](../../README.md)
