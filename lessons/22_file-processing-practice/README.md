# 第 22 课：综合练习——排序、校验、匹配与结果写出

> 示例使用 GnuCOBOL 3.2.0 默认方言与固定格式。

## 一、课程目标

学完本课后，你可以：

- 用 `SORT`、`INPUT PROCEDURE`、`RELEASE` 和 `RETURN` 处理未排序交易。
- 检查行记录长度、文件状态、交易类型和金额字段。
- 将升序交易与升序账户主档顺序匹配。
- 分别写出已接受和已拒绝交易，并保留孤立主档账户清单计数。
- 用文件状态和 `RETURN-CODE` 表达批次成功或失败。
- 说明排序键唯一、输入布局固定、输出文件会被覆盖等运行前提。

本课把第 12–20 课的顺序文件、定长字段和匹配逻辑，与第 21 课的 SORT 输入/输出过程连成一个可运行的小型批次。它演示数据流和错误处置，不计算账户新余额，也不代表完整的生产账务控制。

## 二、输入与输出记录

程序从当前工作目录读取 `transactions-unsorted.txt` 和 `accounts.txt`。它在当前目录创建 `accepted.txt`、`rejected.txt`；两个输出都使用 `OPEN OUTPUT`，所以每次运行会覆盖同名旧文件。请在临时目录运行。

| 文件 | 字段顺序 | 字段宽度 | 记录宽度 |
|---|---|---:|---:|
| `transactions-unsorted.txt` | 账户号、类型、金额分 | 10 + 1 + 9 | 20 字符 |
| `accounts.txt` | 账户号、客户号、余额分 | 10 + 8 + 9 | 27 字符 |
| `accepted.txt` | 账户号、客户号、类型、金额分 | 10 + 8 + 1 + 9 | 28 字符 |
| `rejected.txt` | 账户号、原因、类型、金额分 | 10 + 10 + 1 + 9 | 30 字符 |

金额字段使用九位数字表示 `PIC 9(7)V99`，`V` 不占物理字符。例如 `000012550` 表示 125.50。输入文件每行是一条记录，没有分隔符；换行符不属于 FD 记录宽度。

夹具中的账户主档按账户号升序排列；交易输入刻意打乱顺序。主档与交易的账户号必须唯一，且两边按相同的十字符排序规则比较。夹具包含匹配交易、缺少主档的交易、错误金额和没有交易的主档账户。

## 三、批次如何处理记录

1. 主程序调用 `SORT`，按 `SD-TRANSACTION-ACCOUNT` 升序排序。
2. `1000-LOAD-TRANSACTIONS` 打开交易输入。每行先检查实际宽度；只有 20 字符的记录才 `RELEASE` 到排序工作文件。
3. `2000-RECONCILE-TRANSACTIONS` 打开账户主档和两个结果文件，然后读入第一条主档记录。
4. 输出过程逐条 `RETURN` 排序后的交易。若主档键较小，程序把该主档账户计为 `MASTER_ONLY` 并读取下一条主档记录；相同键进入交易验证；若交易键较小或主档已结束，交易记为 `NO_ACCOUNT`。
5. 有主档匹配时，交易类型必须是 `D` 或 `C`，金额必须为数字。有效记录写入 `accepted.txt`；无效记录写入 `rejected.txt`。
6. 交易处理结束后，剩余主档账户逐条计为 `MASTER_ONLY`。程序关闭已打开的文件并显示计数；检测到 I/O、记录宽度或排序错误时设置非零返回码。

拒绝原因固定为十字符：`NO_ACCOUNT`、`BAD_TYPE__`、`BAD_AMOUNT`。缺少主档优先判为 `NO_ACCOUNT`，因此无主档交易的类型或金额错误不会再分类为字段错误。

## 四、编译、运行和预期结果

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_22" lesson.cob
cp accounts.txt transactions-unsorted.txt "$scratch_dir/"
(cd "$scratch_dir" && ./lesson_22)
```

标准输出：

```text
已接受 账户号=A000000001
已接受 账户号=A000000003
已拒绝 账户号=A000000004 REASON=NO_ACCOUNT
已接受 账户号=A000000005
已拒绝 账户号=A000000006 REASON=NO_ACCOUNT
已拒绝 账户号=A000000007 REASON=BAD_AMOUNT
仅主档账户 账户号=A000000009
输入记录数=006 排序记录数=006
接受记录数=003
拒绝记录数=003 仅主档记录数=001
```

`accepted.txt` 的完整内容：

```text
A000000001C0001001D000012550
A000000003C0001003C000000200
A000000005C0001005D000004000
```

`rejected.txt` 的完整内容：

```text
A000000004NO_ACCOUNTD000007500
A000000006NO_ACCOUNTX000000100
A000000007BAD_AMOUNTD00000X001
```

语法检查、`-Wall` 编译和夹具运行已实际验证。也已验证练习的两项输出变化、错误交易类型、空交易文件、空主档、错误交易宽度、缺少交易文件及接受文件无法打开时的非零退出。当前环境的 `libxml` 版本警告（若出现）写到标准错误，不属于程序输出。

## 五、错误处理和边界

- 交易行宽必须为 20，主档行宽必须为 27；多余或缺失字符会中止批次并返回非零状态。
- 交易类型只允许大写 `D` 和 `C`；金额字段必须全为数字。
- 文件 OPEN、READ、WRITE、CLOSE 状态及 SORT/RELEASE/RETURN 结果都会参与错误判断。EOF 状态 `10` 是正常结束。
- 两个输出文件使用 `OPEN OUTPUT`。目录权限或文件系统错误可能使打开/写入失败；失败批次不能视为成功交付。
- 主档必须按账户号升序输入。程序当前不扫描并验证主档是否有序，也不检测重复键；重复交易账户不受支持。
- 输入行数、排序行数和分类计数使用三位数字字段，微型夹具最多按 999 条计数；生产批次应根据最大输入规模选择字段宽度。
- 本例只做分类与写出，不累计余额、不实施借贷金额规则，也不提供原子化双文件交付。真实账务批次还需明确定义重复键、回滚、批次标识和输出交付策略。

## 六、修改练习（有答案）

1. 在临时副本中，把交易账户 `A000000004` 改为主档中存在的 `A000000009`，保留交易类型和金额。重新运行，检查该交易进入接受文件、孤立主档计数变化，并逐行核对输出文件。
2. 在副本中把账户 `A000000007` 的金额从 `00000X001` 改为 `000000001`。重新运行，检查交易由拒绝变为接受，且余额主档记录仍用于匹配。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；操作步骤见 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

为夹具增加同一账户的第二笔有效交易。设计新的匹配规则，使主档记录可以匹配同一账户的多笔交易；定义输出排序、余额变更和拒绝政策，并用多笔交易、缺少账户及 EOF 边界验证。说明现有程序在哪个过程消费了主档，以及需要怎样改变状态推进。

本题不提供答案。不要把完整输入装入 `OCCURS` 表，也不要省略运行后的接受、拒绝文件内容。

## 八、企业实战补充

日终对账常见流程是标准化输入、排序、按键匹配、保留拒绝记录并生成控制计数。本课以独立输出文件展现这一链路。部署前还要定义输入签名与批次日期、重复记录策略、金额借贷规则、失败重跑和输出原子交付；这些控制不由本示例实现。

## 参考资料

- [GnuCOBOL Programmer’s Guide：File-Based SORT](https://superbol.eu/gnucobpg/chapter7.html#file-based-sort)
- [GnuCOBOL Programmer’s Guide：RELEASE](https://superbol.eu/gnucobpg/chapter7.html#release)
- [GnuCOBOL Programmer’s Guide：RETURN](https://superbol.eu/gnucobpg/chapter7.html#return)
- [GnuCOBOL Programmer’s Guide：LINE SEQUENTIAL](https://superbol.eu/gnucobpg/chapter5.html#organization-line-sequential)
- [GnuCOBOL Programmer’s Guide：SORT file description](https://superbol.eu/gnucobpg/chapter6.html#fileasort-description)
