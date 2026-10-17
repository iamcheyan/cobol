---
_translated_from: lessons/12_indexed-by/answer.md
_translated_by: site-src/translation agent
---
# Lesson 12 Modification Exercises: Reference Answers

This answer covers only the two modification steps in `exercise.md`; it does not answer Apply What You Learned. Start step 1 from this lesson’s original `lesson.cob`; continue from step 1 for step 2.

## Step 1: Expand the Account Table to Five Entries

Change capacity and the number of loaded entries to 5:

```cobol
          05 WS-ACCOUNT-ENTRY OCCURS 5 TIMES
             INDEXED BY WS-ACCOUNT-IDX.
```

```cobol
       01 WS-LAST-ACCOUNT PIC 9 VALUE 5.
```

Append the fifth account after the fourth in `1000-LOAD-ACCOUNTS`. Remove the period at the end of the fourth entry and keep it only at the end of the fifth:

```cobol
           MOVE 520.00 TO WS-ACCOUNT-BALANCE(4)
           MOVE "0005550001" TO WS-ACCOUNT-NUMBER(5)
           MOVE 75.00 TO WS-ACCOUNT-BALANCE(5).
```

Loading still uses numeric subscripts, traversal still uses the index, and the loop structure remains unchanged. The standard output after recompilation and execution is:

```text
口座=0001234567 BALANCE=0001000.00
口座=0007654321 BALANCE=0000250.75
口座=0000000042 BALANCE=0000000.00
口座=0002468101 BALANCE=0000520.00
口座=0005550001 BALANCE=0000075.00
処理件数=005
```

Only the end changes: a fifth output line is added and the processed count changes from `004` to `005`. The first four lines are byte-for-byte unchanged because their load statements and subscripts were not changed. Capacity, loaded-entry count, and loop endpoint all change from 4 to 5. The index advances from 1 through 5; after entry 5, it becomes 6, making `UNTIL index > WS-LAST-ACCOUNT` true. `cobc -fsyntax-only` and `cobc -x -Wall` both return 0 without diagnostics; the program exits with code 0.

## Step 2: Out-of-Range Boundary

When only `WS-LAST-ACCOUNT` is changed to `6` (with `OCCURS` still at 5), the compiler reports no error: the loop endpoint is a runtime comparison, and `WS-ACCOUNT-IDX` is not a compile-time known out-of-range constant (unlike a hard-coded out-of-range literal subscript).

`cobc -x -Wall` returns 0 without diagnostics. The default run also exits with code 0. After the fifth line, standard output contains one more line of out-of-table data, and the processed count is `006`:

```text
口座=0001234567 BALANCE=0001000.00
口座=0007654321 BALANCE=0000250.75
口座=0000000042 BALANCE=0000000.00
口座=0002468101 BALANCE=0000520.00
口座=0005550001 BALANCE=0000075.00
口座=<out-of-table meaningless bytes> BALANCE=<out-of-table meaningless bytes>
処理件数=006
```

The sixth line (shown above with `<out-of-table meaningless bytes>`) reads memory outside the account table. It is not a valid account record. The observed output contained meaningless bytes, including NULs, which may appear blank or garbled in a terminal; it cannot be treated as a business result. This demonstrates that exit code 0 does not prove the result is correct.

With runtime subscript checking enabled, the result changes:

```sh
cobc -x -fsubscript-check=full -fec=EC-BOUND-SUBSCRIPT -o build/lesson_12_checked lesson.cob
./build/lesson_12_checked
```

Standard output stops after the fifth account. Standard error reports a libcob bounds error (the line number and file path reflect the local output):

```text
libcob: lesson.cob:36: error: subscript of 'WS-ACCOUNT-BALANCE' out of bounds: 6
note: maximum subscript for 'WS-ACCOUNT-BALANCE': 5
```

The program terminates while accessing entry 6 and exits with code 1. By default, compilation does not protect against index overruns. The key guarantee must therefore be that the loop endpoint never exceeds table capacity. To add a runtime safeguard, compile with the options above; an overrun then becomes an immediate, visible failure.
