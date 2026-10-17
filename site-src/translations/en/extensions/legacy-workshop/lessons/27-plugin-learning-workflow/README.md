# Lesson

## Learning objectives

plugin不是 COBOL 语言本身；把标尺、大纲、跳转、Copybook 预览、PIC 计算、诊断、折叠和格式化融入lesson。

After this lesson, explain these terms in your own words and locate their declarations or uses in a small program. Observe inputs, outputs, and state changes instead of memorizing syntax.

## Example code

Open  [`L27.COB`](./L27.COB)。The source uses fixed format: divisions and paragraphs begin in Area A, while declaration and execution statements are in Area B. Read the source line by line, then run it.

## Compile and run

Run these commands from the repository root:

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/27-plugin-learning-workflow/L27.COB
cobc -x -Wall -o build/l27 extensions/legacy-workshop/lessons/27-plugin-learning-workflow/L27.COB
./build/l27
```

Expected result: 提示学员plugin辅助learn但不能代替 GnuCOBOL compiler和权威语义验证。

If the compiler reports a format or column error, check columns 7, 8, 12, and 72, then verify periods, variable PIC clauses, and scope terminators. `-Wall` adds warnings; understand them before deciding what to do.

## Understand the program

1. `IDENTIFICATION DIVISION` declares the program unit; `PROGRAM-ID` is its compiler-visible name.
2. `DATA DIVISION` describes runtime data; where fields are declared, observe their level numbers and PIC clauses.
3. `PROCEDURE DIVISION` is the entry point; `0000-MAIN` is a readable paragraph name and does not repeat automatically.
4. Statements run in source order until control flow changes the path or `STOP RUN` ends the process.

## Modification exercise

选择前 10 课中的一个知识点：写代码、编译、run、故意出错、Use the plugin to 定位、修复并record。

After each change, rerun syntax checking, compilation, and the program. Change one concept at a time and record the output before and after.

## Learn with cobol.nvim

完成 README 的plugin任务卡，use  :CobolGuideToggle、:CobolCalcRecord、:CobolLint 和 :CobolQuickfix。

If the plugin does not respond, check the filetype with `:set filetype?` and then run `cobc --version`. The plugin provides navigation, layout hints, and diagnostics; GnuCOBOL compilation determines whether the program compiles.

## Self-check

- Can you identify the lines where this lesson’s concepts are declared and used?
- How does the output change when an input or field value changes?
- Can you introduce a small error related to this lesson and explain the compiler message?
- What inputs and failure paths would you validate before using this example in a real batch project?
