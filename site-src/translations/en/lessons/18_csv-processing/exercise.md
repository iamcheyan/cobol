---
_translated_from: lessons/18_csv-processing/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 18 Exercise: Field-Length and Field-Count Boundaries

## Modification Exercises (Answers in `answer.md`)

Start each of the two exercises independently from the original `customers.csv`. Copy `lesson.cob` and `customers.csv` into a temporary directory, make changes to the temporary copies, and compile and run there. Do not overwrite the lesson fixture.

Baseline (the original fixture has 8 lines):

```text
汇总 行数=08 有效=05 拒绝=03
```

1. **Field too long:** Change only the name on line 5 from 20 bytes to 21 bytes.
   - Change and constraint: line 5, `"12345678901234567890"` → `"123456789012345678901"`; leave the note and all other lines unchanged.
   - Recompile and run (inside that temporary copy directory): `cobc -x -Wall -o build/lesson_18 lesson.cob && ./build/lesson_18`
   - Expected complete difference: line 5 changes from “success, with all five fields printed” to `行=05 状態=拒否 原因=FIELD_TOO_LONG`; the other 7 lines are unchanged, and the summary becomes `汇总 行数=08 有效=04 拒绝=04`.
   - In your explanation, identify which field and which byte triggered the rejection.
2. **Too many fields:** Append `,EXTRA` to the end of line 1 only.
   - Change and constraint: line 1 becomes `C0001042,"Ada Lovelace",0001234567,A,REGULAR,EXTRA`; leave all other lines unchanged.
   - Recompile and run: same as above.
   - Expected complete difference: line 1 becomes `行=01 状態=拒否 原因=TOO_MANY_FIELDS`; the other 7 lines are unchanged, and the summary becomes `汇总 行数=08 有效=04 拒绝=04`.
   - In your explanation, identify which comma starts the rejected field.

For each exercise, retain the complete output (do not look only at the summary), confirm that the process exit code is `0`, and explain which field or delimiter triggered the rejection.

## Apply What You Learned (No Answer)

Design a four-field transaction CSV with a transaction ID, payee, amount, and note. Allow commas and double quotes in the payee field (including `""` escaping), and allow an empty note. Require rejection of the wrong field count, an unclosed quote, and an overlong note. Design fixtures for valid records, an empty note, escaped quotes, and each error type, and explain:

- Which commands you use to run the program and how you check each row’s decision.
- Whether length is measured in bytes or characters, and which command proves it (for example, `od -c` or `wc -c`).
- Which conditions the program really validates in code and which ones you merely assume.

No answer is provided. Do not handle quoted fields spanning physical lines, connect to a database, or describe the parsing result as a database import or a production-grade CSV compatibility check.
