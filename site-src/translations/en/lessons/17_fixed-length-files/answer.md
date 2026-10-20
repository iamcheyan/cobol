---
_translated_from: lessons/17_fixed-length-files/answer.md
_translated_by: site-src/translation agent
---
# Lesson 17 Modification Exercise: Reference Answer

This answer covers only the modification exercise in [`exercise.md`](./exercise.md). It does not include an answer to the apply-what-you-learned exercise.

## Put the Account Number First in the Output FD

Location of the change: `01 FD-BALANCE-RECORD` under `FD BALANCE-FILE` in `lesson.cob`.

Before:

```cobol
       01 FD-BALANCE-RECORD.
           05 FD-OUT-CUSTOMER-ID PIC X(8).
           05 FD-OUT-ACCOUNT-NUMBER PIC X(10).
           05 FD-OUT-BALANCE PIC 9(7)V99.
```

After:

```cobol
       01 FD-BALANCE-RECORD.
           05 FD-OUT-ACCOUNT-NUMBER PIC X(10).
           05 FD-OUT-CUSTOMER-ID PIC X(8).
           05 FD-OUT-BALANCE PIC 9(7)V99.
```

Commands:

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

**Standard output:** Exactly the same 5 lines as the baseline. The three `MOVE` statements assign by field name, and the names have not changed, so the account number, customer ID, and balance displayed for each record remain the same:

```text
ファイルを開きました
出力 口座番号=0001234567 顧客番号=C0001042 残高=0001000.00
出力 口座番号=0002468101 顧客番号=C0002042 残高=0000020.00
出力 口座番号=0007654321 顧客番号=C0003042 残高=0000250.75
クローズ完了 件数=03
```

**Output file:** `wc -c build/balances.dat` prints `81`, which is `3 × 27`. `cmp accounts.dat build/balances.dat` produces no output and exits with code 0, confirming that the output is byte-for-byte identical to the input (the file still contains no line breaks; line breaks below are for viewing only):

```text
0001234567C00010420001000000
0002468101C0002042000002000
0007654321C0003042000025075
```

For the first record, `0001234567` occupies output bytes 1–10, `C0001042` occupies bytes 11–18, and `000100000` occupies bytes 19–27, matching the input record offsets.

**Complete difference from the baseline:**

| Record | Baseline `balances.dat` | `balances.dat` after reordering |
|---:|---|---|
| 1 | `C00010420001234567000100000` | `0001234567C00010420001000000` |
| 2 | `C00020420002468101000002000` | `0002468101C0002042000002000` |
| 3 | `C00030420007654321000025075` | `0007654321C0003042000025075` |
| Total file size | 81 | 81 |

**Why:** `MOVE` assigns by data name, independently of declaration order. `WRITE` writes the record bytes in the order in which fields are declared inside the `01` record. Changing the order of the `05` declarations therefore changes each field's output offset, while each record remains `10 + 8 + 9 = 27` bytes as determined by the `PIC` clauses. The record count and total file size (`3 × 27 = 81`) do not change.

## Answer Key: Verifying Offsets with a Column Ruler

This answers the three tasks in the “Verify Offsets with a Column Ruler” section of [`exercise.md`](./exercise.md).

### Task 1

| Field | Start column | End column | Width | `:PositionRange` output |
|---|---:|---:|---:|---|
| Customer name | 19 | 48 | 30 | `POSITION(19:48)` |
| Balance | 89 | 108 | 20 | `POSITION(89:108)` |
| Reserved | 177 | 200 | 24 | `POSITION(177:200)` |

Width is “end column − start column + 1”: `48 − 19 + 1 = 30`, `108 − 89 + 1 = 20`, `200 − 177 + 1 = 24`. All three match the Length column of the README layout table, so you measured the same bytes.

**Where this goes wrong:** `:PositionRange` reports an **inclusive** span, so subtracting `:PositionJump 19` from `:PositionJump 48` gives 29, one column short. Read the width straight from the `:PositionRange` output instead of subtracting.

### Task 2

1. Before the deletion, columns 49–56 contain `BR-TOKYO` (8 characters).
2. After deleting the `T` at column 19, columns 49–56 contain `R-TOKYO2`.
3. The file size goes from `600` to `599`.
4. The program does **not** report an error.

**Why the second answer is `R-TOKYO2`.** Deleting column 19 shifts every byte from column 19 onward one position left. The 30-byte name in columns 19–48 loses one character, so the `BR-TOKYO` that was at 49–56 moves to 48–55. From column 49 you read `R-TOKYO` (the original `BR-TOKYO` minus its first byte `B`), and column 56 picks up the first byte of the next record's account number, `2`.

**Why `600 ÷ 200` no longer means anything.** 600 was exactly 3 × 200, but 599 is not a multiple of 200: `599 = 2 × 200 + 199`. The file can now be read as only two complete records; the third has 199 bytes, one short. **This is exactly the boundary stated earlier in the lesson — the program does not validate the total file size.** On the third `READ` it fills 199 bytes and leaves the last byte position holding leftover data from the previous record. `AT END` still fires normally and the program says nothing.

**Why no error.** Three things are unchecked:

- `OPEN` only checks that the file can be opened; a 599-byte ordinary file opens fine;
- every `READ` succeeds (the first two complete, the third padded with residue), so there is no exception other than `AT END`;
- `WRITE` still writes one 200-byte record with a truncated field and returns status `00`.

So the exit code is still `0` and the screen still shows three `出力 …` lines, but the balance on the third line is already being read wrong. **Only someone checking columns with the ruler can see it.**

### Task 3

```sh
cd lessons/17-fixed-length-files
cp account-master-200.dat build/account-master-200.dat   # restore if you modified the lesson fixture
wc -c account-master-200.dat                              # should print 600
cmp account-master-200.dat build/account-master-200.dat   # compare with the original fixture
```

**Submit:**

- the table from Task 1;
- the four answers from Task 2;
- `cmp` produces no output and exits `0`, and `wc -c` prints `600`.

If `wc -c` prints `599`, the deleted character has not been restored. If `cmp` reports `differ: byte 19`, it was restored in the wrong place — `cmp` names the first differing byte offset, which is itself a useful locating exercise.
