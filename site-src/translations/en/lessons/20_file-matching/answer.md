# Lesson 20 Modification Exercise Reference Answers

These answers cover only the two modification exercises in `exercise.md`; no answer is provided for the Take It Further exercise. Make both changes to fixture copies in a temporary directory:

```sh
scratch=$(mktemp -d)
cp lesson.cob accounts.txt transactions.txt "$scratch/"
cd "$scratch"
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o lesson_20 lesson.cob
```

## 1. Delete the Transaction for Account A000000004

In the copy, delete the 20-character line in `transactions.txt` that begins with `A000000004` (the file will then have 3 lines and remain sorted in ascending order). The current master key `A000000003` is less than the next transaction key `A000000005`, so the program first reports `口座のみ` and advances only the master stream. Then `A000000005` matches the master, and `A000000006` is classified as a transaction-only record:

```text
口座のみ 口座番号=A000000003 顧客番号=C0001003 残高=0000002.00
一致 口座番号=A000000005 顧客番号=C0001005 残高=0000250.75 種別=T 金額=0000040.00
取引のみ 口座番号=A000000006 種別=D 金額=0000020.00
照合件数=002 口座のみ=001 取引のみ=001
```

Invariant check: `2 + 1 = 3` (master record count), and `2 + 1 = 3` (transaction count after deletion). Exit code: `0`.

## 2. Change Transaction Key A000000004 to A000000003

Change the line in the copy of the transaction file that begins with `A000000004` to:

```text
A000000003D000005000
```

It remains 20 characters, and the file order `A000000001`, `A000000003`, `A000000005`, `A000000006` remains ascending. This key equals the second master record's key, so the program reports `一致` and advances both streams:

```text
一致 口座番号=A000000003 顧客番号=C0001003 残高=0000002.00 種別=D 金額=0000050.00
一致 口座番号=A000000005 顧客番号=C0001005 残高=0000250.75 種別=T 金額=0000040.00
取引のみ 口座番号=A000000006 種別=D 金額=0000020.00
照合件数=003 口座のみ=000 取引のみ=001
```

Invariant check: `3 + 0 = 3` (master record count), and `3 + 1 = 4` (transaction record count). Exit code: `0`.

Both exercises demonstrate the same point: classification and counts depend entirely on which current key is larger, so the input must truly be sorted in ascending order and keys must be unique; the program does not check either condition.
