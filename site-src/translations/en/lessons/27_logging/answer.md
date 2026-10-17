---
_translated_from: lessons/27_logging/answer.md
_translated_by: site-src/translation agent
---

# Lesson 27 Modification Exercise: Reference Answer

This answer covers only the modification exercises in `exercise.md`, not the transfer exercise. Do both tasks in the `build/` working directory:

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_27 lesson.cob
cp transactions.txt build/
```

## 1. Correct the Second Transaction’s Amount

Change the second line in `build/transactions.txt` to:

```text
A00002|00150
```

Run `(cd build && ./lesson_27)`. The business event for that record changes from rejection to acceptance:

```text
EVENT=RECORD_READ NO=002 ACCOUNT=A00002
EVENT=RECORD_ACCEPTED NO=002 ACCOUNT=A00002
```

The previous `EVENT=BUSINESS_REJECT ... REASON=BAD_AMOUNT` no longer appears. `BATCH_END` becomes:

```text
EVENT=BATCH_END INPUT=005 ACCEPTED=003 REJECTED=002 SYSTEM_ERROR=N
```

Standard output changes in step with it to `集計 入力=005 受理=003 拒否=002` and `システムエラー=N`; the exit code remains `0`. `accepted.txt` now has 3 lines (including the new `A00002|00150`), and `rejected.txt` has 2 lines.

Check the invariant: `5 = 3 + 2`; `ACCEPTED=003` matches the 3 lines in `accepted.txt`, and `REJECTED=002` matches the 2 lines in `rejected.txt`.

A business rejection is already a completed processing result. One fewer rejection simply means one more accepted record; no input, output, or log file operation failed, so `SYSTEM_ERROR=N` and the exit code is `0`.

## 2. Missing Input File

Delete `build/transactions.txt` (and the result files left by the previous exercise), then run `(cd build && ./lesson_27)`. Standard output is:

```text
エラー=OPEN_INPUT STATUS=35
集計 入力=000 受理=000 拒否=000
システムエラー=Y
```

The exit code is `1`. The complete contents of `build/batch.log` are:

```text
EVENT=BATCH_START ID=TRAINING-001
EVENT=SYSTEM_ERROR OP=OPEN_INPUT STATUS=35
EVENT=BATCH_END INPUT=000 ACCEPTED=000 REJECTED=000 SYSTEM_ERROR=Y
```

The order is: write `BATCH_START` after the log opens and before the business input opens; after input opening fails with status `35`, write `SYSTEM_ERROR`; then write `BATCH_END`. Its `SYSTEM_ERROR=Y` makes clear that this run was incomplete, so it cannot be mistaken for a successful empty batch. The input never opened successfully, so `INPUT=000`.
