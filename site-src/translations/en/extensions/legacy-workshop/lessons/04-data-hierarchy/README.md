# DATA DIVISION, Level Numbers, and Group Items

## Learning objectives

Understand level numbers 01, 05, 10, 77, and 88; group and elementary items; and the lifecycle differences among `WORKING-STORAGE`, `LOCAL-STORAGE`, and `LINKAGE`.

After this lesson, you should be able to explain these terms in your own words and find where they are declared or used in a small program. Do not just memorize syntax: first observe the inputs, outputs, and changes in state.

## Example code

Open [`L04.COB`](./L04.COB). This lesson's source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/04-data-hierarchy/L04.COB
cobc -x -Wall -o build/l04 extensions/legacy-workshop/lessons/04-data-hierarchy/L04.COB
./build/l04
```

Expected result: the program defines a customer record and an independent counter.

If the compiler reports a format or column-position error, first check columns 7, 8, 12, and 72. Then verify the periods, variable PIC clauses, and scope-terminating statements. `-Wall` provides additional warnings; understand each warning before deciding whether to address it.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is the program name seen by the compiler.
2. `DATA DIVISION` describes the data used at runtime. If this lesson declares fields, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the program's entry point; `0000-MAIN` is a readable paragraph name and does not execute repeatedly on its own.
4. Each statement runs in source order until a control-flow statement changes the path or `STOP RUN` ends the process.

## Modification exercise

Add a city field, adjust its level-number indentation, and consider which 01 record it belongs to.

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time, and record the output before and after.

## Learn with cobol.nvim

Place the cursor on a field name and use `gd` to find its definition. Use `:CobolCalcRecord` to view an estimate of the record layout.

If the plugin does not respond, first check the current filetype with `:set filetype?`, then check `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; the actual GnuCOBOL compilation result determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson's concepts are declared and used?
- How will the output change if an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you need to validate before using the example in a real batch project?
