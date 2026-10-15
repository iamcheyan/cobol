# 第 13 课：SEARCH 与 SEARCH ALL 查找

> 示例使用 GnuCOBOL 3.2.0 默认方言与固定格式。

## 一、课程目标

学完本课后，你可以：

- 用 `SEARCH` 从当前索引开始逐项查找表格键。
- 用 `SEARCH ALL` 对有序键表进行二分查找。
- 用 `AT END` 处理未找到的账户。
- 说明 `SEARCH ALL` 的 `INDEXED BY`、排序和唯一键要求。
- 识别编译器不会检查实际数据是否符合 `ASCENDING KEY` 顺序。

## 二、样例账户表

[`lesson.cob`](./lesson.cob) 将四个账户按 `X(10)` 账户号递增顺序装入 OCCURS 表格。账户号唯一，第三项余额为 `520.00`。表格声明 `ASCENDING KEY IS WS-ACCOUNT-NUMBER`，并用 `INDEXED BY WS-ACCOUNT-IDX` 提供搜索索引。

该程序对已存在的 `0002468101` 和不存在的 `0005550000` 分别执行两种查找。固定宽度的文本账户号包含前导零；这些样例按相同长度的字符顺序升序排列。

## 三、SEARCH 与 SEARCH ALL

`SEARCH WS-ACCOUNT-ENTRY` 是顺序查找。程序先将搜索索引设为 1；每个 `WHEN` 检查当前账户号，未匹配时 `SEARCH` 自动前进到下一项。全部项目都不匹配时执行 `AT END`。

`SEARCH ALL WS-ACCOUNT-ENTRY` 是二分查找。它自动选择表项位置；`WHEN` 通过该表的 `INDEXED BY` 索引，将目标值与当前账户号比较。它要求表格声明索引和 `ASCENDING KEY` 或 `DESCENDING KEY`，且实际键值顺序必须符合声明。若顺序错误，编译器不保证报错，运行时查找可能失败或返回错误结果。用于本课的键值也必须唯一。

| 查找方式 | 比较顺序 | 使用场景与前提 |
|---|---|---|
| `SEARCH` | 从当前索引逐项检查，直到找到或到达表尾 | 不要求表格按键排序；执行前把索引设为合理起点 |
| `SEARCH ALL` | 二分缩小有序表的查找范围 | 要求 `INDEXED BY`、匹配的键排序和唯一键 |

## 四、程序执行步骤

1. `1000-LOAD-ACCOUNTS` 用常量下标装入四个账户，确保账户号严格升序且没有重复。
2. 主段落把 `0002468101` 设为搜索目标，依次调用顺序查找和二分查找；两者都显示匹配账户及 `520.00` 余额。
3. 主段落再把 `0005550000` 设为目标。两个查找都没有匹配项，并分别执行自己的 `AT END` 输出。
4. 顺序查找在运行前把索引重置为 1；二分查找则自动选择检查位置。
5. 搜索索引只用于表格引用，不作为普通数值运算字段。

## 五、编译、运行和预期输出

在本目录运行以下命令：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_13" lesson.cob
"$scratch_dir/lesson_13"
```

GnuCOBOL 3.2.0 的程序标准输出：

```text
検索=SEQUENTIAL キー=0002468101
逐次検索=検出 口座=0002468101  残高=0000520.00
検索=BINARY キー=0002468101
二分検索=検出 口座=0002468101  残高=0000520.00
検索=SEQUENTIAL キー=0005550000
逐次検索=NOT_FOUND
検索=BINARY キー=0005550000
二分検索=NOT_FOUND
```

当前工作区语法检查、编译和运行均返回 0，输出与上面一致。运行时标准错误另有系统警告 `Warning: program compiled against libxml 212 using older 209`；它不是 COBOL 程序输出。

## 六、修改练习（有答案）

1. 将账户 `0002468101` 的余额从 `520.00` 改为 `600.00`。检查两种查找是否都返回更新后的余额。
2. 把 OCCURS 表格扩为五项，追加最大账户号 `0009999999`、余额 `75.00`，并将第二个搜索目标改为该账户号。保持所有键值升序且唯一，确认两种查找都找到新增账户。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；练习说明见 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

为五个产品代码和库存数量创建表格。使用 `SEARCH` 查找中间产品，并测试不存在的产品。然后为 `SEARCH ALL` 声明合适的键，确保所有产品代码唯一且实际按所声明方向排序，再分别测试命中与未命中。说明改动表格顺序但未同步键声明会造成什么风险。

本题不提供答案。使用固定内存表格；不添加文件或数据库。

## 八、企业实战补充

把交易账户号关联到账户主档时，查找结果决定后续余额和状态读取。`SEARCH ALL` 只有在装载或排序流程确实维持唯一且有序的键时才可靠；仅在数据描述中写 `ASCENDING KEY` 不会自动排序数据。生产流程必须定义重复键处理、缺失账户处理和数据顺序验证，并确保文件读取或表格重载过程维持该契约。

## 参考资料

- [GnuCOBOL Programmer’s Guide：SEARCH](https://superbol.eu/gnucobpg/chapter7.html#search)
- [GnuCOBOL Programmer’s Guide：SEARCH ALL](https://superbol.eu/gnucobpg/chapter7.html#search-all)
- [GnuCOBOL Programmer’s Guide：OCCURS](https://superbol.eu/gnucobpg/chapter6.html#occurs)
