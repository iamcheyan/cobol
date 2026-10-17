---
_translated_from: lessons/07_paragraphs/answer.md
_translated_by: site-src/translation agent
---
# Lesson 07 Modification Exercise: Reference Answers

This answer covers only the two modifications in `exercise.md`. Start each separately from the original `lesson.cob`. Compile and run with:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_07 lesson.cob
./build/lesson_07
```

## Change the Amounts

Set the initial values as follows:

```cobol
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 2000.00.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 250.00.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
```

The processing paragraph calculates `2000.00 + 250.00 - 40.10 = 2209.90`. Key output:

```text
期末残高=0002209.90
最終残高=0002209.90
```

The stage order remains initialization, processing, and final summary.

## Swap Initialization and Processing

In the main paragraph, perform `2000-PROCESS` first, then `1000-INITIALIZE`, and finally `9000-FINALIZE`. The key output order becomes:

```text
段階=PROCESS
期末残高=0001085.40
段階=INITIALIZE
段階=FINALIZE
最終残高=0000000.00
バッチ=COMPLETE
```

The paragraphs share `WORKING-STORAGE` fields. Processing first writes `1085.40`, then initialization clears that same field, so the final summary reads `0000000.00`. This demonstrates the dependency on paragraph call order.
