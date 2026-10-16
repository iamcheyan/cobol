---
_translated_from: lessons/06_perform-loops/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 06 Exercise: PERFORM

This section uses only the material covered in lesson 06: the `PERFORM VARYING` counted loop, `EVALUATE` classification, `COMPUTE` accumulation, and `DISPLAY` output.

## Modification Exercise (a reference answer is provided in `answer.md`)

Starting from this lesson's original `lesson.cob`, modify only the `VALUE` of `WS-LAST-SAMPLE` each time, setting it to `0`, `1`, `3`, and `4` respectively, while keeping the rest of the source unchanged:

1. `0`: the loop body should execute 0 times.
2. `1`: only the 1st sample is handled.
3. `3`: three fixed samples are handled.
4. `4`: the three known samples and one `UNMAPPED` are handled.

Recompile and run after each modification:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_06 lesson.cob
./build/lesson_06
```

Record the number of sample lines displayed and the value of `WS-PROCESSED-COUNT` for each value, and explain why the loop body still executes when the index equals the last sequence number. The reference answer is in `answer.md`.

## Apply It Elsewhere (no answer provided)

Design four fixed payment samples, use `PERFORM VARYING` to process them in order, display the sequence number, category, and amount each round, and tally the count processed after the loop ends. For now, use `EVALUATE` to output each sample by its sequence number; this exercise does not use tables, files, or named paragraphs.

Test separately with the last sequence number being 0 and 4, submit the complete fixed-format source code, the actual compile command, the actual output and exit code for both boundary cases, and explain how you confirmed that "no samples are processed when the last sequence number is 0".