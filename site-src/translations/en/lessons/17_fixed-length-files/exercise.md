---
_translated_from: lessons/17_fixed-length-files/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 17 Exercise: Fixed-Length Records, Field Offsets, and Byte-Count Verification

This exercise uses only techniques covered in Lessons 09 and 15–17: `SELECT` and `FD` record declarations, `FILE STATUS`, `READ ... AT END`, `MOVE`, `WRITE`, and fixed-format column conventions.

## Modification Exercise (Answer in `answer.md`)

Starting with the original `lesson.cob` and `accounts.dat` for this lesson, change the field declaration order in the output FD so that the account number occupies output-record bytes 1–10, the customer ID bytes 11–18, and the balance bytes 19–27. In other words, make the output record layout match the input record layout.

Constraints:

- Change only the three `05` declarations under `01 FD-BALANCE-RECORD` in `FD BALANCE-FILE`, in this order: account number → customer ID → balance.
- Keep each `PIC` width unchanged (`X(10)`, `X(8)`, `9(7)V99`).
- Do not change the three `MOVE` statements, the input FD, or any paragraph logic.

Recompile and run after making the change (the working directory must contain `accounts.dat`, so first copy the fixture into the runtime directory):

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_17 lesson.cob
cp accounts.dat build/
(cd build && ./lesson_17)
wc -c build/balances.dat
cmp accounts.dat build/balances.dat
rm -rf build
```

Submit:

- The modified `01 FD-BALANCE-RECORD` declaration snippet.
- Standard output (it should still have 5 lines).
- The output of `wc -c build/balances.dat` and the exit code from `cmp`.
- The 27 bytes of each of the first two output records, written in three groups (account number / customer ID / balance).

Independent check: each record is still `10 + 8 + 9 = 27` bytes, for `81` bytes total across 3 records. The field names have not changed, so the account number, customer ID, and balance values in each output record should match the baseline; only their byte positions within each record change.

## Verify Offsets with a Column Ruler (Answer in `answer.md`)

This exercise uses [`account-master-200.dat`](./account-master-200.dat): three 200-byte records whose field positions are in the README layout table. Install `position-ruler.nvim` and register the `.dat` filetype as described in the README.

### Task 1: Measure three field ranges

Open the fixture and use `:PositionJump` and `:PositionRange` to fill in the column range and width of the three fields below:

| Field | Start column | End column | Width | `:PositionRange` output |
|---|---:|---:|---:|---|
| Customer name | ? | ? | ? | ? |
| Balance | ? | ? | ? | ? |
| Reserved | ? | ? | ? | ? |

Requirement: the three widths must reconcile. Check each one against the README layout table; any mismatch means the commands were used incorrectly.

### Task 2: Create a shift and locate it

1. Record the 8 characters at columns 49–56 of record 1.
2. Delete one character at column 19 of record 1, then save.
3. Jump there with `:PositionJump 49` and record the 8 characters now present.
4. Confirm the total file size with `wc -c`.

Answer:

- What are the contents of columns 49–56 before and after the deletion?
- What is the total file size now? Is `600 ÷ 200` still meaningful?
- Will the program report an error for this file? Why?

### Task 3: Restore and verify

Put the deleted character back and use `cmp` to confirm the file is byte-identical to the original fixture.

Submit:

- The completed table from Task 1.
- The four answers from Task 2.
- The exit code of `cmp` and the output of `wc -c` after restoring.

## Apply What You Learned (No Answer Provided)

Design an interface for a 32-byte fixed-length customer record: an 8-byte customer ID, a 20-byte name, and a 4-byte status. Concatenate two records byte by byte (do not insert line breaks), then use the same open/read/write approach from this lesson to read and output each customer ID and status.

Submit a field-offset table, the input file's total byte count, actual runtime output, and an explanation of how line terminators would damage the fixed-length boundaries.

Do not switch to `LINE SEQUENTIAL`, introduce a database, or use syntax that has not yet been taught. No answer is provided for this exercise.
