---
_translated_from: lessons/05_evaluate/answer.md
_translated_by: site-src/translation agent
---

# Lesson 05 Modification Exercise — Reference Answer

This answer covers only the modification exercise in `exercise.md`; it does not include an answer for the "apply it elsewhere" exercise (payment-method classification). The baseline is this lesson's original `lesson.cob`.

## Changes

In `EVALUATE WS-TRANSACTION-CODE`, after the `DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"` of the `WHEN "T"` branch and before `WHEN OTHER`, insert:

```cobol
               WHEN "F"
                   DISPLAY "分類=FEE"
                   DISPLAY "処理=CHARGE_FEE"
```

and change the data item initial value to `F`:

```cobol
       01 WS-TRANSACTION-CODE PIC X VALUE "F".
```

The other branches, the output of `WHEN OTHER`, and the fixed format are all unchanged. The modified `EVALUATE` paragraph should be:

```cobol
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   DISPLAY "分類=DEPOSIT"
                   DISPLAY "処理=ADD_TO_ACCOUNT"
               WHEN "W"
                   DISPLAY "分類=WITHDRAWAL"
                   DISPLAY "処理=SUBTRACT_FROM_ACCOUNT"
               WHEN "T"
                   DISPLAY "分類=TRANSFER"
                   DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"
               WHEN "F"
                   DISPLAY "分類=FEE"
                   DISPLAY "処理=CHARGE_FEE"
               WHEN OTHER
                   DISPLAY "分類=UNKNOWN"
                   DISPLAY "処理=REJECT_FOR_REVIEW"
           END-EVALUATE
```

## Running

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_05 lesson.cob
./build/lesson_05
echo $?
```

## Expected output

```text
取引参照番号=TXN-00000001
取引コード=F
分類=FEE
処理=CHARGE_FEE
```

`cobc -fsyntax-only` and the compile exit code are `0` with no diagnostics, and the process exit code is `0`. Line 1, the reference number, is unchanged because that field was not modified.

## Boundary check (confirming `WHEN OTHER` was not changed)

Keep the newly added `WHEN "F"` branch, change the initial value back to `X`, and recompile and run:

```text
取引参照番号=TXN-00000001
取引コード=X
分類=UNKNOWN
処理=REJECT_FOR_REVIEW
```

`X` is not equal to any of `D`, `W`, `T`, or `F`, so it is still caught by the `WHEN OTHER` fallback. This shows that the new branch only affects `F` and does not change the unknown-code path. `REJECT_FOR_REVIEW` is only the handling label printed by the program; this lesson does not implement any real rejection flow.
