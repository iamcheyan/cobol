---
_translated_from: lessons/21_sort/answer.md
_translated_by: site-src/translation agent
---
# Lesson 21 Modification Exercise Answers

These answers cover only the two modification exercises in `exercise.md`; no answer is provided for the extension. Use fixture copies in a temporary directory:

```sh
scratch=$(mktemp -d)
cp lesson.cob accounts-unsorted.txt "$scratch/"
cd "$scratch"
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o lesson_21 lesson.cob
```

## 1. Swap the First Two Input Rows

Swap the `A000000005` and `A000000001` rows in the copy, leaving the other rows unchanged. The file becomes:

```text
A000000001C0001001000100000
A000000005C0001005000025075
A000000004C0001004000002500
A000000002C0001002000000200
```

Sorted output remains unchanged and in ascending account-number order:

```text
ソート済み 口座番号=A000000001 顧客番号=C0001001 残高=0001000.00
ソート済み 口座番号=A000000002 顧客番号=C0001002 残高=0000002.00
ソート済み 口座番号=A000000004 顧客番号=C0001004 残高=0000025.00
ソート済み 口座番号=A000000005 顧客番号=C0001005 残高=0000250.75
入力レコード数=004 出力レコード数=004
```

Input procedure `1000-LOAD-INPUT` reads four rows and successfully `RELEASE`s each. Output procedure `2000-RETURN-SORTED` `RETURN`s four rows. Exit code: `0`.

## 2. Add Account A000000006

Append this 27-character row to a fresh copy of the original fixture:

```text
A000000006C0001006000000001
```

`A000000006` is the largest sort key, so it appears last. Balance digits `000000001` display as `0000000.01` under `9(7)V99`:

```text
ソート済み 口座番号=A000000001 顧客番号=C0001001 残高=0001000.00
ソート済み 口座番号=A000000002 顧客番号=C0001002 残高=0000002.00
ソート済み 口座番号=A000000004 顧客番号=C0001004 残高=0000025.00
ソート済み 口座番号=A000000005 顧客番号=C0001005 残高=0000250.75
ソート済み 口座番号=A000000006 顧客番号=C0001006 残高=0000000.01
入力レコード数=005 出力レコード数=005
```

The input procedure releases five rows, the output procedure returns five, and `005 = 005`. Exit code: `0`.

Neither exercise changes source code. `SORT` reorders only by `SD-ACCOUNT-NUMBER`, so physical row order does not affect the result.
