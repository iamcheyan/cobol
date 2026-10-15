# 第 03 课修改练习参考答案

只回答 `exercise.md` 中的修改练习，不包含举一反三练习答案。

从原始 `lesson.cob` 开始，只改两条初值，其余声明与语句不动：

```cobol
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 200.65.
       01 WS-PERIOD-RATE PIC 9(1)V9(4) VALUE 0.0150.
```

重新检查、编译并运行（命令同 `exercise.md`）：

```sh
cd lessons/03_move-compute
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_03 lesson.cob
./build/lesson_03
echo $?
rm -rf build
```

## 手算核对

1. 计息前余额：`1000.00 + 200.65 − 40.10 − 5.25 = 1155.30`（先加后减，单位元）。
2. 利息中间值：`1155.30 × 0.0150 = 17.3295`，接收字段 `WS-INTEREST-RAW` 是 `9(5)V9999`（四位小数），能完整容纳。
3. `MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE`：`WS-INTEREST-MOVE` 是 `9(5)V99`，不写 `ROUNDED` 等同截断，`17.3295 → 17.32`；`WS-INTEREST-RAW` 本身仍是 `17.3295`。
4. `COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW`：不写 `ROUNDED`，同一截断规则，结果 `17.32`。
5. `COMPUTE WS-INTEREST-ROUNDED ROUNDED = WS-INTEREST-RAW`：默认 `NEAREST-AWAY-FROM-ZERO`，第 3 位是 `9`，进位得 `17.33`。
6. 期末余额：按本课记账规则把舍入利息入账，`1155.30 + 17.33 = 1172.63`。

## 完整预期输出

```text
期首残高=0001000.00
預入額=0000200.65
払戻額=0000040.10
手数料=00005.25
期間利率=0.0150
利息加算前残高=0001155.30
利息（4桁）=00017.3295
MOVE後利息（2桁）=00017.32
COMPUTE切捨て利息=00017.32
COMPUTE四捨五入利息=00017.33
期末残高=0001172.63
```

与基线输出相比，`期首残高`、`払戻額`、`手数料` 三行不变；其余 8 行按 `exercise.md` 的预期差异表变化。`cobc -fsyntax-only`、`cobc -x` 和程序运行的退出码均为 `0`，标准错误只有环境自带的 libxml 版本警告，编译无警告。

## 问题回答

- 截断与舍入共同的源值是 `WS-INTEREST-RAW`，即 `17.3295`；它由 `9(5)V9999` 决定，保留四位小数。
- `MOVE` 的结果由接收字段 `WS-INTEREST-MOVE`（`9(5)V99`）决定；不带 `ROUNDED` 的 `COMPUTE` 由 `WS-INTEREST-TRUNC`（`9(5)V99`）决定；带 `ROUNDED` 的 `COMPUTE` 由 `WS-INTEREST-ROUNDED`（`9(5)V99`）决定。三者源值相同、接收字段尺度相同，差别只来自“是否写 `ROUNDED`”。
