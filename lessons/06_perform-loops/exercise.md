# 第 06 课练习：PERFORM

本节只使用第 06 课讲过的内容：`PERFORM VARYING` 计数循环、`EVALUATE` 分类、`COMPUTE` 累加和 `DISPLAY` 输出。

## 修改练习（会在 `answer.md` 提供参考答案）

从本课原始 `lesson.cob` 开始，每次只修改 `WS-LAST-SAMPLE` 的 `VALUE`，分别设置为 `0`、`1`、`3`、`4`，其余源码保持不变：

1. `0`：循环体应执行 0 次。
2. `1`：只处理第 1 笔样例。
3. `3`：处理三笔固定样例。
4. `4`：处理三笔已知样例和一笔 `UNMAPPED`。

每次修改后重新编译并运行：

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_06 lesson.cob
./build/lesson_06
```

记录每种取值下显示的样例行数和 `WS-PROCESSED-COUNT` 的值，并解释为什么索引等于最后序号时循环体仍会执行。参考答案见 `answer.md`。

## 举一反三（不提供答案）

设计四笔固定支付样例，用 `PERFORM VARYING` 按序处理，逐轮显示编号、类别和金额，并在循环结束后统计处理件数。暂时用 `EVALUATE` 按序号输出每笔样例，本题不使用表格、文件或命名段落。

分别测试最后序号为 0 和 4 两种情况，提交完整固定格式源码、实际编译命令、两种边界的实际输出与退出码，并说明你如何确认“最后序号为 0 时一笔也不处理”。
