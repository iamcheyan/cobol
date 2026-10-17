---
_translated_from: lessons/32_bank-reconciliation-project/answer.md
_translated_by: site-src/translation agent
---

# Lesson 32 Modification Exercise: Suggested Answers

This file answers only the two numbered modification exercises in `exercise.md`. It does not answer the further exploration question.

## 1. Post a 1.00 Deposit to A000000003

Add this line to `fixtures/transactions.txt`:

```text
A000000003D000000100
```

Field breakdown: account `A000000003`, type `D`, and amount `000000100` cents, or 1.00. The account’s opening balance is 2.00, so its balance after posting is 3.00. After running `./build.sh run`, you should see:

```text
POSTED TX=006 ACCOUNT=A000000003 TYPE=D BALANCE=0000003.00
SYNC UPDATED ACCOUNT=A000000003 BALANCE=0000003.00
集計 口座=03 取引=006 記帳=003 拒否=003 更新=002 変更なし=001 挿入=000
```

`build/run/accepted.txt` now has TX=006; `build/run/account-report.txt` lists A000000003 as `UPDATED`. The balance for this account in SQLite is 3.00.

## 2. Delete A000000005 from the Initial Database

Remove this row from the `INSERT INTO ACCOUNT_SNAPSHOT VALUES` list in `schema.sql`:

```sql
('A000000005', 'C0001005', 250.75)
```

Run `./build.sh run`. A000000005 is still present in the input master; because the query finds no row, the program inserts its customer number and master balance:

```text
SYNC INSERTED ACCOUNT=A000000005 BALANCE=0000250.75
集計 口座=03 取引=005 記帳=002 拒否=003 更新=001 変更なし=001 挿入=001
```

Then run `./build.sh run-existing` again. The account now exists in the database with matching fields, so the result becomes:

```text
SYNC UNCHANGED ACCOUNT=A000000005 BALANCE=0000250.75
集計 口座=03 取引=005 記帳=002 拒否=003 更新=001 変更なし=002 挿入=000
```

`run-existing` preserves the database state; `run` recreates the database. Together, the two commands verify the initial insert and the idempotent classification on rerun.
