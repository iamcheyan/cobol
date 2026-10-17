---
_translated_from: lessons/14_data-structures-practice/answer.md
_translated_by: site-src/translation agent
---
# Lesson 14 Modification Exercises: Reference Answers

This answer covers only the two modification exercises in `exercise.md`; it does not answer Apply What You Learned. Start each modification independently from the original `lesson.cob`. Compile and run with:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_14 lesson.cob
./build/lesson_14
```

## Make the Fourth Transfer Succeed

In `1100-LOAD-TRANSACTIONS`, change the target account to:

```cobol
           MOVE "0002468101" TO WS-TARGET-ACCOUNT(4)
```

The fourth transaction transfers `20.00` from `0007654321` to `0002468101`. Expected result and summary:

```text
結果=POSTED 振込元口座=0007654321 振込先口座=0002468101
口座残高 口座=0001234567 残高=0001085.50
口座残高 口座=0002468101 残高=0000295.00
口座残高 口座=0007654321 残高=0000070.00
集計 処理件数=04 成功=04 拒否=00
```

## Verify That an Insufficient Balance Does Not Change Either Account

Starting from the original source, change the fourth transaction:

```cobol
           MOVE "0001234567" TO WS-TARGET-ACCOUNT(4)
           MOVE 100.00 TO WS-TRANSFER-AMOUNT(4).
```

The target exists, but the source account `0007654321` has only `90.00`. Expected output:

```text
結果=拒否 REASON=INSUFFICIENT_FUNDS
口座残高 口座=0001234567 残高=0001085.50
口座残高 口座=0002468101 残高=0000275.00
口座残高 口座=0007654321 残高=0000090.00
集計 処理件数=04 成功=03 拒否=01
```

The program looks up the source and then the target before updating either balance. Therefore, if the target is missing or the source has insufficient funds, it does not update just one side. This is only protection provided by statement order: this lesson has no transaction, rollback, or rerun guarantee. If the two sides were stored in different files or databases, update ordering and failure recovery would need to be designed separately (see Lessons 31 and 32).
