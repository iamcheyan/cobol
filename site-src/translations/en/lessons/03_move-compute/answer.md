---
_translated_from: lessons/03_move-compute/answer.md
_translated_by: site-src/translation agent
---

# Lesson 03 Modification Exercise — Reference Answer

This answer only covers the modification exercise in `exercise.md`; no answer is included for the "apply it elsewhere" exercise.

Starting from the original `lesson.cob`, change only two initial values; leave all other declarations and statements untouched:

```cobol
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 200.65.
       01 WS-PERIOD-RATE PIC 9(1)V9(4) VALUE 0.0150.
```

Re-check, compile, and run (the same commands as in `exercise.md`):

```sh
cd lessons/03_move-compute
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_03 lesson.cob
./build/lesson_03
echo $?
rm -rf build
```

## Manual verification

1. Pre-interest balance: `1000.00 + 200.65 − 40.10 − 5.25 = 1155.30` (add then subtract; unit is yuan).
2. Intermediate interest: `1155.30 × 0.0150 = 17.3295`; the receiving field `WS-INTEREST-RAW` is `9(5)V9999` (four decimals), so it can hold the full value.
3. `MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE`: `WS-INTEREST-MOVE` is `9(5)V99`; not writing `ROUNDED` is equivalent to truncation: `17.3295 → 17.32`; `WS-INTEREST-RAW` itself is still `17.3295`.
4. `COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW`: no `ROUNDED`, same truncation rule; result `17.32`.
5. `COMPUTE WS-INTEREST-ROUNDED ROUNDED = WS-INTEREST-RAW`: default `NEAREST-AWAY-FROM-ZERO`; the 3rd digit is `9`, round up to `17.33`.
6. Closing balance: under this lesson's posting rule (rounded interest credited), `1155.30 + 17.33 = 1172.63`.

## Complete expected output

```text
期首残高=0001000.00
預入額=0000200.65
払戻額=0000040.10
手数料=00005.25
期間利率=0.0150
利息加算前残高=0001155.30
利息（4桁）=00017.3295
MOVE後利息（2桁）=00017.32
COMPUTE切捨て利息=00017.32
COMPUTE四捨五入利息=00017.33
期末残高=0001172.63
```

Compared with the baseline output, the three lines `期首残高`, `払戻額`, `手数料` are unchanged; the other 8 lines change according to the expected-diff table in `exercise.md`. The exit codes of `cobc -fsyntax-only`, `cobc -x`, and the program run are all `0`; standard error contains only the environmental libxml version warning; there is no compile warning.

## Answer to the questions

- The common source value for truncation and rounding is `WS-INTEREST-RAW`, namely `17.3295`; it is decided by `9(5)V9999`, keeping four decimals.
- The `MOVE` result is decided by the receiving field `WS-INTEREST-MOVE` (`9(5)V99`); the `COMPUTE` without `ROUNDED` is decided by `WS-INTEREST-TRUNC` (`9(5)V99`); the `COMPUTE` with `ROUNDED` is decided by `WS-INTEREST-ROUNDED` (`9(5)V99`). The three have the same source value and the same receiving field scale; the difference is solely due to "whether `ROUNDED` is written".
