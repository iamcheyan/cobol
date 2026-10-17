---
_translated_from: lessons/31_data-synchronization/answer.md
_translated_by: site-src/translation agent
---

# Lesson 31 Modification Exercise: Reference Answers

This file answers only the two modification exercises in [`exercise.md`](./exercise.md); it does not provide an answer to the “Extend the Idea” exercise. Both exercises start from the original `snapshot.txt` and `schema.sql`, with `lesson.cob` unchanged. After making a change, run:

```sh
./build.sh run
echo $?
cat differences.txt
sqlite3 -header build/lesson31.db "SELECT ACCOUNT_NO, FILE_STATUS, FILE_CUSTOMER, FILE_BALANCE FROM RECON_RESULT;"
```

The output below was produced by running the exercises in this workspace.

## 1. Change the Amount on Line 2 to `000087500`

Change location: columns 19–27 of line 2 in `snapshot.txt`.

```text
A000000001C0001001000125075
A000000002C0001002000087500
A000000003C0001003000002500
```

Expected standard output (6 lines, exit code `0`):

```text
接続=成功
MATCH ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=01250.75
MATCH ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00875.00
FILE_ONLY ACCOUNT=A000000003 CUSTOMER=C0001003 BALANCE=00025.00
集計 行数=003 一致=002 変更=000 ファイルのみ=001
切断=成功
```

Expected `differences.txt` (one line remains; the `CHANGED` line from the baseline is gone):

```text
FILE_ONLY ACCOUNT=A000000003 CUSTOMER=C0001003 BALANCE=00025.00
```

`RECON_RESULT` still has 3 rows: `A000000001|MATCH`, `A000000002|MATCH`, and `A000000003|FILE_ONLY`.

Reason: `000087500` fen on the file side equals `875.00` yuan in `ACCOUNT_SNAPSHOT` for `A000000002`, and the customer ID also matches. Therefore, the condition `IF WS-CUSTOMER = WS-DB-CUSTOMER AND WS-BALANCE = WS-DB-BALANCE` in `3100-LOOKUP-ACCOUNT` is true, and the classification changes from `CHANGED` to `MATCH`. The counting invariants change accordingly: `一致 2 + 変更 0 + ファイルのみ 1 = file row count 3`, and `differences.txt` has `1 = 変更 + ファイルのみ` line.

## 2. Add Two Accounts to `ACCOUNT_SNAPSHOT`

Change location: the value list in `INSERT INTO ACCOUNT_SNAPSHOT` in `schema.sql` (add a comma after the preceding row and a semicolon after the last row).

```sql
INSERT INTO ACCOUNT_SNAPSHOT VALUES
    ('A000000001', 'C0001001', 1250.75),
    ('A000000002', 'C0001002', 875.00),
    ('A000000003', 'C0001003', 25.00),
    ('A000000099', 'C0001099', 500.00);
```

Expected standard output (6 lines, exit code `0`):

```text
接続=成功
MATCH ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=01250.75
CHANGED ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00100.00
MATCH ACCOUNT=A000000003 CUSTOMER=C0001003 BALANCE=00025.00
集計 行数=003 一致=002 変更=001 ファイルのみ=000
切断=成功
```

Expected `differences.txt` (one line remains, 62 bytes including the newline):

```text
CHANGED ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00100.00
```

Database state: `RECON_RESULT` has 3 rows (`MATCH`, `CHANGED`, `MATCH`); `ACCOUNT_SNAPSHOT` has 4 rows. Although `A000000099` is in the snapshot table, it does **not** appear in standard output, the difference file, or `RECON_RESULT`.

Reason: after `A000000003` is added to the snapshot table, the third query changes from `SQLCODE = 100` to `0`. Its customer ID `C0001003` and amount `25.00` both match the file-side values, so the classification changes from `FILE_ONLY` to `MATCH`, and the `ファイルのみ` count becomes zero. `A000000099` has no corresponding file row, and the program traverses only the file side and queries the database by each file key. It never creates a result for a database-only account. This explains both why this lesson has no `DB_ONLY` category and the fourth counting invariant: the database-only account count is `4 − (一致 2 + 変更 1) = 1`, but the account appears in none of the outputs.

## How to Check Both Exercises

For each exercise, check all four of these: the three classifications and their counts in standard output, the number and contents of lines in `differences.txt`, the row count and classifications in `RECON_RESULT`, and the process exit code (expected to be `0` for both exercises). The summary numbers alone cannot show where a particular record went; the difference file alone cannot reveal a missing row in the result table.
