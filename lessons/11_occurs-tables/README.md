# 第 11 课：OCCURS 固定容量表格——按下标装入并遍历交易表

银行批次常把一小批交易先暂存在内存里，再逐笔按交易码记账。本课用 `OCCURS` 声明一张固定四格的交易表，用显式下标装入、用 `PERFORM VARYING` 按下标逐项读出，最后输出处理件数与期末余额。这张内存表是[第 12 课](../12_indexed-by/README.md)索引遍历与[第 13 课](../13_search-tables/README.md)按键查找的共同对象。

## 为什么现在学

[第 06 课](../06_perform-loops/README.md) 已能用 `PERFORM VARYING` 重复固定次数，[第 09 课](../09_group-items/README.md) 已能用组项把交易码和金额组织成一条记录。但一组变量名只能保存一条记录：第 06 课的循环只能靠 `EVALUATE` 按索引硬选样例，写不出“第 n 笔交易”。缺口是一个能按下标寻址、容量又写死在声明里的容器。`OCCURS` 补上这个容器，并把“表有多大”变成源码里可以核对的数字。

## 本课完成后的能力与边界

学完本课后，你可以：

- 在组项上用 `OCCURS n TIMES` 声明 n 个出现项，并算出整张表占用的字节数。
- 用 `WS-TXN-AMOUNT(2)` 这样的普通数值下标读写指定出现项，并说明下标为什么从 1 开始。
- 用 `PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1 UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE` 遍历到最后一项，解释退出条件为什么不会漏掉第 4 项。
- 区分表格容量、已装入数量和遍历上界这三个数字，并说明只改遍历上界会造成越界读取。

边界：本课不声明 `INDEXED BY` 索引、不做 `SEARCH` 查找、不排序、不从文件装入，也不校验下标范围；四笔交易和余额初值都是程序内常量。索引见第 12 课，按键查找见第 13 课，从文件装入见第 15 课起。

## 运行环境

- GnuCOBOL 3.2.0，使用默认方言（不加 `-std=cobol85`），源文件为固定格式。
- Linux 终端；本课不依赖数据库、附加工具或第三方库。
- 程序不读写业务数据文件，只在 `build/` 或临时目录生成可执行文件。

## 业务与知识点

### 表格布局与内存语义

[`lesson.cob`](./lesson.cob) 把 `OCCURS` 写在组项 `WS-TRANSACTION-ENTRY` 上，于是两个子项一起重复四次：

```text
01 WS-TRANSACTION-TABLE
   05 WS-TRANSACTION-ENTRY OCCURS 4 TIMES
      10 WS-TXN-CODE      PIC X          1 字节
      10 WS-TXN-AMOUNT    PIC 9(5)V99    7 字节
```

每个出现项占 1 + 7 = 8 字节，四个出现项连续排列、无填充，整张表 32 字节；`cobc -C` 生成的 C 代码把该表声明为 `cob_u8_t b_17[32]`，与手算一致。`WS-TXN-AMOUNT(3)` 访问第 3 个出现项的金额，即从表内偏移 (3−1)×8 + 1 起（从 0 计）的 7 个字节。

下标是 1 起的出现项编号，合法范围恒为 1 到 `OCCURS` 声明的容量。声明 `OCCURS` 只分配空间：不填充样例、不排序、不建索引；装载内容完全由 `1000-LOAD-TABLE` 的 `MOVE` 决定。

源码为固定格式：第 7 列只用于注释指示符 `*`（本课 3 行注释），Division、段落名和 01 级从第 8 列（Area A）起，语句从第 12 列（Area B）起。按字节实测，本课最长的一行是 65 字节，所有行都未越过第 72 列，因此不会掉进编译器忽略的 73–80 列。

## 输入与规则

- **输入：** 无外部输入。四笔交易和 `WS-ACCOUNT-BALANCE` 的初值 `1000.00` 都是程序内常量，分别写在 `1000-LOAD-TABLE` 的 `MOVE` 和 `VALUE` 子句里，不是从文件或数据库读来的。
- **记账规则：** 交易码 `C` 把金额加入余额，`D` 从余额扣减，其他代码只显示“未知代码被忽略”，不改变余额。未知码由 `EVALUATE ... WHEN OTHER` 分流；本课没有码表校验，这不等于码值已通过业务校验。
- **计数规则：** 每处理一个出现项，`WS-PROCESSED-COUNT` 加一，与交易码是否被接受无关。
- **未校验的前提：** 程序既不检查 `WS-LAST-SAMPLE` 是否超过容量 4，也不检查某一项是否真的装入过。这两点靠容量、装入语句和遍历上界三处一致来保证，见「修改练习」第 3 题的越界观察。

## 运行与观察

在本课目录执行（与[第 01 课](../01_hello-cobol/README.md)相同的编译/运行方式）：

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                   # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_11 lesson.cob     # 编译并生成可执行文件
./build/lesson_11                               # 运行程序，输出写到标准输出
echo $?                                         # 查看上一条命令的退出码
rm -rf build                                    # 清除生成的可执行文件
```

`-fsyntax-only` 只验证语法路径；只有编译并运行后才会出现下面 10 行输出。本课没有输入文件，在任何目录运行结果都相同。

**预期 stdout（本工作区实测）：**

| 行 | 内容 | 含义 |
|---|---|---|
| 1、3、5、7 | `明細=01 コード=C 金額=00125.50` 等四行 | 当前出现项的序号、交易码、金额 |
| 2、4、6、8 | `処理=入金`／`処理=出金`／`処理=未知コードを無視` | 该交易码走的分支：贷记、借记、忽略 |
| 9 | `処理件数=004` | 已处理的表项数 |
| 10 | `最終残高=0001105.40` | 期末余额 |

输出文本沿用仓库既定日文：`明細` 是明细序号，`コード` 是交易码，`金額` 是金额，`処理` 是处理动作，`処理件数` 是处理件数，`最終残高` 是期末余额。

余额可独立核算：`1000.00 + 125.50 − 40.10 + 20.00 = 1105.40`；第 3 项交易码 `X` 的 `25.00` 不参与计算，但仍计入处理件数。

**退出码：** 语法检查、编译、运行三次都为 `0`。运行时标准错误输出 `Warning: program compiled against libxml 212 using older 209`，这是本机链接库版本差异产生的环境警告，不是本程序的业务输出（与第 01 课观察到的现象相同）。

## 源码阅读路径

按数据被写入、读取的顺序读：

1. `0000-MAIN` 依次调用装入、处理、汇总三个段落。
2. `1000-LOAD-TABLE` 用常量下标 1、2、3、4 写明每一笔交易的存放位置。
3. `2000-PROCESS-TABLE` 用 `PERFORM VARYING` 把 `WS-SAMPLE-INDEX` 从 1 递增，`UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE` 退出：第 4 项在判断 `4 > 4` 为假时仍被处理，而循环不会走到第 5 项。
4. `2100-PROCESS-ENTRY` 在每个字段名后加 `(WS-SAMPLE-INDEX)`，读取当前出现项的交易码和金额；括号里的 `WS-SAMPLE-INDEX` 是普通数值字段，不是表格索引（索引见第 12 课）。
5. `9000-REPORT` 输出处理件数和期末余额，二者都是循环累加的结果，不是重新扫描表格得到的。

`2100-PROCESS-ENTRY` 不接收参数，它读的是“当前下标指向的出现项”，所以必须在循环内调用才有意义。

## 实战位置

批处理程序常用固定容量的内存表暂存一小批记录：交易明细、账户快照或码值映射。本课的表格会被逐课加强：[第 12 课](../12_indexed-by/README.md)用 `INDEXED BY` 索引遍历已装入的账户表，[第 13 课](../13_search-tables/README.md)在同一类有序表上用 `SEARCH`/`SEARCH ALL` 把交易账户号关联到账户主档，[第 14 课](../14_data-structures-practice/README.md)把内存表组合成账户-交易匹配。第 15 课起改从文件逐条读入记录，[第 16 课](../16_file-writing/README.md)把结果行放进表格后写出文件，[第 18 课](../18_csv-processing/README.md)用 `OCCURS` 按下标保存解析出的 CSV 字段。

真实系统还需要本课没有的部分：容量的来源（不是硬编码 4）、逐个下标的范围检查，以及“装入失败”与“表未满”的区分。本课把容量、已装入数量和遍历上界写成三个显式数字，正是为了先看清它们必须一致；[第 21 课](../21_sort/README.md)和[第 22 课](../22_file-processing-practice/README.md)会说明为什么不把整份文件装进 `OCCURS` 表。

## 修改练习

三题都从原始 [`lesson.cob`](./lesson.cob) 出发、各自独立修改；题目与约束见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

1. 把第四项金额 `20.00` 改为 `35.00`，核对变化的输出行与期末余额。
2. 把表容量和 `WS-LAST-SAMPLE` 一起扩到 5，再装入第五项 `C`／`10.00`，确认五项都被处理。
3. 边界观察：容量保持 4，只把 `WS-LAST-SAMPLE` 初值改为 5，观察程序是否报错、第 5 项打印了什么。

## 举一反三

写一张暂存五个账户（账户号 `PIC X(10)` + 余额 `PIC 9(7)V99`）的固定容量表，装入至少三项，用普通数值下标从第一项遍历到最后一个已装入项，逐项输出账户号和余额，最后输出处理件数与余额合计；修改容量时同步调整处理上界，并说明容量、已装入项数和遍历上界分别是多少、未装入位置与已装入位置有什么区别。只使用本课的 `OCCURS` 和普通数值下标，不使用 `INDEXED BY`、`SEARCH`、文件或数据库。本题不提供答案，题目见 [`exercise.md`](./exercise.md)。

## 证据来源

- 语法检查、编译（`-Wall`）、运行、退出码均在本工作区实际执行：三次退出码都是 `0`，编译无诊断，stdout 与上表一致；修改注释后再次执行，输出逐字节不变。
- 运行时 stderr 只有上述 libxml 警告。
- 表宽 32 字节、每项 8 字节来自 `cobc -C lesson.cob` 生成的 C 代码（`cob_u8_t b_17[32]`，以及 `b_17 + 8LL * (下标 - 1)` 的地址计算），与 `PIC X` = 1 字节、`PIC 9(5)V99` = 7 字节的手算一致。
- 越界观察为实测：容量 4 而 `WS-LAST-SAMPLE` 为 5 时，编译和运行都成功（退出码 `0`），第 5 项输出 `コード=0`、`金額=5`，其后是四个不可打印 NUL 字节和 `.00`——读到的是紧邻表格之后的工作存储字节，余额与处理件数不再可信。具体读到的内容取决于编译器布局，不可移植，不能当作业务数据；默认编译未启用下标范围检查。
- 未验证：本课命令不使用 GnuCOBOL 的 `-fsubscript-check` 等下标检查选项，也没有验证启用该选项后的行为。

## 参考资料

- [GnuCOBOL Programmer’s Guide：Table Handling](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Table-Handling)
- [GnuCOBOL Programmer’s Guide：Table References（下标引用）](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Table-References)
- [GnuCOBOL Programmer’s Guide：PERFORM（含 VARYING）](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PERFORM)
- 仓库课程主页：[README.md](../../README.md)
