---
_translated_from: lessons/24_call-subprograms/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 24 Exercises: Calling an Amount-Validation Subprogram

Both modifications start from the original `lesson.cob` and `amount_check_24.cob`. Restore the originals before starting the second exercise; do not layer the changes. The validation rules live in the subprogram, so compile both source files together after each change:

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob amount_check_24.cob
cobc -x -Wall -o build/lesson_24 lesson.cob amount_check_24.cob
./build/lesson_24
echo $?
rm -rf build
```

## Modification Exercises (Answers in [`answer.md`](./answer.md))

### 1. Raise the Amount Limit and Observe the Boundary Case

- **Baseline:** original `amount_check_24.cob`, with a limit of `1000.00`.
- **Change and constraints:** in `0000-VALIDATE-AMOUNT`, change only the constant in `WHEN LK-AMOUNT > 1000.00` to `1500.00`. Do not change PIC declarations, field order, the call, or any amount in the main program.
- **Correctness criteria:** `1000.01` is no longer over the limit, while `9999999.99` remains over it; the main program exits with code `0`.
- **Expected output differences:** only three output lines related to the result and counts change; the other 17 lines remain byte-for-byte identical.

  ```text
  -CALL RETURN status=LIMIT-EXCEEDED      (after case 4, amount 1000.01)
  +CALL RETURN status=VALID
  -checks=008 valid=005 rejected=003
  -zero amount rejects=001 limit rejects=002
  +checks=008 valid=006 rejected=002
  +zero amount rejects=001 limit rejects=001
  ```

- **Why:** `1000.01 ≤ 1500.00`, so the value reaches `WHEN OTHER` and returns `VALID`. Valid count rises by one and limit rejects fall by one. The zero-amount case is unchanged, so total checks and zero-amount rejects stay the same.

### 2. Remove the Zero-Amount Case

- **Baseline:** original `lesson.cob`, where `1200-CHECK-ZERO-AMOUNT` contains `MOVE ZERO TO WS-AMOUNT`.
- **Change and constraints:** change only that paragraph’s `MOVE ZERO` to `MOVE 0.01`. Do not change the subprogram, limit, the other seven amounts, or count logic.
- **Correctness criteria:** case 2 changes from rejected to valid. Its amount now matches case 5 (`1500-CHECK-SMALL-POSITIVE`), so the output contains two `amount=0000000.01` results with `VALID` status.
- **Expected output differences:**

  ```text
  -before CALL amount=0000000.00
  -after CALL status=ZERO-AMOUNT
  +before CALL amount=0000000.01
  +after CALL status=VALID
  -checks=008 valid=005 rejected=003
  -zero amount rejects=001 limit rejects=002
  +checks=008 valid=006 rejected=002
  +zero amount rejects=000 limit rejects=002
  ```

- **Why:** `0.01` is nonzero and does not exceed the limit, so it returns `VALID`. The zero-amount case has no other source, so its count becomes zero and valid count increases by one. Limit rejects remain `002`.

### Explain the Control Flow in Both Exercises

Save complete output and identify the control-flow point represented by each label:

- `before CALL amount=` is displayed by the caller before transferring control to the subprogram.
- `CALL returned status=` is displayed after `CALL`; its appearance shows that `GOBACK` returned control to the caller.
- `Caller continues after subprogram` appears after all eight cases. It shows that `LESSON24` was not ended by `CHECK-AMOUNT`; the run unit ends later at the main program’s `STOP RUN`.

## Extension (No Answer Provided)

Write a second subprogram to validate customer activity status. The main program passes a status field before amount validation. Define the new `PROGRAM-ID`, the customer status field in `LINKAGE SECTION` (choose its PIC and width), and results for `ACTIVE`, `FROZEN`, and unknown status.

When customer validation fails, the main program must **skip** the amount-validation `CALL`; explain which returned value controls that decision. Record the source files changed, compile command, positional mapping of actual and linkage arguments, the return state from each `CALL`, and observable output proving that the second `CALL` did not run.

No answer is provided. Do not make the return value display-only when the caller needs to test it. Do not compile only the main program: both program sources are part of the build. Do not use file I/O, a database, or parameter-passing modes not covered in this lesson.
