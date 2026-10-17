---
_translated_from: lessons/31_data-synchronization/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 31 Exercise: Differences Between File and Database Snapshots

This exercise uses only material covered through Lesson 31: GixSQL precompilation, host variables, `SQLCODE` branches, the `RECON_RESULT` result table, and file I/O and cursors through Lesson 30.

## Modification Exercises (Reference Answers in `answer.md`)

Start both exercises from the **original fixtures** (`snapshot.txt` unchanged with its three lines, `schema.sql` unchanged, and `lesson.cob` unmodified). First run the batch once and save the baseline:

```sh
./build.sh run
echo $?
cat differences.txt
sqlite3 build/lesson31.db "SELECT ACCOUNT_NO, FILE_STATUS FROM RECON_RESULT;"
```

The script recreates `build/lesson31.db` and truncates `differences.txt` on every run, so you do not need to clean them manually. However, **restore the fixtures to their original contents before starting the other exercise**; do not combine the two changes.

1. **Change the file-side amount.** Change the amount on line 2 of `snapshot.txt` from `000010000` to `000087500` (keep the line at 27 bytes and leave the other fields unchanged). Run the batch again and check the classification of line 2, `BALANCE=` in standard output, the three summary counts, and the number and contents of the lines in `differences.txt`.
2. **Add rows on the database side.** At the end of the `ACCOUNT_SNAPSHOT` insert list in `schema.sql`, add `('A000000003', 'C0001003', 25.00)` and `('A000000099', 'C0001099', 500.00)` (note: add these as values in the insert list, put a comma at the end of the preceding row, and a semicolon at the end of the last row). Run the batch again and check the classification of line 3, the summary counts, whether `differences.txt` is empty, and whether `A000000099` appears in standard output, the difference file, or `RECON_RESULT`.

Constraints: do not change `lesson.cob` or `build.sh`; keep every `snapshot.txt` line 27 bytes (9 amount digits, zero-padded on the left); record the exit code for each exercise and use `sqlite3` to read the number of rows in the modified `RECON_RESULT`. See [`answer.md`](./answer.md) for the reference answers.

## Extend the Idea (No Answer Provided)

Make the reconciliation **two-way**: use the Lesson 30 cursor to scan `ACCOUNT_SNAPSHOT` in reverse, add a `DB_ONLY` classification and count for accounts found only in the database, and make the result-table row-count relationship (file row count = result-table row count = sum of the three categories) independently checkable in the two-way version. Also add a duplicate account key to the input and decide whether it is a business rejection or a system failure, how to keep the rejected record out of `RECON_RESULT`, and how to clean up after a failed batch so it can be rerun without leaving dirty data.

Submit the modified `lesson.cob`, `schema.sql`, and fixtures, the commands used to run them, and the actual output, before-and-after database state, and exit code for the normal path, the `DB_ONLY` path, and the duplicate-key path. No answer is provided.
