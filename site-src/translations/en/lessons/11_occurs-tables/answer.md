---
_translated_from: lessons/11_occurs-tables/answer.md
_translated_by: site-src/translation agent
---
# Lesson 11 Modification Exercises: Reference Answers

This answer covers only the three modification exercises in `exercise.md`; no answer is provided for Apply What You Learned. Start each exercise independently from the original `lesson.cob` for this lesson. The commands match the README:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_11 lesson.cob
./build/lesson_11
```

All output below was observed in this workspace. The syntax checks, compilations, and runs for all three cases returned `0`. Runtime standard error also contained a libxml version warning; it is not program output.

## 1. Change the Fourth Entry’s Amount

Only one line changes in `1000-LOAD-TABLE`:

```cobol
           MOVE 35.00 TO WS-TXN-AMOUNT(4)
```

Complete expected output:

```text
明細=01 コード=C 金額=00125.50
処理=入金
明細=02 コード=D 金額=00040.10
処理=出金
明細=03 コード=X 金額=00025.00
処理=未知コードを無視
明細=04 コード=C 金額=00035.00
処理=入金
処理件数=004
最終残高=0001120.40
```

Difference and reason: the `C` branch adds this amount to the balance, so only the amount on `明細=04` and `最終残高` change: `1000.00 + 125.50 − 40.10 + 35.00 = 1120.40`. `処理件数` remains `004` because it counts table entries, regardless of their amounts. The first six lines are byte-for-byte unchanged.

## 2. Expand to Five Entries and Load the Fifth

Change all three values together; otherwise capacity, loaded-entry count, and traversal limit will disagree:

```cobol
          05 WS-TRANSACTION-ENTRY OCCURS 5 TIMES.
       01 WS-LAST-SAMPLE PIC 9 VALUE 5.
           MOVE "C" TO WS-TXN-CODE(5)
           MOVE 10.00 TO WS-TXN-AMOUNT(5).
```

Place the two `MOVE` statements for the fifth entry after the fourth. Keep `WS-TXN-AMOUNT(4)` at `20.00`. Complete expected output:

```text
明細=01 コード=C 金額=00125.50
処理=入金
明細=02 コード=D 金額=00040.10
処理=出金
明細=03 コード=X 金額=00025.00
処理=未知コードを無視
明細=04 コード=C 金額=00020.00
処理=入金
明細=05 コード=C 金額=00010.00
処理=入金
処理件数=005
最終残高=0001115.40
```

Difference and reason: `PERFORM VARYING` now processes the new `C` / `10.00` entry. The balance increases from `1105.40` to `1000.00 + 125.50 − 40.10 + 20.00 + 10.00 = 1115.40`; the processed count changes from `004` to `005`. The original four entries are unchanged, and the new detail line appears last.

## 3. Out-of-Range Observation: Increase Only the Traversal Limit to 5

The only change is this line:

```cobol
       01 WS-LAST-SAMPLE PIC 9 VALUE 5.
```

Observed results:

- `cobc -fsyntax-only lesson.cob` and compilation both return `0`, with no diagnostics: the compiler does not check whether a subscript is within the table capacity.
- The program also exits with code `0`. The fifth entry is printed as `明細=05 コード=0 金額=5`, followed by four non-printable NUL bytes and `.00`.
- Those bytes are neither `C` nor `D`, so `EVALUATE` takes `WHEN OTHER` and prints `処理=未知コードを無視`. The final values are `処理件数=005` and `最終残高=0001105.40` (coincidentally the result for the first four entries, because the bytes read do not enter an accounting branch).
- Thus the program neither reports an error nor returns a nonzero code, but the fifth entry’s value is entirely untrustworthy.

Reason: four table entries occupy 32 bytes, and subscript 5 addresses memory outside the table. By default, GnuCOBOL calculates the address directly from the subscript without checking the bounds, so it reads work-storage bytes immediately following the table. (`cobc -C` output shows fields such as `WS-SAMPLE-INDEX` immediately after the table.) The bytes depend on compiler layout and can differ after a version change or field reordering; they cannot be predicted or treated as business data.

Keep capacity, loaded-entry count, and traversal limit consistent (as in exercise 2), or validate the subscript range explicitly before reading. In batch processing, silently reading the wrong bytes is harder to detect than failing immediately.
