# 用 cobol.nvim 边学边练

## 学习目标

插件不是 COBOL 语言本身；把标尺、大纲、跳转、Copybook 预览、PIC 计算、诊断、折叠和格式化融入课程。

完成本课后，你应该能用自己的话解释上面的术语，并在小程序中找到相应的声明或执行位置。不要只背语法：先观察输入、输出和状态变化。

## 示例代码

打开 [`L27.COB`](./L27.COB)。本课源文件使用固定格式：Division 和段落从 Area A 开始，声明/执行语句在 Area B。先逐行读源码，再运行它。

## 编译和运行

从仓库根目录执行：

```sh
mkdir -p build
cobc -fsyntax-only course/lessons/27-plugin-learning-workflow/L27.COB
cobc -x -Wall -o build/l27 course/lessons/27-plugin-learning-workflow/L27.COB
./build/l27
```

预期观察：提示学员插件辅助学习但不能代替 GnuCOBOL 编译器和权威语义验证。

若编译器报告格式或列位置错误，先检查第 7、8、12、72 列；再确认句点、变量 PIC 和终止作用域语句。`-Wall` 会提供额外警告，警告也需要理解后再决定是否处理。

## 逐段理解

1. `IDENTIFICATION DIVISION` 声明程序单元，`PROGRAM-ID` 是编译器看到的程序名。
2. `DATA DIVISION` 描述程序运行时使用的数据；本课如有字段声明，请观察层级号与 PIC。
3. `PROCEDURE DIVISION` 是执行入口；`0000-MAIN` 只是可读的段落名，不会自动重复执行。
4. 每条语句按源码顺序执行，直到控制流语句改变路径或 `STOP RUN` 结束进程。

## 修改练习

选择前 10 课中的一个知识点：写代码、编译、运行、故意出错、用插件定位、修复并记录。

每次修改后都重新执行语法检查、编译和运行。一次只改一个概念，并记录改动前后的输出。

## 用 cobol.nvim 学习

完成 README 的插件任务卡，使用 :CobolGuideToggle、:CobolCalcRecord、:CobolLint 和 :CobolQuickfix。

如果插件没有响应，先确认当前文件类型：`:set filetype?`，再检查 `cobc --version`。插件用于导航、布局提示和诊断；GNUCOBOL 的实际编译结果才是程序是否可编译的依据。

## 自测

- 你能指出本课概念在哪几行声明、在哪几行使用吗？
- 输入或字段值变化后，输出会如何变化？
- 你能制造一个与本课主题相关的小错误，并解释编译器信息吗？
- 如果要将示例放入真实批处理项目，你还需要校验哪些输入和失败路径？
