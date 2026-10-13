# 第 02 课：数据类型与 PIC

> 状态：课程草稿。目录已确认；本课源码按 100–300 行约束制作。示例面向 GnuCOBOL 3.2.0，并使用固定格式。

## 一、课程目标

学完本课后，你可以：

- 读懂 `PIC A`、`PIC X`、`PIC 9`、重复次数、符号 `S` 和隐含小数点 `V`。
- 根据业务含义选择文本键、字母字段和数值字段。
- 解释 `VALUE` 如何给 `WORKING-STORAGE` 数据项提供程序初始值。
- 区分字段的业务含义、PIC 描述、存储表示和 `DISPLAY` 输出。
- 说明为什么 `PIC 9(8)` 看起来像日期，仍不能证明日期有效。

## 二、知识讲解

### 为什么要显式描述数据

批处理接收的数据往往来自 COBOL 文件、数据库或其他系统。两边必须对记录格式达成一致：客户号有几位、金额有几位小数、状态码占几个字符。COBOL 的数据描述把这份契约写在程序里，编译器和维护者都能检查字段的类别与宽度。

Java / Python 通常通过类、`String`、整数或 `Decimal` 等类型表达意图；COBOL 的 `PIC` 还直接描述字符/数字位置与小数尺度。它并不自动执行业务校验：`PIC 9(8)` 不能保证八位数字是有效日期，`PIC X(12)` 也不能保证账户存在。

### 本课使用的 PIC 符号

- `A`：字母位置。本例用它描述客户姓名、客户类别和国家码。
- `X`：字母数字位置，可承载代码、标点和数字字符。本例把账户号、邮编、币种和批次号作为文本。
- `9`：数字位置。`9(4)` 等价于四个 `9`，适合本例的分行号、计数和日期数字字段。
- `S`：声明数值字段带符号。本例用 `SIGN LEADING SEPARATE CHARACTER` 让正负号以单独字符显示。
- `V`：声明数值的小数点位置。它不占存储位置；本机 GnuCOBOL 3.2.0 的 `DISPLAY` 会把隐含小数点呈现在输出中。
- 重复次数：`X(12)` 表示十二个 X 位置，`9(7)V99` 表示七个整数位和两个小数位。
- `VALUE`：在编译时给数据项设定初值。本课值是演示样例，不是运行时输入，也不代表字段已经通过业务校验。

本例没有声明 `USAGE COMP`、`COMP-3` 等存储格式，数值字段采用默认 DISPLAY 用法。不要仅凭 PIC 推断所有目标平台的二进制布局或字节数；具体物理表示与 `USAGE`、编译选项和平台有关。

### 银行业务里为什么要区分“号码”和“数值”

账户号、客户号、邮编和转账参考号即使由数字组成，也常是标识符而非数量。把 `0002046819` 定义为 `PIC X(10)` 能保留开头的零；对它做加减没有业务意义。分行交易笔数是数量，适合 `PIC 9(4)`。金额需要明确小数尺度，例如 `PIC 9(7)V99`。

常见误区：

- `PIC 9` 限定字段的数值类别与位置，但不代替对外部输入的校验。
- 日期用八个数字表示，只说明字段形状；仍要验证月份天数、闰年和业务日。
- `V` 不占一个存储字符，但 GnuCOBOL 的 DISPLAY 输出会呈现小数点；它不是“直接打印出原始字节”。
- `A`、`X`、`9` 的宽度不等于任意 `USAGE` 下的物理字节长度。
- `VALUE` 是程序初始值，不是数据库默认值或文件输入值。

## 三、完整示例源码

打开 [`lesson_02.cob`](./lesson_02.cob)。源码共 105 行，包含账户快照的平面数据项和输出语句；记录分组会在第 09 课学习。

## 四、源码逐步解析

1. 文件顶部注释说明示例范围：只声明数据并显示初值，不使用 MOVE、算术、分支、循环或文件输入。
2. `IDENTIFICATION DIVISION` 和 `PROGRAM-ID` 标识可执行程序；`DATA DIVISION`、`WORKING-STORAGE SECTION` 开始常驻工作数据声明。
3. 每个 `01 WS-...` 都是一个独立的基本数据项。本课暂时把字段平铺，避免提前引入 Group Item。
4. 每条字段声明都由名字、`PIC` 和 `VALUE` 构成。读法见下表：

| 字段 | PIC / 初值 | 业务含义与观察点 |
|---|---|---|
| `WS-ACCOUNT-KEY` | `X(12)` / `000123456789` | 文本键，保留前导零 |
| `WS-CUSTOMER-NAME` | `A(12)` / `ADA LOVELACE` | 字母型姓名 |
| `WS-CUSTOMER-TYPE` | `A(1)` / `P` | 字母类别代码 |
| `WS-ACCOUNT-STATUS` | `X(1)` / `A` | 可扩展状态字符；需另做业务判断 |
| `WS-BRANCH-CODE` | `9(4)` / `2048` | 四位数值分行码 |
| `WS-CURRENCY-CODE` | `X(3)` / `USD` | 文本币种码 |
| `WS-OPEN-DATE-DIGITS` | `9(8)` / `20261013` | 日期数字形状，不验证日历 |
| `WS-CUSTOMER-NUMBER` | `X(10)` / `0002046819` | 客户标识，前导零是有效字符 |
| `WS-PRODUCT-CODE` | `X(4)` / `SAV1` | 混合字符产品码 |
| `WS-LEDGER-BALANCE` | `9(7)V99` / `125000.75` | 七位整数与两位小数 |
| `WS-AVAILABLE-BALANCE` | `9(7)V99` / `123500.25` | 与账面余额相同尺度 |
| `WS-OVERDRAFT-LIMIT` | `9(7)V99` / `2500.00` | 非负额度样例 |
| `WS-LAST-CREDIT` | `S9(7)V99` / `1250.50` | 带单独前导符号的正金额 |
| `WS-LAST-DEBIT` | `S9(7)V99` / `-75.25` | 带单独前导符号的负金额 |
| `WS-INTEREST-RATE` | `9(2)V9(4)` / `0.0125` | 四位小数的利率样例 |
| `WS-FEE-RATE` | `9(2)V9(4)` / `0.0030` | 同尺度费用率 |
| `WS-MONTHLY-TXN-COUNT` | `9(4)` / `18` | 月交易笔数，输出保留字段宽度 |
| `WS-LAST-BATCH-SEQ` | `9(6)` / `521` | 六位批次序号 |
| `WS-STATEMENT-DAY` | `9(2)` / `25` | 对账单日数字 |
| `WS-POSTAL-CODE` | `X(9)` / `00100-200` | 含前导零和连字符的代码 |
| `WS-COUNTRY-CODE` | `A(2)` / `JP` | 两字母国家码 |
| `WS-TRANSFER-REF` | `X(15)` / `TRF-20261013-01` | 混合字符参考号 |
| `WS-BATCH-ID` | `X(14)` / `BATCH-20261013` | 批次标识 |
| `WS-CUSTOMER-INITIAL` | `A(1)` / `A` | 单字母首字母 |
| `WS-LANGUAGE-CODE` | `A(2)` / `EN` | 两字母语言码 |

5. `PROCEDURE DIVISION` 后的 `DISPLAY` 按源码顺序输出字段标签和值；没有段落或循环，符合当前课程进度。
6. GnuCOBOL 3.2.0 的实际输出把 `V` 的小数点显示出来，例如 `125000.75`；`V` 仍不占一个存储字符位置。
7. `STOP RUN` 结束程序。程序运行期间没有读取外部数据或改变字段初值。

## 五、运行输入与输出

本例没有标准输入、文件或数据库输入。`VALUE` 提供所有样例数据。

从本课目录运行；可执行文件放临时目录，脚本退出时删除，不在课程目录留下构建产物：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson_02.cob
cobc -x -Wall -o "$scratch_dir/lesson_02" lesson_02.cob
"$scratch_dir/lesson_02"
```

GnuCOBOL 3.2.0 的标准输出：

```text
ACCOUNT FIELD DATA TYPES
Text keys preserve their declared characters:
ACCOUNT-KEY=000123456789
CUSTOMER-NAME=ADA LOVELACE
CUSTOMER-TYPE=P
ACCOUNT-STATUS=A
BRANCH-CODE=2048
CURRENCY-CODE=USD
OPEN-DATE-DIGITS=20261013
CUSTOMER-NUMBER=0002046819
PRODUCT-CODE=SAV1
Numeric account amounts and rates:
LEDGER-BALANCE=0125000.75
AVAILABLE-BALANCE=0123500.25
OVERDRAFT-LIMIT=0002500.00
LAST-CREDIT=+0001250.50
LAST-DEBIT=-0000075.25
INTEREST-RATE=00.0125
FEE-RATE=00.0030
MONTHLY-TXN-COUNT=0018
LAST-BATCH-SEQ=000521
STATEMENT-DAY=25
Other account reference fields:
POSTAL-CODE=00100-200
COUNTRY-CODE=JP
TRANSFER-REF=TRF-20261013-01
BATCH-ID=BATCH-20261013
CUSTOMER-INITIAL=A
LANGUAGE-CODE=EN
```

本工作区执行时，语法检查与编译返回码均为 0，程序返回码为 0，标准输出与上面一致。运行时标准错误另有系统警告 `Warning: program compiled against libxml 212 using older 209`；这条警告不是 COBOL 程序输出，触发组件尚未定位。

## 六、修改练习（有答案）

1. 把分行号从 `2048` 改为 `3107`。
2. 把币种码从 `USD` 改为 `EUR`。
3. 把客户号改成 `0000000042`。保留 `PIC X(10)`，观察前导零。

按运行命令重新编译。比较输出中对应的三行，其他字段应保持不变。

## 七、举一反三练习（无答案）

为保险保单建立平面数据字段目录：保单号（含前导零）、投保人姓名、币种、保额、保费、保单生效日和状态码。为每个字段选择 `PIC` 和长度，给出样例初值，并说明哪些字段是标识符、哪些字段是数量/金额、哪些内容仍需要业务校验。

只提交源码、选择理由、实际编译命令和输出；不要用未学过的 Group Item、MOVE、条件或循环。

## 八、企业实战补充

在银行接口中，字段定义常常就是文件布局和下游接口契约的一部分。账户标识必须保留前导零，金额必须明确小数位，日期数字必须经过日历校验，状态码必须核对业务允许值。错误的 PIC 可能造成截断、错位或接口解释差异；但单靠 PIC 不能证明外部文件或数据库值符合业务规则。

## 参考资料

- [GnuCOBOL Programmer’s Guide：PICTURE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PICTURE)
- [GnuCOBOL Programmer’s Guide：VALUE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#VALUE)
- [GnuCOBOL Programmer’s Guide：SIGN IS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SIGN-IS)
- 仓库现有课程入口：[course/README.md](../../../README.md)
