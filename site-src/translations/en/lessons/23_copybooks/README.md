---
_translated_from: lessons/23_copybooks/README.md
_translated_by: site-src/translation agent
---
# Lesson 23: Copybooks — Define a Record Once

The 27-byte account-master layout has been copied into individual programs in Lessons 17, 20, and 22. This lesson extracts it into `copybooks/ACCOUNT-REC.CPY`. Two independent programs use `COPY` to include the same declaration at compile time. Then you change a field width and identify the affected consumers.

## The Business Setting

At 3 p.m. on Tuesday, the core-system interface owner sends a revised document: **the account number grows from 10 to 12 digits**; everything else stays the same.

Three programs in the overnight reconciliation chain read the same account record: one reads and writes the 27-byte fixed-length master, another matches by account number, and a third produces a balance report for finance. Three people copied the layout into their own programs at different times.

The question is no longer “How do I change it?” It is **“How many places do I have to change?”**

Adding two digits shifts the customer number and balance two bytes to the right. You update the master reader, but the report program still slices the file at the old offsets. Its balance field now contains the end of the customer number and the start of the balance. It does not report an error. A fixed-length file has no separators; declarations determine which bytes belong to each field. With a wrong declaration, the file still opens and reads to completion, the log is clean, and the exit code is `0`. The error may be unnoticed for days.

A Copybook moves the declaration out of a program into its own file. Every consumer includes it at compile time. Since they use the same file, the upstream width change is made in **one declaration**.

But `COPY` is not runtime sharing: it inserts source text during compilation. If a consumer is not rebuilt after the Copybook changes, its old executable still uses the old layout. This produces the same offset failure, with an extra source of confusion: the file and Copybook are correct, but a stale binary remains.

(The institution, timing, and amounts are fictional teaching examples.)

## Why Learn This Now

Lesson 9 used `01` and `05` to build a hierarchical record in one program; Lesson 17 used the layout in a 27-byte fixed-length file. Why devote a lesson to moving a few `PIC` declarations?

Because the problem is not how to write them; it is **who needs to use and maintain them**. Each declaration belongs to one source file. A second program can use the same layout only by copying it.

`PIC X(10)` and `PIC X(1)` are both valid syntax. The compiler does not check that two programs use matching offsets. No warning appears until someone asks why a report is wrong.

What is missing is **sharing**: turning a declaration in one source file into a file referenced by multiple programs. Use `COPY "NAME.CPY".` to include it and `-I copybooks` to tell the compiler where to search.

This is not optional optimization. In [Lesson 24](../24_call-subprograms/README.md), amount validation moves into a subprogram, and [Lesson 24](../24_call-subprograms/README.md) also exchanges records through `LINKAGE`. The main program and subprogram must agree on the record layout, so they need a shared declaration.

**The business problem.** When the host-interface document changes a field width, the overnight-batch maintainer must update every consumer in **one release**. The next morning, reconciliation staff depend on the program and file agreeing about the account number. A report balance is reliable only when the report program uses the same declaration as the master reader. A Copybook changes the task from asking around to identify every copied layout to changing one declaration and rebuilding a known set of programs.

**When not to use it and what can go wrong.** Two costly misunderstandings matter:

- **Treating it as runtime sharing.** `COPY` inserts text at compile time. Each consumer has its own compiled copy. If only one consumer is rebuilt, another continues with the old layout. Exercise 1 demonstrates this case.
- **Putting procedure logic in a Copybook.** A Copybook contains declarations—records, fields, and interface parameters. Reusable processing belongs in `CALL` (Lesson 24), not in a Copybook.

Copybook versioning, change review, notifying all consumers, and running old and new layouts side by side are production release controls, outside this lesson’s mechanism-focused scope.

## What This Concept Is and the Problem It Solves

**What it is.** Put a data declaration in a separate file, conventionally a **Copybook** with the `.CPY` suffix. Each program writes `COPY "ACCOUNT-REC.CPY".`. The compiler finds the file, inserts its contents **verbatim at that location**, and continues compiling. In short: **write one layout once and use it in multiple programs**.

**Why use it.** Without a Copybook, every program has its own declaration and nothing ties the copies together. A width error is valid syntax; updates depend on memory; and a wrong fixed-record offset may silently corrupt reported amounts while the program exits with `0`.

**The business problem.** When a host-interface width changes, the overnight-batch maintainer must update every consumer in **one release**. The account number available to reconciliation staff depends on the program and file agreeing. A report’s balance is correct only when its declaration matches the master reader’s. Copybooks turn “Who copied this layout?” into “Which programs must be rebuilt after changing this file?” Rebuilding remains necessary, but the affected set can be found.

**Misunderstandings and risk.** `COPY` inserts text during compilation. Each consumer has its own compiled copy, so rebuilding only one leaves another executable with the old layout. Copybooks hold declarations—records, fields, interface parameters—not procedure logic; reusable logic belongs in `CALL` ([Lesson 24](../24_call-subprograms/README.md)). Versioning, change review, consumer notification, and parallel old/new layouts belong in a production release process.

## Capabilities and Limits After This Lesson

After completing this lesson, you can:

- Put account and transaction declarations in `copybooks/ACCOUNT-REC.CPY` and `copybooks/TRANSACTION-REC.CPY`, then include them from `WORKING-STORAGE SECTION` with `COPY "NAME.CPY".`.
- Set the search path with `cobc -I copybooks` and explain missing-file and cascading undefined-field errors.
- Compile and run `lesson.cob` and `account_report_23.cob` as separate programs using the same physical `.CPY` file.
- Measure account and transaction records as 27 and 20 bytes and compare them with Lessons 17, 20, and 22.
- Identify consumers that must be rebuilt after changing a width, recognize the warning, and explain the external fixed-length mismatch.

Scope: no business files are read or written; both programs use source constants. Subprogram calls (Lessons 24–25), error classification (Lesson 26), logs (Lesson 27), and a build script (Lesson 28) are outside this lesson. Copybook version management, dependency tracking, and production change procedures are also out of scope.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (**do not** add `-std=cobol85`); fixed-format source.
- Linux terminal; no database or extra tools required.
- Compile with `-I copybooks` **from this lesson directory**. The path is relative to the working directory; from the repository root it will not find the declarations.
- Executables go in Git-ignored `build/`.

## What the Two Copybooks Share

### Field Widths Are Byte Contracts

The Lesson 17 account record is 27 bytes: account number 10, customer ID 8, balance 9. The [Lesson 22](../22_file-processing-practice/README.md) transaction is 20 bytes: account 10, type 1, amount 9. See [Lesson 17](../17_fixed-length-files/README.md) for the 27-byte master interface. These are **byte contracts**. Every field’s starting offset must match on both sides of an exchange. A Copybook turns the contract from a declaration in one program into a file included by multiple programs.

### `COPY` Inserts Text at Compile Time

When the compiler sees `COPY "ACCOUNT-REC.CPY".`, it inserts the file’s text at that location. The declaration is needed at compile time through an `-I` directory, not when the program runs. Its contents must be valid data declarations at the inclusion point, here `WORKING-STORAGE SECTION`. It is not `CALL`: there is no program unit, argument passing, or runtime cost. `COPY` changes **what is compiled**; `CALL` changes **where runtime control goes**.

### Why Not Keep Separate Declarations?

Exercise 1 narrows the account number from `PIC X(10)` to `PIC X(8)` and rebuilds both consumers. At most, the compiler emits a warning. `-Wtruncate` appears only with a warning option (`-Wall` or `-Wtruncate`). Without `-W`, `cobc -x` and `cobc -fsyntax-only` are silent. The record width changes, but both programs’ counts and balance stay the same.

## Inputs and Rules

**Data source:** neither program reads an external file or command-line argument. `1000-INITIALIZE-RECORDS` initializes the shared account as `A000000001`, customer `C0001001`, balance `1000.00`; five paragraphs then set transactions in fixed order.

| Order | Paragraph | Type | Amount | Result | Reason |
|---:|---|---|---:|---|---|
| 1 | `1100-POST-DEPOSIT` | `D` | 125.50 | Posted | Adds to balance |
| 2 | `1200-POST-WITHDRAWAL` | `C` | 25.25 | Posted | Balance 1125.50; amount is within it |
| 3 | `1300-POST-OVERDRAFT` | `C` | 2000.00 | `INSUFFICIENT` | 2000.00 > 1100.25 |
| 4 | `1400-POST-UNKNOWN-TYPE` | `X` | 1.00 | `BAD_TYPE` | Only `D` and `C` are valid branches |
| 5 | `1500-POST-MISSING-ACCOUNT` | `D` | 1.00 | `NO_ACCOUNT` | `A000000099` differs from `A000000001` |

| Copybook | Field | PIC | Bytes |
|---|---|---|---:|
| `ACCOUNT-REC.CPY` | `WS-ACCOUNT-NUMBER` | `X(10)` | 10 |
| | `WS-CUSTOMER-ID` | `X(8)` | 8 |
| | `WS-ACCOUNT-BALANCE` | `9(7)V99` | 9 |
| `TRANSACTION-REC.CPY` | `WS-TRANSACTION-ACCOUNT` | `X(10)` | 10 |
| | `WS-TRANSACTION-TYPE` | `X` | 1 |
| | `WS-TRANSACTION-AMOUNT` | `9(7)V99` | 9 |

`V` uses no byte; `9(7)V99` is nine digits. Thus the records are `10 + 8 + 9 = 27` and `10 + 1 + 9 = 20` bytes. These match Lesson 17’s 27-character master and Lesson 22’s 20-character transaction row.

**Checked rules and assumptions:** the program checks account equality, type `D`/`C`, and withdrawal against balance. It does not check account/customer widths or numeric format; upstream data must guarantee them. Rejection precedence is contractual: `2000-POST-TRANSACTION` checks account **first**, so an account mismatch returns `NO_ACCOUNT` even if the type is invalid. Rejected paths do not change the shared balance.

## A Source-Reading Path

1. The two `COPY` statements in `WORKING-STORAGE SECTION` supply all data declarations. `ACCOUNT-REC.CPY` expands to `01 WS-ACCOUNT-RECORD` and three `05` items.
2. `1000-INITIALIZE-RECORDS` initializes the account record and copies its account number to the transaction record. Five paragraphs overwrite **the same** transaction area and perform `2000-POST-TRANSACTION`; it is one reused storage area, not five independent records.
3. `2000-POST-TRANSACTION` → `2100-VALIDATE-AND-POST` → `2200-CHECK-WITHDRAWAL` is the decision path. Account, type, and balance must pass before `POSTED`.
4. `WS-POST-STATUS` is `X(12)`. Short alphanumeric comparisons are space-padded; `FUNCTION TRIM(... TRAILING)` is needed only for display.
5. `WS-EDITED-AMOUNT` and `WS-EDITED-BALANCE` are display fields. The decimal point in `9(7).99` is not part of storage. The report’s `WS-REPORT-BALANCE` is display-only too.
6. `account_report_23.cob` is the second consumer of the same physical `ACCOUNT-REC.CPY`.

## Run and Observe

**Input:** none; values are source constants. Compile from this lesson directory:

```sh
mkdir -p build
cobc -fsyntax-only -I copybooks lesson.cob
cobc -fsyntax-only -I copybooks account_report_23.cob
cobc -x -Wall -I copybooks -o build/lesson_23 lesson.cob
cobc -x -Wall -I copybooks -o build/account_report_23 account_report_23.cob
./build/lesson_23
echo $?
./build/account_report_23
rm -rf build
```

`-fsyntax-only` does not create an executable. Expected compiler and process exit codes are `0` without diagnostics. The first program prints seven lines; the report prints one.

| Observation | Expected value |
|---|---|
| Both `cobc -fsyntax-only` commands | exit code `0`, no diagnostics |
| Both `cobc -x -Wall` commands | exit code `0`, no diagnostics |
| `./build/lesson_23` standard output | 7 lines, shown below |
| `./build/account_report_23` standard output | 1 line, shown below |
| Both process exit codes | `0` |
| Files created | only `build/lesson_23` and `build/account_report_23` |

```text
入账成功 类型=D 金额=0000125.50
入账成功 类型=C 金额=0000025.25
入账拒绝 原因=INSUFFICIENT
入账拒绝 原因=BAD_TYPE
入账拒绝 原因=NO_ACCOUNT
账户号码=A000000001 客户号码=C0001001 余额=0001100.25
成功笔数=002 拒绝笔数=003
```

```text
口座レポート 口座番号=A000000009 顧客番号=C0001009 残高=0000020.00
```

Check the arithmetic: `1000.00 + 125.50 = 1125.50`, then `1125.50 − 25.25 = 1100.25`. The third transaction is insufficient; type `X` gives `BAD_TYPE`; the unknown account gives `NO_ACCOUNT`. Two post and three reject, totaling five. Runtime output intentionally mixes Chinese and Japanese labels, following repository convention.

This workspace also prints `Warning: program compiled against libxml 212 using older 209` to standard error. It is a linked-library warning, not business output. Without `-I copybooks`, the compiler first reports missing `.CPY` files, then undefined fields. The observed missing-file text is Japanese: `そのようなファイルやディレクトリはありません` (“No such file or directory”).

## Fixed Format and Byte Checks

The source is fixed format: column 7 is the indicator, column 8 begins Area A, and column 12 begins Area B. Level `05` items start at column 11.

| Position convention | Measured in this lesson |
|---|---|
| Column 7 indicator | `lesson.cob` lines 1, 2, 3, 8, 9, 12, 16, 17, and 56 carry `*` |
| Area A, column 8 | `IDENTIFICATION DIVISION.`, `PROGRAM-ID.`, `WORKING-STORAGE SECTION.`, paragraph names, and level `01` start in column 8 |
| Repository convention: level `05` in column 11 | `05` items in both `.CPY` files start in column 11; `01` groups start in column 8 |
| Area B from column 12 | `MOVE`, `PERFORM`, `IF`, and `DISPLAY` start in column 12; nesting moves to 16, 20, 24 |
| Program text within column 72 | Longest lines: `lesson.cob` 65 bytes, `account_report_23.cob` 71 bytes, the two `.CPY` files 44/47 bytes | Longest program-text lines measured 65 bytes in `lesson.cob`, 71 in `account_report_23.cob`, and 44/47 in the Copybooks.

GnuCOBOL 3.2.0 truncates long source lines by **byte** near column 72. A measured 42-character, 82-byte `DISPLAY` line produced `continuation character expected` and `invalid literal`; cutting inside a multibyte Chinese character corrupts the literal. A `*` comment in column 7 is ignored even at 110 bytes. Use the default dialect, not `-std=cobol85`; this lesson uses COBOL 2002 `FUNCTION TRIM`.

Changing a width requires rebuilding both consumers, checking the [Lesson 17](../17_fixed-length-files/README.md) fixed-length contract, and separately synchronizing the physically independent Copybook copies in [Lesson 28](../28_modular-batch-project/README.md). The 27-byte account and 20-byte transaction interfaces in Lessons 17, 20, and 22 can become misaligned.

## Modification Exercises

Make changes on working copies, not repository originals. Commands and expected differences are in [`exercise.md`](./exercise.md); reference answers are in [`answer.md`](./answer.md).

1. Starting from the original sources, change `WS-ACCOUNT-NUMBER` in `copybooks/ACCOUNT-REC.CPY` from `PIC X(10)` to `PIC X(8)`. Recompile both consumers and run them. Record compiler output, differences in the seven output lines, the balance, and both counts. Use alphanumeric comparison rules to explain the results, and state the new record width and the effect on the 27-byte contract.
2. From a fresh copy, change the account in `1500-POST-MISSING-ACCOUNT` from `A000000099` to `A000000001`. Check the fifth transaction, the balance, and both counts. Explain which consumers need recompiling and which can keep their executable.

## Extension Exercise

Write a third consumer for a monthly statement using the same Copybook. Change the balance to a signed PIC and measure the record width. Choose a display field for negative values, explain why `PIC 9(7).99` is insufficient, and change a posting rule to produce a debit balance. Submit complete compile commands and output for both programs, and state whether the 27-byte contract remains valid. Full prompt: [`exercise.md`](./exercise.md). Reference answers are in [`answer.md`](./answer.md).

## Follow the Real Workflow

1. **Upstream:** the core system exports a 27-byte account master according to its interface document; Lesson 17 reads and writes it. This Copybook expresses that contract in source.
2. **This lesson:** `lesson.cob` uses it for posting rules and `account_report_23.cob` for reporting. They share the **declaration**, not data; each executable is compiled independently.
3. **Next:** [Lesson 24](../24_call-subprograms/README.md) passes records through `LINKAGE`; [Lesson 25](../25_using-parameters/README.md) also shares parameter declarations. See [Lesson 24](../24_call-subprograms/README.md) for `CALL` details.
4. **Engineering:** [Lesson 28](../28_modular-batch-project/README.md) automates builds; [Lesson 32](../32_bank-reconciliation-project/README.md) checks versions and contents.
5. **When width changes:** update the Copybook, find all consumers, rebuild them, renegotiate external file widths, and synchronize independent copies. Missing a step can yield wrong data without an error.

## What Happens If This Code Goes into Production

These are manual teaching programs without batch arguments, logs, or a build script. In production, a scheduler checks exit codes and artifacts. Batch staff check posted/rejected counts, interface owners check account width, and reconciliation staff verify details. A common incident is rebuilding only one consumer, leaving another on old offsets; neither reports an error.

The Copybook becomes an external interface for later subprograms, parameter definitions, and build projects. Width and field order need versioned agreement. This lesson does not implement Copybook versions, old/new layout support, change review, a consumer inventory, or upstream format checks. Related mechanisms appear in Lessons 24–28 and 32.

## Verified Scope and Limitations

Both syntax checks and builds in this workspace exited `0` without diagnostics. `FUNCTION LENGTH` measured account and transaction groups as 27 and 20 bytes; narrowing the account number made the account group 25 bytes. With `-Wall`, both consumers report `-Wtruncate`; without warning flags the change is silent. `lesson_23` truncates the account number but leaves balance and counts unchanged.

The behavior of [Lessons 17](../17_fixed-length-files/README.md), [20](../20_file-matching/README.md), and [22](../22_file-processing-practice/README.md) with a 25-byte account record, and behavior on other platforms or compiler versions, have not been verified. Root `make course-check` checks syntax but not runtime behavior.

## References

- [GnuCOBOL Programmer’s Guide: Copybooks](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Copybooks)
- [GnuCOBOL Programmer’s Guide: COPY and replacement rules](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#COPY)
- [GnuCOBOL Manual: `-I` Copybook search path](https://gnucobol.sourceforge.io/doc/gnucobol.html)
- [GnuCOBOL Programmer’s Guide: `FUNCTION`](https://superbol.eu/gnucobpg/chapter8.html)
- Course index: [`DIRECTORY.md`](../DIRECTORY.md)
