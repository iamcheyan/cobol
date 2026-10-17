---
_translated_from: lessons/30_sql-cursors/answer.md
_translated_by: site-src/translation agent
---

# Lesson 30 Modification Exercises: Reference Answers

This answer covers only the two modification exercises in [`exercise.md`](./exercise.md); it does not answer the apply-what-you-learned exercise. Both exercises use the original [`lesson.cob`](./lesson.cob) as the baseline. The baseline output is in [`expected-output.txt`](./expected-output.txt): 8 lines, exit code `0`.

Both changes were tested in this workspace: the source was copied to a temporary directory, changed as instructed, and run with the same GixSQL toolchain using `./build.sh run` (`BUILD_DIR` and `GIXSQL_ROOT` pointed to temporary locations). The outputs below are the values actually observed.

## 1. Reverse the Result Order

**Change location:** The sort clause in the cursor declaration.

```sql
ORDER BY ACCOUNT_NO DESC
```

**Command:** `./build.sh run`

**Actual output:**

```text
接続=成功
オープン=成功
行=A000000002 CUSTOMER=C0001002 BALANCE=00875.00
行=A000000001 CUSTOMER=C0001001 BALANCE=01250.75
取得=EOF SQLCODE=100
クローズ=成功
行数=002
切断=成功
```

**Full difference from the baseline and why:** Only lines 3 and 4 switch places: `A000000002` appears first, followed by `A000000001`. `ORDER BY` controls only the **order** of rows returned by the database; it does not change the row count, so `行数=002` stays the same. After the last row, the `FETCH` loop still receives `SQLCODE 100`, so `取得=EOF SQLCODE=100` and `クローズ=成功` also stay the same. Balances `00875.00` / `01250.75` correspond to `875.00` / `1250.75` in `schema.sql` (`PIC 9(5).99` pads the integer part to 5 digits).

## 2. Limit the Query to One Account

**Change location:** After `FROM` in the cursor’s `SELECT`, independently of Exercise 1.

```sql
WHERE ACCOUNT_NO = 'A000000002'
```

**Command:** `./build.sh run`

**Actual output:**

```text
接続=成功
オープン=成功
行=A000000002 CUSTOMER=C0001002 BALANCE=00875.00
取得=EOF SQLCODE=100
クローズ=成功
行数=001
切断=成功
```

**Full difference from the baseline and why:** Only one row remains: `行=A000000002 CUSTOMER=C0001002 BALANCE=00875.00`; `行数` changes from `002` to `001`. The `WHERE` clause reduces the result set to one row. The first `FETCH` returns `SQLCODE 0` (the count is incremented and the row is displayed). The **next** `FETCH` finds no more rows and returns `SQLCODE 100`, so the program prints `取得=EOF SQLCODE=100` and exits the loop. It then runs `CLOSE` on the cursor and disconnects normally; the exit code is `0`.

Note: `SQLCODE 100` here means “end of result set,” not an error and not “account does not exist.” This lesson has no “not found” branch. If the account does not exist, the result set is empty; see “Empty, Single-Row, Multiple-Row, and EOF Cases” in [`README.md`](./README.md) (with this toolchain, an empty table first returns one blank record).
