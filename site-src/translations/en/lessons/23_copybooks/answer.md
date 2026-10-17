---
_translated_from: lessons/23_copybooks/answer.md
_translated_by: site-src/translation agent
---
# Lesson 23 Modification Exercise Answers

These answers cover the two modification exercises in [`exercise.md`](./exercise.md), not the extension exercise described in [`exercise.md`](./exercise.md). Start each exercise from a clean working copy: follow the copy commands in `exercise.md`, then run syntax checks, compilation, and programs from `build/work` (`-I copybooks` is required). Return to the lesson directory and remove `build/` when finished.

## 1. Change the Shared Account Number to `PIC X(8)`

**Change** (one Copybook line only):

```cobol
          05 WS-ACCOUNT-NUMBER PIC X(8).
```

**Recompile and run** (both consumers must be rebuilt):

```sh
cd build/work
cobc -fsyntax-only -I copybooks lesson.cob                 # without -Wall: no output, exit code 0
cobc -fsyntax-only -Wall -I copybooks lesson.cob           # with -Wall: emits the -Wtruncate warning below
cobc -x -Wall -I copybooks -o lesson_23 lesson.cob         # exit code 0, warning remains
cobc -x -Wall -I copybooks -o account_report_23 account_report_23.cob
./lesson_23
./account_report_23
```

**Compiler output:** each program emits a `-Wtruncate` warning pointing to the changed Copybook line. Exit code remains `0`; a warning is not an error.

```text
lesson.cob:31: warning: value size exceeds data size [-Wtruncate]
lesson.cob:31: note: value size is 10 [-Wtruncate]
copybooks/ACCOUNT-REC.CPY:5: note: 'WS-ACCOUNT-NUMBER' defined here as PIC X(8) [-Wtruncate]
account_report_23.cob:16: warning: value size exceeds data size [-Wtruncate]
```

Without `-Wall` or `-Wtruncate`, neither `cobc -fsyntax-only` nor `cobc -x` shows this warning in the verified environment. Enable a warning option to see it.

**`lesson_23` standard output** (only the account summary line changes):

```text
入账成功 类型=D 金额=0000125.50
入账成功 类型=C 金额=0000025.25
入账拒绝 原因=INSUFFICIENT
入账拒绝 原因=BAD_TYPE
入账拒绝 原因=NO_ACCOUNT
账户号码=A0000000 客户号码=C0001001 余额=0001100.25
成功笔数=002 拒绝笔数=003
```

**`account_report_23` standard output:** `口座レポート 口座番号=A0000000 顧客番号=C0001009 残高=0000020.00`.

**Record width:** `WS-ACCOUNT-RECORD` changes from 27 bytes to `8 + 8 + 9 = 25` bytes (`FUNCTION LENGTH(WS-ACCOUNT-RECORD)` measures 25). It no longer matches the 27-byte fixed-length account interface in Lessons 17, 20, and 22. Programs that split records at 27 bytes will be misaligned.

**Why two transactions still post:** `MOVE "A000000001" TO WS-ACCOUNT-NUMBER` truncates the value on the right to `A0000000` because the destination is eight characters. Moving that value into the 10-character transaction account gives `A0000000` followed by two spaces. In `IF WS-TRANSACTION-ACCOUNT NOT = WS-ACCOUNT-NUMBER`, COBOL pads the shorter alphanumeric operand with spaces to equal length. Thus `A0000000  ` equals `A0000000`, and the posting path is unchanged. The fifth transaction still uses the 10-character `A000000099` from the transaction Copybook, so it differs from `A0000000  ` and remains `NO_ACCOUNT`. Balance and counts therefore stay the same. The key observation is that **a width change can leave counts unchanged while silently truncating data and breaking the external 27-byte contract**.

## 2. Change the Last Transaction to a Known Account

**Baseline:** make a fresh `build/work` copy; do not reuse the modified copy from Exercise 1.

**Change** (one line in `lesson.cob`):

```cobol
           MOVE "A000000001" TO WS-TRANSACTION-ACCOUNT
```

**Recompile and run:** only the main program needs rebuilding. Neither `account_report_23.cob` nor its Copybook input changed, so its existing executable remains valid.

```sh
cd build/work
cobc -x -Wall -I copybooks -o lesson_23 lesson.cob
./lesson_23
```

**Compiler output:** no warning or error; exit code `0`.

**`lesson_23` standard output:**

```text
入账成功 类型=D 金额=0000125.50
入账成功 类型=C 金额=0000025.25
入账拒否 原因=INSUFFICIENT
入账拒否 原因=BAD_TYPE
入账成功 类型=D 金额=0000001.00
账户号码=A000000001 客户号码=C0001001 余额=0001101.25
成功笔数=003 拒绝笔数=002
```

The fifth transaction now matches the shared account record, bypasses `NO_ACCOUNT`, and posts `1.00` as a debit: `1100.25 + 1.00 = 1101.25`. Successful transactions rise to 3; the only rejects are `INSUFFICIENT` and `BAD_TYPE`, for a total of 5 transactions. `account_report_23` output remains `口座レポート 口座番号=A000000009 顧客番号=C0001009 残高=0000020.00`.

**Comparison with Exercise 1:** this changes a business constant in the main program without changing record layout, so only `lesson.cob` needs recompilation. Exercise 1 changed a shared declaration and affected the layout, so both consumers needed recompilation and the external fixed-length interface was broken.
