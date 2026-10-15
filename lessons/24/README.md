# 第 24 课：CALL——把校验逻辑拆成子程序

> 状态：课程草稿。目录已确认；主程序 102 行固定格式，子程序单独保存在 `amount_check_24.cob`，适用于 GnuCOBOL 3.2.0 默认方言。

## 一、课程目标

学完本课后，你可以：

- 用 `CALL` 把执行交给另一个 COBOL 程序单元。
- 通过 `PROGRAM-ID` 与 `CALL` 字面程序名定位被调用模块。
- 用 `LINKAGE SECTION` 和 `PROCEDURE DIVISION USING` 接收调用方字段。
- 观察子程序用 `GOBACK` 返回后，调用方从 `CALL` 后一条语句继续执行。
- 将主程序与子程序源文件一起编译链接，并用同一子程序检查多笔交易金额。

本课展示最简单的 `CALL ... USING` 数据接口；默认参数传递方式为 `BY REFERENCE`。第 25 课专门定义参数方向、传递方式与接口 Copybook，本课不展开那些契约选择。

## 二、主程序与子程序

- [`lesson.cob`](./lesson.cob) 负责准备八个测试金额、执行 `CALL`、统计结果并显示汇总。
- [`amount_check_24.cob`](./amount_check_24.cob) 的 `PROGRAM-ID` 是 `CHECK-AMOUNT`。它在 `LINKAGE SECTION` 声明两个接收字段：金额和结果状态。

调用方每次先清空结果字段，然后执行：

```cobol
           CALL "CHECK-AMOUNT" USING WS-AMOUNT WS-CHECK-RESULT
```

`USING` 的字段次序必须与子程序 `PROCEDURE DIVISION USING LK-AMOUNT LK-CHECK-RESULT` 的次序相同，PIC 长度与类型也必须兼容。子程序读取金额、写入状态后执行 `GOBACK`。控制返回调用方时，调用方的 `WS-CHECK-RESULT` 已包含新结果。`GOBACK` 让子程序返回；主程序最终用 `STOP RUN` 结束整个运行。

## 三、校验规则与运行流程

金额字段为 `PIC 9(7)V99`：7 位整数和 2 位小数，隐含小数点不占存储字符。子程序按顺序判断：

1. 金额为零：返回 `ZERO-AMOUNT`。
2. 金额大于 1000.00：返回 `LIMIT-EXCEEDED`。
3. 其他金额：返回 `VALID`。所以 1000.00 正好在允许边界内。

主程序依次传入普通金额、零、上限、上限多一分钱、最小正金额、上限前一分钱、PIC 最大值和中间金额。每次 `CALL` 前显示金额，返回后显示结果并更新计数；最后显示“调用已返回”标记和分类摘要。

## 四、编译、运行和预期输出

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob amount_check_24.cob
cobc -x -Wall -o "$scratch_dir/lesson_24" lesson.cob amount_check_24.cob
"$scratch_dir/lesson_24"
```

标准输出：

```text
调用方：开始
调用前 金额=0000125.50
调用返回 状态=VALID
CALL=BEGIN AMOUNT=0000000.00
调用返回 状态=ZERO-AMOUNT
CALL=BEGIN AMOUNT=0001000.00
调用返回 状态=VALID
CALL=BEGIN AMOUNT=0001000.01
调用返回 状态=LIMIT-EXCEEDED
CALL=BEGIN AMOUNT=0000000.01
调用返回 状态=VALID
CALL=BEGIN AMOUNT=0000999.99
调用返回 状态=VALID
CALL=BEGIN AMOUNT=9999999.99
调用返回 状态=LIMIT-EXCEEDED
CALL=BEGIN AMOUNT=0000500.00
调用返回 状态=VALID
调用方：子程序返回后继续
检查总数=008 有效=005 拒绝=003
零金额拒绝数=001 超限拒绝数=002
```

组合语法检查、`-Wall` 编译链接和运行已实际验证。当前环境可能在标准错误中报告 `Warning: program compiled against libxml 212 using older 209`；它不是程序标准输出。

## 五、逐步读代码

1. `WS-AMOUNT` 和 `WS-CHECK-RESULT` 是调用方的存储；第一次调用前结果字段为空。
2. 每个 `1100` 至 `1800` 段落只负责设置一笔金额，然后 `PERFORM` 共用的 `2000-CALL-AMOUNT-CHECK`。
3. `CALL` 把控制交给 `CHECK-AMOUNT`，并按顺序提供金额与结果字段。
4. 子程序的 `LK-AMOUNT` 和 `LK-CHECK-RESULT` 是 LINKAGE 项；它们对应调用方提供的两个参数。
5. `GOBACK` 结束这次子程序执行。调用方随后显示状态，再把结果归入总计和原因计数。
6. 最后的 `调用方：子程序返回后继续` 表明主程序在调用返回后继续执行；程序没有被子程序提前结束。

## 六、修改练习（有答案）

1. 在子程序中把上限 `1000.00` 提高到 `1500.00`。重新编译两个源文件并运行，检查 `1000.01` 的结果、总计和 `OVER_LIMIT` 数。
2. 从原始源码出发，把 `1200-CHECK-ZERO-AMOUNT` 的金额从零改成 `0.01`。重新编译运行，检查零金额原因计数是否下降，及有效数是否增加。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；操作步骤见 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

再抽出一个客户状态检查子程序，并从主程序传入客户状态。设计不同返回状态代表活动、冻结和未找到；测试这些状态如何影响交易是否进入金额校验。说明是否需要把客户资料与交易金额放进同一个参数组。

本题不提供答案。不要把子程序状态写成固定终端文本而让调用方无法判断，也不要遗漏重新编译子程序。

## 八、企业实战补充

批处理常把客户资格、交易类型或金额上限校验拆为可独立调用的程序单元。这样可以让不同主批次共享同一规则，但调用方和子程序必须对 `PROGRAM-ID`、参数顺序、PIC、返回状态和编译/部署依赖保持一致。本课只显示一个显式结果字段；生产接口还要定义输入输出方向、错误码版本和向后兼容策略。

## 参考资料

- [GnuCOBOL Programmer’s Guide：CALL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#CALL)
- [GnuCOBOL Programmer’s Guide：PROCEDURE DIVISION USING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-USING)
- [GnuCOBOL Programmer’s Guide：GOBACK](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#GOBACK)
