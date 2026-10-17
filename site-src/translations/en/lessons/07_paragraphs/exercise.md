---
_translated_from: lessons/07_paragraphs/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 07 Exercise: Paragraphs

This lesson uses only material covered in Lesson 07: named paragraphs in `PROCEDURE DIVISION`, `PERFORM paragraph-name`, `MOVE`, `COMPUTE`, `DISPLAY`, and `STOP RUN`. All input data is fixed in the program.

## Modification Exercise (reference answers in `answer.md`)

Perform each change separately, starting from the original `lesson.cob` each time.

1. Amount change: set the initial `WS-OPENING-BALANCE` to `2000.00` and `WS-DEPOSIT` to `250.00`; leave `WS-WITHDRAWAL` at `40.10`. Recompile and run, then check the new ending and final balances.
2. Call order change: in `0000-MAIN`, move `PERFORM 2000-PROCESS` before `PERFORM 1000-INITIALIZE`; leave other statements unchanged. Record the stage markers and final balance. Explain why a value written by the processing paragraph is overwritten by the later initialization.

After each change, run:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_07 lesson.cob
./build/lesson_07
```

See `answer.md` for reference answers to these two changes only.

## Apply What You Learned (No Answer Provided)

Design four named paragraphs: load a sample, validate a transaction code, calculate a balance, and print a summary. Arrange their calls in the main paragraph. Use fixed `VALUE` data only; do not use files, tables, loops, or `CALL`.

Then swap two paragraphs that depend on each other's data (for example, validate before loading or summarize before calculating). Record the output differences and explain when that dependency could cause an error. Submit the full fixed-format source, compile command, actual output before and after reordering, and exit codes. No answer is provided.
