---
_translated_from: lessons/04_if-conditions/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 04 Exercise: IF Conditions

This exercise uses only material covered in Lesson 04: `VALUE` initial values in `WORKING-STORAGE`, relational conditions (`=`, `<`, `>`, `<=`, `>=`), `IF` / `ELSE` / `END-IF`, `DISPLAY`, and `STOP RUN`.

## Modification Exercise (reference answer in `answer.md`)

### Baseline

Start from the unchanged original [`lesson.cob`](./lesson.cob). Start each scenario from the original source so that values from one scenario do not affect another.

### Changes and constraints

Change only the initial values in these two `VALUE` clauses:

```cobol
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
```

Do not change `PIC`, `SIGN IS LEADING SEPARATE CHARACTER`, `WS-MAXIMUM-AMOUNT`, relational operators, nesting, the association of any `ELSE`, or any `DISPLAY` text. Write amounts as decimal literals with two fractional digits, such as `-0.01`; do not use `COMPUTE`, `MOVE`, or loops to produce boundary values. Use a one-character status literal such as `"I"`.

### Commands

```sh
mkdir -p build                                   # output directory must exist first
cobc -fsyntax-only lesson.cob                    # syntax check
cobc -x -Wall -o build/lesson_04 lesson.cob      # compile
./build/lesson_04                                # run and observe the decision
echo $?                                          # exit code
```

### Seven scenarios

Standard output always has 6 lines. `取引参照番号=` remains `TXN-00000001`, `上限金額=` remains `0001000.00`, and `口座状態=` shows the selected status. The other values vary as follows:

| # | Amount `VALUE` | Status `VALUE` | `取引金額=` | `判定=` | `理由=` |
|---|---|---|---|---|---|
| 1 | `0.00` | `"A"` | `+0000000.00` | `REJECTED` | `AMOUNT_NOT_POSITIVE` |
| 2 | `-0.01` | `"A"` | `-0000000.01` | `REJECTED` | `AMOUNT_NOT_POSITIVE` |
| 3 | `0.01` | `"A"` | `+0000000.01` | `ACCEPTED` | `WITHIN_RULES` |
| 4 | `1000.00` | `"A"` | `+0001000.00` | `ACCEPTED` | `WITHIN_RULES` |
| 5 | `1000.01` | `"A"` | `+0001000.01` | `REJECTED` | `AMOUNT_OVER_LIMIT` |
| 6 | `125.50` (unchanged initial value) | `"I"` | `+0000125.50` | `REJECTED` | `ACCOUNT_INACTIVE` |
| 7 | `-5.00` | `"I"` | `-0000005.00` | `REJECTED` | `AMOUNT_NOT_POSITIVE` |

For scenario 4 (amount `1000.00`, status `"A"`), expected output is:

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0001000.00
上限金額=0001000.00
判定=ACCEPTED
理由=WITHIN_RULES
```

Every scenario exits with code `0`.

### Questions

1. Which relational condition separates scenarios 1 and 2 from scenario 3, although the boundary values differ by only `0.01`?
2. Scenarios 3 and 4 are both accepted. Are their reasons different? Why does the upper-limit rule accept the endpoint `1000.00`?
3. Which relational condition changes the result between scenarios 4 and 5?
4. Why is scenario 6 rejected even though its amount complies? Which `ELSE` branch does it enter?
5. In scenario 7, both the amount and status are invalid. Why is only one reason printed? Does the status check run?

Record actual output for each scenario and identify the source statement that determines each result. See [`answer.md`](./answer.md) for reference answers.

## Apply What You Learned (No Answer Provided)

Design a transfer validation program with a minimum amount of `5.00`, a maximum of `5000.00`, and a requirement that the receiving account status be `A`. Choose field names and `PIC` clauses, explain the amount's sign and integer width, and choose and justify the nested order because only the first rejection reason is reported. Decide whether each boundary is inclusive. Test `4.99`, `5.00`, `5000.00`, `5000.01`, and a non-`A` status with a valid amount; if the field is signed, test a negative amount too.

Use only this lesson's declarations, `VALUE`, relational conditions, `IF` / `ELSE` / `END-IF`, `DISPLAY`, and `STOP RUN`; do not use loops, paragraphs, tables, `EVALUATE`, `AND`, or `OR`. Copy `lesson.cob` to a temporary directory before editing. Submit the source, commands, actual outputs, and an explanation of which comparison determines each branch. No answer is provided.
