---
_translated_from: lessons/10_redefines/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 10 Exercise: REDEFINES

This lesson uses only material from Lesson 10 and earlier: `05` / `10` level data items (Lesson [09](../09_group-items/README.md)), `REDEFINES`, `MOVE`, `DISPLAY`, paragraph calls with `PERFORM` (Lesson [07](../07_paragraphs/README.md)), and `STOP RUN`.

## Modification Exercise (reference answer in `answer.md`)

### Baseline

Start from the unchanged original [`lesson.cob`](./lesson.cob). Copy it before editing, for example with `cp lesson.cob /tmp/lesson_10_ex.cob`, so the baseline can be rerun.

### Change and constraints

Change only this statement in `2000-LOAD-TRANSFER`:

```cobol
           MOVE 250.75 TO WS-TRANSFER-AMOUNT
```

Replace `250.75` with `99.99`.

Do not change any `PIC`, field order, the position or target of `REDEFINES`, or either view's length. Do not change `DISPLAY` text, `1000-LOAD-DEPOSIT`, or the `MOVE` values for transaction code, account numbers, or reference number. Change only this numeric literal; do not add `COMPUTE`, `IF`, `EVALUATE`, or data items.

### Commands

```sh
mkdir -p build                                   # create the output directory first
cobc -fsyntax-only lesson.cob                    # syntax check
cobc -x -Wall -o build/lesson_10 lesson.cob      # compile
./build/lesson_10                                # run and inspect 12 output lines
echo $?                                          # exit code
```

### Expected Difference

Standard output still has 12 lines, and only two change:

| Line | Original | After the change |
|---|---|---|
| 8 | `振込金額=00250.75` | `振込金額=00099.99` |
| 12 | `参照番号=3210025075` | `参照番号=3210009999` |

The other 10 lines, including line 11 `金額=00076.54`, remain byte-for-byte unchanged. Syntax check, compilation, and program exit codes are all `0`.

Complete expected output after the change:

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

Independent check using the layout table in this lesson's README: `9(5)V99` stores seven digits. `99.99` occupies payload bytes 21–27 as `0009999`; the reference number reads payload bytes 18–27, giving the last three target-account digits `321` followed by `0009999`, or `3210009999`. The deposit amount reads only bytes 11–17 (`0007654` from the target account's first seven digits), so it does not change.

### Questions

1. Why does `金額=00076.54` remain unchanged? Which byte positions determine it?
2. Which byte ranges provide `321` and `0009999` in `参照番号=3210009999`?
3. Which statement in the source chooses the deposit or transfer view based on the transaction code? If there is no such statement, what determines that this write uses the transfer view? Which conditions does the program actually validate?

Record actual output for each question and cite the relevant source. See [`answer.md`](./answer.md) for reference answers.

## Apply What You Learned (No Answer Provided)

Design two views sharing the same payload for cash withdrawal and account-to-account transfer.

Choose the fields and `PIC` clauses for each view. Calculate the size of every elementary item and each complete view, and confirm the views have equal length (a longer redefining view fails compilation; a shorter view can compile but leaves bytes uncovered). Use a transaction code such as `W` / `T` to distinguish the views and explain how the reader knows which view applies. Explain what happens for an unrecognized code and why that does not count as correct processing. Write sample values through one view, then read through the other and explain why that output is not a valid interpretation of the original transaction.

Use only hierarchical items, `REDEFINES`, `MOVE`, `DISPLAY`, paragraphs and `PERFORM`, and `STOP RUN`. You may add Lesson [04](../04_if-conditions/README.md) or [05](../05_evaluate/README.md) conditionals to choose which view to display, but that is optional. Do not introduce files, tables (`OCCURS` is taught in Lesson [11](../11_occurs-tables/README.md)), databases, or subprograms. Submit the source, byte calculations, commands, actual output, exit code, and an explanation of who is responsible for keeping the type code and layout consistent. No answer is provided.
