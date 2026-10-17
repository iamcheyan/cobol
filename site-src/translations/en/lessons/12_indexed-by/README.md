---
_translated_from: lessons/12_indexed-by/README.md
_translated_by: site-src/translation agent
---

# Lesson 12: INDEXED BY — Traverse an Account Table with a Table Index

## The Business Setting

At 8:45 a.m., fifteen minutes before the branch morning meeting, the risk team sends over a list of accounts to watch today. Before the doors open, each account’s balance snapshot must go into the duty log so counter staff can answer customers.

The list is short. This lesson uses four accounts, because the point is not volume but whether the reported count matches the rows actually printed. If one account is missed, staff have no snapshot; if an extra one appears, the meaningless row looks like a missed read.

So the practical question is: **which entries did I actually read?** `INDEXED BY` is the subject of this lesson.

## Why Learn This Now

In [Lesson 11](../11_occurs-tables/README.md), you read a table with `WS-ACCOUNT-NUMBER(2)`, where `2` is an ordinary `PIC 9` numeric field.

You might ask why learn another syntax when you can keep a `WS-I`, initialize it to 1, increment it after each entry, and stop at 4. That works, but **the number you maintain is not bound to the table**. It is like a note saying “slot 2” that the table itself does not recognize. If the number is reused inside the loop or incremented before the table read, the wrong entry is read, and the program may still finish without a diagnostic.

`INDEXED BY` gives the table definition responsibility for the current occurrence. The index name is attached to `OCCURS`; use `SET` to position or advance it, and put the index name in the table reference. This makes it impossible to separate the position marker from the table access in the same way.

Two boundaries: an index does not search by key; Lesson 13 covers `SEARCH`. It also does not protect you from going past the table end; by default that is silent, as demonstrated below.

## What This Concept Is and What Problem It Solves

**What it is.** Add `INDEXED BY index-name` to an `OCCURS` clause to declare a **table index**. It has no `PIC` and is not a business number; it represents the access position. `SET index-name TO 1` positions at the first occurrence, `SET index-name UP BY 1` advances one, and a reference such as `WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)` reads that occurrence.

**What it solves.** It binds “which entry to process” to “which entry to read.” This provides three practical benefits:

- Each step reads fields from the same slot; the account number and balance cannot accidentally come from different occurrences.
- The table definition owns the current position, so there is no separate number to maintain and accidentally corrupt.
- A separate count (`WS-PROCESSED-COUNT PIC 9(3)` here) can report how many entries were processed and be reconciled against the printed rows.

**When not to use it, and what goes wrong:**

- For a keyed lookup such as finding account `0007654321`, use Lesson 13’s `SEARCH`.
- Do not put a large file or database extract into an `OCCURS` table; its capacity is fixed at compile time. See Lessons 21–22.
- If the loop end exceeds table capacity, the default compiler and runtime do not stop you. The program reads bytes beyond the table and may still report success. Exercise step 2 demonstrates this.

## Capabilities and Limits After This Lesson

You can:

- Declare a table index with `INDEXED BY` on an `OCCURS` item.
- Position it with `SET idx TO 1` and advance with `SET idx UP BY 1`.
- Use the same index to read multiple fields of one occurrence.
- Explain the difference between a `USAGE INDEX` index and a `PIC 9` numeric subscript, and why this repository moves indexes with `SET` instead of integer arithmetic.
- Set a traversal endpoint with `PERFORM UNTIL idx > loaded-count` and understand that an out-of-range index is not caught by default.

Limits: no keyed search (`SEARCH` is Lesson 13), sorting, file or database input; the capacity and accounts are program constants. An index represents only the current occurrence, not business meaning.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (no `-std=cobol85`), fixed-format source.
- Linux terminal; no database, extra tools, or third-party libraries.
- No external input; the executable is created under `build/`.

## Looking Inside the Code

### Keep the Two Similar-Looking Numbers Distinct

In [`lesson.cob`](./lesson.cob), loading and traversal are separate:

- `1000-LOAD-ACCOUNTS` loads four **constant** accounts using literal numeric subscripts `(1)` through `(4)`. These are program constants, not file input.
- `2000-DISPLAY-ACCOUNTS` reads entries using an index; `2100-DISPLAY-ONE-ACCOUNT` prints one row.

| Number | Where it appears | Who determines it |
|---|---|---|
| `4` in `OCCURS 4 TIMES` | Table definition | Compile-time **capacity** (number of slots) |
| `WS-LAST-ACCOUNT PIC 9 VALUE 4` | Separate `PIC 9` field | Program-set **number loaded** (last slot to process) |

They are both four here. Exercises 1 and 2 make them disagree so you can see the result. Also remember: increasing capacity without adding load statements leaves empty slots that can still be read as garbage.

### What Indexes and Numeric Subscripts Do

| | Ordinary numeric subscript | Table index (`INDEXED BY`) |
|---|---|---|
| Declaration | Separate `PIC 9` numeric field | Index name on `OCCURS`; no `PIC` |
| Meaning | Occurrence number; can participate in arithmetic | Access position associated with the table; position/movement uses `SET` |
| Bounds | Literal subscripts are checked at compile time | Runtime `SET` and loop condition determine position; no compile-time check |

The last row matters. With capacity 4, literal `WS-ACCOUNT-NUMBER(5)` is caught by `cobc`, which reports `error: subscript of 'WS-ACCOUNT-NUMBER' out of bounds: 5` and returns 1. But changing `WS-LAST-ACCOUNT` to 5 while capacity remains 4 compiles and runs with exit code 0, reading unrelated bytes beyond the table. **An exit code of 0 does not mean the result is correct.**

To make runtime out-of-range access fail, compile with `cobc -x -fsubscript-check=full -fec=EC-BOUND-SUBSCRIPT ...`. With these options the access returns 1 as a runtime error; see exercise step 2.

One repository convention: move indexes only with `SET`. The toolchain does not enforce this: a temporary copy using `ADD 1 TO WS-ACCOUNT-IDX` instead of `SET WS-ACCOUNT-IDX UP BY 1` compiled and produced identical output. It runs, but treats the index like an ordinary integer and loses the table-associated meaning. Other compilers or later changes may not preserve that behavior.

### Fixed Format and Column Positions (Measured in Bytes)

Column 7 is blank throughout (no continuation indicators; lines 5, 11, 21, and 31 are comment lines marked `*`). `IDENTIFICATION DIVISION`, `01`, and paragraph names start in column 8 (Area A); `MOVE`, `SET`, and `PERFORM` start in column 12 (Area B). On line 7, level number `05` occupies columns 11–12, following the repository’s established convention; GnuCOBOL’s default dialect accepts it (`cobc -fsyntax-only -fareacheck` returns 0). The longest code line is 57 bytes and the longest comment is 71; neither passes column 72 into ignored columns 73–80.

## Source Reading Path

Key parts of [`lesson.cob`](./lesson.cob):

- `WS-ACCOUNT-TABLE`: `05 WS-ACCOUNT-ENTRY OCCURS 4 TIMES` with `INDEXED BY WS-ACCOUNT-IDX` declares capacity four. Each occurrence contains `WS-ACCOUNT-NUMBER PIC X(10)` (account number with leading zeros) and `WS-ACCOUNT-BALANCE PIC 9(7)V99` (seven integer and two decimal digits). `WS-ACCOUNT-IDX` is the table index.
- `WS-LAST-ACCOUNT PIC 9 VALUE 4`: the last occurrence to process. It is a **numeric count**, not an index; it must equal the number loaded and not exceed capacity.
- `1000-LOAD-ACCOUNTS`: loads constants into four slots using numeric subscripts `(1)` through `(4)`.
- `2000-DISPLAY-ACCOUNTS`: `SET WS-ACCOUNT-IDX TO 1` positions at the first slot. `PERFORM UNTIL WS-ACCOUNT-IDX > WS-LAST-ACCOUNT` stops only after the index passes the last item, so entry 4 is processed.
- `2100-DISPLAY-ONE-ACCOUNT`: the index in `WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)` makes this an indexed reference. The same index reads account number and balance from the same slot. After reading, `SET ... UP BY 1` advances.
- `9000-REPORT`: displays the processed count.

## Run and Observe

The program uses constants only, so it behaves the same in any directory. The commands below assume this lesson’s directory.

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                    # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_12 lesson.cob      # 编译并生成可执行文件
./build/lesson_12                                # 运行程序，输出写到标准输出
echo $?                                          # 查看上一条命令的退出码
rm -rf build                                     # 清理生成的可执行文件
```

Expected stdout (`口座=` means account; `処理件数=` means processed count, following the repository’s Japanese output convention):

```text
口座=0001234567 BALANCE=0001000.00
口座=0007654321 BALANCE=0000250.75
口座=0000000042 BALANCE=0000000.00
口座=0002468101 BALANCE=0000520.00
処理件数=004
```

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` exit code | `0`, no diagnostics |
| `cobc -x -Wall` exit code | `0`, no diagnostics |
| Standard output | The five lines above, in fixed account order |
| Process exit code | `0` |
| Generated file | `build/lesson_12` only |

The output can be checked from the four literal balances in `1000-LOAD-ACCOUNTS`: `1000.00`, `250.75`, `0.00`, and `520.00`. `PIC 9(7)V99` displays seven integer digits and two decimal digits (for example `0001000.00`). The third entry’s zero balance is valid data, not an unfilled slot. Processed count `004` equals the four traversed entries.

Environment note: running `./build/lesson_12` in this workspace writes `Warning: program compiled against libxml 212 using older 209` to stderr. This is a linked-library version warning, not business output; stdout contains the program output and the exit code is 0. The same warning appears in later lessons.

### Evidence and Unverified Items

- The commands above, five output lines, `-fsyntax-only -fareacheck` result 0, and maximum line lengths (57 code bytes/71 comment bytes) were measured with GnuCOBOL 3.2.0 in this workspace. Runtime stderr contains only the libxml warning. Syntax-only checking cannot replace compilation and execution.
- Both out-of-range cases were tested with temporary copies: literal `WS-ACCOUNT-NUMBER(5)` at capacity 4 fails syntax checking with the diagnostic above and return code 1; setting `WS-LAST-ACCOUNT` to 5 with capacity 4 compiles with return code 0 and runs with return code 0 while reading beyond the table.
- Both exercises were tested on temporary copies. Step 1 (expand capacity and loaded count to five and add an entry) prints `口座=0005550001 BALANCE=0000075.00` as line 5 and `処理件数=005`, exit code 0. Step 2 (set the endpoint to 6 while capacity stays 5) compiles and runs with code 0, printing meaningless out-of-table bytes on line 6 (including NULs). Recompiling with `-fsubscript-check=full -fec=EC-BOUND-SUBSCRIPT` stops stdout after line 5, reports an out-of-range `WS-ACCOUNT-BALANCE` subscript in stderr, and exits 1.
- **Not verified:** The exact bytes beyond the table depend on compiler layout and are not portable. Other compilers and bounds-checking options were not tested. This lesson also does not verify that the loaded count matches the true input count; that becomes relevant when files are read from Lesson 15 onward.

## Modification Exercise

Expand the account table to five entries and load account `0005550001` with balance `75.00`, then separately observe what happens when the loop endpoint exceeds capacity. Step 1 should add `口座=0005550001 BALANCE=0000075.00` after line 4 and change the count to `005`, with the first four rows unchanged byte for byte. For step 2, change only the endpoint to `6` and check the predicted boundary behavior. Full requirements, constraints, and commands are in [`exercise.md`](./exercise.md); reference answers are in [`answer.md`](./answer.md).

## Apply It Elsewhere

Create an `OCCURS` table for five accounts with an `INDEXED BY` index. Load at least three using ordinary numeric subscripts, then traverse from the first entry through the last loaded entry with the index. Explain which command would verify that an out-of-range index is detected. Use only syntax from Lessons 11–12; no `SEARCH`, `SORT`, files, or databases. See [`exercise.md`](./exercise.md); no answer is provided.

## Walk Through a Real Workflow

1. **Where the list comes from:** These four accounts are hard-coded in four `MOVE` statements in `1000-LOAD-ACCOUNTS`. In a real batch the list comes from an upstream file or account master: Lesson 15 reads a file record by record; from Lesson 29, a database query supplies it.
2. **Who receives the traversed rows:** Here “account + balance” is displayed on screen. Lesson 16 writes it to a result file, and Lesson 27 records it in a log for duty staff.
3. **What the final count is for:** Here it is `004`. A real batch reconciles it with the number supplied upstream and rows received downstream. A mismatch leads to the overnight investigation in Lesson 20 or the capstone in Lesson 32.
4. **What changes next:** Lesson 13 looks up keys in a similar table. The list contains account numbers, and balances are retrieved from the account master by key; this uses `SEARCH`, not traversal.

The small `処理件数` output is not decoration: it is a numeric answer to “how many entries did I process?”

## What Happens If This Code Goes to Production

- **Who schedules it:** An overnight batch or a pre-opening preparation job. Duty staff need the balance snapshot before opening.
- **Who reads the output:** Counter and duty staff read the rows; reconciliation staff check `処理件数`. Check the exit code first, then the count.
- **Who is called when something goes wrong:** If count and printed rows disagree, the first question is whether the values really came from the table.
- **How the next system connects:** Account balances go to a result file (Lesson 16) or log (Lesson 27); until the master lookup, they are demonstration data in memory.
- **The most likely first-month incident:** Capacity is increased without updating `WS-LAST-ACCOUNT`, or the endpoint is raised beyond capacity. The program does not report an error, but the count in the log is already misleading. Exercises 1 and 2 demonstrate these cases.
- **What is still missing:** File input, checking that accounts exist, runtime bounds protection, and failure reporting. Lessons 15, 13, and 26 respectively add these pieces. This example teaches traversal of the correct slots; it is not a production balance-query program.

## References

- [GnuCOBOL Programmer’s Guide: OCCURS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#OCCURS)
- [GnuCOBOL Programmer’s Guide: SET Index](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SET-Index)
- [GnuCOBOL Programmer’s Guide: SET UP/DOWN](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SET-UP_002fDOWN)
- [GnuCOBOL Programmer’s Guide: Table Subscripting versus Table Indexing](https://superbol.eu/gnucobpg/chapter12.html#table-subscripting-versus-table-indexing)
- Previous lesson: [Lesson 11 OCCURS Fixed-Size Tables](../11_occurs-tables/README.md)
- Next lesson: [Lesson 13 SEARCH](../13_search-tables/README.md)
- Course directory: [DIRECTORY.md](../DIRECTORY.md)
