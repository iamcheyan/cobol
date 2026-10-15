# 第 25 课练习：调用参数的数据方向

本课源码：主程序 `lesson.cob`，子程序 `add_one_25.cob`（`ADD-ONE`）、`report_binary_25.cob`（`REPORT-BINARY`），参数声明 `copybooks/AMOUNT-INTERFACE.CPY`。讲解与预期结果见 [`README.md`](./README.md)。

每次修改后都要用同一条命令重新编译三个源文件（`-I copybooks` 不能漏）：

```sh
mkdir -p build
cobc -x -Wall -I copybooks -o build/lesson_25 \
  lesson.cob add_one_25.cob report_binary_25.cob
./build/lesson_25
echo $?
rm -rf build
```

编译器对 `BY VALUE` 的 "unfinished" 警告在本课环境中是预期信息；运行时三项自检仍应全部通过（`集計 合格=003 不合格=000`），退出码为 `0`。

## 修改练习（答案见 [`answer.md`](./answer.md)）

两项都从**当前源码**开始，互不依赖；不要改动 `report_binary_25.cob` 和 Copybook。

1. **把子程序增量改成 2。**
   - 修改位置：`add_one_25.cob` 中 `ADD 1 TO AMOUNT-ARGUMENT` → `ADD 2 TO AMOUNT-ARGUMENT`；`lesson.cob` 的 `1100-TEST-REFERENCE` 中 `WS-EXPECTED` 从 `11` 改为 `12`。
   - 约束：其他段落、其他预期值、`WS-MODE` 标签都不动。
   - 预期：`BY REFERENCE` 段调用后调用方看到 `12`；`BY CONTENT` 段子程序内部显示 `22`，而调用方仍是 `20`；`BY VALUE` 段保持 `30`；汇总 `集計 合格=003 不合格=000`，退出码 `0`。
   - 要回答的问题：为什么同一个子程序，两段的"子程序内部显示值"都变了，调用方字段却只有一个变？

2. **把第二次调用改成 `BY REFERENCE`。**
   - 修改位置：`lesson.cob` 的 `1200-TEST-CONTENT` 中 `CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT` → `... USING BY REFERENCE AMOUNT-ARGUMENT`；同段 `WS-EXPECTED` 从 `20` 改为 `21`；同段 `WS-MODE` 从 `"BY CONTENT"` 改为 `"BY REFERENCE"`。
   - 约束：`1100`、`1300` 两段不动。
   - 预期：该段调用后调用方看到 `21`，这次成功被计入 `BY REFERENCE`：汇总为 `方式 BY REFERENCE=002 BY CONTENT=000 値=001`，`集計 合格=003 不合格=000`，退出码 `0`。
   - 要回答的问题：如果只把 `BY CONTENT` 改成 `BY REFERENCE` 而不改 `WS-EXPECTED` 和 `WS-MODE`，程序会显示什么？为什么仅改调用方式还不够？

两项都要求保存完整标准输出，并分别指出"子程序内部值"和"调用方字段值"。

## 举一反三（无答案）

用一个接口 Copybook 增加金额输入字段和状态输出字段（状态取 `VALID` / `REJECTED`）。让子程序按 `BY REFERENCE` 写回状态，主程序 `CALL` 后按状态字段分支；再单独把状态参数改成 `BY CONTENT`，比较调用方是否还能收到状态。记录两种调用下的调用方结果、参数位置、两个字段的 `PIC`/`USAGE`，以及你用哪些输入值验证了合法与不合法两种情况。

作为边界核对，再故意让状态参数的传递方式与子程序 `PROCEDURE DIVISION USING` 的声明不一致（例如调用方 `BY VALUE`、子程序按默认 `BY REFERENCE` 接收），记录你实际观察到的现象：编译是否报错、运行是否中止、状态字段是否可信。说明为什么这类接口错误不能靠程序自检发现。

本题不提供答案。不要把 `BY VALUE` 当作 group item 或任意长度数据的传递方式，也不要假定三种方式在各编译器和平台上的行为相同。要求独立完成的范围：字段设计、参数顺序、验证用输入值和现象记录都由你决定并解释。
