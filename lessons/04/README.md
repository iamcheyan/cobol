# 第 04 课：IF 条件判断

> 状态：课程草稿。目录已确认；源码为 102 行固定格式，适用于 GnuCOBOL 3.2.0。

## 一、课程目标

学完本课后，你可以：

- 使用关系条件比较数值和字符字段。
- 用 `IF`、`ELSE`、`END-IF` 写出明确的接受与拒绝路径。
- 用嵌套条件按顺序执行金额下限、上限和账户状态检查。
- 解释零、最大金额边界及无效状态如何影响结果。
- 用显式作用域避免 `ELSE` 与错误的 `IF` 关联。

## 二、条件判断概念

### IF 选择执行路径

`IF condition` 在条件为真时执行紧随其后的命令；`ELSE` 提供条件为假时的命令；`END-IF` 结束该 IF 的作用域。本例每个 IF 都写了对应的 `END-IF`，让三层嵌套和三个 `ELSE` 的归属清楚可见。

缩进是给人阅读的，编译器根据 COBOL 语句作用域判断分支。COBOL 的 `ELSE` 与最近一个尚未结束的 `IF` 关联。嵌套代码应使用 `END-IF`，不要依赖空格猜测范围；句点会结束当前句子并关闭尚未结束的语句作用域。

### 关系条件与边界

关系运算符包括 `=`、`<`、`>`、`<=` 和 `>=`。GnuCOBOL 对数值按实际代数值比较；字段显示出的前导零和符号不是比较逻辑。本例使用：

- `WS-TRANSACTION-AMOUNT <= ZERO`：零和负数都拒绝。
- `WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT`：只拒绝超过上限的金额，因此恰好等于上限仍可继续。
- `WS-ACCOUNT-STATUS = "A"`：只有状态字符为 `A` 才接受。

金额检查嵌套在账户状态检查之外。程序在第一个失败条件处输出拒绝原因，不再执行更深层检查。规则顺序会影响报出的原因，必须与业务契约一致。

### 与 Java / Python 的联系

Java 可用 `if`/`else if` 做类似判断；Python 使用 `if`/`elif`/`else`。COBOL 的 `END-IF` 明确标记条件语句结束。比较前要确认字段是数值还是文本：账户状态是字符；金额是带符号十进制数值。

## 三、示例程序

[`lesson.cob`](./lesson.cob) 共 102 行。它用固定数据判断一笔交易是否为正数、是否不超过 1000.00，以及账户是否有效。它不读用户输入或文件，也不修改余额。

### 数据定义

| 字段 | PIC / 初值 | 用途 |
|---|---|---|
| `WS-TRANSACTION-REFERENCE` | `X(12)` / `TXN-00000001` | 文本标识符，不参与金额运算 |
| `WS-ACCOUNT-STATUS` | `X(1)` / `A` | 账户状态，`A` 表示本例中的有效账户 |
| `WS-TRANSACTION-AMOUNT` | `S9(7)V99` / `125.50` | 带符号金额，可表达负数 |
| `WS-MAXIMUM-AMOUNT` | `9(7)V99` / `1000.00` | 非负金额上限，包含两位小数 |

金额字段使用独立前导符号，输出时可直接辨认正负。`V` 表示隐含小数点位置；两个金额字段具有相同的小数尺度。

### 过程逻辑逐步解析

1. `PROCEDURE DIVISION` 后先显示交易号、状态、金额和上限，方便核对当前固定样例。
2. 最外层 `IF WS-TRANSACTION-AMOUNT <= ZERO` 拒绝零及负金额。`ELSE` 只在金额为正时进入上限检查。
3. 第二层 `IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT` 拒绝超限金额。因为条件是严格大于，金额等于 `1000.00` 时条件为假并进入下一层。
4. 第三层 `IF WS-ACCOUNT-STATUS = "A"` 接受有效账户；`ELSE` 拒绝其他状态。
5. 各分支各自输出一条决定和原因。若金额和状态同时不合规，只报告先检查到的金额错误。
6. 按从内到外的顺序写出三个 `END-IF`，各自结束一个嵌套条件。末尾的 `STOP RUN.` 结束程序句子。

## 四、编译、运行与输出

输入来自 `WORKING-STORAGE` 的 `VALUE` 子句，没有键盘、文件或数据库输入。可在本课目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_04" lesson.cob
"$scratch_dir/lesson_04"
```

GnuCOBOL 3.2.0 的标准输出：

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0000125.50
上限金額=0001000.00
判定=ACCEPTED
理由=WITHIN_RULES
```

本工作区实测语法检查、编译和运行返回码均为 0；输出与上面一致。运行时标准错误另有系统警告 `Warning: program compiled against libxml 212 using older 209`，该警告不是 COBOL 程序输出，触发组件尚未定位。

## 五、修改练习（有答案）

在 `lesson.cob` 中分别调整金额和状态，观察对应分支：

1. 金额为 `0.00`：拒绝，原因 `AMOUNT_NOT_POSITIVE`。
2. 金额为 `-0.01`：拒绝，原因 `AMOUNT_NOT_POSITIVE`。
3. 金额为 `1000.00`：接受；这是允许的最大边界。
4. 金额为 `1000.01`：拒绝，原因 `AMOUNT_OVER_LIMIT`。
5. 金额为 `50.00`，状态改为 `I`：拒绝，原因 `ACCOUNT_INACTIVE`。

每次只修改一个或一组明确的 `VALUE` 子句，重新编译运行，并比较输入与决定。第 1–5 项答案见 [`answer.md`](./answer.md)。

## 六、举一反三练习（无答案）

为转账增加单笔最低金额 `5.00` 和日限额 `5000.00`，并要求收款账户状态为 `A`。设计分支顺序，让程序报告首个失败原因。分别验证低于最低金额、等于最低金额、等于日限额、超过日限额以及非活动收款账户。说明每个比较运算符如何决定边界是否接受。

只用本课已学的字段、`IF`、`ELSE`、`END-IF`、`DISPLAY` 和 `STOP RUN`。提交源码、编译命令及实际输出；本题不提供答案。

## 七、企业实战补充

交易校验通常包含金额范围、账户状态、币种、授权额度和重复请求等规则。上线前要与产品及会计约定边界是否包含、拒绝优先级和错误代码；还要区分业务拒绝与系统故障。此例只演示三个本地规则，不负责账户授权、并发控制、重复检测、交易入账或持久化。

## 参考资料

- [GnuCOBOL Programmer’s Guide：IF](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#IF)
- [GnuCOBOL Programmer’s Guide：Relation Conditions](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Relation-Conditions)
- [GnuCOBOL Programmer’s Guide：Combined Conditions](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Combined-Conditions)
- [GnuCOBOL Programmer’s Guide：Use of Periods](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Use-of-Periods)
- [GnuCOBOL Programmer’s Guide：END-verb Constructs](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Use-of-VERB_002fEND_002dVERB-Constructs)
