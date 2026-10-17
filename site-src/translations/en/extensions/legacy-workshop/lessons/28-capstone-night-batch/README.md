# Lesson

## Learning objectives

Requirements breakdown, input formats, Copybooks, data validation, sequential files, business calculations, control-break reports, exit codes, Bash testing, and documentation.

After this lesson, explain these terms in your own words and locate their declarations or uses in a small program. Observe inputs, outputs, and state changes instead of memorizing syntax.

## Example code

Open [`L28.COB`](./L28.COB). The source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/28-capstone-night-batch/L28.COB
cobc -x -Wall -o build/l28 extensions/legacy-workshop/lessons/28-capstone-night-batch/L28.COB
./build/l28
```

Expected result: the capstone project specification is in the README. You can start by combining `BATCHRPT.COB` and `INPUTCSV.COB`.

If the compiler reports a format or column error, check columns 7, 8, 12, and 72, then verify periods, variable PIC clauses, and scope terminators. `-Wall` adds warnings; understand them before deciding what to do.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is its compiler-visible name.
2. `DATA DIVISION` describes runtime data; where fields are declared, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the entry point; `0000-MAIN` is a readable paragraph name and does not repeat automatically.
4. Statements run in source order until control flow changes the path or `STOP RUN` ends the process.

## Modification exercise

First write sample inputs and outputs and define acceptance criteria. Then divide the work into paragraphs and add a test script. Make sure repeated runs behave predictably.

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time and record the output before and after.

## Learn with cobol.nvim

Use Aerial to review the structure. Perform a code review for record calculations, diagnostics, Copybook navigation, and folding.

If the plugin does not respond, check the filetype with `:set filetype?` and then run `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; GnuCOBOL compilation determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson’s concepts are declared and used?
- How does the output change when an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you validate before using this example in a real batch project?
