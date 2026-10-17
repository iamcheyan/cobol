---
_translated_from: lessons/13_search-tables/README.md
_translated_by: site-src/translation agent
---

# Lesson 13: SEARCH and SEARCH ALL — Match a Transaction’s Account Number to an Account

A transaction file contains an account number but no balance. This lesson loads four accounts into an in-memory table, uses sequential `SEARCH` and binary `SEARCH ALL` to find account `0002468101` and its `520.00` balance, then follows the “account not found” path separately.

## The Business Setting

At 7:30 a.m. on reconciliation day, last night’s transaction file is ready. The problem is obvious: each transaction contains only an account number, such as `0002468101`, **with no balance, status, or customer name**. To determine whether the transaction is valid, first use its account number to find that account in the master record; only then can you compare balances.

Whether the lookup succeeds determines what happens next. A match proceeds to normal comparison. A miss goes to a manual queue, where someone investigates the account number: a new account, an unsynchronized master, or an erroneous transaction?

Someone may suggest “treat a missing account as a zero balance” to save time. Do not do that. **“Not found” and “balance is zero” are different results.** Treating a miss as zero can silently erase an amount that should have been investigated. The report may still look balanced, and the problem may not be found until after a close. That is why this lesson searches for the nonexistent account `0005550000` and shows exactly what happens at `AT END`.

Account masters are generally maintained in account-number order, so a common first thought is to use binary `SEARCH ALL`. You can, but it carries a precondition: `SEARCH ALL` assumes **you have already guaranteed that the table is sorted and its keys are unique**. If the assumption is false, it does not report an error. This lesson includes two probes: reverse the load order, then expand to five entries and load in descending order. The compiler stays silent, and this machine produces the same line-by-line result as the baseline. The key lesson is not “binary is faster”; it is **a lookup is only valid when someone guarantees its preconditions, and a test cannot catch every precondition failure**.

## Why Learn This Now

In the previous lesson, you learned to move through entries one at a time using an `INDEXED BY` index. That is traversal, not lookup by account number. To search by traversal, you would have to write your own loop, compare each entry, and maintain a flag recording whether a match occurred. That gets slow on a large table, and a missing flag update can cause a wrong result.

COBOL provides two ways to search by value:

- `SEARCH`: compare entries one at a time, starting where you specify, until a match or the table end.
- `SEARCH ALL`: binary search. It uses far fewer comparisons, but requires the table to be ordered as declared and keys to be unique.

You may think you can just sort before using binary search. That is the right direction, but COBOL’s ordering comes from two things together: an `ASCENDING KEY` declaration and load code that **actually** loads entries in that order. The declaration is only a statement of the expected order; it does not sort the table. The compiler does not catch a wrong order, which this lesson demonstrates.

## What This Concept Is and What Problem It Solves

**What it is.** Search a loaded table for an item by key. Sequential `SEARCH` does not require sorted data; it starts at an index position you set. Binary `SEARCH ALL` requires an `INDEXED BY` index, a key ordering consistent with `ASCENDING KEY` or `DESCENDING KEY`, and unique keys. Once a match is found, other fields in the same occurrence can be read too; here, the balance is read immediately after the account number matches.

**What it solves in business systems.** It turns relationships such as “which account owns this transaction?” or “what rate applies to this product?” into a deterministic lookup instead of a manual decision. Reconciliation, interest calculation, monthly close, and eligibility checks all begin by finding a master record using an account number, customer number, or product code. Without that step, later balance comparisons and status checks cannot proceed.

**What to do when there is no match is part of the concept.** `AT END` is the “not in the table” path. In business terms it is not “balance zero”; it is a separate outcome to report, such as routing to a manual queue, logging it, or rejecting the transaction. The programmer must state what happens on a miss instead of letting it fall into the normal path.

**When not to use it.** If the table is unsorted or keys may repeat, use `SEARCH`; if the data changes each time and its order cannot be guaranteed, forcing `SEARCH ALL` is a risk. A genuinely large master should not be loaded wholesale into an in-memory table; file lookup and `SORT` are covered in Lessons 17 and 21.

## Capabilities and Limits After This Lesson

After this lesson, you can:

- Use `SEARCH` to check table keys sequentially from a chosen index and handle a miss with `AT END`.
- Use `SEARCH ALL` for binary search in a table declared with `ASCENDING KEY` and `INDEXED BY`.
- Explain the requirements for the index, key ordering, and unique keys in `SEARCH ALL`, and who maintains each.
- Search for the same account with both methods and confirm that they return the same balance; confirm that both methods output `NOT_FOUND` for a missing account.
- Explain why declaring `ASCENDING KEY` does not make the data sorted, and what this lesson’s probes can and cannot reveal about that risk.

Limits: this lesson uses only a four-entry in-memory table of program constants. It does not read files or databases and does not cover indexed files. `SEARCH` does not require sorted data, but `SEARCH ALL` requires keys to be unique and ordered as declared. Loading and sorting workflows are covered with files and `SORT` in Lessons 17 and 21.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (no `-std=cobol85`), fixed-format source.
- Linux terminal; no database or extra tools required.
- No input fixtures or output data files; build products are under `build/` and can be deleted and recreated.

## Sample Account Table

See [`lesson.cob`](./lesson.cob) for the complete source. The program loads four accounts into an `OCCURS` table in ascending `X(10)` account-number order. Account numbers are unique, and the third entry has a balance of `520.00`.

These four entries are **demonstration data** hard-coded in the program and loaded by `1000-LOAD-ACCOUNTS`; they do not come from a file. This determines what the lesson can and cannot demonstrate.

| Entry | Account number | Balance |
|---:|---|---:|
| 1 | `0000000042` | 0.00 |
| 2 | `0001234567` | 1000.00 |
| 3 | `0002468101` | 520.00 |
| 4 | `0007654321` | 250.75 |

The table declares `ASCENDING KEY IS WS-ACCOUNT-NUMBER` and provides a search index with `INDEXED BY WS-ACCOUNT-IDX`. Account numbers are fixed-width text with leading zeros and equal lengths, so ascending character order is the same as ascending account-number order.

The program searches for two targets twice each: `0002468101`, which is present, and `0005550000`, which is absent.

## SEARCH and SEARCH ALL

`SEARCH WS-ACCOUNT-ENTRY` is sequential search. The program first positions the index at entry 1 with `SET WS-ACCOUNT-IDX TO 1`, then each `WHEN` compares the current entry’s account number to the target. If there is no match, `SEARCH` advances automatically. If it reaches the end, control goes to `AT END`. In short: **you provide the starting point; it walks the table**.

`SEARCH ALL WS-ACCOUNT-ENTRY` is binary search. It chooses which entry to inspect and which half of the remaining range to discard, so it needs far fewer comparisons. The trade-off is in its preconditions: the table needs an `INDEXED BY` index and an `ASCENDING KEY` (or `DESCENDING KEY`) declaration; the **actual loaded keys must be in the declared order**, and they must be unique. If any condition is missing, the result is not guaranteed.

| Search method | How it compares | Preconditions |
|---|---|---|
| `SEARCH` | Checks entries sequentially from the current index until found or at the table end | No key sort required; set a suitable starting index before searching |
| `SEARCH ALL` | Binary search narrows the range of an ordered table | Requires `INDEXED BY`, keys ordered as declared, and unique keys |

**A declaration does not sort data.** `ASCENDING KEY` states the order required if the table is used with `SEARCH ALL`. It is not a sort instruction; the program will not reorder the table. The load code establishes the actual order, and in this lesson that is `1000-LOAD-ACCOUNTS`.

## What Each Part of the Program Does

- `1000-LOAD-ACCOUNTS`: writes four accounts into the table using literal subscripts. Account numbers are strictly ascending and unique. **This is the only place in this lesson that guarantees the table order**, not the `ASCENDING KEY` declaration.
- `0000-MAIN`: sets target `0002468101`, runs sequential and binary search, then changes the target to `0005550000` and runs both searches again.
- `2000-SEQUENTIAL-SEARCH`: prints `検索=SEQUENTIAL` and the target key, resets the index to entry 1 with `SET WS-ACCOUNT-IDX TO 1`, then searches. Do not omit the reset: `SEARCH` starts from the **current** index, so without it the second lookup would continue from where the first stopped.
- `3000-BINARY-SEARCH`: prints `検索=BINARY` and runs `SEARCH ALL`; the search chooses its own starting position.
- A match prints `検出 口座=... 残高=...`; a miss takes its own `AT END` branch and prints `NOT_FOUND`.
- `WS-ACCOUNT-IDX` is used only to reference an occurrence (`WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)`), not in ordinary arithmetic.

## Run and Observe

The program reads no input file, command-line arguments, or database, so it behaves the same in this lesson’s directory and elsewhere. Commands below assume this lesson’s directory.

**Input:** None. The four accounts and two search targets are fixed program data.

**Commands and their purpose:**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                  # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_13 lesson.cob    # 编译并生成可执行文件
./build/lesson_13                              # 运行程序，查找结果写到标准输出
echo $?                                        # 查看退出码
rm -rf build                                   # 清理生成的可执行文件
```

**Expected results:**

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x` exit code | `0`, no compilation diagnostics |
| Standard output | Eight lines, shown below |
| Process exit code | `0` |

```text
検索=SEQUENTIAL キー=0002468101
逐次検索=検出 口座=0002468101  残高=0000520.00
検索=BINARY キー=0002468101
二分検索=検出 口座=0002468101  残高=0000520.00
検索=SEQUENTIAL キー=0005550000
逐次検索=NOT_FOUND
検索=BINARY キー=0005550000
二分検索=NOT_FOUND
```

**Output glossary (Japanese output → meaning):** `検索` = search method (`SEQUENTIAL` or `BINARY`); `キー` = search key; `逐次検索` / `二分検索` = result of each method; `検出` = found; `口座` = matched account number; `残高` = account balance (`PIC 9(7)V99`, with `520.00` zero-filled as `0000520.00`); `NOT_FOUND` = no match.

**Observed environment detail:** Running the executable in this workspace writes `Warning: program compiled against libxml 212 using older 209` to stderr. This is a runtime linked-library version warning, not program output; its triggering component has not been identified. Program output is on stdout and the exit code is 0.

## Can the Ordering Precondition Be Observed Locally?

`SEARCH ALL` relies on entries following the `ASCENDING KEY` order. Can compilation or one test run expose a violation? This workspace tried two probes using temporary copies of [`lesson.cob`](./lesson.cob):

1. Reverse the load order of all four entries while keeping the `ASCENDING KEY` declaration.
2. Expand the table to five entries and load them in descending order, again leaving the declaration unchanged.

**Observed result:** Both probes compiled (`cobc -x -Wall` returned `0`, with no diagnostics). Their output matched the table above line for line: `SEARCH ALL` still found `0002468101`, and the missing key still returned `NOT_FOUND`.

**Conclusion, limited to local GnuCOBOL 3.2.0 and this table size:** For this lesson’s small table, the compiler does not reject a violation of `ASCENDING KEY`, and the runtime result does not reveal the error. A test run cannot verify the ordering. The load or sort process must guarantee order, and reviewers must check the data source and processing steps separately. This is the cost of saving comparisons with `SEARCH ALL`: its correctness is harder to ensure. **Do not interpret the probes as proof that a wrong order is harmless.** They show only that this test does not expose the problem at this scale, not that production data will be safe.

## Modification Exercises

1. Starting from the original [`lesson.cob`](./lesson.cob), change the balance for account `0002468101` in `1000-LOAD-ACCOUNTS` from `520.00` to `600.00`. Run both search methods and compare the returned balances.
2. Starting from the original [`lesson.cob`](./lesson.cob), expand the account table from four to five entries, append account `0009999999` with balance `75.00`, and change the second search target from `0005550000` to `0009999999`. Keep keys unique and ascending, and confirm both methods find the new account.

Full requirements and expected output are in [`exercise.md`](./exercise.md), with reference answers in [`answer.md`](./answer.md).

## Apply It Elsewhere

Create a table of five product codes and inventory quantities. Use `SEARCH` to find a middle product and a missing product. Then declare a suitable key for `SEARCH ALL`, ensuring the product codes are unique and actually ordered as declared; test both a match and a miss. Explain the risk if table order changes without updating the key declaration, and why this lesson’s probes cannot automatically detect it. Use an in-memory table only, with no files or database. See [`exercise.md`](./exercise.md); no answer is provided.

## Walk Through a Real Workflow

1. An upstream system exports the day’s transactions to a file in a shared directory. Lesson 15 teaches you to read that file.
2. The account master is ordered by account number and loaded into an in-memory table—the precondition for `SEARCH ALL` (fixed-length master files in Lesson 17, sorting in Lesson 21).
3. **This lesson’s step:** each transaction supplies its account number for lookup. A match yields a balance for comparison; a miss goes to a manual queue.
4. Comparison results go to an output file (Lesson 16) or back to a database (from Lesson 29), with logs (Lesson 27). `NOT_FOUND` entries tell staff what to investigate the next day.
5. Lesson 14 first combines the account and transaction tables in memory. In Lesson 20, the same “ordered and unique” precondition appears in file matching.

This lookup is the entry point to the reconciliation process. If it finds the wrong account, everything downstream is wrong.

## What Happens If This Code Goes to Production

- **Who schedules it:** An overnight batch, after the transaction file is ready and the account master has been loaded and sorted. Without those steps, lookup results have no meaning.
- **Who reads the output:** Duty staff scan for exceptions such as `NOT_FOUND`; an unmatched transaction must be investigated that night.
- **How the next system connects:** Matched accounts and balances go to the comparison stage (the in-memory version in Lesson 14 and the file version in Lesson 20).
- **The most likely first-month incident:** Load order does not match the `ASCENDING KEY` declaration. The two probes in this lesson show that compilation does not report it and a small table may not reveal it. Before launch, reviewers must verify how upstream data is ordered and whether sorting was skipped.
- **Another equally serious error:** Treating “account not found” as “balance zero.” This does not crash the program; it silently corrupts the books and is difficult to discover.
- **What is still missing:** File input, sorting, account-number format checks, logging, and business return codes. Duplicate-key policy and missing-record categories are developed in Lesson 20; writing rejected records is covered in Lesson 16. File reading, sorting, error classification, and logging appear in Lessons 15, 21, 26, and 27. This is a search teaching example, not a production reconciliation program.

## References

- [GnuCOBOL Programmer’s Guide: SEARCH](https://superbol.eu/gnucobpg/chapter7.html#search)
- [GnuCOBOL Programmer’s Guide: SEARCH ALL](https://superbol.eu/gnucobpg/chapter7.html#search-all)
- [GnuCOBOL Programmer’s Guide: OCCURS](https://superbol.eu/gnucobpg/chapter6.html#occurs)
- Course home in this repository: [README.md](../../README.md)
