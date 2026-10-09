# 顺序文件、SELECT/FD 与 READ/WRITE

## 学习目标

ASSIGN、ORGANIZATION SEQUENTIAL、FD 记录、OPEN INPUT/OUTPUT/EXTEND、READ、WRITE、AT END、CLOSE。

完成本课后，你应该能用自己的话解释上面的术语，并在小程序中找到相应的声明或执行位置。不要只背语法：先观察输入、输出和状态变化。

## 示例代码

打开 [`L12.COB`](./L12.COB)。本课源文件使用固定格式：Division 和段落从 Area A 开始，声明/执行语句在 Area B。先逐行读源码，再运行它。

## 编译和运行

从仓库根目录执行：

```sh
mkdir -p build
cobc -fsyntax-only course/lessons/12-sequential-files/L12.COB
cobc -x -Wall -o build/l12 course/lessons/12-sequential-files/L12.COB
./build/l12
```

预期观察：此课使用附带的文件 I/O 完整例子，避免把关键文件控制声明藏在截图片段中。

若编译器报告格式或列位置错误，先检查第 7、8、12、72 列；再确认句点、变量 PIC 和终止作用域语句。`-Wall` 会提供额外警告，警告也需要理解后再决定是否处理。

## 逐段理解

1. `IDENTIFICATION DIVISION` 声明程序单元，`PROGRAM-ID` 是编译器看到的程序名。
2. `DATA DIVISION` 描述程序运行时使用的数据；本课如有字段声明，请观察层级号与 PIC。
3. `PROCEDURE DIVISION` 是执行入口；`0000-MAIN` 只是可读的段落名，不会自动重复执行。
4. 每条语句按源码顺序执行，直到控制流语句改变路径或 `STOP RUN` 结束进程。

## 修改练习

在下方创建 input.txt，然后将 README 的 SELECT/FD 示例逐步加入本课程序。

每次修改后都重新执行语法检查、编译和运行。一次只改一个概念，并记录改动前后的输出。

## 用 cobol.nvim 学习

用插件检查 FD/01 记录层级并在 READ 处理段落间跳转。

如果插件没有响应，先确认当前文件类型：`:set filetype?`，再检查 `cobc --version`。插件用于导航、布局提示和诊断；GNUCOBOL 的实际编译结果才是程序是否可编译的依据。

## 自测

- 你能指出本课概念在哪几行声明、在哪几行使用吗？
- 输入或字段值变化后，输出会如何变化？
- 你能制造一个与本课主题相关的小错误，并解释编译器信息吗？
- 如果要将示例放入真实批处理项目，你还需要校验哪些输入和失败路径？

## 可运行的顺序文件练习

本目录另附完整的 [`FILE-DEMO.COB`](./FILE-DEMO.COB) 和 [`input.txt`](./input.txt)。程序按当前工作目录查找输入文件，因此从本课目录编译并运行：

```sh
mkdir -p build
cobc -x -Wall -o build/file-demo FILE-DEMO.COB
./build/file-demo
```

READ 每次读取一条逻辑记录；`AT END` 处理文件尾，`FILE STATUS` 提供成功或失败状态。试着删除 `input.txt`，观察 OPEN 错误路径；再修改记录长度、行结束符和空行，验证输入假设。
