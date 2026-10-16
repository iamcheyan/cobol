---
_translated_from: lessons/02_data-types/answer.md
_translated_by: site-src/translation agent
---

# Lesson 02 Modification Exercise — Reference Answer

This answer covers only the three initial-value modifications in `exercise.md` and the boundary self-check. No answer is provided for the "apply it elsewhere" exercise.

## The three modifications

Starting from this lesson's original `lesson.cob`, only change the `VALUE` clauses of the three data declarations:

```cobol
       01 WS-BRANCH-CODE PIC 9(4) VALUE 3107.
       01 WS-CURRENCY-CODE PIC X(3) VALUE "EUR".
       01 WS-CUSTOMER-NUMBER PIC X(10) VALUE "0000000042".
```

Do not modify the field names, `PIC`, field order, or `PROCEDURE DIVISION`. Recompile and run:

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_02 lesson.cob
./build/lesson_02
```

Both `cobc -fsyntax-only` and `cobc -x` return `0` with no diagnostics; the program exit code is `0` (the only stderr is the libxml environmental warning).

## Complete expected diff

Compared with the original program's standard output, exactly three lines differ:

| Original output | Modified output | Why |
|---|---|---|
| `支店コード=2048` | `支店コード=3107` | The `PIC 9(4)` initial changes to `3107`, still a four-digit number; the output width is unchanged |
| `通貨コード=USD` | `通貨コード=EUR` | The three characters of `PIC X(3)` are replaced by `EUR`; the width is unchanged |
| `顧客番号=0002046819` | `顧客番号=0000000042` | `PIC X(10)` still stores ten characters as-is; leading zeros are preserved |

The other 26 lines are byte-for-byte unchanged, because no other field's `PIC` or initial value was changed. The output line label is Japanese: the customer number line is `顧客番号=`, not the field name `WS-CUSTOMER-NUMBER`.

## Why the customer number continues to use PIC X(10)

The customer number is an identifier, not a quantity involved in addition and subtraction:

- The leading zeros are part of the key itself. This lesson verified: declaring the same ten-digit string as `PIC 9(10)` or `PIC X(10)` makes `DISPLAY` look the same (both print `0002046819`); the difference isn't in this one display — it's in semantics: `9` declares the field as numeric, and subsequent program logic handles it with numeric semantics (participates in arithmetic, aligns numerically, compares numerically), but a customer number should not participate in arithmetic, nor should any numeric processing drop its leading zeros or shift its digit count.
- Using `X` can also accommodate values that are not pure digits (e.g., numbered formats with separators or check digits), although this lesson does not introduce such values.
- Conclusion: keep the width as `X(10)`. Only the `VALUE` is changed.

## Boundary self-check

After temporarily changing the initial value of `WS-BRANCH-CODE` to `12345`, the actual measurement on this machine:

- Both `cobc -fsyntax-only lesson.cob` and `cobc -x -Wall -o build/lesson_02 lesson.cob` produce `warning: value size exceeds data size [-Wothers]` pointing to that declaration line; both commands still return `0`.
- The run output changes that line to `支店コード=2345`: the initial `12345` exceeds the capacity of `PIC 9(4)`, the highest `1` is dropped, leaving the low four digits `2345`.
- The program does not raise a runtime error, and the exit code is still `0`.

So the width of `PIC 9(n)` is a hard constraint: the overflow is only a compile-time warning, and the truncated value still enters the program. After writing the initial value, check the width; on this machine's GnuCOBOL 3.2.0 this warning also appears without `-Wall`. After finishing the self-check, revert the initial value to `3107`.
