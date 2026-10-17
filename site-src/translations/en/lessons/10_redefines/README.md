---
_translated_from: lessons/10_redefines/README.md
_translated_by: site-src/translation agent
---

# Lesson 10 — REDEFINES: Two Ways to Read the Same 27 Bytes for Deposits and Transfers

For the exact same 27 bytes, if the transaction code is `D`, read it as "account number + amount + reference number"; if it is `T`, read it as "source account + target account + amount". This lesson packs both interpretations into the exact same storage sharing the exact same offset, and then reads it again using the **wrong interpretation** — you will see that even when read incorrectly, the program terminates normally as usual, with an exit code of `0`.

## The Business Setting

At 7:50 a.m., just as you sit down, a colleague from the clearing team calls across the cubicles: yesterday's batch of transfer messages has arrived, 124,000 records, and total amounts must be summarized before counters open at 9:00 a.m.

The interface documentation for that message has only a single line describing format: **1-byte type code + 27-byte fixed-length payload**. Type code `D`: read the following 27 bytes as "account number + amount + reference"; type code `T`: read those exact same 27 bytes as "source account + target account + amount". The document ends there, saying nothing further — especially silent on "what happens if read incorrectly."

In your toolkit you have only what the previous lesson gave you: one record, one interpretation. If you were to declare two `05` payloads in parallel, each would occupy 27 bytes, inflating the whole record from 28 bytes to 55 bytes, misaligning with the message from byte 2 onward, producing completely garbled reads. And the most insidious aspect of misalignment is that it never screams: the type code is clearly `T`, but the program reads with the deposit view, obtaining a string of shifted bytes, **yet the program still terminates normally, exiting with code `0`**, leaving clean logs. The error hides where nobody looks, usually discovered only when a customer calls asking about their balance.

What this lesson teaches is making two views map cleanly onto the **exact same storage**, while remembering: deciding which view to pick and validating content are not `REDEFINES`'s job.

(The institutions, amounts, and batch dates above are educational demonstrations created to explain the problem and do not correspond to real data from any actual institution.)

## What This Knowledge Point Is, and What Problem It Solves

**What this knowledge point is.** A single chunk of memory, allowing you to attach two sets of field names and layouts without either yielding space to the other. In COBOL, this is written by adding `REDEFINES` after the second declaration:

```cobol
          05 WS-DEPOSIT-PAYLOAD.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             ...
          05 WS-TRANSFER-PAYLOAD REDEFINES WS-DEPOSIT-PAYLOAD.
             10 WS-SOURCE-ACCOUNT PIC X(10).
             ...
```

In plain terms: **the storage area for `WS-TRANSFER-PAYLOAD` is the exact same space as before**. There is only one allocation of storage, and the two group names are merely two access points; whichever field name you use to read, that is the interpretation you get.

**What business problem it solves.** Upstream packs different business types into the same fixed-length message (one of the most common and accident-prone designs in interface specifications), requiring the receiver to handle "one sequence of bytes, multiple interpretations." With it, you can: align record width byte-for-byte with upstream documentation; avoid declaring duplicate field sets that double record sizes; produce one-page offset tables where expected values can be calculated by hand during testing.

**When not to use it.** Steer clear in three situations:

- When both sets of data must **coexist simultaneously** (e.g., preserving both old and new values), let each occupy its own bytes rather than redefining — redefining is "overwriting", where writing to the second view overwrites bytes of the first view.
- When hoping to perform **format conversion** (such as turning digits into display format), do not count on it: it does not touch a single byte or convert a single character.
- When needing to **determine which view should be used**, that is the job of `IF`/`EVALUATE` (Lessons [04](../04_if-conditions/README.md)/[05](../05_evaluate/README.md)). `REDEFINES` only declares layouts; it neither selects views nor validates content.

## Why Learn This Now

You might think: wasn't the hierarchical record tree in the previous lesson good enough; why is it insufficient again?

It is good enough, but only for a single interpretation. In Lesson [09](../09_group-items/README.md) you learned to organize customer, account, and transaction fields into a record, but that record's meaning from byte 2 to the end was cast in stone. Now the same physical message must change layouts based on transaction type: the payload for `D` is the deposit trio, and the payload for `T` is the transfer trio.

Can we declare two `05` groups in parallel? It does not fit — each would take 27 bytes, inflating the record to 55 bytes and breaking message length alignment; worse yet, **not a single line of code expresses that 'these two groups are actually at the same position'**. A maintainer reading the second group would assume it is a fresh, separate space.

`REDEFINES` supplies that missing declaration, along with hard constraints on length and declaration position. Subsequent lessons all build on this prerequisite: Lesson [11](../11_occurs-tables/README.md) uses `OCCURS` to repeat "transaction code + amount" items into tables, Lesson [14](../14_data-structures-practice/README.md) places this 27-byte payload into in-memory account matching, Lesson [17](../17_fixed-length-files/README.md) writes it into real fixed-length files, and Lesson [23](../23_copybooks/README.md) shares the layout across programs via Copybooks — all starting from "one sequence of bytes, multiple interpretations."

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you will be able to:

- Declare two level-`05` views for a payload area within an `01` record, explaining that they start at the same offset without taking extra storage.
- Reconcile offsets and lengths of a 28-byte record using this lesson's byte layout table, explaining why `9(5)V99` stores 7 bytes but displays 8 characters.
- Predict which lines change and which remain unchanged in the 12-line output after writing via the second view, calculating new values from byte positions.
- Reproduce two boundary conditions: making the redefining item longer triggers compile failure; placing alphabetic characters into bytes covered by `9(5)V99` triggers no error.
- Explain that `REDEFINES` does not copy, convert, or validate — correspondence between transaction codes and payload content can only be guaranteed by interface contracts.

Limits: This lesson reads no terminal, file, or database inputs; sample values are in-program constants; the program does not branch by transaction code, merely printing both views once. `OCCURS` tables appear in Lesson [11](../11_occurs-tables/README.md), reading real fixed-length messages appears in Lesson [17](../17_fixed-length-files/README.md), shared layouts appear in Lesson [23](../23_copybooks/README.md), while payload validation and rejection policies require real inputs starting in Lesson [15](../15_sequential-file-read/README.md) and systematic error handling in Lesson [26](../26_error-handling/README.md).

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (without `-std=cobol85`), source file in fixed format: column 7 indicator, Area A starting in column 8, Area B starting in column 12, program text not exceeding column 72.
- Linux terminal, requiring no database, extra tools, or third-party libraries.
- Commands are executed under this lesson's directory `lessons/10_redefines/`; because the source argument is specified as `lesson.cob`, adjust paths if running from another directory.

## One Sequence of Bytes, Two Layouts

In `lesson.cob` there is only a single `01` record: byte 1 is the transaction code (**not** in the redefined area), and bytes 2–28 form the 27-byte payload area. The deposit (`D`) payload is "account number, amount, reference", and the transfer (`T`) payload is "source account, target account, amount"; both views start at byte 1 of the payload area and both occupy 27 bytes, aligning them over the exact same physical storage.

`REDEFINES` allows the redefining item (object) to occupy the same physical storage as the redefined item (subject). It is not a second copy of storage, nor a conversion: **it is the exact same bytes, depending on which field name you use to read them**. Writing through the second view simply overwrites that old space using the new field names.

The distinction from Lesson [09](../09_group-items/README.md) also lies here. That lesson covered hierarchy itself (group items, elementary items, disambiguating identical names with `OF`); this lesson covers **two interpretations at the exact same hierarchical position** — field names between the two views share no `OF` prefix relation, and reading the same bytes produces two sets of completely different, yet "valid", values.

## Hard Constraints on REDEFINES

GnuCOBOL Programmer's Guide 6.9.37 lists several rules, all satisfied in this lesson. Level numbers and contiguous positioning are enforced by the compiler, while equal length, `OCCURS`, and `VALUE` must be watched by you — in verification tests, the toolchain enforced length in only one direction, which is precisely why it causes incidents:

- Level numbers of subject and object must be identical (both `05` here), and cannot be levels 66, 78, or 88.
- The object must immediately follow the subject: no other data items of the same level may intervene (unless they are also `REDEFINES` of that subject), nor may items of lower level numbers intervene. Moving `REDEFINES` after another data item produces diagnostic `error: REDEFINES 句は参照元の項目の直後になければなりません` on this machine, returning code `1`.
- The **total allocated byte count of both must be identical**. Do not assume "the compiler will stop me" on this point. In tests on this machine's GnuCOBOL 3.2.0, errors occurred only when **the object was larger**: changing `WS-TARGET-ACCOUNT` to `X(11)` (28 bytes > 27 bytes) caused `cobc -fsyntax-only` to return code `1` with diagnostic `error: larger REDEFINES used`; but changing to `X(9)` (26 bytes) compiled cleanly (return code `0`), with leftover bytes at the end of the subject falling outside the second view's declaration. Thus "equal length" is a rule **you must guarantee yourself**; passing compilation does not equal compliance.
- Neither subject nor object itself may contain `OCCURS`; when both are group items, subordinate items within them may contain `OCCURS`.
- Neither the object nor its subordinates may specify `VALUE` (except for level-88 condition names). Testing `VALUE "X"` on `WS-TRANSFER-PAYLOAD` on this machine was not rejected at compile time (return code `0`), but initializing the same shared bytes via two views is semantically ambiguous — so this lesson keeps initial payload values cleanly in the procedure division, writing them explicitly via `MOVE`.

## Views Do Not Automatically Validate

`REDEFINES` only declares layouts; it does not do three things: it does not copy (the second write overwrites the first 27 bytes directly), it does not convert (`9(5)V99` will not turn letters from an `X` view into digits), and it does not validate (nobody checks whether the transaction code matches either view).

The last 4 lines of output in this lesson intentionally break the contract: transfer bytes are read as a deposit, yet the program finishes normally, still exiting with code `0`. **Who, then, selects the view?** The business type code, which is to say the upstream interface contract. You can inspect `lesson.cob` yourself — the program merely prints the transaction code as-is, never evaluating it for decisions.

## Inputs and Rules

**Input:** No external input. Sample values are literals moved in `lesson.cob`'s procedure division; reading no keyboard, file, or database, every run produces identical results.

**Byte layout (verified using `FUNCTION LENGTH` on this machine):** Record 28 bytes = transaction code 1 byte + payload 27 bytes; both `WS-DEPOSIT-PAYLOAD` and `WS-TRANSFER-PAYLOAD` are 27 bytes. Positions count from byte 1 of payload (or record):

| View | Elementary Item | PIC / Bytes | Position in Payload | Position in Record |
|---|---|---|---:|---:|
| Deposit `D` | `WS-ACCOUNT-NUMBER` | `X(10)` / 10 | 1–10 | 2–11 |
| Deposit `D` | `WS-DEPOSIT-AMOUNT` | `9(5)V99` / 7 | 11–17 | 12–18 |
| Deposit `D` | `WS-REFERENCE` | `X(10)` / 10 | 18–27 | 19–28 |
| Transfer `T` | `WS-SOURCE-ACCOUNT` | `X(10)` / 10 | 1–10 | 2–11 |
| Transfer `T` | `WS-TARGET-ACCOUNT` | `X(10)` / 10 | 11–20 | 12–21 |
| Transfer `T` | `WS-TRANSFER-AMOUNT` | `9(5)V99` / 7 | 21–27 | 22–28 |

`PIC 9(5)V99` stores 7 numeric digits; `V` is an assumed decimal point and **occupies no storage**, rendered positionally only when `DISPLAY`ed, showing as 8 characters `00125.50`. Amounts in this lesson are demo accounting units with two decimal places, lacking currency fields; the program performs only `MOVE` and `DISPLAY` without arithmetic, so rounding and overflow are not involved.

**Rules, prerequisites, and validation responsibility:**

| Rule / Prerequisite | Guaranteed By | Validated in This Lesson |
|---|---|---|
| Both views have identical total length (27 bytes) | Manual rule; this toolchain errors only when object is larger | Partial — larger fails compilation, shorter passes silently |
| Object immediately follows subject and shares level `05` | Compiler | Yes, violation fails compilation |
| Correspondence between transaction code and payload layout (`D`=deposit, `T`=transfer) | Upstream interface contract | **No**, program only echoes transaction code |
| Payload byte content conforms to field types of selected view | Upstream interface contract | **No** — placing letters into bytes covered by `9(5)V99` triggers no error |
| Overwriting deposit payload with transfer payload leaves it invalid as a deposit record | Consumer interpretation discipline | **No**, program performs no evaluation |

Demo data note: account numbers, amounts, and reference strings are educational demo values and do not represent any real business policy.

## Complete Example Source

For complete source, see [`lesson.cob`](./lesson.cob), written in fixed format.

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. REDEF10.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-RECORD.
          05 WS-TRANSACTION-CODE PIC X.
          05 WS-DEPOSIT-PAYLOAD.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-DEPOSIT-AMOUNT PIC 9(5)V99.
             10 WS-REFERENCE PIC X(10).
          05 WS-TRANSFER-PAYLOAD REDEFINES WS-DEPOSIT-PAYLOAD.
             10 WS-SOURCE-ACCOUNT PIC X(10).
             10 WS-TARGET-ACCOUNT PIC X(10).
             10 WS-TRANSFER-AMOUNT PIC 9(5)V99.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-LOAD-DEPOSIT
           PERFORM 2000-LOAD-TRANSFER
           STOP RUN.
       1000-LOAD-DEPOSIT.
           MOVE "D" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER
           MOVE 125.50 TO WS-DEPOSIT-AMOUNT
           MOVE "TXN-000001" TO WS-REFERENCE
           DISPLAY "取引種別=" WS-TRANSACTION-CODE
           DISPLAY "入金口座=" WS-ACCOUNT-NUMBER
           DISPLAY "入金額=" WS-DEPOSIT-AMOUNT
           DISPLAY "入金参照番号=" WS-REFERENCE.
       2000-LOAD-TRANSFER.
           MOVE "T" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-SOURCE-ACCOUNT
           MOVE "0007654321" TO WS-TARGET-ACCOUNT
           MOVE 250.75 TO WS-TRANSFER-AMOUNT
           DISPLAY "取引種別=" WS-TRANSACTION-CODE
           DISPLAY "振込元口座=" WS-SOURCE-ACCOUNT
           DISPLAY "振込先口座=" WS-TARGET-ACCOUNT
           DISPLAY "振込金額=" WS-TRANSFER-AMOUNT
           DISPLAY "同じバイト列の入金ビュー:"
           DISPLAY "口座=" WS-ACCOUNT-NUMBER
           DISPLAY "金額=" WS-DEPOSIT-AMOUNT
           DISPLAY "参照番号=" WS-REFERENCE.
```

The above omits comment lines from the source. Comments describe only rules and contracts (sample values fixed in-program, transaction code guaranteed by interface contract while `REDEFINES` neither validates nor selects views, redefining item must follow immediately and not be larger, final 4 `DISPLAY` statements intentionally misread) without restating the text of each `DISPLAY`.

## Source Reading Path

Tracing along "when data changes and who reads it", five steps suffice:

1. `01 WS-TRANSACTION-RECORD` (28 bytes): byte 1 is the transaction code, and byte 2 onward begins the payload area. Both views start at byte 1 of the payload area, so subsequent updates to transaction code never touch payload bytes.
2. `05 WS-DEPOSIT-PAYLOAD` and immediately following `05 WS-TRANSFER-PAYLOAD REDEFINES ...`: both level `05`, declared contiguously, both 27 bytes. These two lines provide written proof of "same length, same level, immediately contiguous."
3. `1000-LOAD-DEPOSIT`: writes 4 values according to the deposit view and prints them. At this point the transfer view field names already point to the same bytes, though nobody has read them yet.
4. `2000-LOAD-TRANSFER`: updates the transaction code first (an independent byte), then writes payload fields via the transfer view — which **overwrites the original 27 bytes byte by byte**; the payload storage area remains singular throughout.
5. Final 4 `DISPLAY` statements: the transaction code remains `T`, yet the same bytes are read using the deposit view. How the strange values `00076.54` and `3210025075` arise is calculated by hand in the next section.

## Run and Observe

**Commands and roles:**

```sh
mkdir -p build                                   # 先建输出目录，否则 -o 会因目录不存在而失败
cobc -fsyntax-only lesson.cob                    # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_10 lesson.cob      # 编译并生成可执行文件
./build/lesson_10                                # 运行，两个视图的输出写到标准输出
echo $?                                          # 查看上一条命令的退出码
rm -rf build                                     # 清理编译产物
```

`-fsyntax-only` proves only that source passes syntax parsing; `-x`/`-o` generates the executable, where return code `0` without diagnostics indicates successful compilation; executing the binary reveals both views' interpretations of the same bytes; `rm -rf build` removes only compilation artifacts, with no business data files generated.

**Expected results (original initial values):**

| Observed Item | Expected Value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x -Wall` exit code | `0`, no compilation diagnostics |
| Standard output | 12 lines below |
| Process exit code (`echo $?`) | `0` |
| Generated files | `build/lesson_10` only |

```text
取引種別=D
入金口座=0001234567
入金額=00125.50
入金参照番号=TXN-000001
取引種別=T
振込元口座=0001234567
振込先口座=0007654321
振込金額=00250.75
同じバイト列の入金ビュー:
口座=0001234567
金額=00076.54
参照番号=3210025075
```

Translations: `取引種別` = transaction code, `入金口座` = deposit account number, `入金額` = deposit amount, `入金参照番号` = deposit reference number, `振込元口座` = transfer source account, `振込先口座` = transfer target account, `振込金額` = transfer amount, `同じバイト列の入金ビュー:` = "deposit view of the same byte sequence:", `口座` = account number, `金額` = amount, `参照番号` = reference number (business outputs follow the repository's Japanese convention; assessing program behavior relies on actual outputs and calculations in this section).

The final 3 lines are determined by byte positions and can be calculated on paper: target account `0007654321` occupies payload bytes 11–20; the deposit view's amount reads bytes 11–17 yielding `0007654` → displayed as `00076.54`; reference reads bytes 18–27, which spans the last three digits of the target account `321` concatenated with the transfer amount's 7 digits `0025075` → `3210025075`. This is not a valid deposit record; it is merely another way to read the exact same bytes.

**Observed environment details:** When running `./build/lesson_10` in this workspace, standard error outputs `Warning: program compiled against libxml 212 using older 209`. This is a library version warning from the runtime environment, not business output, and the triggering component has not been located. Business output appears on standard output, with an exit code of `0`.

### Evidence Sources and Verification Scope

All executable conclusions in this lesson were verified directly using GnuCOBOL 3.2.0 in this workspace: `-fsyntax-only` and `-x -Wall` returned `0` without compilation diagnostics, run exit codes were `0`, and standard output matched the 12 lines above byte for byte. Byte counts (28 / 27 / 27 / 10 / 7 / 10 / 10 / 10 / 7) and starting offsets of both views were measured with a separate `FUNCTION LENGTH` program. Four boundaries were verified individually: altering object to `X(11)` (longer) returned compile code `1` with diagnostic `larger REDEFINES used`; altering to `X(9)` (shorter) returned code `0`; moving `REDEFINES` after another data item returned compile code `1`; changing transaction code to `X` caused only the `取引種別=` line out of the 12 to change, with remaining lines matching byte for byte. Furthermore, changing `WS-TARGET-ACCOUNT` to `ABC7654321` (non-numeric) still returned exit code `0`, with `金額=ABC76.54` printed verbatim — confirming that views perform no validation.

**Unverified** scenarios: file or database input, branching by transaction code to select views, and validation logic for payload content and record length — the lesson program contains none of these paths, leaving them unexecuted.

## What Happens if This Code Goes to Production

- **Who schedules it**: The overnight batch scheduler, placed after the pre-check verifying that "message file has arrived"; it looks only at exit codes, not your screen.
- **Who reads its output**: Operators look at exit codes first, then check counts and amount rollups. Here lies the most hazardous situation — exit code `0` does not mean accounts are balanced; values misread through the wrong view flow quietly into summary totals.
- **Who gets called when something breaks**: Usually not that night. More often it is when daylight reconciliation reports discrepancies or customers call asking about balances that someone traces back to find which bytes were read out of alignment.
- **How the next system connects**: This lesson's 28-byte layout is shared material for subsequent lessons — Lesson [11](../11_occurs-tables/README.md) uses `OCCURS` to repeat the 8-byte "transaction code + amount" items into a table (capacity, loaded count, iteration upper bounds), Lesson [14](../14_data-structures-practice/README.md) performs in-memory account matching using the same "transaction code + 27-byte payload", Lesson [17](../17_fixed-length-files/README.md) writes it into real fixed-length files (width, offsets, and line breaks frozen together), Lesson [23](../23_copybooks/README.md) shares this layout across matching programs via Copybooks, and the integrated batch in Lesson 32 handles version and content validation.
- **Most common first-month incidents**: Type code mismatching the view without being intercepted. The program reads misaligned bytes, finishes cleanly, and exits quietly until accounts fail to balance.
- **What it hasn't done yet**: In real systems, such records typically carry version numbers, record lengths, checksums, and legal domains for transaction codes; receivers must first select layouts based on length and type code, then validate field formats, rejecting failures rather than interpreting them blindly. `REDEFINES` is responsible solely for "multiple views over the same bytes", providing none of those safeguards.

## Walking Through a Real Workflow

Placing this lesson into that "7:50 a.m. batch of 124,000 records", the processing chain looks like this:

1. **Upstream clearing system** outputs fixed-length messages per interface documentation: `1-byte type code + 27-byte payload`; all consumers of that document write code to that width.
2. **Your receiving program** takes a sequence of bytes, declares two views (what this lesson did), and decides which view to read based on transaction code — **this step is not yet written here**: you must first learn to read records from files (Lesson [15](../15_sequential-file-read/README.md)), then branch by transaction code to select views (Lesson [05](../05_evaluate/README.md)), requiring both before it can be built.
3. **Validation stage** checks whether each field matches the types of the chosen view (alphabetic characters in `9(5)V99` must be rejected), sending failed records to a rejection file (Lesson [16](../16_file-writing/README.md)) and logging them (Lesson [27](../27_logging/README.md)).
4. **Summary and handover**: Amounts post to the account master to update balances, and variance reports are handed to reconciliation staff; the integrated batch in Lesson [32](../32_bank-reconciliation-project/README.md) wraps version, length, and content validation together.

This lesson sits at the very beginning of step 2 — **enabling the same bytes to be read correctly as two distinct structures**. Without `REDEFINES`, the subsequent three steps are castles in the air.

## Exercises and References

### Modification Exercise (with answer)

Starting from this lesson's original [`lesson.cob`](./lesson.cob), change the `MOVE` value of the transfer amount in `2000-LOAD-TRANSFER` from `250.75` to `99.99`, changing only this single location. In the expected 12-line output, **only two lines change**: `振込金額=00250.75` → `00099.99`, and `参照番号=3210025075` → `3210009999`; `金額=00076.54` remains unchanged because it is determined solely by the first seven digits of the target account. For complete requirements (baseline, modification constraints, commands, line-by-line expected diffs, and questions to answer), see [`exercise.md`](./exercise.md); for reference answers, see [`answer.md`](./answer.md).

### "Apply It Elsewhere" Exercise (no answer)

Design two level-`05` views sharing the same payload for "cash withdrawal" and "inter-account transfer": write `PIC` definitions and total byte counts for each elementary item first, confirm both views have equal length, then set transaction codes, write sample values via the selected view, and print them; finally, read them once using the other view, explaining why that output cannot serve as a valid original transaction. Record commands, output, and exit codes yourself. See [`exercise.md`](./exercise.md) for details; no reference answer is provided for this exercise.

## References

- [GnuCOBOL Programmer's Guide: REDEFINES (6.9.37)](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#REDEFINES)
- [GnuCOBOL Programmer's Guide: Data Definition Principles (6.1)](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Data-Definition-Principles)
- [Complete Course Directory](../DIRECTORY.md)
- [Repository Course Home](../../README.md)
