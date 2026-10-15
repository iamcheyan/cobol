# 第 06 课：PERFORM 重复处理——用计数循环顺序处理固定样例

批处理要按顺序逐笔处理数据，而不是把同一条逻辑复制多遍。本课用 `PERFORM VARYING` 写一个计数循环，把三笔固定样例（存款、取款、转账）依次处理并统计实际处理件数，为后续课用同一个循环结构遍历文件记录和内存表格打基础。

## 为什么现在学

你已经能用 `IF` / `EVALUATE` 对单条数据做分支判断，但还只能处理一笔写死的记录。缺口是“重复”：真实批次要对 N 笔交易执行同一套处理，而 N 在运行时才确定。本课引入带计数控制字段的 `PERFORM VARYING`，把“处理一笔”的代码包进循环，并让循环边界和计数结果可以被独立核对。

## 本课完成后的能力与边界

学完本课后，你可以：

- 写出 `PERFORM VARYING <索引> FROM <起始> BY <步长> UNTIL <退出条件> ... END-PERFORM` 并说明各部分作用。
- 解释初始值、步长和退出条件如何共同决定迭代次数。
- 说明使用 `UNTIL 索引 > 上限` 时，为什么索引等于上限的那一轮仍会执行。
- 把上限改为 0、1、3、4，观察零次、一次、三次和越过样例范围三种边界下 stdout 与处理计数的变化。
- 用 `END-PERFORM` 标出循环范围，并在循环结束后报告实际处理件数。

边界：本课只用三笔程序内固定的样例，不读文件或数据库；循环上限由字段直接控制，程序不会校验样例是否真的存在。内存表格（`OCCURS`）在第 11 课引入，文件读取在第 15 课引入，本课不提前使用。

## 运行环境

- GnuCOBOL 3.2.0，默认方言（不加 `-std=cobol85`），源文件为固定格式。
- Linux 终端；本课不依赖数据库或附加工具。
- 语法检查与编译在 `build/` 下生成可执行文件，可直接删除重来。

## PERFORM VARYING 工作方式

本课使用的语句形状：

```cobol
PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
    UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
    ...循环体...
END-PERFORM
```

- `FROM 1` 把循环索引初始设为 1。
- `BY 1` 指定每轮结束后索引递增 1。
- `UNTIL 索引 > 上限` 是退出条件，默认在进入循环体之前检查；条件为真就不执行本轮。
- 由于用的是严格大于，索引等于上限时条件仍为假，该轮会执行；只有再递增一次后才退出。这就是“上限本身也被处理”的来源。
- `END-PERFORM` 结束循环作用域。循环体里如果写了句点，可能提前结束更大的语句作用域；本例只在整段处理结束后写 `STOP RUN.`。

## 固定样例程序

完整源码见 [`lesson.cob`](./lesson.cob)，按固定格式编写。

本课尚未讲解 `OCCURS` 表格，因此示例用 `EVALUATE` 按索引挑选三笔固定的演示样例：存款、取款和转账。每轮显示一笔样例，再用 `COMPUTE` 把已处理件数加一；第 11 课引入表格后会换成真正的表项访问。

| 字段 | PIC / 初值 | 用途 |
|---|---|---|
| `WS-LAST-SAMPLE` | `9` / `3` | 最后一个要处理的样例序号，包含此序号 |
| `WS-SAMPLE-INDEX` | `9` / `0` | `PERFORM VARYING` 控制字段；进入循环时由 `FROM 1` 设为 1 |
| `WS-PROCESSED-COUNT` | `9(3)` / `0` | 每轮结束后递增，循环结束后用于报告实际处理件数 |

固定样例与索引的对应关系：1 是符号 `D`、金额 `125.50`；2 是 `W`、`040.10`；3 是 `T`、`075.00`。若把最后序号改成 4，循环仍会执行第四轮，`EVALUATE` 的 `WHEN OTHER` 会显示 `例=UNMAPPED`。这说明循环边界只由 `WS-LAST-SAMPLE` 控制，并不会自动检查样例是否存在。

## 程序逐步解析

1. `WORKING-STORAGE SECTION` 初始化最后序号和处理计数；索引的实际起始值由 `FROM 1` 设置，不依赖初值。
2. 第一条 `DISPLAY` 显示配置的最后序号。
3. `PERFORM VARYING` 在每轮执行前设置索引并检查 `UNTIL` 条件。
4. 循环体的 `EVALUATE WS-SAMPLE-INDEX` 按当前索引显示第 1、2、3 笔固定记录；其他索引走 `WHEN OTHER`，显示 `UNMAPPED`。
5. 每轮完成样例选择后，`COMPUTE` 把 `WS-PROCESSED-COUNT` 加 1。
6. 循环结束后显示处理件数。若上限为 0，第一次检查就是 `1 > 0`，循环体一次也不执行，计数保持 `000`。
7. `STOP RUN.` 正常结束程序。

## 运行与观察

本课不读取键盘、文件或数据库，因此在本课目录或任意目录执行结果相同。下面按本课目录说明。

**输入：** 无。三笔样例是程序内固定数据，`WS-LAST-SAMPLE` 的初值决定循环执行几次。

**命令及作用：**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                  # 只做语法检查
cobc -x -Wall -o build/lesson_06 lesson.cob    # 编译并生成可执行文件
./build/lesson_06                              # 运行，输出写到标准输出
echo $?                                        # 查看退出码
rm -rf build                                   # 清理生成的可执行文件
```

**预期结果（默认 `WS-LAST-SAMPLE` 为 3）：**

| 观察项 | 预期值 |
|---|---|
| `cobc -fsyntax-only` 退出码 | `0` |
| `cobc -x` 退出码 | `0`，无编译诊断 |
| 标准输出 | 5 行，见下方代码块 |
| 进程退出码 | `0` |

```text
最終サンプル番号=3
例=001 符号=D 額=125.50
例=002 符号=W 額=040.10
例=003 符号=T 額=075.00
処理件数=003
```

**输出字段对照（日文输出 → 含义）：** `最終サンプル番号` = 最后样例序号；`例` = 样例序号；`符号` = 交易符号（`D` 存款 / `W` 取款 / `T` 转账）；`額` = 金额；`処理件数` = 实际处理件数。

**实际观察到的环境细节：** 在本工作区运行可执行文件时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境的链接库版本警告，不是本程序的业务输出；其触发组件尚未定位。程序输出在标准输出，退出码为 0。

## 修改练习

从原始 [`lesson.cob`](./lesson.cob) 开始，把 `WS-LAST-SAMPLE` 的 `VALUE` 分别改为 `0`、`1`、`3`、`4`，每次重新编译运行，记录本次显示了几笔样例、`WS-PROCESSED-COUNT` 显示为多少、最后一轮是否落到 `UNMAPPED`。完整题目与预期结果见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

## 举一反三练习

把固定样例改成四笔支付记录，仍用 `PERFORM VARYING` 顺序处理：为每轮输出序号、类别和金额，累计处理件数；当最后序号为 0 时不得处理任何记录。暂时仍可用 `EVALUATE` 映射固定序号，不要引入尚未学习的表格或文件。题目见 [`exercise.md`](./exercise.md)，本题不提供答案。

## 在企业中的位置

批量程序用循环处理输入记录时，必须保证每轮都会读取或推进输入，并且退出条件最终能够到达，否则会死循环或漏处理。上线前至少要验证空批次、单条记录、最后一笔记录和超出预期范围这几种边界。

本例把上限直接设为 4 时会进入 `UNMAPPED` 分支，说明“循环边界”和“样例定义”是两回事；生产程序应在继续处理前按接口契约拒绝或记录这种不一致。第 11 课会引入 `OCCURS` 表格，第 15 课开始从文件读取记录，第 26 课处理记录级错误与返回码。

## 参考资料

- [GnuCOBOL Programmer’s Guide：PERFORM](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PERFORM)
- [GnuCOBOL Programmer’s Guide：Inline PERFORM](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Inline-PERFORM)

- [GnuCOBOL Manual：PERFORM loop example](https://gnucobol.sourceforge.io/doc/gnucobol.html)
- 仓库课程主页：[README.md](../../README.md)
