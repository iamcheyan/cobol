# 第 03 课：MOVE 与 COMPUTE

> 状态：课程草稿。目录已确认；源码采用固定格式并符合 100–300 行范围。本例针对 GnuCOBOL 3.2.0。

## 一、课程目标

学完本课后，你可以：

- 用 `MOVE` 将数值数据项赋给另一数据项，并观察目标字段尺度较小时的小数截断。
- 用 `COMPUTE` 编写包含加、减、乘的金额表达式。
- 解释接收字段的 PIC 如何控制结果所保留的小数位。
- 比较不使用 `ROUNDED` 与使用 `ROUNDED` 时的计算结果。
- 指出真实批次还必须明确舍入、记账和金额溢出处理规则。

## 二、知识讲解

### MOVE：复制并转换到接收字段

`MOVE source TO target` 把 source 的值移到 target。它不执行加法，也不会修改 source。目标字段的 `PIC` 决定可以保留多少数字和小数位。本例将四位小数的利息移到两位小数的字段，未使用 `ROUNDED`，结果截为 `15.06`。

这类似把一个 Java `BigDecimal` 赋给另一个变量，但 COBOL 的接收字段有明确的 PIC 尺度，数据搬移时会按该描述转换。Python 的 `Decimal` 通常保持对象的十进制数值与尺度语义；本例展示 COBOL 的接收字段如何影响结果。

### COMPUTE：求表达式并存入指定接收字段

`COMPUTE target = expression` 先求右侧表达式，再把结果存入等号左侧的数据项。示例先计算账户余额：

```cobol
COMPUTE WS-PRE-INTEREST-BALANCE =
    WS-OPENING-BALANCE + WS-DEPOSIT
        - WS-WITHDRAWAL - WS-SERVICE-FEE
```

之后按演示期利率计算利息。数据项和常量都使用明确的十进制 PIC，因此可以在源码中核对输入尺度、表达式和接收尺度。

### 截断与舍入不是同一件事

GnuCOBOL 中，缺省没有 `ROUNDED` 时，多出的目标小数位按截断处理。本例的精确利息为 `15.0650`：移到两位小数得到 `15.06`。对 `COMPUTE` 接收字段加 `ROUNDED` 后，默认舍入模式是 `NEAREST-AWAY-FROM-ZERO`，得到 `15.07`。生产规则需结合币种、产品和会计政策明确定义；不要把某个默认舍入方式当成所有业务的通用规则。

`ROUNDED` 写在接收字段之后、等号之前，例如：

```cobol
COMPUTE WS-INTEREST-ROUNDED ROUNDED = WS-INTEREST-RAW
```

### 溢出风险与企业用途

算术结果超出接收字段容量时，必须设计明确的错误处理。GnuCOBOL 手册说明 `ON SIZE ERROR` 可处理接收字段不足等算术失败；若没有相应处理，字段尺寸错误可能不会由运行时自动报告。第 26 课会系统处理错误路径。

银行批处理中，MOVE 常用于字段间搬移、布局转换和输出准备；COMPUTE 常用于余额、费用、利息和控制总额。必须检查结果字段范围、币种尺度、舍入点、负数规则和守恒关系。

## 三、完整示例源码

见 [`lesson_03.cob`](./lesson_03.cob)，共 100 行。它使用固定样例，不读取外部数据；先计算交易后余额，再比较 `MOVE`、不舍入的 `COMPUTE` 和舍入的 `COMPUTE`。

## 四、源码逐步解析

程序注释行只说明意图，不执行。`IDENTIFICATION DIVISION`、`PROGRAM-ID`、`DATA DIVISION`、`WORKING-STORAGE SECTION` 建立程序和工作数据区；`PROCEDURE DIVISION` 后按源代码顺序执行，不使用尚未学习的 IF、循环或段落。

### 数据声明

| 字段 | PIC / 初值 | 用途 |
|---|---|---|
| `WS-OPENING-BALANCE` | `9(7)V99` / `1000.00` | 期初余额 |
| `WS-DEPOSIT` | `9(7)V99` / `250.55` | 本期入账 |
| `WS-WITHDRAWAL` | `9(7)V99` / `40.10` | 本期支取 |
| `WS-SERVICE-FEE` | `9(5)V99` / `5.25` | 服务费 |
| `WS-PERIOD-RATE` | `9(1)V9(4)` / `0.0125` | 单次演示利率；无日计数规则 |
| `WS-PRE-INTEREST-BALANCE` | `9(7)V99` | 交易后、计息前余额 |
| `WS-INTEREST-RAW` | `9(5)V9999` | 保留四位小数的利息中间值 |
| `WS-INTEREST-MOVE` | `9(5)V99` | `MOVE` 到两位小数的结果 |
| `WS-INTEREST-TRUNC` | `9(5)V99` | 不带 `ROUNDED` 的计算结果 |
| `WS-INTEREST-ROUNDED` | `9(5)V99` | 带 `ROUNDED` 的计算结果 |
| `WS-CLOSING-BALANCE` | `9(7)V99` | 本例按舍入利息入账后的余额 |

### 过程语句与运行时状态

1. 第一个 `COMPUTE`：`1000.00 + 250.55 - 40.10 - 5.25`，将 `1205.20` 写入 `WS-PRE-INTEREST-BALANCE`。
2. 第二个 `COMPUTE`：`1205.20 × 0.0125 = 15.065`，目标 PIC 保留四位小数，GnuCOBOL 输出 `15.0650`。
3. `MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE`：目标只有两位小数，未舍入的结果为 `15.06`；源字段仍为 `15.0650`。
4. 第三个 `COMPUTE` 不写 `ROUNDED`，两位小数结果为 `15.06`。
5. 第四个 `COMPUTE` 在接收字段上写 `ROUNDED`，默认 `NEAREST-AWAY-FROM-ZERO` 将 `15.0650` 舍入为 `15.07`。
6. 最后一个 `COMPUTE` 按本例明示的记账规则，将舍入利息加到计息前余额，得到 `1220.27`。
7. `DISPLAY` 逐项输出初值与中间结果；`STOP RUN` 正常结束。

## 五、输入与输出

没有键盘、文件或数据库输入；`VALUE` 提供固定样例。使用临时目录保存可执行文件，避免将构建产物留在课程目录：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson_03.cob
cobc -x -Wall -o "$scratch_dir/lesson_03" lesson_03.cob
"$scratch_dir/lesson_03"
```

GnuCOBOL 3.2.0 的标准输出：

```text
期首残高=0001000.00
預入額=0000250.55
払戻額=0000040.10
手数料=00005.25
期間利率=0.0125
利息加算前残高=0001205.20
利息（4桁）=00015.0650
MOVE後利息（2桁）=00015.06
COMPUTE切捨て利息=00015.06
COMPUTE四捨五入利息=00015.07
期末残高=0001220.27
```

本工作区实测：语法检查、编译和运行返回码均为 0；标准输出与上面一致。运行时标准错误另有系统警告 `Warning: program compiled against libxml 212 using older 209`，该警告不是 COBOL 程序输出，触发组件尚未定位。

## 六、修改练习（有答案）

把存款金额改为 `200.65`，把演示期利率改为 `0.0150`。重新编译并运行，核对计息前余额、四位小数利息、MOVE 结果、两种 COMPUTE 结果和期末余额。

## 七、举一反三练习（无答案）

为一个小型存款账户增加“月度利息预提”计算：选择四位小数的演示期利率和两位小数的入账字段；分别用 `MOVE`、不带 `ROUNDED` 的 `COMPUTE`、带 `ROUNDED` 的 `COMPUTE` 输出结果。说明你选用的舍入规则及其业务影响。不要用尚未学习的 IF、循环或文件操作。

## 八、企业实战补充

生产级金额计算必须从接口定义和业务规则出发。设计时明确字段的币种、整数位、小数位、最大值、负数规则、舍入位置和超限策略；用控制总额或独立算例核对结果。不要因为示例可以编译运行，就把单次演示利率当成真实银行计息方案。

## 参考资料

- [GnuCOBOL Programmer’s Guide：Arithmetic Expressions](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Arithmetic-Expressions)
- [GnuCOBOL Programmer’s Guide：COMPUTE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#COMPUTE)
- [GnuCOBOL Programmer’s Guide：Simple MOVE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Simple-MOVE)
- [GnuCOBOL Programmer’s Guide：ROUNDED](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#ROUNDED)
- [GnuCOBOL Programmer’s Guide：ON SIZE ERROR](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#ON-SIZE-ERROR-_002b-NOT-ON-SIZE-ERROR)
