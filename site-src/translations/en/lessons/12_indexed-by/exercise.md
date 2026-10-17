---
_translated_from: lessons/12_indexed-by/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 12 Exercise: INDEXED BY

This lesson uses only material covered in Lessons 11–12: fixed-format declarations, `OCCURS` tables, ordinary numeric subscripts, `INDEXED BY` indexes, and `SET` / `PERFORM UNTIL`. Do not use `SEARCH`, `SORT`, files, or databases.

## Modification Exercises (Reference Answers in `answer.md`)

The baseline is this lesson’s original [`lesson.cob`](./lesson.cob). Continue from step 1’s source for step 2; make only the specified changes in each step.

### Step 1: Expand the Account Table to Five Entries

Expand both `WS-ACCOUNT-ENTRY OCCURS 4 TIMES` and the initial value of `WS-LAST-ACCOUNT` to 5. Append a fifth account in `1000-LOAD-ACCOUNTS`: account `0005550001`, balance `75.00`.

Constraints:

- Change only these three places (capacity, number of loaded entries, and one appended load); leave the first four accounts unchanged.
- Keep ordinary numeric subscripts in the loading paragraph and `WS-ACCOUNT-IDX` in the traversal paragraph; do not change the loop structure.

Run in order:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_12 lesson.cob
./build/lesson_12
```

Provide the complete actual standard output and exit code. Explain why the first four lines are byte-for-byte unchanged.

### Step 2: Observe the Out-of-Range Boundary

Starting with the result of step 1, change **only** `WS-LAST-ACCOUNT` to `6` (leave `OCCURS` at 5 and keep the fifth entry as the last loaded one).

First write down your prediction (number of standard-output lines, content of the last line, and exit code), then verify with:

```sh
cobc -x -Wall -o build/lesson_12 lesson.cob
./build/lesson_12
cobc -x -fsubscript-check=full -fec=EC-BOUND-SUBSCRIPT -o build/lesson_12_checked lesson.cob
./build/lesson_12_checked
```

`-fsubscript-check=full -fec=EC-BOUND-SUBSCRIPT` asks GnuCOBOL to check subscript/index bounds at runtime; the default compilation does not enable this check.

Provide the complete standard output, standard error, and exit code for both runs. Explain why the program appears to succeed without checking, and why this option can detect the problem at runtime.

## Apply What You Learned (No Answer Provided)

Create an account table with five entries and declare an `INDEXED BY` index:

1. Load at least three accounts (account number and balance of your choice) using ordinary numeric subscripts.
2. Traverse from the first entry to the last loaded entry using the index, and print the account number, balance, and number processed.
3. Explain the relationship among table capacity, loaded-entry count, the index’s current entry, and the loop endpoint.
4. State which command you would use to verify that an endpoint beyond the table capacity is detected, and record the actual result.

Constraints: use only syntax covered in Lessons 11–12; do not use `SEARCH`, `SORT`, files, or databases. Record the compile command, actual output, exit code, and verification method.
