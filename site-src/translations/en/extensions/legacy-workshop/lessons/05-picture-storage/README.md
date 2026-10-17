# Lesson

## Learning objectives

PIC X/A/9、V 隐含小数、S 符号、编辑符号、JUSTIFIED、SIGN、USAGE DISPLAY/COMP/COMP-3；字节数受compiler ABI 影响。

After this lesson, explain these terms in your own words and locate their declarations or uses in a small program. Observe inputs, outputs, and state changes instead of memorizing syntax.

## Example code

Open  [`L05.COB`](./L05.COB)。The source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/05-picture-storage/L05.COB
cobc -x -Wall -o build/l05 extensions/legacy-workshop/lessons/05-picture-storage/L05.COB
./build/l05
```

Expected result: 展示数值field和编辑outputfield。

If the compiler reports a format or column error, check columns 7, 8, 12, and 72, then verify periods, variable PIC clauses, and scope terminators. `-Wall` adds warnings; understand them before deciding what to do.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is its compiler-visible name.
2. `DATA DIVISION` describes runtime data; where fields are declared, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the entry point; `0000-MAIN` is a readable paragraph name and does not repeat automatically.
4. Statements run in source order until control flow changes the path or `STOP RUN` ends the process.

## Modification exercise

把amount改成有符号负数；比较 DISPLAY 与 COMP-3；check不同field的范围与小数位。

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time and record the output before and after.

## Learn with cobol.nvim

在 01 record上use  <leader>cr；将result视为常见布局估算，并用 cobc -C 或compiler文档确认目标 ABI。

If the plugin does not respond, check the filetype with `:set filetype?` and then run `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; GnuCOBOL compilation determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson’s concepts are declared and used?
- How does the output change when an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you validate before using this example in a real batch project?
