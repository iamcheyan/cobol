# 第 14 课：账户与交易匹配综合练习

> 状态：课程草稿。目录已确认；示例源码 171 行固定格式，适用于 GnuCOBOL 3.2.0 默认方言。

## 一、课程目标

将第 09–13 课的层级记录、`REDEFINES`、`OCCURS` 表格、索引和 `SEARCH ALL` 组合起来，完成一个内存中的小型账户交易批次。程序逐笔查找账户并更新余额；转账在同时找到来源账户和目标账户且余额足够后才更新两边。

## 二、数据布局

[`lesson_14.cob`](./lesson_14.cob) 有两个主要数据结构：

- 账户主档是三项 OCCURS 表格。每个账户组包含账户号和余额。账户号唯一，表格实际按 `ASCENDING KEY` 声明的账户号排序，并由 `INDEXED BY` 提供搜索索引。
- 交易表包含四项。每项有交易类型和 27 字节负载。存款视图包含账户号、金额和参考号；转账视图以 `REDEFINES` 复用同一空间，包含来源账户、目标账户和金额。两个视图在本例中占用相同长度。

类型 `D` 解释为存款视图，类型 `T` 解释为转账视图。`REDEFINES` 不转换数据；交易类型决定哪些字段有意义。

## 三、处理流程

1. 主段落先装入账户主档和交易表，再按顺序处理四笔交易。
2. `SEARCH ALL` 使用账户号查找账户。`ASCENDING KEY` 只是声明要求；装载的数据也必须真实按键排序，且键不能重复。
3. 存款只在找到目标账户时入账。
4. 转账先查找来源账户并保存其表索引，再查找目标账户。仅当两者都存在且来源余额足够时才扣款并入账；未找到目标账户或余额不足时，两边余额都不变。
5. 报告段落逐项显示最终余额和已处理、入账、拒绝笔数。

样例四笔交易依次为：给 `0001234567` 存入 `125.50`；向 `0007654321` 转入 `40.00`；给 `0002468101` 存入 `75.00`；尝试向不存在的 `0009999999` 转入 `20.00`。最后一笔拒绝，来源余额不变。

## 四、编译、运行和预期输出

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson_14.cob
cobc -x -Wall -o "$scratch_dir/lesson_14" lesson_14.cob
"$scratch_dir/lesson_14"
```

GnuCOBOL 3.2.0 的程序标准输出：

```text
BATCH=START ACCOUNTS=3 TRANSACTIONS=4
TXN=1 TYPE=D
RESULT=POSTED DEPOSIT ACCOUNT=0001234567 AMOUNT=00125.50
TXN=2 TYPE=T
RESULT=POSTED TRANSFER SOURCE=0001234567 TARGET=0007654321
TXN=3 TYPE=D
RESULT=POSTED DEPOSIT ACCOUNT=0002468101 AMOUNT=00075.00
TXN=4 TYPE=T
RESULT=REJECTED REASON=TARGET_NOT_FOUND
BALANCE ACCOUNT=0001234567 VALUE=0001085.50
BALANCE ACCOUNT=0002468101 VALUE=0000275.00
BALANCE ACCOUNT=0007654321 VALUE=0000090.00
SUMMARY PROCESSED=04 POSTED=03 REJECTED=01
```

本课运行时标准错误中会出现本机 GnuCOBOL 环境警告：`Warning: program compiled against libxml 212 using older 209`。它不是程序的标准输出。

## 五、修改练习（有答案）

1. 将第四笔转账的目标从 `0009999999` 改为已存在的 `0002468101`。确认转账成功，两个账户余额相应变化，拒绝数归零。
2. 从原始源码出发，将第四笔目标改为 `0001234567`，并把金额改为 `100.00`。来源账户 `0007654321` 只有 `90.00`；确认系统因余额不足拒绝，且转账两边余额保持原样。

参考答案只涵盖以上两项修改练习，见 [`answer.md`](./answer.md)；练习说明见 [`exercise.md`](./exercise.md)。

## 六、举一反三（无答案）

增加一个账户和一笔存款，再增加一笔来源账户存在、目标账户不存在的转账。为每种结果给出处理计数和最终余额。说明账户表排序、搜索索引、交易负载视图以及转账更新顺序分别由哪些语句维护。

不提供举一反三答案。数据仍在内存中；不添加文件或数据库。

## 七、企业实战补充

批处理程序必须把记录布局、类型码含义、主档排序、缺失账户策略和转账原子更新规则视为同一业务契约。本例验证了有限的确定性数据路径，不包含文件状态、并发更新、重启恢复或持久化；这些主题在后续文件和工程课程中处理。

## 参考资料

- [GnuCOBOL Programmer’s Guide：OCCURS](https://superbol.eu/gnucobpg/chapter6.html#occurs)
- [GnuCOBOL Programmer’s Guide：REDEFINES](https://superbol.eu/gnucobpg/chapter6.html#redefines)
- [GnuCOBOL Programmer’s Guide：SEARCH ALL](https://superbol.eu/gnucobpg/chapter7.html#search-all)
