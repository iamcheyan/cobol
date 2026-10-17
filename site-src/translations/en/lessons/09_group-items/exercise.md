---
_translated_from: lessons/09_group-items/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 09 Exercise: Group Items

## Modification Exercise (answer in `answer.md`)

Starting from the original `lesson.cob`, change the initial value of `WS-ACCOUNT-NUMBER` from `0001234567` to `0007654321`:

```cobol
             10 WS-ACCOUNT-NUMBER PIC X(10)
                VALUE "0007654321".
```

Change only this `VALUE`; leave `PIC`, level number, and declaration order unchanged.

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_09 lesson.cob && ./build/lesson_09
```

Expected difference: only the following 3 lines change (the third line and bytes 21–30 in each group output); the other 7 lines and exit code `0` remain unchanged.

```text
口座番号=0007654321
グループデータ=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
外部記録=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
```

## Apply What You Learned (No Answer Provided)

Design a payment instruction `01` record with three `05` subgroups for payer, payee, and payment details. Put several `10` elementary items with `VALUE` clauses in each group. Reuse at least two field names in separate groups and qualify references with `OF`. Declare an equal-width `PIC X(n)` receiving item, move the whole group, and display it. Calculate the record size and field positions, then verify them against the output.

Use only hierarchical data items and fixed `VALUE` clauses from this lesson. Do not add `REDEFINES`, `OCCURS`, file input, or a database.
