---
_translated_from: lessons/02_data-types/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 02 Exercise: Data Types and PIC

This exercise uses only the material from lessons 01 and 02: fixed-format source files, `PIC` / `VALUE` field declarations, `DISPLAY` output, and `STOP RUN`. No `MOVE`, arithmetic, conditions, loops, group items, or file operations.

Before changing any values, think about one thing: is this field an "identifier" or a "quantity"? Get it wrong once and the leading zeros disappear — and the cross-checks downstream won't line up.

## Modification Exercise (reference answer in `answer.md`)

### Baseline

Start from this lesson's original `lesson.cob` (program name `DATA02`, all fields laid out flat in `WORKING-STORAGE SECTION`). Do not do the "apply it elsewhere" exercise first.

### Change locations and constraints

Only change the `VALUE` clauses of the following three fields. Keep `PIC`, the field names, the field order, and the `PROCEDURE DIVISION` untouched:

1. `WS-BRANCH-CODE`: change the initial value `2048` to `3107` (keep `PIC 9(4)`).
2. `WS-CURRENCY-CODE`: change the initial value `"USD"` to `"EUR"` (keep `PIC X(3)`).
3. `WS-CUSTOMER-NUMBER`: change the initial value `"0002046819"` to `"0000000042"` (keep `PIC X(10)`).

For the third item you must explain why the customer number continues to use a text type, instead of being changed to `PIC 9(10)`.

### Recompile and run

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_02 lesson.cob
./build/lesson_02
```

### Complete expected diff

Compared with the original program's standard output, exactly three lines should differ; the other 26 lines should be byte-for-byte unchanged:

| Original output line | Modified output line | Why |
|---|---|---|
| `支店コード=2048` | `支店コード=3107` | The `9(4)` initial changes from 2048 to 3107; the four-digit width doesn't change |
| `通貨コード=USD` | `通貨コード=EUR` | The three characters of `X(3)` are replaced with `EUR` |
| `顧客番号=0002046819` | `顧客番号=0000000042` | `X(10)` stores character by character; the leading eight zeros are preserved as is |

Both `cobc -fsyntax-only` and `cobc -x` should return 0 with no diagnostics; the program's exit code is still 0. If a warning such as `value size exceeds data size` appears, your changes exceed the declared width — check whether you accidentally modified `PIC`.

### Boundary self-check (also part of this exercise)

Temporarily change the initial value of `WS-BRANCH-CODE` to `12345`, compile (you can compare `-Wall` versus no `-Wall`) and run, record the compiler output and the branch code the program prints; then revert to `3107`. Explain how this result relates to the width declaration of `PIC 9(4)`, and whether this warning also appears without `-Wall`.

## Apply It Elsewhere Exercise (no answer)

Build a flat field catalog of policies for an insurance company's nightly batch. At a minimum it must include: policy number (with leading zeros), policyholder name, currency, sum insured, premium, policy effective date, and status code.

Requirements:

- Use only this lesson's independent field declarations, `PIC`, `VALUE`, and `DISPLAY`. Do not use Group Items, `MOVE`, conditions, loops, or file operations.
- For every field, write the name, `PIC`, and initial value, and state whether it is an identifier, a quantity, or an amount. For amounts, specify the integer and decimal positions.
- Point out which fields still need business validation (e.g., calendar validity of the effective date, legal status code values).
- Submit the source, the rationale for your choices, the actual compile commands and run output, and explain how you verified that each field's output width matches its declared `PIC`.
