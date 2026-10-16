---
_translated_from: lessons/05_evaluate/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 05 Exercise: EVALUATE

This exercise uses only the material covered in lessons 04–05: `EVALUATE` / `WHEN` / `WHEN OTHER` multi-way selection, the `VALUE` initial value in `WORKING-STORAGE`, `DISPLAY` output, and the `STOP RUN` ending. All inputs are constants inside the program — no files, loops, or databases are involved.

## Modification Exercise (a reference answer is provided in `answer.md`)

The interface contract adds a transaction code `F` (fee), and the program must be able to classify it too. Starting from this lesson's original [`lesson.cob`](./lesson.cob):

1. Where to change: in `EVALUATE WS-TRANSACTION-CODE`, after the last `DISPLAY` of the `WHEN "T"` branch (`DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"`) and before `WHEN OTHER`, insert a new branch:

   ```cobol
               WHEN "F"
                   DISPLAY "分類=FEE"
                   DISPLAY "処理=CHARGE_FEE"
   ```

2. To make the fixed sample exercise the new branch, change the data item initial value `01 WS-TRANSACTION-CODE PIC X VALUE "D".` to `VALUE "F"`.

Constraints:

- Do not change the output of the `WHEN "D"`, `WHEN "W"`, and `WHEN "T"` branches;
- Do not change the semantics or output of `WHEN OTHER`;
- The new branch must use the same indentation as its neighbors (Area B starts at column 12), and the program text must not exceed column 72.

Recompile and run:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_05 lesson.cob
./build/lesson_05
echo $?
```

Expected differences (compared line by line against the original version's output):

- Line 2 changes from `取引コード=D` to `取引コード=F`;
- Lines 3 and 4 change from `分類=DEPOSIT` / `処理=ADD_TO_ACCOUNT` to `分類=FEE` / `処理=CHARGE_FEE`;
- Line 1 `取引参照番号=TXN-00000001` is unchanged (this field is not modified);
- `cobc -fsyntax-only`, `cobc -x`, and the process exit code are still `0`, with no compile diagnostics.

Reason: `EVALUATE` does an exact match between each `WHEN` value and the subject (`WS-TRANSACTION-CODE`); the initial value `F` now hits the new branch, so it no longer falls into `WHEN OTHER`. The reference-number field did not take part in this change, so it stays the same.

Independent accounting boundary: keep the newly added `WHEN "F"` branch, change the initial value back to `X`, and run once more — you should get `分類=UNKNOWN` / `処理=REJECT_FOR_REVIEW`. This shows that the new branch only affects `F` and does not change the fallback behavior of `WHEN OTHER`. This check is used to confirm the "do not change `WHEN OTHER`" constraint above.

## Apply It Elsewhere (no answer provided)

For a batch record, classify the payment method: `C` cash, `B` bank transfer, `K` check; any code outside the contract must uniformly output "pending manual review".

Requirements: write a complete fixed-format program that uses `EVALUATE` to map each payment-method code to a category label and a handling suggestion, and run once for each of the following values, recording the actual output: `C`, `B`, `K`, `Z` (a different letter), and a space (`VALUE " "`).

Limitations: only use this lesson's program structure, `EVALUATE` / `WHEN` / `WHEN OTHER`, `DISPLAY`, and `STOP RUN`; do not introduce tables, files, loops, or subprograms that have not yet been taught.

Submit the source code, the compile command, and the actual output for each value, and explain: how you confirmed that exactly only the matched branch executed, why undefined letters and the space both fall into the same fallback path, and why the "category / handling label" does not mean the payment itself has actually been processed.
