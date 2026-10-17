---
_translated_from: lessons/08_control-flow-practice/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 08 Exercise: Mini Account Transaction Batch

This lesson uses only material from Lessons 01–08: `WORKING-STORAGE` fields, `MOVE`, `COMPUTE`, `IF`, `EVALUATE`, `PERFORM VARYING`, and named paragraphs. Sample data is fixed in the program; there are no files, tables, or databases.

## Modification Exercise (reference answers in `answer.md`)

Perform both modifications separately, starting from the original `lesson.cob` each time. Check the complete output after each run, not just the ending balance.

1. Change the initial value of `WS-OPENING-BALANCE` from `1000.00` to `2000.00`. Compile and run, recording `処理件数`, `承認件数`, `拒否件数`, and `最終残高`.
2. In `2100-LOAD-SAMPLE`, change the withdrawal amount in `WHEN 3` from `1500.00` to `1085.40`. Check whether a withdrawal exactly equal to the balance available at that point is accepted, and record the final balance and both result counts.

After each change, run:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_08 lesson.cob
./build/lesson_08
```

See `answer.md` for reference answers to these modifications only.

## Apply What You Learned (No Answer Provided)

Extend the fixed batch with a sixth transaction. Choose its code and amount, explain whether it should be accepted, and record the balance after every transaction. Finish with `処理件数`, `承認件数`, `拒否件数`, and `最終残高`. Include a case where a withdrawal equals the current balance and confirm that `処理件数` increases only for transactions actually processed.

Update the last sample number and loading logic as needed. Keep all sample data fixed; do not add file input, tables, or a database. Submit the complete modified fixed-format source, compile command, actual output, and exit code. No answer is provided.
