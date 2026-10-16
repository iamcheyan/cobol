---
_translated_from: lessons/01_hello-cobol/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 01 Exercise: Hello COBOL

This exercise uses only the material covered in lesson 01: a minimal fixed-format program, `DISPLAY` string output, and the `STOP RUN` ending.

## Modification Exercise (a reference answer is provided in `answer.md`)

Starting from the original `lesson.cob` of this lesson, change the greeting from `こんにちは、COBOL！` to:

```text
こんにちは、バッチチーム！
```

Limit your changes to the string literal of the `DISPLAY` statement; do not modify the program structure, the Divisions, or the paragraph order. Run the syntax check, the compile, and the program in sequence:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_01 lesson.cob
./build/lesson_01
```

Expected difference: standard output changes from one line `こんにちは、COBOL！` to one line `こんにちは、バッチチーム！`, and the process exit code is still 0. Record the actual output, and confirm which COBOL statement this line of text comes from.

## Apply It Elsewhere (no reference answer provided)

Write a greeting program for an insurance company's nightly batch: output two lines — the first line states the batch name, the second line states that the program is waiting for the input file.

Constraints: only use this lesson's program structure, fixed string output, and the ending statement. Do not yet use fields, conditions, loops, file operations, or subprograms. Submit your source code, the compile commands, the actual run output, and the exit code; also explain how you verified that the output is exactly those two lines.
