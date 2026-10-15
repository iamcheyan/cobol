# 第 11 课：OCCURS 固定长度表格

> 状态：课程草稿。目录已确认；示例源码 105 行固定格式，适用于 GnuCOBOL 3.2.0 默认方言。

## 一、课程目标

学完本课后，你可以：

- 用 `OCCURS n TIMES` 定义固定容量的数据表。
- 在组项上声明 `OCCURS`，让整组字段按出现次数重复。
- 用括号中的数值下标读写指定表项。
- 让 `PERFORM VARYING` 的处理范围与表格已装入的范围一致。
- 区分普通数值下标与下一课的 `INDEXED BY` 索引。

## 二、表格布局

[`lesson.cob`](./lesson.cob) 在 `WS-TRANSACTION-TABLE` 中声明四次出现的 `WS-TRANSACTION-ENTRY`。每个出现项包含交易码 `WS-TXN-CODE` 和金额 `WS-TXN-AMOUNT`：

```text
01 WS-TRANSACTION-TABLE
   05 WS-TRANSACTION-ENTRY OCCURS 4 TIMES
      10 WS-TXN-CODE
      10 WS-TXN-AMOUNT
```

`OCCURS 4 TIMES` 为组项分配四个位置，每个位置都包含这两个基本项。程序用 `WS-TXN-CODE(1)` 和 `WS-TXN-AMOUNT(1)` 写第一项；括号中的普通数值字段 `WS-SAMPLE-INDEX` 则在循环中选择当前项。这个程序没有 `INDEXED BY`，索引数据项会在第 12 课讲解。

表格容量固定为四项。`WS-LAST-SAMPLE` 控制本次要处理到哪一项，必须保持在已装入的表项范围内。声明 `OCCURS` 不会自动填充样例，也不会执行排序或查找；本例先用 `MOVE` 写入四项，再按序处理它们。

## 三、程序逐步解析

1. `1000-LOAD-TABLE` 用显式的下标 1、2、3、4，分别装入两笔信用、一笔借记和一笔未知代码。
2. `2000-PROCESS-TABLE` 用 `PERFORM VARYING` 将 `WS-SAMPLE-INDEX` 从 1 加到 `WS-LAST-SAMPLE`。退出条件是 `index > last`，因此最后一项也会处理。
3. `2100-PROCESS-ENTRY` 在字段名后加 `(WS-SAMPLE-INDEX)`，读取当前出现项的交易码和金额。
4. `EVALUATE` 按代码处理：`C` 增加余额，`D` 扣减余额，其他代码只显示忽略动作。
5. 每处理一项，已处理计数加一。四项结束后，余额为 `1105.40`：`1000.00 + 125.50 - 40.10 + 20.00`。未知代码的 `25.00` 不进入余额计算。

普通数值下标使用一开始于 1 的表项编号。它是一个普通数值数据项；这与专门通过 `INDEXED BY` 声明的表格索引不同。避免使用小于 1 或大于声明上界的下标。

## 四、编译、运行和预期输出

在本目录运行以下命令，二进制写入临时目录：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_11" lesson.cob
"$scratch_dir/lesson_11"
```

GnuCOBOL 3.2.0 的程序标准输出：

```text
ENTRY=01 CODE=C AMOUNT=00125.50
ACTION=CREDIT
ENTRY=02 CODE=D AMOUNT=00040.10
ACTION=DEBIT
ENTRY=03 CODE=X AMOUNT=00025.00
ACTION=IGNORED_UNKNOWN_CODE
ENTRY=04 CODE=C AMOUNT=00020.00
ACTION=CREDIT
PROCESSED=004
FINAL-BALANCE=0001105.40
```

当前工作区的语法检查、编译和运行均已执行并返回 0，标准输出与上面一致。运行时标准错误另有系统警告 `Warning: program compiled against libxml 212 using older 209`；这不是 COBOL 程序输出。

## 五、修改练习（有答案）

1. 将第四项信用金额从 `20.00` 改为 `35.00`，重新运行并核对期末余额。
2. 将表格容量和 `WS-LAST-SAMPLE` 都扩展到 5，加入一笔 `C`、金额 `10.00` 的第五项。确认第五项被处理且最终计数和余额正确。

答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；练习要求见 [`exercise.md`](./exercise.md)。

## 六、举一反三（无答案）

将表格改为暂存五个账户余额，每项包含账户号和余额。装入至少三项，以数值下标从第一项遍历到最后一项，并报告所有账户号和余额。修改容量时同步调整处理上界；检查每个下标都在声明的范围内。

本题不提供答案。只使用本课的 `OCCURS` 和普通数值下标；不使用 `INDEXED BY`、`SEARCH`、文件或数据库。

## 七、企业实战补充

批处理程序常在内存中暂存一小批交易、账户或代码映射。固定 `OCCURS` 上界让最大内存布局清晰，但容量、已装入条目数和循环上界是不同概念，必须保持一致。读取表格前还要确保该项已装入；本示例把全部四项显式初始化，不代表外部输入已校验。

## 参考资料

- [GnuCOBOL Programmer’s Guide：OCCURS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#OCCURS)
- [GnuCOBOL Programmer’s Guide：PERFORM VARYING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#VARYING)
