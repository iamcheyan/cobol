---
_translated_from: lessons/04_if-conditions/answer.md
_translated_by: site-src/translation agent
---
# Lesson 04 Modification Exercise: Reference Answers

This answer covers only the modification exercise in [`exercise.md`](./exercise.md), not the open-ended exercise.

## How to Make the Changes

Start each scenario from the original `lesson.cob` and change only the initial values in the two `VALUE` clauses below. Keep `PIC`, `SIGN IS LEADING SEPARATE CHARACTER`, the maximum amount, relational operators, nesting, and all `DISPLAY` text unchanged.

```cobol
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
```

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_04 lesson.cob
./build/lesson_04
echo $?
```

Both compiler commands and each run return `0`. A business rejection does not affect the process exit code.

## Scenario 1: Amount `0.00`, status `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 0.00.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0000000.00
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_NOT_POSITIVE
```

`IF WS-TRANSACTION-AMOUNT <= ZERO` is true because zero is not greater than zero. The program prints the rejection in the outer branch; neither check inside `ELSE` runs.

## Scenario 2: Amount `-0.01`, status `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE -0.01.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=-0000000.01
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_NOT_POSITIVE
```

The same comparison is true. `S9(7)V99` with `SIGN IS LEADING SEPARATE CHARACTER` stores the negative value, displays its leading `-`, and compares it numerically, so `-0.01 <= ZERO` is true.

## Scenario 3: Amount `0.01`, status `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 0.01.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0000000.01
上限金額=0001000.00
判定=ACCEPTED
理由=WITHIN_RULES
```

`0.01 <= ZERO` is false, so the lower bound passes. `0.01 > 1000.00` is also false, and status is `"A"`; all rules pass. The split from scenarios 1 and 2 is caused by `<=`.

## Scenario 4: Amount `1000.00`, status `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 1000.00.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0001000.00
上限金額=0001000.00
判定=ACCEPTED
理由=WITHIN_RULES
```

The upper-bound condition uses strict `>`. `1000.00 > 1000.00` is false, so the endpoint is included and the status check accepts it.

## Scenario 5: Amount `1000.01`, status `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 1000.01.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0001000.01
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_OVER_LIMIT
```

The positive-amount check passes, then `1000.01 > 1000.00` is true. The second nested branch rejects it, so the status check does not run.

## Scenario 6: Amount remains `125.50`, status becomes `"I"`

Only the status changes:

```cobol
       01 WS-ACCOUNT-STATUS PIC X VALUE "I".
```

The amount clause remains at its original value:

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
```

```text
取引参照番号=TXN-00000001
口座状態=I
取引金額=+0000125.50
上限金額=0001000.00
判定=REJECTED
理由=ACCOUNT_INACTIVE
```

Both amount checks pass, so execution reaches `IF WS-ACCOUNT-STATUS = "A"`. `"I"` is unequal to `"A"`, so the innermost `ELSE` prints `ACCOUNT_INACTIVE`. The program uses the same reason for every status other than `A`.

## Scenario 7: Amount `-5.00`, status `"I"`

```cobol
       01 WS-ACCOUNT-STATUS PIC X VALUE "I".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE -5.00.
```

```text
取引参照番号=TXN-00000001
口座状態=I
取引金額=-0000005.00
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_NOT_POSITIVE
```

Both conditions are invalid, but the nested decision checks the outer condition first. Since `<= ZERO` is true, its branch prints the reason immediately; the status comparison in the innermost level never runs. This demonstrates that nesting order defines the first failure reported.

## Answers to the Questions

1. `IF WS-TRANSACTION-AMOUNT <= ZERO`. It is true for `0.00` and `-0.01`, and false for `0.01`.
2. Both accepted cases report `WITHIN_RULES`. The strict `>` upper-limit test includes `1000.00` because `1000.00 > 1000.00` is false.
3. `IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT`; it is true for `1000.01` and false for `1000.00`.
4. Both amount checks pass, so the status condition runs. `"I"` does not equal `"A"`, and the innermost `ELSE` reports `ACCOUNT_INACTIVE`.
5. The branches are nested. When the outer condition is true, its reason is printed and execution never reaches the status condition, so only one reason appears.
