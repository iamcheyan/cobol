# 第 03 课：MOVE 与 COMPUTE——金额运算中的截断与舍入

银行夜间批次要在同一笔账户上完成“期初余额 + 入账 − 支取 − 手续费”，再按演示利率计提本期利息并写出期末余额。本课把这条金额链写进 COBOL：用 `MOVE` 在字段间搬值、用 `COMPUTE` 求加减乘，并让同一个四位小数利息 `15.0650` 分别经过截断与舍入，得到 `15.06` 和 `15.07` 两个利息结果（期末余额随之相差 `0.01`），从而看清“接收字段的 PIC 决定结果保留几位”。

## 为什么现在学

第 02 课已经能用 `PIC 9(7)V99` 描述金额字段，但那些字段只被 `DISPLAY` 打印过初值，没有参与计算。缺口有三处：怎样把一个值搬到另一个字段；怎样写出含加减乘的金额表达式；当结果的小数位比接收字段多时，多余位是丢掉还是进位。最后一条直接决定期末余额写几，是银行对账里最容易出差错的环节。本课只用顺序执行的赋值与算术语句，不引入条件（第 04 课）和循环（第 06 课），先把“接收字段尺度决定结果”这一条规则看清楚。

## 本课完成后的能力与边界

学完本课后，你可以：

- 用 `MOVE` 把值搬到另一个数值字段，并说明接收字段的小数位如何决定去留（本例 `15.0650` → `15.06`）。
- 用 `COMPUTE` 写出含加减乘的金额表达式，并在标准输出中逐项核对每一步中间值。
- 区分“截断”（不写 `ROUNDED`）与“按接收字段舍入”（写 `ROUNDED`），解释同一笔利息为什么会得到 `15.06` 和 `15.07`。
- 说明两种规则会让期末余额相差 `0.01`，并指出必须由业务/会计规则选定其中的一种。
- 说出金额字段位数不足时会发生什么，以及为什么本课样例不会触发这个边界。

边界：本课不引入 `IF` / `EVALUATE`（第 04、05 课）、循环（第 06 课）、段落（第 07 课）、文件输入（第 15 课）和错误处理语句（第 26 课）。所有余额和利率都是程序内演示常量，不是真实账户数据，也不代表任何银行计息方案；程序没有实现溢出检查。

## 运行环境

- GnuCOBOL 3.2.0，使用默认方言（不加 `-std=cobol85`），源文件为固定格式。
- Linux 终端；本课不依赖数据库、附加工具或第三方库。
- 程序不读也不写数据文件，只在 `build/` 下生成可执行文件。
- 公共约定见[课程导航](../README.md)，本课在依赖链中的位置见[32 课总目录](../DIRECTORY.md)。

## 知识讲解

### MOVE：把值搬进接收字段，并按接收字段的 PIC 转换

`MOVE source TO target` 把 `source` 的值复制给 `target`，不修改 `source`，也不做任何运算。关键在于接收字段自带 `PIC` 尺度：`WS-INTEREST-RAW` 是 `9(5)V9999`（四位小数），`WS-INTEREST-MOVE` 是 `9(5)V99`（两位小数），用它俩做 `MOVE` 时多出的两位小数会被丢掉，得到 `15.06`，而源字段仍是 `15.0650`。

用 Java 或 Python 类比时要注意差别：把一个 `BigDecimal` 赋给另一个变量通常不会改变数值，而 COBOL 的接收字段有明确的十进制尺度，搬移时按该描述转换，所以“搬一次值”本身就可能改变金额。生产代码因此要求把搬移前后的字段尺度和业务单位写清楚，不能靠读者从代码猜测。

### COMPUTE：先求表达式，再存进接收字段

`COMPUTE target = expression` 先按右侧表达式求值，再把结果存入左侧数据项，接收字段的 `PIC` 同样决定保留几位小数。本例先算交易后余额：

```cobol
COMPUTE WS-PRE-INTEREST-BALANCE =
    WS-OPENING-BALANCE + WS-DEPOSIT
        - WS-WITHDRAWAL - WS-SERVICE-FEE
```

再算利息 `WS-PRE-INTEREST-BALANCE * WS-PERIOD-RATE`，把中间值写进四位小数的 `WS-INTEREST-RAW`。所有输入、中间值和接收字段都用明确的十进制 `PIC` 声明，因此每一步都能在源码里核对，不依赖浮点近似。

这些值必须由字段算出，而不是写死在 `DISPLAY` 的字面量里：写死只能复述一次结果，初值一改就得手工重算，业务规则也从源码里消失了；用 `COMPUTE` 则规则留在代码中，改初值就自动得到新结果（本课练习正是这样做的）。

### 截断与舍入：同一次计算，两条业务规则

GnuCOBOL 中，接收字段小数位不足时，**不写** `ROUNDED` 等同于 `ROUNDED MODE IS TRUNCATION`（截断；本课金额非负，即丢弃多余小数位）；**写** `ROUNDED` 而不写模式时等同于 `NEAREST-AWAY-FROM-ZERO`（就近舍入，遇到正好一半时远离零）。本例利息的精确值是 `15.0650`：

| 写法 | 结果 | 说明 |
|---|---|---|
| `MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE` | `15.06` | 接收字段两位小数，丢掉第 3、4 位 |
| `COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW` | `15.06` | 不写 `ROUNDED`，同一截断规则 |
| `COMPUTE WS-INTEREST-ROUNDED ROUNDED = WS-INTEREST-RAW` | `15.07` | 第 3 位是 `5`，就近舍入进位 |

`ROUNDED` 写在接收字段之后、等号之前：

```cobol
COMPUTE WS-INTEREST-ROUNDED ROUNDED = WS-INTEREST-RAW
```

选哪一种不是编程偏好，而是业务和会计政策：截断值与舍入值会让期末余额相差 `0.01`，币种、产品和利息计提方式不同，规则也可能不同，所以不要把 GnuCOBOL 的默认模式当作所有业务通用的规则。

### 溢出：接收字段装不下时程序不会自己报警

接收字段的整数位也可能不够。用一段独立探针在本机观察（探针不属于 [`lesson.cob`](./lesson.cob)，只用本课已学的 `PIC`、`COMPUTE`、`DISPLAY`）：

```sh
mkdir -p /tmp/l03probe && cd /tmp/l03probe
cat > probe.cob <<'EOF'
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROBE03.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-BAL PIC 9(7)V99 VALUE 1234567.89.
       01 WS-RATE PIC 9(1)V9(4) VALUE 0.9000.
       01 WS-INT PIC 9(5)V99 VALUE 55.55.
       PROCEDURE DIVISION.
           COMPUTE WS-INT = WS-BAL * WS-RATE.
           DISPLAY "利息=" WS-INT.
           STOP RUN.
EOF
cobc -x -o probe probe.cob && ./probe
```

`1234567.89 × 0.9000 = 1111111.101`，收进 `PIC 9(5)V99` 后实际打印 `利息=11111.10`，进程退出码为 `0`：高位数字被静默丢弃，程序既不中止也不报错。“算错了”本身不会变成错误信号，所以金额字段的容量、溢出判断和上报方式必须由程序显式规定。`ON SIZE ERROR` 能捕获这类条件，但它属于错误处理内容，本课未使用，留到第 26 课。

## 完整示例源码

完整源码见 [`lesson.cob`](./lesson.cob)，按固定格式编写，只使用 `MOVE`、`COMPUTE`、`DISPLAY` 和 `STOP RUN`。上面已摘录余额与利息两处关键语句，其余语句在下面的阅读路径中说明。

## 源码阅读路径

### 数据声明

| 字段 | PIC / 初值 | 用途与尺度 |
|---|---|---|
| `WS-OPENING-BALANCE` | `9(7)V99` / `1000.00` | 期初余额，元，两位小数 |
| `WS-DEPOSIT` | `9(7)V99` / `250.55` | 本期入账 |
| `WS-WITHDRAWAL` | `9(7)V99` / `40.10` | 本期支取 |
| `WS-SERVICE-FEE` | `9(5)V99` / `5.25` | 服务费；整数位 5 位，容量小于余额字段 |
| `WS-PERIOD-RATE` | `9(1)V9(4)` / `0.0125` | 演示利率 1.25%，四位小数；无日计数规则 |
| `WS-PRE-INTEREST-BALANCE` | `9(7)V99` / `ZERO` | 交易后、计息前余额 |
| `WS-INTEREST-RAW` | `9(5)V9999` / `ZERO` | 利息中间值，故意保留四位小数 |
| `WS-INTEREST-MOVE` | `9(5)V99` / `ZERO` | `MOVE` 后的两位小数结果 |
| `WS-INTEREST-TRUNC` | `9(5)V99` / `ZERO` | 不写 `ROUNDED` 的计算结果 |
| `WS-INTEREST-ROUNDED` | `9(5)V99` / `ZERO` | 写 `ROUNDED` 的计算结果 |
| `WS-CLOSING-BALANCE` | `9(7)V99` / `ZERO` | 按本课记账规则（入账舍入利息）的期末余额 |

### 执行顺序与状态变化

1. 第一个 `COMPUTE`：`1000.00 + 250.55 − 40.10 − 5.25`，把 `1205.20` 写入 `WS-PRE-INTEREST-BALANCE`。
2. 第二个 `COMPUTE`：`1205.20 × 0.0125 = 15.065`，接收字段是 `9(5)V9999`，输出为 `15.0650`。
3. `MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE`：接收字段只有两位小数，未舍入，得 `15.06`；`WS-INTEREST-RAW` 仍为 `15.0650`。
4. `COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW`：不写 `ROUNDED`，同样得 `15.06`。
5. `COMPUTE WS-INTEREST-ROUNDED ROUNDED = WS-INTEREST-RAW`：默认 `NEAREST-AWAY-FROM-ZERO`，得 `15.07`。
6. `COMPUTE WS-CLOSING-BALANCE = WS-PRE-INTEREST-BALANCE + WS-INTEREST-ROUNDED`：按本课记账规则，`1205.20 + 15.07 = 1220.27`。
7. 十一个 `DISPLAY` 按源码顺序输出标签和值，`STOP RUN` 正常结束。

第 2–5 步都源自同一个 `WS-INTEREST-RAW`，所以三个两位小数结果之间的差别只来自接收字段，不是重复计算造成的。`DISPLAY` 本身不改变任何字段。

## 运行与观察

### 从哪里执行

程序不读文件、命令行参数或数据库，在本课目录或任意目录运行结果都相同。下面按本课目录书写：`lesson.cob` 与 `build/lesson_03` 都是相对当前目录的路径，先 `cd lessons/03_move-compute` 再执行。

### 输入

无标准输入、文件或数据库输入，数据全部来自 `lesson.cob` 中 `01` 级字段的 `VALUE`：

- 金额字段为 `PIC 9(7)V99` 或 `9(5)V99`，单位是元，隐含两位小数，最小记账单位 0.01；
- 利率字段为 `PIC 9(1)V9(4)`，`0.0125` 表示 1.25%，没有日计数规则，只在计息前余额上乘一次；
- 没有负数、空值或位数不足输入的校验：这些边界属于 `IF`（第 04 课）、文件与校验（第 15 课以后）和错误处理（第 26 课）。

### 四条命令各自证明什么

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                    # check：只解析语法，不生成可执行文件
cobc -x -Wall -o build/lesson_03 lesson.cob      # build：生成可执行文件，-Wall 打开编译期警告
./build/lesson_03                                # run：运行程序，标准输出就是业务结果
echo $?                                          # 查看上一条运行命令的退出码
rm -rf build                                     # clean：删除本课构建产物
```

`-fsyntax-only` 通过只说明语法路径没问题，行为要编译并运行才能验证。`-Wall` 让编译器提前报告字面量宽度超出接收字段一类问题；本课源码没有这类警告。

### 预期 stdout、stderr 与退出码

| 输出行 | 值 | 怎么得来 |
|---|---|---|
| `期首残高=0001000.00` | 1000.00 | 初值，按 `9(7)V99` 补齐 |
| `預入額=0000250.55` | 250.55 | 初值 |
| `払戻額=0000040.10` | 40.10 | 初值 |
| `手数料=00005.25` | 5.25 | 初值，按 `9(5)V99` 补齐 |
| `期間利率=0.0125` | 0.0125 | 初值，按 `9(1)V9(4)` 输出 |
| `利息加算前残高=0001205.20` | 1205.20 | 1000.00 + 250.55 − 40.10 − 5.25 |
| `利息（4桁）=00015.0650` | 15.0650 | 1205.20 × 0.0125，接收 `9(5)V9999` |
| `MOVE後利息（2桁）=00015.06` | 15.06 | 15.0650 截断到两位小数 |
| `COMPUTE切捨て利息=00015.06` | 15.06 | 不写 `ROUNDED`，同一截断规则 |
| `COMPUTE四捨五入利息=00015.07` | 15.07 | 写 `ROUNDED`，第 3 位是 `5`，进位 |
| `期末残高=0001220.27` | 1220.27 | 1205.20 + 15.07 |

- `cobc -fsyntax-only` 退出码 `0`，无诊断；`cobc -x` 退出码 `0`，无编译诊断；程序退出码 `0`。
- 标准输出共 11 行，与上表一致，没有多余空行。
- 输出文本沿用仓库的日文约定：`期首残高` = 期初余额，`預入額` = 入账额，`払戻額` = 支取额，`手数料` = 手续费，`期間利率` = 期间利率，`利息加算前残高` = 计息前余额，`利息（4桁）` = 四位小数利息，`MOVE後利息（2桁）` = MOVE 后两位小数利息，`COMPUTE切捨て利息` = COMPUTE 截断利息，`COMPUTE四捨五入利息` = COMPUTE 舍入利息，`期末残高` = 期末余额。
- 标准错误（stderr）另有一行系统警告 `Warning: program compiled against libxml 212 using older 209`，来自本机运行环境链接的 libxml 版本差异，不是本程序的业务输出。

**证据来源：** 上表是 2026-10-16 在本工作区用 GnuCOBOL 3.2.0 实际执行 `cobc -fsyntax-only lesson.cob`、`cobc -x -Wall -o build/lesson_03 lesson.cob`、`./build/lesson_03` 观察到的结果，三条命令退出码依次为 `0`、`0`、`0`；每个金额都能用“怎么得来”一列里的算式手工复核。本课数据全部是程序内常量，这一次运行就是程序的全部行为；输出中 `15.0650` 与 `1220.27` 都完整落在各自接收字段的容量内，因此这份输出里没有发生上一节描述的位数丢失。

### 固定格式提醒

源码是固定格式：第 7 列是指示符（`*` 为注释），Area A 从第 8 列开始（`01` 级声明、Division 名），Area B 从第 12 列开始（`COMPUTE`、`MOVE`、`DISPLAY` 等语句），有效程序文本不能越过第 72 列。本机 GnuCOBOL 3.2.0 按**字节**数判断这一列位置：日文字面量每个字符占 3 个字节，一行即使字符数不多，也可能在第 72 字节被截断，报出“缺少字符串结束引号”一类错误。改写 `DISPLAY` 文本时不要把该行推到接近第 72 列；本课两条最长的 `DISPLAY`（含 `MOVE後利息` 与 `COMPUTE切捨て利息`）各为 62 字节，最长的注释行为 71 字节，都未越过第 72 列。

## 修改练习（有答案）

把 `WS-DEPOSIT` 的初值从 `250.55` 改为 `200.65`，把 `WS-PERIOD-RATE` 的初值从 `0.0125` 改为 `0.0150`，然后重新检查、编译并运行，核对计息前余额、四位小数利息、`MOVE` 结果、截断与舍入两种 `COMPUTE` 结果和期末余额。完整题目、约束与预期差异见 [`exercise.md`](./exercise.md)，参考答案与手算过程见 [`answer.md`](./answer.md)。

## 举一反三练习（无答案）

为另一笔存款设计“月度利息预提”：自己选定期初余额、演示利率、四位小数的中间字段和两位小数的接收字段，分别演示 `MOVE`、不带 `ROUNDED` 的 `COMPUTE`、带 `ROUNDED` 的 `COMPUTE`，并说明你选用的舍入规则及其业务影响。只使用独立字段、`VALUE`、`MOVE`、`COMPUTE`、`DISPLAY` 和 `STOP RUN`；提交源码、编译命令、实际输出与核对算式。题目见 [`exercise.md`](./exercise.md)，本题不提供答案。

## 在企业中的位置

在银行批次里，`MOVE` 常见于字段间搬移、布局转换和输出准备，`COMPUTE` 常见于余额、费用、利息和控制总额。它们看着简单，却是金额正确性的落点：接收字段的小数位决定舍入、整数位容量决定溢出，任何一处与业务规则不符都会让余额与业务口径不一致，而程序未必报错。真实批次上线前至少要固定字段的币种、整数位、小数位、最大值、负数规则、舍入位置和超限策略，并用独立算例或控制总额核对。

本课只证明“同一笔利息按不同规则得到不同结果，期末余额随之相差 `0.01`”，还没有做出任何接受/拒绝判断：条件分支从第 04 课开始，用同一批金额字段决定交易是否被接受；文件输入从第 15 课开始，让金额来自真实交易文件而不是常量；溢出与失败上报在第 26 课统一处理；整条金额链最终在第 32 课的对账项目里与账户主档核对。

## 参考资料

- [GnuCOBOL Programmer's Guide：Arithmetic Expressions](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Arithmetic-Expressions)
- [GnuCOBOL Programmer's Guide：COMPUTE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#COMPUTE)
- [GnuCOBOL Programmer's Guide：Simple MOVE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Simple-MOVE)
- [GnuCOBOL Programmer's Guide：ROUNDED](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#ROUNDED)
- [GnuCOBOL Programmer's Guide：ON SIZE ERROR / NOT ON SIZE ERROR](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#ON-SIZE-ERROR-_002b-NOT-ON-SIZE-ERROR)
- 仓库课程主页：[README.md](../../README.md)
