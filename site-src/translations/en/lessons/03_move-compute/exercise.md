---
_translated_from: lessons/03_move-compute/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 03 Exercise: MOVE and COMPUTE

This exercise uses only the material from lesson 03: `VALUE` initial values, `MOVE`, `COMPUTE` (including `ROUNDED`), `DISPLAY`, `STOP RUN`, and fixed format.

## Modification Exercise (reference answer provided in `answer.md`)

**Baseline:** start from the lesson's original [`lesson.cob`](./lesson.cob). Do not modify the program structure, field declaration order, field `PIC`s, `DISPLAY` text, or statement order.

**Changes (change only two `VALUE`s):**

1. `WS-DEPOSIT` initial from `250.55` to `200.65`.
2. `WS-PERIOD-RATE` initial from `0.0125` to `0.0150`.

**Constraint:** Do not change any `PIC`. The phenomenon this question asks you to observe is exactly "truncation versus rounding", and the result is fully determined by the receiving field's `PIC`; changing the `PIC` would mask the difference and prevent comparison against the expected values below. Do not add or remove fields or statements either.

**Re-check, compile, and run:**

```sh
cd lessons/03_move-compute
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_03 lesson.cob
./build/lesson_03
echo $?
rm -rf build
```

**Complete expected diff:** Compared with the baseline output in the README, the following 8 lines change; the other 3 lines (`期首残高`, `払戻額`, `手数料`) are unchanged:

| Output line | Baseline | After change | Reason |
|---|---|---|---|
| `預入額=` | `0000250.55` | `0000200.65` | changed initial value |
| `期間利率=` | `0.0125` | `0.0150` | changed initial value |
| `利息加算前残高=` | `0001205.20` | `0001155.30` | 1000.00 + 200.65 − 40.10 − 5.25 |
| `利息（4桁）=` | `00015.0650` | `00017.3295` | 1155.30 × 0.0150 |
| `MOVE後利息（2桁）=` | `00015.06` | `00017.32` | truncated to two decimals |
| `COMPUTE切捨て利息=` | `00015.06` | `00017.32` | no `ROUNDED`, same truncation rule |
| `COMPUTE四捨五入利息=` | `00015.07` | `00017.33` | 3rd digit is `9`, round to nearest (up) |
| `期末残高=` | `0001220.27` | `0001172.63` | 1155.30 + 17.33 |

**Expected exit codes and diagnostics:** the exit codes of `cobc -fsyntax-only`, `cobc -x`, and `./build/lesson_03` are all `0`, with no compile warning; standard error is only the environmental libxml version warning.

**Question to answer:** In this output, which field is the common source value for both truncation and rounding? Which receiving field's `PIC` decides the `MOVE` result, and which decides each `COMPUTE` result? Write out your own formula (e.g. compute the pre-interest balance first, then multiply by the rate), compare line by line with the table above, and only then run the program.

## Apply It Elsewhere (no answer)

Design a "monthly interest accrual" demonstration for another deposit: pick your own opening balance, demonstration rate, four-decimal intermediate field, and two-decimal receiving field; demonstrate `MOVE`, `COMPUTE` without `ROUNDED`, and `COMPUTE` with `ROUNDED`.

Requirements:

- Use only independent field declarations (`01`-level + `PIC` + `VALUE`), `MOVE`, `COMPUTE` (with `ROUNDED` allowed), `DISPLAY`, and `STOP RUN`; do not introduce `IF`, loops, paragraphs, files, or databases.
- Report the rounding rule you chose and its business implications, and explain why that rule fits your scenario.
- Submit the complete source, the compile/run commands, the actual output, and the hand-computation verification of each amount (compute first, run after, and use the run result to verify — not the other way around).
