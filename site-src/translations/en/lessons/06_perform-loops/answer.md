---
_translated_from: lessons/06_perform-loops/answer.md
_translated_by: site-src/translation agent
---

# Lesson 06 Modification Exercise — Reference Answer

This answer covers only the modification exercise on `WS-LAST-SAMPLE` in `exercise.md`; it does not provide an answer for the "apply it elsewhere" exercise. Each value starts from the original `lesson.cob`, and the compile and run commands use the `build/` flow in the README:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_06 lesson.cob
./build/lesson_06
```

## Last Sequence Number 0

Modify to `01 WS-LAST-SAMPLE PIC 9 VALUE 0.`. The initial index is 1, so `1 > 0` holds before the loop body executes, and therefore no sample lines are output:

```text
最終サンプル番号=0
処理件数=000
```

## Last Sequence Number 1

Modify to `01 WS-LAST-SAMPLE PIC 9 VALUE 1.`. Only sequence 1 is handled; after incrementing to 2, `2 > 1`, and the loop ends:

```text
最終サンプル番号=1
例=001 符号=D 額=125.50
処理件数=001
```

## Last Sequence Number 3

Keep the original initial value; each of the three fixed samples is handled once:

```text
最終サンプル番号=3
例=001 符号=D 額=125.50
例=002 符号=W 額=040.10
例=003 符号=T 額=075.00
処理件数=003
```

## Last Sequence Number 4

Modify to `01 WS-LAST-SAMPLE PIC 9 VALUE 4.`. Index 4 is still less than or equal to the upper bound, so the loop body executes; however, the example only defines three samples, so the fourth round is marked by `WHEN OTHER`:

```text
最終サンプル番号=4
例=001 符号=D 額=125.50
例=002 符号=W 額=040.10
例=003 符号=T 額=075.00
例=UNMAPPED
処理件数=004
```

The strict-greater-than condition `index > last` is only true after the index exceeds the upper bound, so the last sequence number itself will be handled.