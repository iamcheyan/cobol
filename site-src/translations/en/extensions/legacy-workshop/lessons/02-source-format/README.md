# Fixed Format, Free Format, and Column Rules

## Learning objectives

Understand the sequence area, indicator area, Areas A and B, and identification area in fixed-format source, as well as GnuCOBOL's free-format directive and compiler option.

After this lesson, you should be able to explain these terms in your own words and find where they are declared or used in a small program. Do not just memorize syntax: first observe the inputs, outputs, and changes in state.

## Example code

Open [`L02.COB`](./L02.COB). This lesson's source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/02-source-format/L02.COB
cobc -x -Wall -o build/l02 extensions/legacy-workshop/lessons/02-source-format/L02.COB
./build/l02
```

Expected result: the program prints the rules for fixed-format columns.

If the compiler reports a format or column-position error, first check columns 7, 8, 12, and 72. Then verify the periods, variable PIC clauses, and scope-terminating statements. `-Wall` provides additional warnings; understand each warning before deciding whether to address it.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is the program name seen by the compiler.
2. `DATA DIVISION` describes the data used at runtime. If this lesson declares fields, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the program's entry point; `0000-MAIN` is a readable paragraph name and does not execute repeatedly on its own.
4. Each statement runs in source order until a control-flow statement changes the path or `STOP RUN` ends the process.

## Modification exercise

Indent the `DISPLAY` statement so that it starts in column 8 and compare the result. Try compiling with `-free`, then restore fixed format.

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time, and record the output before and after.

## Learn with cobol.nvim

Show the ruler and use `g7`, `g8`, `g12`, and `g73` to jump to columns. Deliberately move code past column 72, then run `:CobolLint`.

If the plugin does not respond, first check the current filetype with `:set filetype?`, then check `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; the actual GnuCOBOL compilation result determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson's concepts are declared and used?
- How will the output change if an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you need to validate before using the example in a real batch project?
