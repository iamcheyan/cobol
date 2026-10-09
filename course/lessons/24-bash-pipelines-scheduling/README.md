# Bash 集成：管道、日志与作业调度

## 学习目标

重定向、管道、tee、日志、管道失败传播、锁文件、cron/systemd timer 的职责边界及可重复运行。

完成本课后，你应该能用自己的话解释上面的术语，并在小程序中找到相应的声明或执行位置。不要只背语法：先观察输入、输出和状态变化。

## 示例代码

打开 [`L24.COB`](./L24.COB)。本课源文件使用固定格式：Division 和段落从 Area A 开始，声明/执行语句在 Area B。先逐行读源码，再运行它。

## 编译和运行

从仓库根目录执行：

```sh
mkdir -p build
cobc -fsyntax-only course/lessons/24-bash-pipelines-scheduling/L24.COB
cobc -x -Wall -o build/l24 course/lessons/24-bash-pipelines-scheduling/L24.COB
./build/l24
```

预期观察：用程序返回状态码驱动 Shell 日志与批处理结果。

若编译器报告格式或列位置错误，先检查第 7、8、12、72 列；再确认句点、变量 PIC 和终止作用域语句。`-Wall` 会提供额外警告，警告也需要理解后再决定是否处理。

## 逐段理解

1. `IDENTIFICATION DIVISION` 声明程序单元，`PROGRAM-ID` 是编译器看到的程序名。
2. `DATA DIVISION` 描述程序运行时使用的数据；本课如有字段声明，请观察层级号与 PIC。
3. `PROCEDURE DIVISION` 是执行入口；`0000-MAIN` 只是可读的段落名，不会自动重复执行。
4. 每条语句按源码顺序执行，直到控制流语句改变路径或 `STOP RUN` 结束进程。

## 修改练习

将输出重定向到日志；在管道中使用 pipefail；试着连续运行两次并保证不会破坏输入。

每次修改后都重新执行语法检查、编译和运行。一次只改一个概念，并记录改动前后的输出。

## 用 cobol.nvim 学习

在插件中查看程序退出路径；用 CobolLint 处理语法，ShellCheck（若安装）处理脚本。

如果插件没有响应，先确认当前文件类型：`:set filetype?`，再检查 `cobc --version`。插件用于导航、布局提示和诊断；GNUCOBOL 的实际编译结果才是程序是否可编译的依据。

## 自测

- 你能指出本课概念在哪几行声明、在哪几行使用吗？
- 输入或字段值变化后，输出会如何变化？
- 你能制造一个与本课主题相关的小错误，并解释编译器信息吗？
- 如果要将示例放入真实批处理项目，你还需要校验哪些输入和失败路径？


## 可运行的 pipeline 示例

运行 [`run-pipeline.sh`](./run-pipeline.sh)：

```sh
course/lessons/24-bash-pipelines-scheduling/run-pipeline.sh
LOG_FILE=/tmp/course-batch.log course/lessons/24-bash-pipelines-scheduling/run-pipeline.sh
```

脚本展示 `tee` 同时输出到终端和日志，并通过 `set -o pipefail` 保留 COBOL 程序在管道中的失败状态。把 `L24.COB` 改成返回非零码后重跑，验证失败分支。
