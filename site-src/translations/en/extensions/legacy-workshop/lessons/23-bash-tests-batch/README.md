# Lesson

## Learning objectives

Safe use of `find` and arrays, loops, temporary directories, stdout/stderr, exit codes, `diff`, test fixtures, and cleanup traps.

After this lesson, explain these terms in your own words and locate their declarations or uses in a small program. Observe inputs, outputs, and state changes instead of memorizing syntax.

## Example code

Open [`L23.COB`](./L23.COB). The source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/23-bash-tests-batch/L23.COB
cobc -x -Wall -o build/l23 extensions/legacy-workshop/lessons/23-bash-tests-batch/L23.COB
./build/l23
```

Expected result: the regression script compiles the program, runs the fixtures, checks the output, and returns a nonzero status on failure.

If the compiler reports a format or column error, check columns 7, 8, 12, and 72, then verify periods, variable PIC clauses, and scope terminators. `-Wall` adds warnings; understand them before deciding what to do.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is its compiler-visible name.
2. `DATA DIVISION` describes runtime data; where fields are declared, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the entry point; `0000-MAIN` is a readable paragraph name and does not repeat automatically.
4. Statements run in source order until control flow changes the path or `STOP RUN` ends the process.

## Modification exercise

Change the expected output and confirm that the test fails. Fix the program and run it again. Use `bash -x` to observe the script execution.

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time and record the output before and after.

## Learn with cobol.nvim

Use `:CobolQuickfix` for COBOL syntax issues. When a shell assertion fails, locate the difference between the expected and actual output.

If the plugin does not respond, check the filetype with `:set filetype?` and then run `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; GnuCOBOL compilation determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson’s concepts are declared and used?
- How does the output change when an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you validate before using this example in a real batch project?
