---
_translated_from: lessons/22_file-processing-practice/answer.md
_translated_by: site-src/translation agent
---
# Lesson 22 Modification Exercise Answers

These answers cover the two modifications in `exercise.md`, not the extension. Begin from fixture copies:

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_22 lesson.cob
cp accounts.txt transactions-unsorted.txt build/
cp build/transactions-unsorted.txt build/orig-transactions.txt
```

## 1. Change the Unmatched Transaction to Account A000000009

In `build/transactions-unsorted.txt`, replace:

```text
A000000004D000007500
```

with:

```text
A000000009D000007500
```

Run `(cd build && ./lesson_22)`. The transaction matches master account `A000000009` and has valid fields, so it enters accepted output. That master row is claimed and the master-only count becomes zero. Standard output:

```text
ACCEPTED 账号=A000000001
ACCEPTED 账号=A000000003
ACCEPTED 账号=A000000005
被拒绝 账号=A000000006 REASON=NO_ACCOUNT
被拒绝 账号=A000000007 REASON=BAD_AMOUNT
ACCEPTED 账号=A000000009
输入记录数=006 排序记录数=006
接受记录数=004
拒绝记录数=002 MASTER_ONLY账户记录数=000
```

`build/accepted.txt` has four rows, including:

```text
A000000009C0001009D000007500
```

`build/rejected.txt` retains two rows: `A000000006...NO_ACCOUNT` and `A000000007...BAD_AMOUNT`.

Check the invariants: `accepted 4 + rejected 2 = input 6`; `matched master 4 + master-only 0 = master 5`. Only one transaction is rejected for a missing master, so `6 − 1 = 5` masters were matched. Exit code: `0`.

## 2. Correct the Amount for Account A000000007

Restore the fixture from `build/orig-transactions.txt`. Change the last transaction from:

```text
A000000007D00000X001
```

to:

```text
A000000007D000000001
```

The nine-character amount is now numeric. The transaction matches master account `A000000007` and enters accepted output. It represents `0.01`; this program validates formatting and writes the row, but **does not update the master balance**. Standard output:

```text
ACCEPTED 账号=A000000001
ACCEPTED 账号=A000000003
被拒绝 账号=A000000004 REASON=NO_ACCOUNT
ACCEPTED 账号=A000000005
被拒绝 账号=A000000006 REASON=NO_ACCOUNT
ACCEPTED 账号=A000000007
MASTER_ONLY账户 账号=A000000009
输入记录数=006 排序记录数=006
接受记录数=004
拒绝记录数=002 MASTER_ONLY账户记录数=001
```

`build/accepted.txt` includes:

```text
A000000007C0001007D000000001
```

`build/rejected.txt` retains the two `NO_ACCOUNT` rows for `A000000004` and `A000000006`.

Check: `accepted 4 + rejected 2 = input 6`; `matched master 4 + master-only 1 = master 5`. Exit code: `0`.

Both exercises show that physical input row order does not determine matching order: `SORT` orders transactions by account number first, then matching compares current keys. The contents change; the processing sequence remains ordered.
