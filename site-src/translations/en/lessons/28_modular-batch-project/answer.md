---
_translated_from: lessons/28_modular-batch-project/answer.md
_translated_by: site-src/translation agent
---

# Lesson 28 Modification Exercises: Reference Answer

This answer covers only the two modification exercises in `exercise.md`; it does not answer the transfer exercise. Run `./build.sh run` for both changes so the subprogram object files are recompiled and relinked with the main program. Otherwise, the source is changed but the old executable is still being run.

```sh
./build.sh check
./build.sh run
echo $?
./build.sh clean
```

## 1. Change the Overdraft Withdrawal to 1000.00

Change `1300-POST-OVERDRAFT` to:

```cobol
           MOVE 1000.00 TO WS-TRANSACTION-AMOUNT
```

The balance is `1000.00 + 125.50 − 25.25 = 1100.25`, and `1000.00 ≤ 1100.25`, so the withdrawal succeeds and the balance becomes `100.25`. The account report and counts become:

```text
口座=A000000001 CUSTOMER=C0001001 BALANCE=0000100.25
集計 記帳=003 拒否=002
```

The third transaction event in `build/batch.log` changes from `STATUS=INSUFFICIENT` to:

```text
EVENT=TRANSACTION NO=003 ACCOUNT=A000000001 TYPE=C STATUS=POSTED
```

Check the invariant: `3 + 2 = 5`. Control flow: `CALL "POST-TRANSACTION28"` occurs in `2000-CALL-POSTER`; `GOBACK` returns control to that paragraph. The posting module updates the balance and writes the status; the main program increments the `記帳` count in `2100-REPORT-RESULT`.

## 2. Change the Unknown Transaction Type to a Deposit

Restore the original source, then change `1400-POST-UNKNOWN-TYPE` to:

```cobol
           MOVE "D" TO WS-TRANSACTION-TYPE
```

The amount remains `1.00`. This deposit succeeds, changing the balance from `1100.25` to `1101.25`:

```text
口座=A000000001 CUSTOMER=C0001001 BALANCE=0001101.25
集計 記帳=003 拒否=002
```

The event retains number `004` in `build/batch.log`, and its type and status become:

```text
EVENT=TRANSACTION NO=004 ACCOUNT=A000000001 TYPE=D STATUS=POSTED
```

Check the invariant: `3 + 2 = 5`. Both exercises demonstrate the same point: when module interfaces (Copybook field order and status values) do not change, only the **business input** changes, so counts and log structure need no adjustment. Conversely, changing a Copybook field width or order requires recompiling all affected modules and rerunning the build.
