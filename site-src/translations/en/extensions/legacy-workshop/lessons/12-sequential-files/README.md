# Lesson

## Learning objectives

ASSIGN, ORGANIZATION SEQUENTIAL, FD records, OPEN INPUT/OUTPUT/EXTEND, READ, WRITE, AT END, and CLOSE.

After this lesson, explain these terms in your own words and locate their declarations or uses in a small program. Observe inputs, outputs, and state changes instead of memorizing syntax.

## Example code

Open [`L12.COB`](./L12.COB). The source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/12-sequential-files/L12.COB
cobc -x -Wall -o build/l12 extensions/legacy-workshop/lessons/12-sequential-files/L12.COB
./build/l12
```

Expected result: this lesson uses a complete file I/O example included with the lesson, so the essential file-control declarations are visible rather than hidden in a cropped excerpt.

If the compiler reports a format or column error, check columns 7, 8, 12, and 72, then verify periods, variable PIC clauses, and scope terminators. `-Wall` adds warnings; understand them before deciding what to do.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is its compiler-visible name.
2. `DATA DIVISION` describes runtime data; where fields are declared, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the entry point; `0000-MAIN` is a readable paragraph name and does not repeat automatically.
4. Statements run in source order until control flow changes the path or `STOP RUN` ends the process.

## Modification exercise

Create input.txt below, then gradually add the SELECT/FD example from this README to the lesson program.

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time and record the output before and after.

## Learn with cobol.nvim

Use the plugin to inspect the FD/01 record hierarchy and jump between paragraphs in the READ procedure.

If the plugin does not respond, check the filetype with `:set filetype?` and then run `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; GnuCOBOL compilation determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson’s concepts are declared and used?
- How does the output change when an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you validate before using this example in a real batch project?

## Runnable sequential-file exercise

This directory also includes a complete [`FILE-DEMO.COB`](./FILE-DEMO.COB) and [`input.txt`](./input.txt). The program looks for the input file in the current working directory, so compile and run it from this lesson's directory:

```sh
mkdir -p build
cobc -x -Wall -o build/file-demo FILE-DEMO.COB
./build/file-demo
```

Each READ retrieves one logical record; `AT END` handles the end of the file, and `FILE STATUS` reports success or failure. Try deleting `input.txt` to observe the OPEN error path. Then change the record length, line endings, and blank lines to verify the input assumptions.
