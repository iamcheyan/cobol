---
_translated_from: lessons/14_data-structures-practice/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 14 Exercise: Matching Accounts and Transactions

This lesson uses only material covered in Lessons 09–14: hierarchical records, `REDEFINES`, `OCCURS` tables, `INDEXED BY` indexes, `SEARCH ALL`, `EVALUATE`, `IF`, `PERFORM`, and `DISPLAY`. All data is held in memory.

## Modification Exercises (Reference Answers in `answer.md`)

1. Change the target account of the fourth transfer from `0009999999` to the existing account `0002468101`. Run the program and confirm that the transfer succeeds, the source and target balances change, and the rejection count is zero.
2. Starting from the original source, set the fourth transfer’s target to `0001234567` and amount to `100.00`. Confirm that it is rejected for insufficient source funds and that neither account’s balance changes.

Start each exercise independently from the original `lesson.cob`; do not combine them. After each change, run:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_14 lesson.cob
./build/lesson_14
```

For each run, verify the transaction result, the final balances of all three accounts, and the summary counts—not only the line that says whether it succeeded. See `answer.md` for the reference answers.

## Apply What You Learned (No Answer Provided)

Add an account to the master table and add two transactions to the transaction table: a deposit to that account and a transfer whose target account does not exist. Update every table upper bound, load statement, and batch-processing range.

Submit the complete source, compile and run commands, actual output, and exit code. Explain how you keep account keys ordered (to preserve the prerequisite for `SEARCH ALL`); why both balances remain unchanged when a transfer fails; and why this lesson’s approach provides only statement-order protection, not a transaction guarantee. No answer is provided. Use in-memory data only; do not add files or databases.
