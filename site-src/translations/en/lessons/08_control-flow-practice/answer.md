---
_translated_from: lessons/08_control-flow-practice/answer.md
_translated_by: site-src/translation agent
---
# Lesson 08 Modification Exercise: Reference Answers

This answer covers only the two modifications in `exercise.md`. Start each from the original `lesson.cob`; compile and run with:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_08 lesson.cob
./build/lesson_08
```

## Change the Opening Balance

Set the initial value in `lesson.cob` to:

```cobol
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 2000.00.
```

After the first two transactions, the balance is `2085.40`, so the third withdrawal, previously rejected for insufficient funds, is now accepted. The new balance is `2000.00 + 125.50 - 40.10 - 1500.00 = 585.40`. Only the negative deposit and unknown code are rejected:

```text
処理件数=005
承認件数=003
拒否件数=002
最終残高=0000585.40
```

## Withdrawal Exactly Equal to the Available Balance

In `2100-LOAD-SAMPLE`, change the amount in `WHEN 3` to:

```cobol
                   MOVE 1085.40 TO WS-TRANSACTION-AMOUNT
```

The balance after the first two transactions is `1085.40`. The withdrawal condition uses `<= WS-CURRENT-BALANCE`, so equality is accepted and the balance becomes zero. The negative deposit and unknown code are still rejected:

```text
レコード=003 符号=W 金額=+01085.40
結果=ACCEPTED 理由=WITHDRAWAL
処理件数=005
承認件数=003
拒否件数=002
最終残高=0000000.00
```

These modifications demonstrate the effect of opening state on the final calculation and the boundary behavior of `<=` when a withdrawal equals the current balance.
