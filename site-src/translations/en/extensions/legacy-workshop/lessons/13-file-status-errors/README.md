# Lesson

## Learning objectives

Two-character FILE STATUS codes, error branches for OPEN/READ/WRITE, AT END/INVALID KEY, input-data validation, and error counting.

After this lesson, explain these terms in your own words and locate their declarations or uses in a small program. Observe inputs, outputs, and state changes instead of memorizing syntax.

## Example code

Open [`L13.COB`](./L13.COB). The source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/13-file-status-errors/L13.COB
cobc -x -Wall -o build/l13 extensions/legacy-workshop/lessons/13-file-status-errors/L13.COB
./build/l13
```

Expected result: success and failure are handled according to the file status codes.

If the compiler reports a format or column error, check columns 7, 8, 12, and 72, then verify periods, variable PIC clauses, and scope terminators. `-Wall` adds warnings; understand them before deciding what to do.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is its compiler-visible name.
2. `DATA DIVISION` describes runtime data; where fields are declared, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the entry point; `0000-MAIN` is a readable paragraph name and does not repeat automatically.
4. Statements run in source order until control flow changes the path or `STOP RUN` ends the process.

## Modification exercise

Use a nonexistent input file to trigger the error path. Ensure the program returns a nonzero status and prints a useful message.

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time and record the output before and after.

## Learn with cobol.nvim

Intentionally remove a field name, then use :CobolLint and :CobolQuickfix to practice jumping from the error column back to the source.

If the plugin does not respond, check the filetype with `:set filetype?` and then run `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; GnuCOBOL compilation determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson’s concepts are declared and used?
- How does the output change when an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you validate before using this example in a real batch project?
