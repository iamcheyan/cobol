---
_translated_from: lessons/27_logging/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 27 Exercise: Build a Log That Can Locate Records

This exercise uses only topics from Lessons 15–27: sequential file I/O, `FILE STATUS`, `STRING`, `EVALUATE`/`IF`, paragraphs, and `PERFORM`.

## Modification Exercise (Answer in `answer.md`)

Do both tasks in the `build/` working directory; do not change the repository fixture. Prepare the workspace first:

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_27 lesson.cob
cp transactions.txt build/
```

1. Change `A00002|00X50` in `build/transactions.txt` to `A00002|00150`. Run `(cd build && ./lesson_27)`, compare the log event for this record before and after the change and the `BATCH_END` counts, and explain why fewer business rejections do not mean a system error.
2. Delete `build/transactions.txt` and run `(cd build && ./lesson_27)`. Record the exit code, the error line in standard output, and the order of the batch-start, system-error, and batch-end events in `build/batch.log`.

Constraints: do not change `lesson.cob` or the lesson fixture. Check the invariant for both tasks: in `BATCH_END`, `INPUT = ACCEPTED + REJECTED`, and `ACCEPTED`/`REJECTED` must match the line counts in the two result files. See `answer.md` for a reference answer.

## Transfer Exercise (No Answer)

Add a business rejection rule for “duplicate account number” and write both the first record number and duplicate record number to the log. Then design two consecutive runs with different batch IDs. Explain how to tell from the log alone whether one particular batch finished, and why `BATCH_END` is not enough to prove all outputs were delivered atomically.

Submit the source, compile and run commands, the two `batch.log` files, and exit codes. Do not log complete customer privacy data or omit the ending status of a failed batch. No answer is provided.
