---
_translated_from: lessons/14_data-structures-practice/README.md
_translated_by: site-src/translation agent
---

# Lesson 14: Data Structures Practice — Connecting the Account Master to Today’s Transactions

The account master is held in an in-memory table sorted by account number, while today’s transactions are held in a separate table, each with its own type code. This is the first lesson that brings together the tools from Lessons 09–13: look up each transaction by account number, update balances, then report the three account balances along with a count that can prove itself: `処理件数 = 成功 + 拒否`.

## The Business Setting

At 12:50 a.m., the overnight batch reaches today’s transfers. Earlier jobs calculated interest and produced statements; your task is simply to post these four transactions, one by one.

Transaction 2 was accepted at a teller window during the day: the customer transfers `40.00` from `0001234567` to `0007654321`. It is just one of four rows in the data, but posting it must **change two accounts**—subtract 40.00 from one and add 40.00 to the other.

The most troublesome transfer failure may sound like a process problem rather than a technical one: **only half the update is made**. Money is deducted from A but never reaches B, or B receives it while A’s balance remains unchanged. Arithmetic mistakes are easier to catch by comparing totals. A half transfer is harder: each account looks normal on its own, until a customer calls the next morning and asks, “The money was deducted. Why didn’t the other account receive it?” They will not ask whether you misused `SEARCH ALL`.

(Educational demonstration: the institution, account numbers, amounts, and batch date and time are fictional and are not real data from any institution.)

This lesson demonstrates a minimal safeguard: in the order “find the source, find the target, and only then update both,” none of the four sample transactions changes only one side. The qualification matters: this protects **statement order**, not a transaction. The safeguard ends immediately if the two accounts are no longer in this same memory area; Lessons 31 and 32 return to that problem.

## Why Learn This Now

You may think: “I practiced groups, redefinitions, tables, indexes, and keyed lookup in Lessons 09–13. Putting them together is just review.”

It is not. Each earlier lesson asked you to handle **one table or one field**: whether a view reads correctly, how many slots a table has, or whether a lookup can find a key. Real business data has more than one source: the account master is one, today’s transactions are another, and the **account number** is the business key that joins them. Three new concerns arise:

1. The account number in a transaction becomes the master table’s search key. It is fixed-width text with leading zeroes, so comparisons use character order, not numeric value.
2. A type code selects how to interpret the same 27-byte payload: `D` means deposit and `T` means transfer. A wrong view does not cause an error; it reads bytes at the wrong offsets.
3. A transfer changes **two accounts at once**. Therefore, who to look up first and when updates may begin are part of the business rule.

## What This Knowledge Point Is and What Problem It Solves

**What it is.** In plain terms, connect two sets of data using a business key. The account master is a small table sorted by key; `SEARCH ALL` retrieves an entry by account number. Today’s transactions are another table, each entry starting with a type code and followed by a payload interpreted as either a deposit or a transfer. Process transactions one by one, look up accounts, update balances, and count outcomes. This is where the tools from Lessons 09–13 first work together.

**What business problem it solves.**

- **Match the right records.** The account number on the transaction is the join key. The master must be sorted for reliable lookup, with no duplicate keys.
- **Read the right bytes.** The type code selects the view. A view is another interpretation of the same storage; it does not validate, convert, or protect the data.
- **Update both or neither.** A transfer performs both lookups and checks the balance before changing either balance. In this lesson, this **statement order** keeps the sample from producing half a transfer.

**When things go wrong or are misused.** Remember three points: declaring `ASCENDING KEY` does not make data sorted; equal view lengths do not make either view safe to use arbitrarily; preserving both sides through statement order does not make this a transaction. The first two problems do not occur with this lesson’s input, and neither does the third—but all have caused real incidents in real systems.

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you can:

- Declare a sorted account master with `OCCURS` + `ASCENDING KEY` + `INDEXED BY`, then retrieve an entry by account number with `SEARCH ALL`.
- Use `REDEFINES` to interpret a transaction payload as a deposit or transfer, and explain that a view does not validate data automatically.
- Process transactions one at a time: post a deposit only when the account exists; update both sides of a transfer only when both accounts exist and the source has enough funds.
- Check the result by listing every final balance and verifying `処理件数 = 成功 + 拒否`.
- Explain why the update order avoids a half transfer on this path and why it is not a transactional guarantee.

Limits: all accounts and transactions are constants in the program; there is no file or database input. The account master is small and sorted when loaded. There is no persistent state, so repeated runs produce the same result; consequently, this lesson has no retry policy (real batches need one). It does not cover file status, concurrent updates, restart recovery, or business validation beyond the `PIC` declarations. File input begins in [Lesson 15](../15_sequential-file-read/README.md); module interfaces begin in Lessons 23–25; databases and consistency are covered in Lessons 29–32.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not add `-std=cobol85`); source is fixed format.
- Linux terminal; no database or additional tools required.
- No input fixtures or output data files. Build products go in `build/` and can be deleted to start over.

## Data Layout

See [`lesson.cob`](./lesson.cob) for the complete source. This lesson has two important data structures.

The **account master** is a three-entry `OCCURS` table. Each entry is a group item containing an account number and balance:

| Entry | Account number | Opening balance |
|---:|---|---:|
| 1 | `0001234567` | 1000.00 |
| 2 | `0002468101` | 200.00 |
| 3 | `0007654321` | 50.00 |

Account numbers are unique, and the load order is ascending as required by `ASCENDING KEY`. `INDEXED BY` provides the lookup index.

The **transaction table** has four `OCCURS` entries. Each consists of a one-byte type code and a 27-byte payload. Two views interpret the same payload:

| View | Layout | Bytes (sum of `PIC` sizes) |
|---|---|---:|
| Deposit view `WS-DEPOSIT-VIEW` | `X(10)` account + `9(5)V99` amount + `X(10)` reference | 10 + 7 + 10 = 27 |
| Transfer view `WS-TRANSFER-VIEW` (`REDEFINES`) | `X(10)` source + `X(10)` target + `9(5)V99` amount | 10 + 10 + 7 = 27 |

Both views are 27 bytes because they overlay the same storage. `REDEFINES` does not convert data. The transaction type selects the meaningful layout: `D` uses the deposit view and `T` the transfer view. A wrong view does not raise an error; it reads bytes at shifted positions. That is what it means for a view not to validate the data.

The four fixed transactions are:

| No. | Type | Details |
|---:|---|---|
| 1 | `D` | Deposit `125.50` to `0001234567` |
| 2 | `T` | Transfer `40.00` from `0001234567` to `0007654321` |
| 3 | `D` | Deposit `75.00` to `0002468101` |
| 4 | `T` | Transfer `20.00` from `0007654321` to nonexistent `0009999999` |

## Processing Flow

1. The main paragraph loads the account master and transaction table, then processes all four transactions in `PERFORM VARYING` order.
2. `3000-FIND-ACCOUNT` uses `SEARCH ALL` by account number and stores the result in `WS-ACCOUNT-FOUND` and the account index `WS-ACCOUNT-IDX`.
3. A deposit is posted only if its target account is found; otherwise it is rejected as `ACCOUNT_NOT_FOUND`.
4. A transfer first looks up its source and saves the index with `SET WS-SOURCE-INDEX TO WS-ACCOUNT-IDX`, then looks up its target. Only if both exist **and the source has sufficient funds** does the program debit and credit. A missing target is rejected as `TARGET_NOT_FOUND`, with neither balance changed.
5. The report paragraph displays each final balance and the three counts.

`ASCENDING KEY` declares a requirement; it does not sort data. The loaded data must actually be sorted by key, and keys must not repeat, or `SEARCH ALL` results are unreliable. Lesson 13 used a probe for this: on this machine and at this scale, incorrectly ordered data is neither caught by the compiler nor prevented at runtime from appearing to return the correct result. A single successful run cannot prove ordering. `1000-LOAD-ACCOUNTS` maintains the order in this lesson.

## Count Invariant and Results You Can Reconcile by Hand

The count invariant is `処理件数 = 成功 + 拒否`, which is `04 = 03 + 01` here. The values are stored in `WS-PROCESSED-COUNT`, `WS-POSTED-COUNT`, and `WS-REJECTED-COUNT`: the loop increments the processed count exactly once per transaction, while each branch increments either the success or rejection count. This gives anyone checking the batch a direct way to ask whether anything was missed.

The balances can be calculated transaction by transaction:

| Account | Opening | Txn 1 | Txn 2 | Txn 3 | Txn 4 | Final |
|---|---:|---|---|---|---|---:|
| `0001234567` | 1000.00 | +125.50 | −40.00 | — | — | 1085.50 |
| `0002468101` | 200.00 | — | — | +75.00 | — | 275.00 |
| `0007654321` | 50.00 | — | +40.00 | — | Rejected (target absent) | 90.00 |

At transaction 4, the source has `90.00`, so `20.00` is within its balance. But target `0009999999` is not in the master, so the whole transfer is rejected and neither side changes. The rejection reason must be explicit; otherwise, when someone asks about it the next day, all you can do is guess.

## Run and Observe

The program reads no terminal, file, command-line argument, or database input and creates no data file, so it behaves the same from any working directory. Commands below are described from this lesson’s directory.

**Input:** None. Accounts and transactions are fixed in the program.

**Commands and their purpose:**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                  # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_14 lesson.cob    # 编译并生成可执行文件
./build/lesson_14                              # 运行程序，结果写到标准输出
echo $?                                        # 查看退出码
rm -rf build                                   # 清理生成的可执行文件
```

**Expected results:**

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x` exit code | `0`, with no compiler diagnostics |
| Standard output | 13 lines, shown below |
| Process exit code | `0` |

```text
バッチ=START 口座数=3 取引数=4
取引=1 種別=D
結果=POSTED 入金口座=0001234567 金額=00125.50
取引=2 種別=T
結果=POSTED 振込元口座=0001234567 振込先口座=0007654321
取引=3 種別=D
結果=POSTED 入金口座=0002468101 金額=00075.00
取引=4 種別=T
結果=拒否 REASON=TARGET_NOT_FOUND
口座残高 口座=0001234567 残高=0001085.50
口座残高 口座=0002468101 残高=0000275.00
口座残高 口座=0007654321 残高=0000090.00
集計 処理件数=04 成功=03 拒否=01
```

**Output field guide (Japanese output → meaning):** `バッチ=START` means batch start (`口座数`/`取引数` = account/transaction counts); `取引` is transaction number; `種別` is type; `結果=POSTED` means posted (`入金口座` = credited account, `金額` = amount; `振込元口座`/`振込先口座` = transfer source/target); `結果=拒否` means rejected, with `REASON=` giving the reason (`TARGET_NOT_FOUND`, `SOURCE_NOT_FOUND`, `INSUFFICIENT_FUNDS`, `ACCOUNT_NOT_FOUND`, or `UNKNOWN_TYPE`); `口座残高` means account balance; `集計 処理件数/成功/拒否` means processed/successful/rejected counts.

**Do the arithmetic yourself; do not only read the last line.** For `0001234567`: `1000.00 + 125.50 − 40.00 = 1085.50`; for `0002468101`: `200.00 + 75.00 = 275.00`; for `0007654321`: `50.00 + 40.00 = 90.00`. Then check the counts: four transactions entered, and all four have an outcome; `3 + 1 = 4`. If either check fails, the logic is not connected correctly.

**Unverified item (left open):** Running the executable in this workspace emits `Warning: program compiled against libxml 212 using older 209` on standard error. This is a runtime library version warning, not business output. The component producing it has not been identified; it is not needed to verify this lesson’s business results. The actual output is on standard output and the exit code is `0`.

## Modification Exercises

Start each change independently from the original [`lesson.cob`](./lesson.cob); do not combine them. Check the full output, not just the last balance.

1. Change transaction 4’s target from `0009999999` to existing account `0002468101`. Confirm the transfer posts, both balances change accordingly, and the rejection count becomes zero.
2. Starting again from the original source, change transaction 4’s target to `0001234567` and its amount to `100.00`. The source `0007654321` has only `90.00`; confirm insufficient funds cause rejection and neither balance changes.

Exercise 2 is the boundary case worth running yourself: **both accounts exist**, and the balance check is the only reason the transfer is blocked. Observe how neither side changes when the condition fails.

Full requirements and expected results are in [`exercise.md`](./exercise.md); see [`answer.md`](./answer.md) for reference answers.

## Apply It Elsewhere

Add an account and a deposit, then add a transfer with an existing source and a nonexistent target. Give the processed counts and final balances for each outcome. Explain which statements maintain account ordering, the search index, transaction payload views, and the transfer update order. Keep data in memory; do not add files or a database. See [`exercise.md`](./exercise.md); no answer is provided.

## Walking Through a Real Workflow

Here is where this lesson fits into the overnight chain:

1. **Upstream input is not in scope yet.** The account master and transactions are hard-coded here. In a real batch, transactions arrive from the file introduced in [Lesson 15](../15_sequential-file-read/README.md), and the account master comes from the fixed-length file in [Lesson 17](../17_fixed-length-files/README.md). The matching rules in [Lesson 20](../20_file-matching/README.md) connect them.
2. **This lesson’s step.** Given the account master and today’s transactions, find an account for each transaction by account number, select a view by type code, and update the balance. The result is three balances, three counts, and an outcome for every transaction.
3. **Record rejected transactions separately.** This lesson prints `結果=拒否 REASON=...` to the screen. A production batch writes rejection details to a file ([Lesson 16](../16_file-writing/README.md)) and records batch start and end in logs ([Lesson 27](../27_logging/README.md)). When someone asks why yesterday’s transaction did not arrive, those are the places to check.
4. **Persist the balances.** In-memory balances disappear when the process ends. They must be written to a master file or database (starting in [Lesson 29](../29_embedded-sql/README.md)). At that point the accounts may no longer be in the same memory, so update order, failure visibility, and retry strategy need separate design ([Lessons 31](../31_data-synchronization/README.md) and [32](../32_bank-reconciliation-project/README.md)).
5. **Reconcile the whole chain.** Connecting file reading, matching, result writing, and logging into an auditable pipeline is covered in [Lessons 22](../22_file-processing-practice/README.md) and [32](../32_bank-reconciliation-project/README.md).

The count must always have an explanation. Here it is `処理件数 = 成功 + 拒否`.

## What Happens If This Code Goes to Production

- **Who schedules it:** An overnight batch scheduler, after the account master and transactions are ready. It checks the exit code, not your screen.
- **Who reads the output:** The on-call operator checks the exit code, the `集計` line, and the three `口座残高` lines. A mismatch must be investigated that night.
- **Who is called if something goes wrong:** Accounting and business staff reconcile the balances. If money is deducted but not received, the first question is about the two accounts involved. Rejections need reasons, and successful postings need detail.
- **How the next system connects:** Updated balances go to a master or database (from Lesson 29 onward); rejection details go to the result file from [Lesson 16](../16_file-writing/README.md); batch counts go to the log from [Lesson 27](../27_logging/README.md).
- **Most likely first-month incidents:** In order of impact: a half update (statement order avoids it here, but offers no protection across memory boundaries); someone changes load order or adds a duplicate key and `SEARCH ALL` silently gives unreliable results (the Lesson 13 probe showed a run cannot prove ordering); or a wrong view interprets shifted bytes as an amount without complaint.
- **What it does not do:** Handle file status, concurrent updates, restart recovery, persistence, transaction rollback, idempotent retries, or business validation beyond `PIC`. File status begins in [Lesson 15](../15_sequential-file-read/README.md), errors and return codes in [Lesson 26](../26_error-handling/README.md), and persistence and retry design in Lessons 29–31. The main course does not provide a complete concurrency-control design; [Lesson 32](../32_bank-reconciliation-project/README.md) lists it as a control still needed for production.

To be precise: this lesson demonstrates that, for four in-memory transactions, lookup, view selection, and update order work together; balances can be checked by hand and counts reconcile. It does **not** demonstrate a validated accounting system, and it does not provide atomic transactions. Once accounts are in different files, modules, or a database, this statement order offers no protection.

## References

- [GnuCOBOL Programmer’s Guide: OCCURS](https://superbol.eu/gnucobpg/chapter6.html#occurs)
- [GnuCOBOL Programmer’s Guide: REDEFINES](https://superbol.eu/gnucobpg/chapter6.html#redefines)
- [GnuCOBOL Programmer’s Guide: SEARCH ALL](https://superbol.eu/gnucobpg/chapter7.html#search-all)
- Repository course home: [README.md](../../README.md)
