# Lesson

## Learning objectives

IDENTIFICATION、ENVIRONMENT、DATA、PROCEDURE 四个 Division 的职责；program name、句点、paragraph和 STOP RUN。

After this lesson, explain these terms in your own words and locate their declarations or uses in a small program. Observe inputs, outputs, and state changes instead of memorizing syntax.

## Example code

Open  [`L01.COB`](./L01.COB)。The source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/01-program-anatomy/L01.COB
cobc -x -Wall -o build/l01 extensions/legacy-workshop/lessons/01-program-anatomy/L01.COB
./build/l01
```

Expected result: 先显示四大部的职责，再调用一个命名paragraph。

If the compiler reports a format or column error, check columns 7, 8, 12, and 72, then verify periods, variable PIC clauses, and scope terminators. `-Wall` adds warnings; understand them before deciding what to do.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is its compiler-visible name.
2. `DATA DIVISION` describes runtime data; where fields are declared, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the entry point; `0000-MAIN` is a readable paragraph name and does not repeat automatically.
4. Statements run in source order until control flow changes the path or `STOP RUN` ends the process.

## Modification exercise

新增 2000-FAREWELL paragraph并从主流程 PERFORM；observe paragraph顺序不等于execution顺序。

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time and record the output before and after.

## Learn with cobol.nvim

use 大纲view  Division/Paragraph；在 PERFORM 名称上用 gd 跳转，在paragraph定义处用 <C-o> 返回。

If the plugin does not respond, check the filetype with `:set filetype?` and then run `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; GnuCOBOL compilation determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson’s concepts are declared and used?
- How does the output change when an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you validate before using this example in a real batch project?
