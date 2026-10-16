---
_translated_from: lessons/01_hello-cobol/answer.md
_translated_by: site-src/translation agent
---

# Lesson 01 Modification Exercise — Reference Answer

This answer covers only the modification exercise in `exercise.md`; it does not include an answer for the "apply it elsewhere" exercise.

Starting from the original `lesson.cob`, change the source line:

```cobol
           DISPLAY "こんにちは、COBOL！".
```

to:

```cobol
           DISPLAY "こんにちは、バッチチーム！".
```

Change only this one string literal; the rest of the program structure and fixed format remain the same. Run:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_01 lesson.cob
./build/lesson_01
```

Expected output:

```text
こんにちは、バッチチーム！
```

The process exit code is still `0`; `cobc -fsyntax-only` returns `0` with no diagnostics.
