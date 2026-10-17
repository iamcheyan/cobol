---
_translated_from: lessons/30_sql-cursors/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 30 Exercises: Cursors and Result-Set Boundaries

Prerequisite: Install the GixSQL/SQLite toolchain from [Lesson 29](../29_embedded-sql/README.md). See [`lesson.cob`](./lesson.cob) for this lesson’s source. For running and observations, see “Build and Run” and “Empty, Single-Row, Multiple-Row, and EOF Cases” in [`README.md`](./README.md).

## Modification Exercises (Answers in [`answer.md`](./answer.md))

Start both exercises from the **original source** `lesson.cob` and complete them independently. Do not continue from the source changed for the previous exercise. After each change, rerun `./build.sh run`; the script first deletes this lesson’s `build/cursor.db` and recreates the two-row fixture from [`schema.sql`](./schema.sql), so the result is repeatable.

1. **Reverse the result order.** Change the sort order in the `ACCOUNT-CURSOR` declaration to `ORDER BY ACCOUNT_NO DESC`. Recompile and run, then compare the output order, `行数=`, and EOF handling. Limit the change to the cursor `SELECT` statement’s `ORDER BY` clause; do not change the `FETCH` loop or `CLOSE`.

2. **Limit the query to one account.** Start from the original source and add a `WHERE ACCOUNT_NO = 'A000000002'` line after `FROM ACCOUNT_SNAPSHOT`. Confirm that only one account is output and that the next `FETCH` handles EOF. Limit the change to the cursor `SELECT` statement’s `WHERE` clause.

## Apply What You Learned (No Answer Provided)

Add `ACCOUNT_STATUS` to `ACCOUNT_SNAPSHOT` (for example, `ACTIVE` / `CLOSED`) and have the cursor return only active accounts. Modify [`schema.sql`](./schema.sql) and [`schema-empty.sql`](./schema-empty.sql) so they still run, then:

- Run `./build.sh run-empty` to observe the **zero-row** result. Compare it with [`expected-empty-output.txt`](./expected-empty-output.txt) and explain the empty-result behavior of this toolchain.
- Design and run separate **one-row** and **multiple-row** fixtures; check `行数=` and EOF.
- Explain the difference between “`FETCH` failed” and “`SQLCODE 100`,” and confirm that every cursor opened successfully is closed with `CLOSE`.

No answer is provided. Record each command, its actual output and exit code, and why the field or rule you chose can verify zero-row, one-row, and multiple-row cases.
