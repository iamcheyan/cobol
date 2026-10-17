# Lesson

## Learning objectives

Independent program units, `CALL USING`, `BY REFERENCE`/`CONTENT`/`VALUE`, `PROCEDURE DIVISION USING`, the `LINKAGE SECTION`, and `RETURNING`.

After this lesson, explain these terms in your own words and locate their declarations or uses in a small program. Observe inputs, outputs, and state changes instead of memorizing syntax.

## Example code

Open [`L15.COB`](./L15.COB). This lesson's source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. The main program, `L15.COB`, passes 7 to `DOUBLE-NUM.COB`. The subprogram receives the argument through `LINKAGE` and returns 14 through the shared result field.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/15-subprograms-linkage/L15.COB extensions/legacy-workshop/lessons/15-subprograms-linkage/DOUBLE-NUM.COB
cobc -x -Wall -o build/l15 extensions/legacy-workshop/lessons/15-subprograms-linkage/L15.COB extensions/legacy-workshop/lessons/15-subprograms-linkage/DOUBLE-NUM.COB
./build/l15
```

Expected result: the program first displays `INPUT=0007`, then displays `RESULT=00014`.

If the compiler reports a format or column error, check columns 7, 8, 12, and 72, then verify periods, variable PIC clauses, and scope terminators. `-Wall` adds warnings; understand them before deciding what to do.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is its compiler-visible name.
2. `DATA DIVISION` describes runtime data; where fields are declared, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the entry point; `0000-MAIN` is a readable paragraph name and does not repeat automatically.
4. Statements run in source order until control flow changes the path or `STOP RUN` ends the process.

## Modification exercise

Change the subprogram to triple the value, then add a check for invalid input.

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time and record the output before and after.

## Learn with cobol.nvim

Use `gd` to jump to the `CALL` target (when it is open in the same project), and use the outline to explore the entry point and parameter area.

If the plugin does not respond, check the filetype with `:set filetype?` and then run `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; GnuCOBOL compilation determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson’s concepts are declared and used?
- How does the output change when an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you validate before using this example in a real batch project?
