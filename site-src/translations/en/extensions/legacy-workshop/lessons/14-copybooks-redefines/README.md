# Lesson

## Learning objectives

COPY's text-inclusion model, COPY search paths, and naming conflicts; REDEFINES shared storage and the use of conditional compilation with REPLACING.

After this lesson, explain these terms in your own words and locate their declarations or uses in a small program. Observe inputs, outputs, and state changes instead of memorizing syntax.

## Example code

Open [`L14.COB`](./L14.COB) and [`RECORD.CPY`](./RECORD.CPY). The source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -I extensions/legacy-workshop/lessons/14-copybooks-redefines -fsyntax-only extensions/legacy-workshop/lessons/14-copybooks-redefines/L14.COB
cobc -I extensions/legacy-workshop/lessons/14-copybooks-redefines -x -Wall -o build/l14 extensions/legacy-workshop/lessons/14-copybooks-redefines/L14.COB
./build/l14
```

Expected result: the same storage area can be interpreted as either raw text or structured fields. During compilation, COPY includes field declarations in the working storage; `REDEFINES` lets two layouts share the same starting bytes.

If the compiler reports a format or column error, check columns 7, 8, 12, and 72, then verify periods, variable PIC clauses, and scope terminators. `-Wall` adds warnings; understand them before deciding what to do.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is its compiler-visible name.
2. `DATA DIVISION` describes runtime data; where fields are declared, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the entry point; `0000-MAIN` is a readable paragraph name and does not repeat automatically.
4. Statements run in source order until control flow changes the path or `STOP RUN` ends the process.

## Modification exercise

Move the record definition into this lesson's RECORD.CPY, then include it with COPY. Try changing a field's length.

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time and record the output before and after.

## Learn with cobol.nvim

On the COPY line, press gf to open the copybook and K to preview it; use <C-o> to return.

If the plugin does not respond, check the filetype with `:set filetype?` and then run `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; GnuCOBOL compilation determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson’s concepts are declared and used?
- How does the output change when an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you validate before using this example in a real batch project?
