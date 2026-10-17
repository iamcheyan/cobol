---
_translated_from: lessons/22_file-processing-practice/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 22 Exercises: Changing Inputs to the Integrated Batch

This section uses only material from Lessons 15–22: sequential file `SELECT` / `OPEN` / `READ` / `CLOSE`, fixed-width records, `SORT` / `RELEASE` / `RETURN`, sequential key matching, `EVALUATE` / `IF`, `FILE STATUS`, and `RETURN-CODE`.

## Modification Exercises (Reference Answers in `answer.md`)

Use **fixture copies** and never edit repository fixtures. Start each run fresh because `OPEN OUTPUT` replaces results. Prepare the working directory:

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_22 lesson.cob
cp accounts.txt transactions-unsorted.txt build/
cp build/transactions-unsorted.txt build/orig-transactions.txt   # save an original transaction copy for reset
```

1. In `build/transactions-unsorted.txt`, change the transaction account `A000000004` to `A000000009`. Keep the other ten-character fields unchanged. Run `(cd build && ./lesson_22)`, check accepted, rejected, and master-only counts, and verify both output files line by line.
2. Restore the transaction fixture from `build/orig-transactions.txt`. Change the amount in the `A000000007` row to the nine digits `000000001`. Run the program and confirm the amount rejection becomes accepted; check the counts and both output files.

Constraints: do not change `lesson.cob`; preserve row widths (20 characters for transactions and 27 for master records).

Save complete standard output and both output files after each run. Explain why `SORT` makes physical input row order irrelevant, and identify which procedure performs `RELEASE` and which performs `RETURN`. Check both results with the count invariants. See `answer.md` for reference answers.

## Extension (No Answer Provided)

Add a second transaction for an account in the master. Design a matching rule allowing one master record to match multiple transactions. Define output order, balance updates, and error handling; test consecutive transactions, a missing account, master EOF, and an invalid amount.

Submit source code, compile/run commands, actual standard output, and both output-file contents. Explain how the master-read position changes from this program. Do not load all records into an `OCCURS` table and do not omit accepted/rejected file contents.
