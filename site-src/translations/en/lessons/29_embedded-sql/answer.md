---
_translated_from: lessons/29_embedded-sql/answer.md
_translated_by: site-src/translation agent
---

# Lesson 29: Sample Answers to the Modification Exercises

This file answers only the two modification exercises in `exercise.md`; it does not answer the apply-the-idea exercise. Start both tasks from the original `lesson.cob`. After each change, run:

```sh
./build.sh run
echo $?
```

## 1. Query the second account

Change the first assignment in `MAIN-PROCEDURE` to:

```cobol
               MOVE "A000000002" TO WS-LOOKUP-ACCOUNT
```

The first output line becomes:

```text
検索=A000000002 状態=FOUND 顧客=C0001002 BALANCE=00875.00
```

`SELECT ... INTO` writes the `ACCOUNT_NO`, `CUSTOMER_ID`, and `BALANCE` columns into `WS-ACCOUNT`, `WS-CUSTOMER`, and `WS-BALANCE`, respectively. `BALANCE` is `PIC 9(7)V99`, so `875.00` is displayed with zero padding as `00875.00`. The second query for `A99999999X` is still `NOT_FOUND`; `接続=成功` and `切断=成功` are unchanged, and the exit code is `0`.

## 2. Change the second query to an existing account

Start from the original source and change the second assignment to:

```cobol
               MOVE "A000000002" TO WS-LOOKUP-ACCOUNT
```

Both queries now find a row. Standard output is:

```text
接続=成功
検索=A000000001 状態=FOUND 顧客=C0001001 BALANCE=01250.75
検索=A000000002 状態=FOUND 顧客=C0001002 BALANCE=00875.00
切断=成功
```

The second query's `SQLCODE` changes from `100` (no matching row) to `0` (success), so the `WHEN 100` branch no longer runs. The exit code remains `0`.

Both exercises demonstrate the same point: `SQLCODE = 100` is a **business result**. If the SQL itself succeeded, the batch should finish normally and return `0`. Only values other than `0` and `100` reach `WHEN OTHER`, display `状態=エラー SQLSTATE=`, and end with exit code `1`.
