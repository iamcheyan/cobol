# 第 25 课练习：调用参数的数据方向

## 修改练习（答案见 `answer.md`）

每次修改后都要用 `-I copybooks` 重新编译主程序和两个子程序。编译器对 BY VALUE 的未完成功能警告在本课环境中是预期信息；运行时的检查计数仍必须为三项通过、零项失败。

1. 在 `add_one_25.cob` 中把 `ADD 1 TO AMOUNT-ARGUMENT` 改成 `ADD 2 TO AMOUNT-ARGUMENT`。在 `lesson.cob` 的 `1100-TEST-REFERENCE` 中把 `WS-EXPECTED` 从 11 改为 12。确认 BY REFERENCE 调用后主程序看到 12，而 BY CONTENT 调用后仍看到原来的 20。
2. 在 `1200-TEST-CONTENT` 中把调用方式改为 `BY REFERENCE`，把该段的 `WS-EXPECTED` 从 20 改成 21，并把 `WS-MODE` 从 `BY CONTENT` 改成 `BY REFERENCE`。确认调用后主程序看到 21，且摘要把这次成功计入 BY REFERENCE。

保存完整标准输出与编译器警告，分别指出子程序内部值和调用方字段值。

## 举一反三（无答案）

用一个接口 Copybook 增加金额输入字段和状态输出字段。让子程序按 `BY REFERENCE` 写回状态；再单独实验把状态参数改成 `BY CONTENT`。记录两种调用下的调用方结果、参数位置与 PIC/USAGE 定义。

本题不提供答案。不把 BY VALUE 当作 group item 或任意长度数据的传递方式。
