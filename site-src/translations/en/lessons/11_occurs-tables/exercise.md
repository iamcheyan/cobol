---
_translated_from: lessons/11_occurs-tables/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 11 Exercise: Fixed-Capacity OCCURS Tables

This lesson uses only material covered in Lesson 11: fixed-capacity `OCCURS` tables, ordinary numeric subscripts, `PERFORM VARYING` traversal, `EVALUATE` branches, and `DISPLAY` output.

## Modification Exercises (Reference Answers in `answer.md`)

Start each of the three exercises independently from the original `lesson.cob` for this lesson; do not combine changes from other exercises. For each, run the commands from README’s “Run and Observe” section:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_11 lesson.cob
./build/lesson_11
```

1. **Change an amount.** In `1000-LOAD-TABLE`, change the loaded value of `WS-TXN-AMOUNT(4)` from `20.00` to `35.00`, leaving all other statements unchanged. Recompile and run; report which output lines change, which remain unchanged, and why the ending balance becomes the new value.
2. **Add an entry.** Expand `WS-TRANSACTION-ENTRY OCCURS 4 TIMES` to 5 entries, change the initial value of `WS-LAST-SAMPLE` to 5, and load a fifth entry after the fourth: transaction code `C`, amount `10.00`. The capacity, number of loaded entries, and traversal limit must all be 5. Run the program and provide the complete output; verify the ending balance.
3. **Observe an out-of-range access.** Change only the initial value of `WS-LAST-SAMPLE` from 4 to 5; leave the table capacity at 4. (Change only this one number.)
   - First use `cobc -fsyntax-only lesson.cob` and the compile command to check whether the compiler reports an error.
   - Run the program and record what the fifth entry prints and whether the ending balance matches the value calculated by the accounting rules.
   - Explain where the fifth entry’s bytes come from and why “only increasing the traversal limit” is dangerous in batch processing.

## Apply What You Learned (No Answer Provided)

Define a fixed-capacity table of five account balances. Each entry has an account number `PIC X(10)` and a balance `PIC 9(7)V99`. Load at least three entries; use an ordinary numeric subscript to traverse from the first entry to the last loaded entry; print each account number and balance; then print the number processed and the sum of all balances.

Constraints: use only this lesson’s `OCCURS`, ordinary numeric subscripts, `PERFORM VARYING`, `EVALUATE`, `DISPLAY`, and previously learned basic statements. Do not use `INDEXED BY`, `SEARCH`, files, or databases. Submit the source, actual output, and exit code. Explain the three numbers for capacity, loaded entries, and traversal limit, and distinguish loaded entries from unfilled positions.
