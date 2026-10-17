---
_translated_from: lessons/23_copybooks/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 23 Exercises: Shared Record Declarations and Their Consumers

Two programs in this lesson use `copybooks/ACCOUNT-REC.CPY`: `lesson.cob` (`PROGRAM-ID. LESSON23`, transaction posting) and `account_report_23.cob` (`PROGRAM-ID. ACCOUNT-REPORT23`, account report). Make every change to **copies** in this lesson’s working directory; do not edit repository originals.

Common requirements:

- Run every command from this lesson directory. `-I copybooks` supplies the Copybook search path. Without it, even syntax checking reports that `ACCOUNT-REC.CPY` cannot be found.
- **Do not edit repository files directly.** Copy both `.cob` files and both `.CPY` files to `build/work` as shown below. Run all later checks, compilation, and programs from that copy directory. Clean up with `rm -rf build` when finished (`build/` is ignored by Git).
- After changing a Copybook, **recompile before running**. Running an old executable does not incorporate the change.

```sh
rm -rf build && mkdir -p build/work/copybooks
cp lesson.cob account_report_23.cob build/work/
cp copybooks/* build/work/copybooks/
cd build/work          # run later checks, compilation, and programs here
```

Baseline standard output (run once before changes):

```text
入账成功 类型=D 金额=0000125.50
入账成功 类型=C 金额=0000025.25
入账拒绝 原因=INSUFFICIENT
入账拒绝 原因=BAD_TYPE
入账拒绝 原因=NO_ACCOUNT
账户号码=A000000001 客户号码=C0001001 余额=0001100.25
成功笔数=002 拒绝笔数=003
```

The report program prints `口座レポート 口座番号=A000000009 顧客番号=C0001009 残高=0000020.00`.

## Modification Exercises (Answers in [`answer.md`](./answer.md))

### 1. Change the Shared Declaration Width

- **Baseline:** original `copybooks/ACCOUNT-REC.CPY`, `lesson.cob`, and `account_report_23.cob`, copied into `build/work` using the commands above.
- **Change and constraints:** change only `05 WS-ACCOUNT-NUMBER PIC X(10).` in `build/work/copybooks/ACCOUNT-REC.CPY` to `PIC X(8).`. Do **not** change any `MOVE` literal or `TRANSACTION-REC.CPY`.
- **Commands:** for each program, run `cobc -fsyntax-only -I copybooks` and `cobc -x -Wall -I copybooks`, then run both executables as shown in [`README.md`](./README.md).
- **Answer these questions:**
  1. What does each compilation print? Does the conclusion change if syntax checking includes `-Wall`?
  2. Does the seven-line output from `lesson_23` change? If so, which line? What are the balance and both counts?
  3. What is the account record’s new physical width? What does it mean for the fixed-length interfaces in Lessons 17, 20, and 22?
  4. Use COBOL alphanumeric comparison rules, including padding of shorter operands, to explain the transaction results.

### 2. Change Only the Main Program’s Business Constant

- **Baseline:** make a fresh `build/work` copy. Do not continue from Exercise 1’s modified copy.
- **Change and constraints:** in `1500-POST-MISSING-ACCOUNT` in `lesson.cob`, change `MOVE "A000000099" TO WS-TRANSACTION-ACCOUNT` to `MOVE "A000000001" TO WS-TRANSACTION-ACCOUNT`. Do not change a Copybook or another paragraph.
- **Command:** recompile and run the consumer that needs rebuilding.
- **Answer:** where does the fifth transaction go? What are the balance and both counts? Which consumers must be recompiled, and which can keep their existing executable? Explain why.

## Extension (No Answer Provided)

Write a third consumer program for a monthly statement (for example, `monthly_statement_23.cob`) that reuses `ACCOUNT-REC.CPY`. Change the balance to a signed PIC representation for debit balances:

- Choose `S9(7)V99` or `S9(7)V99 SIGN LEADING SEPARATE` and measure the resulting shared-record width. Use `FUNCTION LENGTH` on the group item or write a fixed-length record and inspect it with `wc -c` / `od -An -c`.
- Choose a display field that shows the minus sign and explain why the original `PIC 9(7).99` is insufficient.
- Make the program produce a debit balance. Identify the posting rule changed and say whether that goes beyond this lesson.
- Deliver complete compile commands and full standard output for both consumers, and state whether the 27-byte fixed-length contract is preserved.

Do not recompile only one consumer, and do not describe compile-time `COPY` as runtime `CALL`. No answer is provided.
