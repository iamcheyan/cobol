---
_translated_from: lessons/10_redefines/answer.md
_translated_by: site-src/translation agent
---
# Lesson 10 Modification Exercise: Reference Answer

This answer covers only the modification exercise in [`exercise.md`](./exercise.md); it does not answer the "try it further" exercise.

## How to Make the Change

Starting from the original `lesson.cob`, change only one `MOVE` in `2000-LOAD-TRANSFER`:

```cobol
           MOVE 99.99 TO WS-TRANSFER-AMOUNT
```

Keep all `PIC` clauses, field order, the `REDEFINES` declaration and target, both view lengths, all `DISPLAY` text, and every other `MOVE` value unchanged.

Commands:

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_10 lesson.cob
./build/lesson_10
echo $?
```

Both compiler calls and the program exit with `0`; compilation produces no diagnostics.

## Complete Output After the Change

```text
取引種別=D
入金口座=0001234567
入金額=00125.50
入金参照番号=TXN-000001
取引種別=T
振込元口座=0001234567
振込先口座=0007654321
振込金額=00099.99
同じバイト列の入金ビュー:
口座=0001234567
金額=00076.54
参照番号=3210009999
```

Only two lines differ from the original:

| Line | Original | After change | Reason |
|---|---|---|---|
| 8, `振込金額=` | `00250.75` | `00099.99` | The changed `MOVE` stores `99.99` as seven digits, `0009999`, in `9(5)V99`. |
| 12, `参照番号=` | `3210025075` | `3210009999` | The reference number reads a shared byte range that includes the transfer amount. |

The remaining 10 lines are byte-for-byte unchanged, including line 11 `金額=00076.54`.

## Answers to the Questions

**1. Why does `金額=00076.54` remain unchanged, and which bytes determine it?**

The deposit amount reads payload bytes 11–17. In the transfer view, those positions overlap the first seven bytes of the target account `0007654321` (the account occupies bytes 11–20). The transfer amount is written to bytes 21–27, so the ranges do not overlap. Changing the transfer amount cannot alter `金額=`; that value depends on `WS-TARGET-ACCOUNT`.

**2. Which byte ranges provide `321` and `0009999` in `参照番号=3210009999`?**

The reference number reads payload bytes 18–27:

- `321` comes from bytes 18–20, the last three bytes of the target account in bytes 11–20.
- `0009999` comes from bytes 21–27, the seven digits for transfer amount `99.99`.

Thus the change affects the final seven characters of the reference number, while its first three remain determined by the target account.

**3. Which source statement chooses a view based on the transaction code?**

There is no such statement. The transaction code appears only in the two `MOVE "D"` / `MOVE "T"` statements and two `DISPLAY` statements; it is never tested in a condition. `1000-LOAD-DEPOSIT` directly uses the deposit-view fields, while `2000-LOAD-TRANSFER` directly uses the transfer-view fields.

The sample-data writer (or the upstream interface contract) determines that this write uses the transfer view; the program does not infer it. At compile time, the compiler checks that the level numbers match, `REDEFINES` immediately follows the redefined item, and the redefining item is not longer. The manual also requires equal lengths, no `OCCURS`, and no `VALUE`, although this toolchain does not warn about the latter two. At runtime, the program validates none of these payload semantics: it does not check the transaction code or whether the bytes match the selected view's field types. Even letters placed in bytes covered by `9(5)V99` are printed unchanged and the program still exits `0`.

The key point is that the business type code is responsible for selecting the view. `REDEFINES` provides multiple field descriptions of the same bytes; it neither selects nor validates a view.
