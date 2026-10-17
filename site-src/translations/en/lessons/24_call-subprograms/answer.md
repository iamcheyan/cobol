---
_translated_from: lessons/24_call-subprograms/answer.md
_translated_by: site-src/translation agent
---
# Lesson 24 Modification Exercise Answers

These answers cover the two modification exercises in [`exercise.md`](./exercise.md), not the extension. Both start from the original two source files and are independent. Compile the main program and subprogram together after each change:

```sh
mkdir -p build
cobc -x -Wall -o build/lesson_24 lesson.cob amount_check_24.cob
./build/lesson_24
rm -rf build
```

## 1. Raise the Amount Limit to 1500.00

In `0000-VALIDATE-AMOUNT` in the original `amount_check_24.cob`, change:

```cobol
               WHEN LK-AMOUNT > 1000.00
```

to:

```cobol
               WHEN LK-AMOUNT > 1500.00
```

`1000.01` now satisfies `0 < 1000.01 ≤ 1500.00`, so the subprogram returns `VALID` through `WHEN OTHER`. `9999999.99` remains above the new limit and returns `LIMIT-EXCEEDED`. Complete output (20 lines):

```text
呼び出し元：開始
呼び出し前 金額=0000125.50
呼び出し戻り 状態=VALID
呼び出し前 金額=0000000.00
呼び出し戻り 状態=ZERO-AMOUNT
呼び出し前 金額=0001000.00
呼び出し戻り 状態=VALID
呼び出し前 金額=0001000.01
呼び出し戻り 状態=VALID
呼び出し前 金額=0000000.01
呼び出し戻り 状態=VALID
呼び出し前 金額=0000999.99
呼び出し戻り 状態=VALID
呼び出し前 金額=9999999.99
呼び出し戻り 状態=LIMIT-EXCEEDED
呼び出し前 金額=0000500.00
呼び出し戻り 状態=VALID
呼び出し元：サブプログラムから戻り継続
検査総数=008 有効=006 拒否=002
ゼロ金額拒否数=001 上限超過拒否数=001
```

Only three lines differ from the original run: case 4 changes from `LIMIT-EXCEEDED` to `VALID`, and the final two count lines change (valid `005→006`, limit rejects `002→001`). Total checks `008` and zero-amount rejects `001` remain unchanged; `8 = 6 + 2` still holds.

Control flow: `呼び出し前 金額=` appears before each `CALL`; `呼び出し戻り 状態=` appears after that `CALL`; `呼び出し元：サブプログラムから戻り継続` appears after all eight cases, showing that the main program continues to `PERFORM 3000-DISPLAY-SUMMARY` and is not ended by the subprogram.

## 2. Change the Zero-Amount Case to One Cent

In `1200-CHECK-ZERO-AMOUNT` in the original `lesson.cob`, change:

```cobol
           MOVE ZERO TO WS-AMOUNT
```

to:

```cobol
           MOVE 0.01 TO WS-AMOUNT
```

`0.01` is nonzero and no greater than `1000.00`, so the subprogram returns `VALID`. This equals the amount in `1500-CHECK-SMALL-POSITIVE`; the output therefore contains two `金額=0000000.01` cases. Complete output:

```text
呼び出し元：開始
呼び出し前 金額=0000125.50
呼び出し戻り 状態=VALID
呼び出し前 金額=0000000.01
呼び出し戻り 状態=VALID
呼び出し前 金額=0001000.00
呼び出し戻り 状態=VALID
呼び出し前 金額=0001000.01
呼び出し戻り 状態=LIMIT-EXCEEDED
呼び出し前 金額=0000000.01
呼び出し戻り 状態=VALID
呼び出し前 金額=0000999.99
呼び出し戻り 状態=VALID
呼び出し前 金額=9999999.99
呼び出し戻り 状態=LIMIT-EXCEEDED
呼び出し前 金額=0000500.00
呼び出し戻り 状態=VALID
呼び出し元：サブプログラムから戻り継続
検査総数=008 有効=006 拒否=002
ゼロ金額拒否数=000 上限超過拒否数=002
```

The second case’s amount changes from `0000000.00` to `0000000.01`, and its status changes from `ZERO-AMOUNT` to `VALID`. The count lines change to zero-amount rejects `001→000`, limit rejects unchanged at `002`, and valid `005→006`. The subprogram and limit are unchanged, so `1000.01` remains `LIMIT-EXCEEDED`; `8 = 6 + 2` still holds.
