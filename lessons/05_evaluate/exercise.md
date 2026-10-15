# 第 05 课练习：EVALUATE

本节只使用第 04–05 课讲过的内容：`EVALUATE` / `WHEN` / `WHEN OTHER` 多路选择、`WORKING-STORAGE` 的 `VALUE` 初值、`DISPLAY` 输出和 `STOP RUN` 结束。所有输入都是程序内常量，不涉及文件、循环或数据库。

## 修改练习（会在 `answer.md` 提供参考答案）

接口契约新增一个交易码 `F`（手续费），需要让程序也能分类它。从本课原始 [`lesson.cob`](./lesson.cob) 开始修改：

1. 改动位置：在 `EVALUATE WS-TRANSACTION-CODE` 中，`WHEN "T"` 分支的最后一条 `DISPLAY`（`DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"`）之后、`WHEN OTHER` 之前，插入一个新分支：

   ```cobol
               WHEN "F"
                   DISPLAY "分類=FEE"
                   DISPLAY "処理=CHARGE_FEE"
   ```

2. 为了让固定样例能观察到新分支，把数据项初值 `01 WS-TRANSACTION-CODE PIC X VALUE "D".` 改为 `VALUE "F"`。

约束：

- 不改动 `WHEN "D"`、`WHEN "W"`、`WHEN "T"` 三个分支的输出；
- 不改动 `WHEN OTHER` 的语义与输出；
- 新分支缩进与相邻分支一致（Area B 从第 12 列起），程序文本不越过第 72 列。

重新编译并运行：

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_05 lesson.cob
./build/lesson_05
echo $?
```

预期差异（与原始版本的输出逐行比较）：

- 第 2 行由 `取引コード=D` 变为 `取引コード=F`；
- 第 3、4 行由 `分類=DEPOSIT` / `処理=ADD_TO_ACCOUNT` 变为 `分類=FEE` / `処理=CHARGE_FEE`；
- 第 1 行 `取引参照番号=TXN-00000001` 不变（该字段没有被改动）；
- `cobc -fsyntax-only`、`cobc -x` 与进程退出码都仍为 `0`，编译无诊断。

原因：`EVALUATE` 按 subject（`WS-TRANSACTION-CODE`）对每个 `WHEN` 的值做精确匹配，初值 `F` 现在命中新分支，所以不再落入 `WHEN OTHER`；参考号字段没有参与本次修改，因此保持不变。

独立核算边界：保留新增的 `WHEN "F"` 分支，把初值改回 `X` 再运行一次，应得到 `分類=UNKNOWN` / `処理=REJECT_FOR_REVIEW`。这说明新增分支只影响 `F`，没有改变 `WHEN OTHER` 的兜底行为。该检查用于确认上面的“不改动 `WHEN OTHER`”约束。

## 举一反三（不提供答案）

为一个批处理记录分类支付方式：`C` 现金、`B` 银行转账、`K` 支票；契约之外的代码统一输出待人工核对。

要求：编写完整固定格式程序，用 `EVALUATE` 把支付方式代码映射到类别标签和处理建议，并对以下每个取值各运行一次、记录实际输出：`C`、`B`、`K`、`Z`（另一个字母）、空格（`VALUE " "`）。

限制：只使用本课的程序结构、`EVALUATE` / `WHEN` / `WHEN OTHER`、`DISPLAY` 和 `STOP RUN`；不要引入尚未学习的表格、文件、循环或子程序。

提交源码、编译命令和每个取值的实际输出，并说明：你如何确认恰好只有被匹配的那条分支执行、未定义字母与空格为什么进入同一条兜底路径、以及“分类/处理标签”为什么不等于已经完成支付处理。
