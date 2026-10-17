---
_translated_from: lessons/18_csv-processing/answer.md
_translated_by: site-src/translation agent
---
# Lesson 18 Modification Exercises: Reference Answers

This answer covers only the two modification exercises in [`exercise.md`](./exercise.md), not the apply-what-you-learned exercise.

Both exercises start independently from the original `customers.csv`. Edit temporary copies in a temporary directory; do not overwrite the lesson fixture.

## 1. Change the Name on Line 5 from 20 Bytes to 21

Change line 5 in the temporary copy to the following (leave the note as `EXACT20`; this exercise changes only the name length to isolate the variable):

```csv
C0005042,"123456789012345678901",0003210001,A,EXACT20
```

Recompile and run from the temporary copy directory (`cobc -x -Wall -o build/lesson_18 lesson.cob && ./build/lesson_18`). The decision for line 5 changes from “success, with all five fields printed” to:

```text
行=05 状態=拒否 原因=FIELD_TOO_LONG
```

The other 7 lines are unchanged, and the summary becomes:

```text
汇总 行数=08 有效=04 拒绝=04
```

Reason: `4000-APPEND-CHARACTER` increments `WS-FIELD-LENGTH` before adding each character. Once the length exceeds 20, it records `FIELD_TOO_LONG` and no longer writes that character to `WS-FIELD-VALUE`. The 21st character is therefore not silently overwritten or truncated; the entire row is rejected.

Independent check: rejected rows are now 03, 05, 06, and 08, for 4 rows. There are `8 - 4 = 4` valid rows.

## 2. Append a Sixth Field to Line 1

Change line 1 of the temporary copy to:

```csv
C0001042,"Ada Lovelace",0001234567,A,REGULAR,EXTRA
```

This line now has 5 delimiter commas; the fifth comma starts the sixth field. After recompiling and running from the temporary copy directory, the decision for line 1 becomes:

```text
行=01 状態=拒否 原因=TOO_MANY_FIELDS
```

The other 7 lines are unchanged, and the summary becomes:

```text
汇总 行数=08 有效=04 拒绝=04
```

Reason: `2300-START-NEXT-FIELD` increments `WS-FIELD-NUMBER` to 6 and records `TOO_MANY_FIELDS`. The field table has only 5 entries, so the sixth field’s contents are not written anywhere. Even if a later check finds another problem, it cannot replace the reason already recorded (first error wins), so the reason remains `TOO_MANY_FIELDS`.

Independent check: rejected rows are now 01, 03, 06, and 08, for 4 rows. There are `8 - 4 = 4` valid rows.
