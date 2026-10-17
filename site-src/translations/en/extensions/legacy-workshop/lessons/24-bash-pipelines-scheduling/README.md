# Lesson

## Learning objectives

Redirection, pipelines, `tee`, logs, failure propagation through pipelines, lock files, the roles of cron and systemd timers, and repeatable runs.

After this lesson, explain these terms in your own words and locate their declarations or uses in a small program. Observe inputs, outputs, and state changes instead of memorizing syntax.

## Example code

Open [`L24.COB`](./L24.COB). The source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/24-bash-pipelines-scheduling/L24.COB
cobc -x -Wall -o build/l24 extensions/legacy-workshop/lessons/24-bash-pipelines-scheduling/L24.COB
./build/l24
```

Expected result: the program's exit status drives shell logging and the batch process result.

If the compiler reports a format or column error, check columns 7, 8, 12, and 72, then verify periods, variable PIC clauses, and scope terminators. `-Wall` adds warnings; understand them before deciding what to do.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is its compiler-visible name.
2. `DATA DIVISION` describes runtime data; where fields are declared, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the entry point; `0000-MAIN` is a readable paragraph name and does not repeat automatically.
4. Statements run in source order until control flow changes the path or `STOP RUN` ends the process.

## Modification exercise

Redirect the output to a log. Use `pipefail` in a pipeline. Try running the job twice in succession and make sure it does not damage the input.

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time and record the output before and after.

## Learn with cobol.nvim

View the program's exit paths in the plugin. Use CobolLint for syntax issues and ShellCheck, if installed, for script issues.

If the plugin does not respond, check the filetype with `:set filetype?` and then run `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; GnuCOBOL compilation determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson’s concepts are declared and used?
- How does the output change when an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you validate before using this example in a real batch project?


## Runnable pipeline example

Run [`run-pipeline.sh`](./run-pipeline.sh):

```sh
extensions/legacy-workshop/lessons/24-bash-pipelines-scheduling/run-pipeline.sh
LOG_FILE=/tmp/course-batch.log extensions/legacy-workshop/lessons/24-bash-pipelines-scheduling/run-pipeline.sh
```

The script uses `tee` to send output to both the terminal and a log, and `set -o pipefail` to preserve the COBOL program's failure status through the pipeline. Change `L24.COB` to return a nonzero code, run the script again, and verify the failure path.
