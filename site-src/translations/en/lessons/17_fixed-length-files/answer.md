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
