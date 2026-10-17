# Lesson

## Learning objectives

重定向、管道、tee、日志、管道failure传播、锁file、cron/systemd timer 的职责边界及可重复run。

After this lesson, explain these terms in your own words and locate their declarations or uses in a small program. Observe inputs, outputs, and state changes instead of memorizing syntax.

## Example code

Open  [`L24.COB`](./L24.COB)。The source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/24-bash-pipelines-scheduling/L24.COB
cobc -x -Wall -o build/l24 extensions/legacy-workshop/lessons/24-bash-pipelines-scheduling/L24.COB
./build/l24
```

Expected result: 用program返回状态码驱动 Shell 日志与批processresult。

If the compiler reports a format or column error, check columns 7, 8, 12, and 72, then verify periods, variable PIC clauses, and scope terminators. `-Wall` adds warnings; understand them before deciding what to do.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is its compiler-visible name.
2. `DATA DIVISION` describes runtime data; where fields are declared, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the entry point; `0000-MAIN` is a readable paragraph name and does not repeat automatically.
4. Statements run in source order until control flow changes the path or `STOP RUN` ends the process.

## Modification exercise

将output重定向到日志；在管道中use  pipefail；试着连续run两次并保证不会破坏input。

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time and record the output before and after.

## Learn with cobol.nvim

在plugin中view program退出path；用 CobolLint process语法，ShellCheck（若安装）process脚本。

If the plugin does not respond, check the filetype with `:set filetype?` and then run `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; GnuCOBOL compilation determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson’s concepts are declared and used?
- How does the output change when an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you validate before using this example in a real batch project?


## Runnable pipeline example

run [`run-pipeline.sh`](./run-pipeline.sh)：

```sh
extensions/legacy-workshop/lessons/24-bash-pipelines-scheduling/run-pipeline.sh
LOG_FILE=/tmp/course-batch.log extensions/legacy-workshop/lessons/24-bash-pipelines-scheduling/run-pipeline.sh
```

脚本展示 `tee` 同时output到终端和日志，并通过 `set -o pipefail` 保留 COBOL program在管道中的failure状态。把 `L24.COB` 改成返回非零码后重跑，验证failure分支。
