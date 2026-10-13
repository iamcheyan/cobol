# 第 12 课：INDEXED BY 表格索引

> 状态：课程草稿。目录已确认；示例源码 100 行固定格式，适用于 GnuCOBOL 3.2.0 默认方言。

## 一、课程目标

学完本课后，你可以：

- 在 `OCCURS` 项上用 `INDEXED BY` 声明表格索引。
- 用 `SET index TO n` 选择出现项，并用 `SET index UP BY n` 前进。
- 在表格引用中使用索引，读取一个出现项里的多个字段。
- 区分普通数值下标与 `USAGE INDEX` 表格索引。
- 让遍历终点不超出已声明并装入的表格范围。

## 二、索引和下标的区别

[`lesson_12.cob`](./lesson_12.cob) 声明四个账户出现项，并在 `OCCURS` 子句上使用 `INDEXED BY WS-ACCOUNT-IDX`。这个索引由表格定义关联；它不是带 `PIC 9` 的普通数值工作字段。循环先执行 `SET WS-ACCOUNT-IDX TO 1`，每轮读完账户号与余额后执行 `SET WS-ACCOUNT-IDX UP BY 1`。

上一课使用 `WS-SAMPLE-INDEX PIC 9(2)` 作为下标。普通数值下标直接表示出现项编号；索引则通过 `SET` 赋值或递增。两者的引用语法都使用括号，例如 `WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)`，但括号里的数据项声明决定它是索引还是下标。索引不能当作普通数值做任意算术；顺序移动使用 `SET UP` 或 `SET DOWN`。

加载段落用已知常量下标写入四笔样例，遍历段落则用表格索引依次读取。这样可以把“通过下标装入固定位置”和“通过索引走访表格”直接对照。

## 三、遍历过程

1. `1000-LOAD-ACCOUNTS` 将四个账户号和余额写入四个出现项。
2. `2000-DISPLAY-ACCOUNTS` 把索引设到第 1 项。
3. `PERFORM UNTIL WS-ACCOUNT-IDX > WS-LAST-ACCOUNT` 检查是否已经越过最后一项。
4. `2100-DISPLAY-ONE-ACCOUNT` 用同一个索引读取当前组里的账户号和余额，并增加处理数。
5. `SET ... UP BY 1` 选择下一项。第 4 项后索引移到 5；条件为真，循环在访问下一表项之前结束。
6. 汇总输出四项已处理。余额为零的第 3 个账户也是已装入的有效表项。

`WS-LAST-ACCOUNT` 是数值计数，不是表格索引。增加表格容量时，要同步增加装入的数据和处理终点；不能让索引访问未声明或未装入的项目。

## 四、编译、运行和预期输出

在本目录运行以下命令：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson_12.cob
cobc -x -Wall -o "$scratch_dir/lesson_12" lesson_12.cob
"$scratch_dir/lesson_12"
```

GnuCOBOL 3.2.0 的程序标准输出：

```text
ACCOUNT=0001234567 BALANCE=0001000.00
ACCOUNT=0007654321 BALANCE=0000250.75
ACCOUNT=0000000042 BALANCE=0000000.00
ACCOUNT=0002468101 BALANCE=0000520.00
PROCESSED=004
```

当前工作区语法检查、编译和运行均返回 0，标准输出与上面一致。运行时标准错误另有系统警告 `Warning: program compiled against libxml 212 using older 209`；它不是程序输出。

## 五、修改练习（有答案）

1. 将第 2 项余额从 `250.75` 改为 `275.25`。确认索引仍读取相同账户，并检查处理数。
2. 把 `OCCURS 4 TIMES` 和 `WS-LAST-ACCOUNT` 一起扩为 5，装入账户号 `0005550001`、余额 `75.00`。确认索引遍历到第 5 项且处理数变为 5。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；完整题目见 [`exercise.md`](./exercise.md)。

## 六、举一反三（无答案）

为五个账户建立 `OCCURS` 账户表，声明一个 `INDEXED BY` 索引。用普通下标装入至少三个账户，再从第一个到最后一个已装入账户遍历，并输出账号、余额和处理数。为该数据表设计一个安全的遍历终点，并说明容量、已装入数量和索引当前项之间的关系。

本题不提供答案。不要使用 `SEARCH`、文件或数据库。

## 七、企业实战补充

索引适合在表格访问中指向当前出现项；普通数值下标适合直接表示或计算明确的出现项编号。实际项目应遵循现有代码约定，并保持索引位置与已装入范围一致。索引不会验证账户数据，也不会自动查找键值；键值查找在下一课介绍。

## 参考资料

- [GnuCOBOL Programmer’s Guide：OCCURS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#OCCURS)
- [GnuCOBOL Programmer’s Guide：SET Index](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SET-Index)
- [GnuCOBOL Programmer’s Guide：SET UP/DOWN](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SET-UP_002fDOWN)
- [GnuCOBOL Programmer’s Guide：Table Subscripting versus Table Indexing](https://superbol.eu/gnucobpg/chapter12.html#table-subscripting-versus-table-indexing)
