# 第 04 课：IF 条件判断——为一笔交易分出接受与拒绝

夜间批次对每笔到达的交易都要先给出“接受”或“拒绝”，而且必须能说清是**哪一条规则**导致的拒绝。本课把一笔交易样例固定在程序内，用三层嵌套 `IF` 依次判定“金额必须为正 → 金额不得超过单笔上限 → 账户状态必须有效”，并只输出**最先命中**的那条失败原因。

## 为什么现在学

第 [02](../02_data-types/README.md) 课让你能用 `PIC` 描述账户号、状态和金额，第 [03](../03_move-compute/README.md) 课让你能算出一个结果。这两个能力还缺一件东西：**按数据本身决定走哪条路**。目前程序只会从头执行到尾，无法表达“这笔金额不合规就不处理”，也无法回答“上限是包含还是排除 1000.00 这个值”。本课补上关系条件和 `IF` / `ELSE` / `END-IF`，并要求你能追踪嵌套里每个 `ELSE` 到底属于哪个 `IF`——这是后面所有业务分流的写法基础。

## 本课完成后的能力与边界

学完本课后，你可以：

- 用 `=`、`<`、`>`、`<=`、`>=` 比较数值字段和字符字段，并说明端点值落在接受侧还是拒绝侧。
- 用 `IF` / `ELSE` / `END-IF` 为每个条件写出显式的接受与拒绝路径，不靠缩进或句点猜测 `ELSE` 的归属。
- 按固定优先顺序嵌套三层判定，说明为什么这样只会输出**一个**拒绝原因，以及换成三个平级 `IF` 会同时命中多条规则。
- 预判并核对边界样例：`0.00`、`-0.01`、`0.01`、`1000.00`、`1000.01` 与状态非 `A` 时的判定结果。
- 区分业务拒绝与系统故障：本课所有拒绝路径的退出码仍是 `0`。

边界：本课不读终端、文件或数据库，样例值写在 `WORKING-STORAGE` 的 `VALUE` 子句里；只有一笔交易，不修改余额、不做计数或汇总；不处理舍入与算术溢出（第 [03](../03_move-compute/README.md) 课已提示，第 [26](../26_error-handling/README.md) 课系统处理）；不做交易类型分类（第 [05](../05_evaluate/README.md) 课）和多笔批次（第 [08](../08_control-flow-practice/README.md) 课）。本课也不实现账户授权、并发控制、重复请求检测或持久化，这些都不是本课要证明的东西。

## 运行环境

- GnuCOBOL 3.2.0，使用默认方言（不加 `-std=cobol85`），源文件为固定格式。
- Linux 终端，无需数据库、附加工具或第三方库。
- 命令在本课目录 `lessons/04_if-conditions/` 下执行；因为源码路径写的是 `lesson.cob`，换目录执行要自己调整路径。

## 知识讲解

### 关系条件：比较的是值，不是显示形状

关系条件写出两个操作数之间的关系，`=`、`<`、`>`、`<=`、`>=` 都可用，`THEN` 是可选词，写不写都不影响结果。GnuCOBOL 对两个数值操作数按**实际代数值**比较，跟字段的 `PIC` 位数、是否带符号、`USAGE` 无关；字符字段之间则按字符集逐字符比较，短的一方在右侧补空格。本课用到三个关系条件：

```cobol
WS-TRANSACTION-AMOUNT <= ZERO
WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
WS-ACCOUNT-STATUS = "A"
```

第一条 `<= ZERO` 对零和负数都为真；第二条 `> WS-MAXIMUM-AMOUNT` 只有严格超过上限才为真；第三条 `= "A"` 是字符比较，`a`、空格和其他字符都为假。

关键点：**端点属于哪一侧完全由运算符决定。** `<=` 让 `0.00` 落进拒绝侧，`>` 让 `1000.00` 落在接受侧。把 `<=` 写成 `<`（`0.00` 就会被接受），或把 `>` 写成 `>=`（`1000.00` 就会被拒绝），都会改变边界行为，所以边界值必须和运算符一起评审。

字符比较是精确比较：`WS-ACCOUNT-STATUS` 是 `X` 类型，`a`（小写）、空格和 `I` 都不等于 `A`，全部落到拒绝分支。如果业务上需要大小写归一化，那属于接口契约，必须显式写出，不能默认 COBOL 会自动处理。

### IF / ELSE / END-IF 与作用域归属

`IF` 在条件为真时执行紧随的语句，`ELSE` 提供为假时的语句，`END-IF` 明确结束这个条件语句的作用域。缩进只给人看，编译器按作用域判断分支；**一个 `ELSE` 归属于最近一个尚未结束的 `IF`**。本课三个 `IF` 都写了对应的 `END-IF`，从最内层开始向外闭合，这样三个 `ELSE` 的归属在源码上一眼可见，不依赖空格或句点。

顺带一个容易踩的坑：句点会结束整个句子，同时关闭尚未结束的语句作用域。本课最后一条 `STOP RUN.` 才是句点；开头的 4 条 `DISPLAY` 之间**没有**句点，它们属于同一个句子里的多条语句，因此仍然按书写顺序依次执行。

### 嵌套顺序决定报出的拒绝原因

三条规则的嵌套顺序就是拒绝原因的优先级：

```text
金额 <= 0            → AMOUNT_NOT_POSITIVE     （最外层，先判）
  否则 金额 > 上限   → AMOUNT_OVER_LIMIT
     否则 状态 = A   → 接受
        否则          → ACCOUNT_INACTIVE      （最内层，最后判）
```

程序在第一个为真的失败条件处输出原因就结束，深层检查不再执行。所以一笔金额为 `-5.00`、状态为 `I` 的交易只会报 `AMOUNT_NOT_POSITIVE`，不会同时报状态问题。这正是为什么要嵌套：如果写成三个平级 `IF`，两个失败条件都会各自命中一次，程序会输出两条互相矛盾的原因，读者也无法判断哪条是真正的业务结论。优先顺序属于业务契约，必须和产品、会计确认后才能改。

### 与 Java / Python 的区别

Java 可以用 `if` / `else if` 表达同样的分支，Python 用 `if` / `elif` / `else`。差别在于 COBOL 用 `END-IF` 显式标记语句结束，并且 `ELSE` 按“最近的未结束 `IF`”绑定而不按缩进绑定。比较前同样要确认类型：账户状态是文本，金额是带符号的十进制数值。

COBOL 也支持用 `AND` / `OR` 把多个条件合成一个复合条件。本课不这么做，原因是嵌套结构能把每条规则的优先级直接写在源码里，便于本节练习要求的逐层追踪；复合条件请在读到相应语法后再使用。

### 关于输出文本的语言

仓库约定：源文件注释与 README 讲解使用中文，程序运行输出的业务文本沿用日文。判定所需的全部信息都在标准输出的 `key=value` 行里，两个关键值是 `判定=` 和 `理由=`，中文对照见下一节。

## 完整示例源码

完整源码见 [`lesson.cob`](./lesson.cob)，按固定格式编写（第 7 列指示符、Area A 从第 8 列、Area B 从第 12 列起，程序文本不越过第 72 列）。

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. IF04.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
       01 WS-MAXIMUM-AMOUNT PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
           DISPLAY "取引参照番号="
               WS-TRANSACTION-REFERENCE
           DISPLAY "口座状態=" WS-ACCOUNT-STATUS
           DISPLAY "取引金額=" WS-TRANSACTION-AMOUNT
           DISPLAY "上限金額=" WS-MAXIMUM-AMOUNT
           IF WS-TRANSACTION-AMOUNT <= ZERO
               DISPLAY "判定=REJECTED"
               DISPLAY "理由=AMOUNT_NOT_POSITIVE"
           ELSE
               IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
                   DISPLAY "判定=REJECTED"
                   DISPLAY "理由=AMOUNT_OVER_LIMIT"
               ELSE
                   IF WS-ACCOUNT-STATUS = "A"
                       DISPLAY "判定=ACCEPTED"
                       DISPLAY "理由=WITHIN_RULES"
                   ELSE
                       DISPLAY "判定=REJECTED"
                       DISPLAY "理由=ACCOUNT_INACTIVE"
                   END-IF
               END-IF
           END-IF
           STOP RUN.
```

上面省略了源码中的注释行。源码里的注释只说明规则和契约（金额必须为正、上限含端点、只报首个失败原因），不逐条复述 `DISPLAY` 的文本。

## 数据与规则

样例交易完全固定在程序内，**没有外部输入**，也没有输入夹具和结果文件。参与判断的四个值：

| 字段 | `PIC` / 存储字节 | 初值 | 作用 |
|---|---|---|---|
| `WS-TRANSACTION-REFERENCE` | `X(12)` / 12 字节 | `TXN-00000001` | 交易标识，只回显，不参与判断 |
| `WS-ACCOUNT-STATUS` | `X(1)` / 1 字节 | `A` | 账户状态，只有 `A` 被本课视为有效 |
| `WS-TRANSACTION-AMOUNT` | `S9(7)V99`，`SIGN IS LEADING SEPARATE CHARACTER` / 10 字节 | `125.50` | 带符号金额，从下界一侧参与判断 |
| `WS-MAXIMUM-AMOUNT` | `9(7)V99` / 9 字节 | `1000.00` | 单笔金额上限，含端点 |

金额字段的 10 字节 = 1 个独立前导符号位 + 7 位整数 + 2 位小数；`V` 是隐含小数点，**不占存储**，只在 `DISPLAY` 时按位置渲染出来。所以存储是 10 字节，而屏幕上看到的 `+0000125.50` 是 11 个字符。上面四个字节数是本机用 `FUNCTION LENGTH` 实测得到的，可以作为后续课程核对记录布局的基准。本课没有币种字段，按演示约定金额视为两位小数的“元”，不涉及汇率与舍入。

规则与边界政策：

| 规则 | 实现条件 | 政策 |
|---|---|---|
| 金额必须为正 | `WS-TRANSACTION-AMOUNT <= ZERO` → 拒绝 | 零与负金额都拒绝；`0.01` 起接受 |
| 单笔上限 | `WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT` → 拒绝 | 上限**含端点**，等于 `1000.00` 接受，`1000.01` 起拒绝 |
| 账户状态 | `WS-ACCOUNT-STATUS = "A"` 才接受 | 只有精确的 `A` 有效；`I`、`a`、空格和其他字符都报同一个理由 |

已由代码校验的条件就是上表三条。**没有**校验的：交易参考号的格式与唯一性（本课只回显）、状态码的具体含义（程序不区分 `I` 表示什么）、金额上限本身的来源（它是本课的演示常量）。前提说明：`WS-MAXIMUM-AMOUNT` 与三个样例值都是教学演示数据，不代表任何真实业务政策或监管限额。

## 边界值在何处分叉

所有拒绝路径都是业务拒绝，退出码仍为 `0`；程序没有系统故障分支。下表每一行都在本机实际编译运行过：

| 金额 | 状态 | 在哪个比较处分叉 | `判定=` | `理由=` |
|---|---|---|---|---|
| `125.50`（原始初值） | `A` | 三个条件全部通过 | `ACCEPTED` | `WITHIN_RULES` |
| `0.00` | `A` | 第 1 层为真 | `REJECTED` | `AMOUNT_NOT_POSITIVE` |
| `-0.01` | `A` | 第 1 层为真 | `REJECTED` | `AMOUNT_NOT_POSITIVE` |
| `0.01` | `A` | 紧贴下界，`<= ZERO` 为假 | `ACCEPTED` | `WITHIN_RULES` |
| `1000.00` | `A` | 第 2 层为假（端点被包含） | `ACCEPTED` | `WITHIN_RULES` |
| `1000.01` | `A` | 第 2 层为真 | `REJECTED` | `AMOUNT_OVER_LIMIT` |
| `125.50` | `I` | 第 3 层为假 | `REJECTED` | `ACCOUNT_INACTIVE` |
| `-5.00` | `I` | 第 1 层为真，第 3 层**未执行** | `REJECTED` | `AMOUNT_NOT_POSITIVE` |

谁决定哪条分叉：

| 观察目标 | 决定它的比较 | 结果 |
|---|---|---|
| 下界 | `AMOUNT <= ZERO` | `0.00` 与负数拒绝，`0.01` 起接受 |
| 上限 | `AMOUNT > MAXIMUM` | 严格大于才拒绝，等于 `1000.00` 被包含 |
| 状态 | `STATUS = "A"` | 仅精确 `A`；`a`、空格、`I` 都拒绝 |
| 报哪个原因 | 三层嵌套顺序 | 只报最先命中的失败规则 |

## 源码阅读路径

1. `WORKING-STORAGE` 的四个字段：先确认状态是 `X(1)` 文本、金额是带独立符号的数值，这正是后面比较行为不同的原因。
2. `PROCEDURE DIVISION` 之后 4 条 `DISPLAY`：把参与判断的输入值先打印出来，便于把输入和判定对照。它们之间没有句点，属于同一句子。
3. 最外层 `IF WS-TRANSACTION-AMOUNT <= ZERO`：`ELSE` 只兜住“金额为正”的情况，因此错误的金额不会继续检查上限和状态。
4. 第二层 `IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT`：注意用的是严格大于，端点因此被包含。
5. 第三层 `IF WS-ACCOUNT-STATUS = "A"`：最内层的 `ELSE` 才是状态拒绝。
6. 三个 `END-IF` 由内向外闭合；最后 `STOP RUN.` 结束程序。注意整段只有这一个句点。

## 运行与观察

**输入：** 无。四个值全部来自 `lesson.cob` 的 `VALUE` 子句，不读键盘、文件或数据库，所以判定会**固定复现**——这一点和[第 15 课](../15_sequential-file-read/README.md)之后的文件课不同。

**命令及作用：**

```sh
mkdir -p build                                   # 先建输出目录，否则 -o 会因目录不存在而失败
cobc -fsyntax-only lesson.cob                    # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_04 lesson.cob      # 编译并生成可执行文件
./build/lesson_04                                # 运行程序，判定结果写到标准输出
echo $?                                          # 查看上一条命令的退出码
rm -rf build                                     # 清理编译产物
```

四条命令证明的事情不同：`-fsyntax-only` 只说明源码能通过语法解析，不生成也不运行程序；`-x` 要求生成可执行文件，`-o` 指定产物路径，返回码 `0` 且无诊断才表示编译通过；运行可执行文件才能观察到判定结果；`rm -rf build` 只是删除编译产物，本课不产生业务数据文件，所以清理不会丢数据。

**预期结果（原始初值）：**

| 观察项 | 预期值 |
|---|---|
| `cobc -fsyntax-only` 退出码 | `0` |
| `cobc -x -Wall` 退出码 | `0`，无编译诊断 |
| 标准输出 | 下面 6 行 |
| 进程退出码（`echo $?`） | `0` |
| 生成文件 | 仅 `build/lesson_04` |

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0000125.50
上限金額=0001000.00
判定=ACCEPTED
理由=WITHIN_RULES
```

输出行与中文对照：`取引参照番号` = 交易参考号，`口座状態` = 账户状态，`取引金額` = 交易金额，`上限金額` = 单笔金额上限，`判定` = 判定结果，`理由` = 判定理由。4 个 `理由` 取值：`WITHIN_RULES` 表示三条规则全部通过，`AMOUNT_NOT_POSITIVE` 表示金额不是正数，`AMOUNT_OVER_LIMIT` 表示金额超过单笔上限，`ACCOUNT_INACTIVE` 表示账户状态不是 `A`。判断程序行为时以标准输出的 `判定=` / `理由=` 为准，README 的中文说明负责解释这些取值。

**实际观察到的环境细节：** 在本工作区运行 `./build/lesson_04` 时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境链接库版本差异产生的警告，不是本程序的业务输出，触发组件尚未定位。程序的业务输出全部在标准输出，退出码为 `0`。

### 证据来源与验证范围

本课 README 中的预期输出、`边界值在何处分叉` 一节的 8 行结果、以及练习答案里的每个场景，都在本工作区用 `cobc 3.2.0` 实际编译运行核对过：`-fsyntax-only` 与 `-x -Wall` 返回码均为 `0`、无编译诊断，运行退出码均为 `0`，标准输出与文档逐字节一致。字段的 12 / 1 / 10 / 9 字节由单独的 `FUNCTION LENGTH` 程序实测。知识讲解里“把 `<=` 改成 `<`，`0.00` 会被接受”与“把 `>` 改成 `>=`，`1000.00` 会被拒绝”两个说法也各改一处运算符实测过（结果分别为 `ACCEPTED` 与 `AMOUNT_OVER_LIMIT`）。**未验证**的场景：多笔交易、并发、超出 `S9(7)V99` 容量的金额（本课不处理算术溢出），以及任何文件或数据库输入——本课没有这些路径。

## 修改练习

从原始 [`lesson.cob`](./lesson.cob) 开始，只改 `WS-TRANSACTION-AMOUNT` 和 `WS-ACCOUNT-STATUS` 的 `VALUE` 子句，观察到接受与拒绝在边界处分叉。七个场景的输入与预期判定：

| 场景 | 金额 `VALUE` | 状态 `VALUE` | `判定=` | `理由=` |
|---|---|---|---|---|
| 1 | `0.00` | `"A"` | `REJECTED` | `AMOUNT_NOT_POSITIVE` |
| 2 | `-0.01` | `"A"` | `REJECTED` | `AMOUNT_NOT_POSITIVE` |
| 3 | `0.01` | `"A"` | `ACCEPTED` | `WITHIN_RULES` |
| 4 | `1000.00` | `"A"` | `ACCEPTED` | `WITHIN_RULES` |
| 5 | `1000.01` | `"A"` | `REJECTED` | `AMOUNT_OVER_LIMIT` |
| 6 | `125.50`（保持初值） | `"I"` | `REJECTED` | `ACCOUNT_INACTIVE` |
| 7 | `-5.00` | `"I"` | `REJECTED` | `AMOUNT_NOT_POSITIVE` |

每个场景都要从原始源码重新开始，避免上一个场景的值影响下一个。完整题目（含基线、改动约束、重编译运行命令、逐场景预期输出和需要回答的问题）见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

## 举一反三练习

为转账校验设计规则：单笔最低金额 `5.00`、单笔最高金额 `5000.00`，并要求收款账户状态为 `A`。自己选择金额字段的 `PIC`（两位小数必须；是否需要符号由你判断并说明）、嵌套顺序和拒绝原因文本，依次验证低于最低金额、恰好等于最低金额、恰好等于最高金额、超过最高金额、以及非活动收款账户分别走哪条分支，并说明每个比较运算符把端点放在接受侧还是拒绝侧。题目见 [`exercise.md`](./exercise.md)，本题不提供答案。

限制：只使用本课已学的字段声明、`VALUE`、关系条件、`IF` / `ELSE` / `END-IF`、`DISPLAY` 和 `STOP RUN`；不要使用循环、段落、表格或 `EVALUATE`。你需要自己决定边界是否包含，并说明用什么值验证。

## 在企业中的位置

真实批次里，交易校验通常还包含币种、账户授权额度、重复请求、交易时间段等规则，并且必须约定边界是否包含、拒绝优先级和错误代码。上线作业还要把业务拒绝和系统故障分开处理：业务拒绝是一次判定结果，系统故障要影响返回码并触发重跑或告警。

本课的产物就是这笔判定的“接受 / 拒绝 + 原因”，但它只演示了三个本地规则，且全部输入固定在程序内。它不负责账户授权、并发控制、重复检测、过账或持久化。承接关系：交易类型分类见[第 05 课](../05_evaluate/README.md)，多笔交易与接受 / 拒绝计数见[第 08 课](../08_control-flow-practice/README.md)，错误分类与返回码见[第 26 课](../26_error-handling/README.md)，真实的文件输入从[第 15 课](../15_sequential-file-read/README.md)开始。

## 参考资料

- [GnuCOBOL Programmer’s Guide：IF](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#IF)
- [GnuCOBOL Programmer’s Guide：Relation Conditions](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Relation-Conditions)
- [GnuCOBOL Programmer’s Guide：END-verb Constructs](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Use-of-VERB_002fEND_002dVERB-Constructs)
- [GnuCOBOL Programmer’s Guide：Use of Periods](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Use-of-Periods)
- [课程总目录](../DIRECTORY.md)
- [仓库课程主页](../../README.md)
