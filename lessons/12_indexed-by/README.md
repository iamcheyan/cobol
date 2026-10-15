# 第 12 课：INDEXED BY——用表格索引遍历账户表

银行夜间批次常先把一小批待处理账户装入内存表，再逐项读出账号与余额；本课在第 11 课的 `OCCURS` 表上声明 `INDEXED BY` 索引，用 `SET` 定位并前进，遍历四笔样例账户并输出处理件数，为第 13 课按键查找账户主档准备索引遍历写法。

## 为什么现在学

第 11 课已经能用普通数字下标读写表项，例如 `WS-TXN-CODE(2)` 里的 `2` 是一个普通数值字段。缺口有两处：访问量自身没有和表定义绑定；以及“当前第几项”和“一共几项”必须分别维护。`INDEXED BY` 声明的索引由表定义关联，只能用 `SET` 定位或移动，本课用它遍历已装入的账户。索引不会按键查找，查找在第 13 课用 `SEARCH` 完成。

## 本课完成后的能力与边界

学完本课后，你可以：

- 在 `OCCURS` 项上用 `INDEXED BY` 声明表格索引。
- 用 `SET idx TO 1` 把索引定位到第 1 项，用 `SET idx UP BY 1` 前进。
- 在表引用中用同一索引读取一个出现项里的多个字段（账号与余额）。
- 说明 `USAGE INDEX` 索引与 `PIC 9` 数字下标分别负责什么、为什么索引不能直接做算术。
- 用 `PERFORM UNTIL idx > 已装入项数` 划定遍历终点，并知道索引越界默认不会被拦住。

边界：本课不按键查找（`SEARCH` 在第 13 课）、不排序、不读文件或数据库；表容量与账户数据都是程序内常量。索引只表示“当前第几项”，不含业务含义。

## 运行环境

- GnuCOBOL 3.2.0，默认方言（不加 `-std=cobol85`），源文件为固定格式。
- Linux 终端；本课不依赖数据库、附加工具或第三方库。
- 程序不读外部输入，编译只在 `build/` 下生成可执行文件。

## 知识讲解

### 业务任务：先装入，再逐项遍历

批处理在读写主档前，常把一批账户暂存在内存表里逐项处理。表的容量在声明时固定，实际装入几项由程序控制。本课把两段职责分开：`1000-LOAD-ACCOUNTS` 用常量下标写入四笔演示账户，`2000-DISPLAY-ACCOUNTS` 用索引逐项读出。四笔账户是**程序内常量**，不是从外部文件读入的数据。

### 索引和数字下标分别负责什么

| | 普通数字下标 | 表格索引（`INDEXED BY`） |
|---|---|---|
| 声明 | 独立的 `PIC 9` 数值字段 | 附在 `OCCURS` 子句上的索引名，不写 `PIC` |
| 表示 | 出现项编号，可参与算术 | 表定义关联的访问量，只能 `SET` 定位/移动 |
| 边界 | 写死的字面量下标在编译期检查 | 由运行期 `SET`/循环条件决定，编译期不检查 |

实测：表容量为 4 时写 `WS-ACCOUNT-NUMBER(5)`，`cobc` 直接报 `error: subscript of 'WS-ACCOUNT-NUMBER' out of bounds: 5` 并返回 1；而把循环终点 `WS-LAST-ACCOUNT` 改成 5（容量仍为 4）时编译返回 0，运行时读到表外字节、退出码仍为 0。要验证索引边界，可用 `cobc -x -fsubscript-check=full -fec=EC-BOUND-SUBSCRIPT` 编译，越界访问会变成运行期错误并返回 1，详见练习第 2 步。

### 固定格式与列位置（按字节实测）

本课源码第 7 列全部为空格（没有续行指示符；第 5、11、21、31 行是 `*` 注释行）；`IDENTIFICATION DIVISION`、`01`、段落名从第 8 列（Area A）开始；`MOVE`/`SET`/`PERFORM` 等语句从第 12 列（Area B）开始。第 6 行两位级号 `05` 占第 11–12 列，这是本仓库既有写法，GnuCOBOL 默认方言通过（`-fsyntax-only -fareacheck` 返回 0）。按字节实测：代码行最长 57 字节，注释行最长 71 字节，均未越过第 72 列。

## 源码阅读路径

[`lesson.cob`](./lesson.cob) 的关键部分：

- `WS-ACCOUNT-TABLE`：`05 WS-ACCOUNT-ENTRY OCCURS 4 TIMES` 加 `INDEXED BY WS-ACCOUNT-IDX` 声明容量为 4 的账户表，每个出现项含 `WS-ACCOUNT-NUMBER PIC X(10)`（账号，含前导零）与 `WS-ACCOUNT-BALANCE PIC 9(7)V99`（7 位整数 + 2 位小数的金额）。`INDEXED BY` 使 `WS-ACCOUNT-IDX` 成为表索引。
- `WS-LAST-ACCOUNT PIC 9 VALUE 4`：本次处理到第几项，是数值计数而不是索引；它必须等于已装入项数且不超过表容量。
- `1000-LOAD-ACCOUNTS`：用 `(1)`…`(4)` 数字下标把常量写入四项。只扩大容量而不追加装入语句，会留下未装入的表项。
- `2000-DISPLAY-ACCOUNTS`：`SET WS-ACCOUNT-IDX TO 1` 定位第 1 项；`PERFORM UNTIL WS-ACCOUNT-IDX > WS-LAST-ACCOUNT` 在索引越过最后一项后结束，因此第 4 项也会被处理。
- `2100-DISPLAY-ONE-ACCOUNT`：`WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)` 括号内是索引名，所以按索引访问；同一次访问用同一索引读账号与余额，保证看到同一出现项。读完后 `SET ... UP BY 1` 前进，索引不能写成 `ADD 1 TO`。
- `9000-REPORT`：输出处理件数。

## 运行与观察

程序只使用程序内常量，在本课目录或任意目录运行结果相同；下面按本课目录说明。

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                    # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_12 lesson.cob      # 编译并生成可执行文件
./build/lesson_12                                # 运行程序，输出写到标准输出
echo $?                                          # 查看上一条命令的退出码
rm -rf build                                     # 清理生成的可执行文件
```

预期标准输出（`口座=` 意为“账号”，`処理件数=` 意为“处理件数”，均沿用仓库既有日文输出）：

```text
口座=0001234567 BALANCE=0001000.00
口座=0007654321 BALANCE=0000250.75
口座=0000000042 BALANCE=0000000.00
口座=0002468101 BALANCE=0000520.00
処理件数=004
```

| 观察项 | 预期值 |
|---|---|
| `cobc -fsyntax-only` 退出码 | `0`，无诊断 |
| `cobc -x -Wall` 退出码 | `0`，无诊断 |
| 标准输出 | 上面 5 行，账户顺序固定 |
| 进程退出码 | `0` |
| 生成文件 | 仅 `build/lesson_12` |

输出可独立核算：四笔余额 `1000.00`、`250.75`、`0.00`、`520.00` 逐个来自 `1000-LOAD-ACCOUNTS` 的 `MOVE`；`PIC 9(7)V99` 显示为 7 位整数加隐含小数点共 10 个字符（如 `0001000.00`）；第 3 项余额 `0.00` 仍是有效表项，0 是数值而不是“空”；处理件数 `004` 等于遍历到的项数 4。

**实际观察到的环境细节：** 在本工作区运行 `./build/lesson_12` 时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境链接库版本差异产生的警告，不是程序的业务输出；业务输出在标准输出，退出码为 0。

`-fsyntax-only` 只证明语法路径，不能替代编译和运行观察。上表命令与输出已在本工作区用 GnuCOBOL 3.2.0 实际运行核对；索引越界行为在课内临时副本上实测，不修改本课源码，见练习第 2 步。

## 修改练习

把账户表扩到第五项并装入账号 `0005550001`、余额 `75.00`，再单独观察循环终点超过容量时的行为。题目、约束与命令见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

## 举一反三练习

为五笔账户建立 `OCCURS` 表格与 `INDEXED BY` 索引，用普通数字下标装入至少三笔，再用索引从第 1 项遍历到最后一个已装入项，并说明你会用哪条命令验证越界会被发现。只使用第 11–12 课讲过的语法，不要使用 `SEARCH`、`SORT`、文件或数据库。题目见 [`exercise.md`](./exercise.md)，本题不提供答案。

## 在企业中的位置

在银行批处理里，内存小表常用于暂存一批账户、交易码或费率，再逐项处理；索引遍历是“已装入范围”循环的常见写法。它不检查边界，也不代表已在主档中查到账户：容量、已装入数量与循环终点三者一致，需要由程序和测试共同保证。真实系统还要求键值查找、文件读写、错误分类与日志，分别见第 13 课、文件阶段（第 15 课起）与第 26–27 课；本课不提供生产级的边界保护或并发保证。

## 参考资料

- [GnuCOBOL Programmer’s Guide：OCCURS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#OCCURS)
- [GnuCOBOL Programmer’s Guide：SET Index](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SET-Index)
- [GnuCOBOL Programmer’s Guide：SET UP/DOWN](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SET-UP_002fDOWN)
- [GnuCOBOL Programmer’s Guide：Table Subscripting versus Table Indexing](https://superbol.eu/gnucobpg/chapter12.html#table-subscripting-versus-table-indexing)
- 上一课：[第 11 课 OCCURS 固定长度表格](../11_occurs-tables/README.md)
- 下一课：[第 13 课 SEARCH](../13_search-tables/README.md)
- 课程总目录：[DIRECTORY.md](../DIRECTORY.md)
