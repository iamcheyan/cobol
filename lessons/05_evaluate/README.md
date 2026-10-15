# 第 05 课：EVALUATE——把交易码分类到明确的处理分支

银行批处理收到一笔交易的类别码，必须先把同一个字段的多个取值归入各自的处理类别：`D` 存款、`W` 取款、`T` 转账，契约之外的取值单独走待人工核对。本课用 `EVALUATE` 把“一个字段 → 多个精确值 → 各自分支”集中表达，并为未定义值准备兜底路径；这套分类在[第 06 课](../06_perform-loops/README.md)的循环里按索引复用，并在第 08 课汇总成多笔交易的计数。

## 为什么现在学

[第 04 课](../04_if-conditions/README.md)你已经能用 `IF` / `ELSE` / `END-IF` 按金额区间和账户状态接受或拒绝一笔交易。但那两处判断的对象分别是数值范围和单一状态；当同一个字段有多个互斥取值、每个取值又要对应一组不同处理时，串起来的 `IF` / `ELSE IF` 会让“哪个代码走哪条路、哪些代码还没有人管”变得难以审阅。本课用 `EVALUATE` 把这种选择集中到一个位置，并第一次显式处理“契约之外还有取值”的情况。

## 本课完成后的能力与边界

学完本课后，你可以：

- 用 `EVALUATE <字段>` 配合多个 `WHEN "<值>"`，对同一个字符字段的多个精确取值分流。
- 用 `WHEN OTHER` 承接契约内未列出的取值，而不是让它们静默通过。
- 运行程序，读出 `D`、`W`、`T` 分别产生的分类标签和处理标签。
- 说明小写 `d`、空格和其他字符为什么都进入 `WHEN OTHER`（字符比较是精确匹配）。
- 说明本课只输出分类标签与处理标签，没有执行任何账户过账。

边界：本课不读文件、不做算术、不修改余额、不写日志或拒绝文件；大小写没有做归一化，空值/格式错误也没有专门的校验分支——它们只是落入 `WHEN OTHER`。文件读取从[第 15 课](../15_sequential-file-read/README.md)开始，拒绝结果写出从第 16 课开始，业务拒绝与系统故障的分流从第 26 课开始。

## 运行环境

- GnuCOBOL 3.2.0，使用默认方言（不加 `-std=cobol85`），源文件为固定格式，编译器与目标平台行为以实际验证为准。
- Linux 终端；本课不依赖数据库、附加工具或第三方库。
- 输入全部是 `WORKING-STORAGE` 里的程序内常量，本课没有输入夹具；运行只在 `build/` 下生成可执行文件。

## 知识讲解

### EVALUATE 解决什么问题

批处理上游按接口契约给出单字符交易码，程序要在同一处把每个已知代码映射到对应的处理类别，并让没人处理的代码也有明确出路。`EVALUATE` 正是“一个 subject 对多个常量”的选择结构：

```cobol
EVALUATE WS-TRANSACTION-CODE
    WHEN "D"
        DISPLAY "分類=DEPOSIT"
    WHEN "W"
        DISPLAY "分類=WITHDRAWAL"
    WHEN OTHER
        DISPLAY "分類=UNKNOWN"
END-EVALUATE
```

- subject 是 `WS-TRANSACTION-CODE`，一次只取一个字段。
- 每个 `WHEN` 给出该字段的一个可能值；程序执行第一个匹配的分支，到 `END-EVALUATE` 结束这一段选择。
- `WHEN OTHER` 在没有任何显式 `WHEN` 匹配时执行，是本课的兜底路径。

### 与 IF / ELSE 的差别，以及为什么这里用 EVALUATE

`IF WS-TRANSACTION-CODE = "D" ... ELSE IF ... = "W" ... ELSE ...` 能表达同样的选择，但有三个特征让 `EVALUATE` 在这里更合适：subject 只写一次，不必在每个条件里重复比较同一个字段；已知值与兜底值并列排布，“哪些代码被显式承认、其余走哪条路”一眼可见；新增一个交易码只需插入一个 `WHEN` 分支，不必调整嵌套的 `ELSE` 归属。第 04 课强调过 `ELSE` 与最近一个尚未结束的 `IF` 关联，`EVALUATE` 用 `END-EVALUATE` 划出明确范围，正好避免这类嵌套风险。GnuCOBOL 也支持 `EVALUATE TRUE` 配合条件表达式，本课先学习 subject 对精确常量的简单形式。

### 字符比较是精确的

`WS-TRANSACTION-CODE` 是 `PIC X` 文本字段，`WHEN "D"` 比较的是字符本身：小写 `d` 不等于大写 `D`，空格、数字或其他字符也都不等于 `D`/`W`/`T`。这些取值都会落入 `WHEN OTHER`，被标为 `UNKNOWN`。本例的接口约定就是大写 `D`、`W`、`T`；若要接受大小写变体或别名，必须先在契约里写清楚再在程序中归一化，不能默默给某个字符追加含义。

### 关于输出文本的语言

仓库约定：源文件注释与 README 讲解使用中文，程序运行输出的业务文本沿用日文。本课输出的 `取引参照番号` 意为“交易参考号”，`取引コード` 意为“交易代码”，`分類` 意为“分类”，`処理` 意为“处理标签”（例如 `処理=ADD_TO_ACCOUNT` 表示“处理建议=记入账户”）。判断程序行为时以实际输出和本节的中文说明为准。

## 完整示例源码

[`lesson.cob`](./lesson.cob) 用固定常量 `D` 展示存款分支：先显示交易参考号与代码，再输出一个分类标签和一个处理标签。

```cobol
      * 合法取引コード D/W/T 由接口契约定义；本课把它当作输入前提，不在程序内校验取值。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVAL05.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
       01 WS-TRANSACTION-CODE PIC X VALUE "D".
       PROCEDURE DIVISION.
           DISPLAY "取引参照番号="
               WS-TRANSACTION-REFERENCE.
           DISPLAY "取引コード=" WS-TRANSACTION-CODE.
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   DISPLAY "分類=DEPOSIT"
                   DISPLAY "処理=ADD_TO_ACCOUNT"
               WHEN "W"
                   DISPLAY "分類=WITHDRAWAL"
                   DISPLAY "処理=SUBTRACT_FROM_ACCOUNT"
               WHEN "T"
                   DISPLAY "分類=TRANSFER"
                   DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"
      * 契约外取值统一归入待人工核对；本课只输出分类标签，不做任何过账。
               WHEN OTHER
                   DISPLAY "分類=UNKNOWN"
                   DISPLAY "処理=REJECT_FOR_REVIEW"
           END-EVALUATE
           STOP RUN.
```

### 数据字段

| 字段 | PIC / 初值 | 含义 |
|---|---|---|
| `WS-TRANSACTION-REFERENCE` | `X(12)` / `TXN-00000001` | 交易参考号文本，不参与算术 |
| `WS-TRANSACTION-CODE` | `X(1)` / `D` | 单字符交易码，取本课契约允许的 `D`/`W`/`T` |

### 过程逐步解析

1. `IDENTIFICATION DIVISION`、`PROGRAM-ID` 给程序命名；`WORKING-STORAGE SECTION` 用 `VALUE` 给出固定的参考号与交易码，程序没有其他输入。
2. 第一条 `DISPLAY` 输出交易参考号（`X(12)` 文本，不参与算术），第二条输出交易代码，方便核对当前固定样例。
3. `EVALUATE WS-TRANSACTION-CODE` 打开多路选择，subject 是那个单字符代码。
4. `WHEN "D"` 输出 `分類=DEPOSIT` 与 `処理=ADD_TO_ACCOUNT`；`WHEN "W"` 输出取款标签，`WHEN "T"` 输出转账标签。每条分支只输出两个静态标签。
5. `WHEN OTHER` 输出 `分類=UNKNOWN` 与 `処理=REJECT_FOR_REVIEW`，覆盖 `D`/`W`/`T` 之外的所有取值。
6. `END-EVALUATE` 显式结束选择范围，`STOP RUN.` 结束程序。

分类与处理标签都是 `DISPLAY` 的静态文本，程序不执行存款、取款或转账，也不改写任何余额。

## 运行与观察

本课不读键盘、文件、命令行参数或数据库，也不生成数据文件，因此在本课目录或任意目录执行结果都相同。下面按本课目录说明。

**输入：** 无外部输入。看到的每一行都来自 `lesson.cob` 里的程序内常量和 `DISPLAY` 字面量，不是文件或数据库数据。

**命令及作用：**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                    # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_05 lesson.cob      # 编译并生成可执行文件
./build/lesson_05                                # 运行程序，业务输出写到标准输出
echo $?                                          # 查看上一条命令的退出码
rm -rf build                                     # 清理生成的可执行文件
```

`-fsyntax-only` 只验证语法路径，不生成也不运行程序，不能替代编译和运行观察；`-x` 要求 GnuCOBOL 生成可执行程序，`-o` 指定输出路径；`rm -rf build` 只删除本课生成的可执行文件，不触碰源码。

**预期结果：**

| 观察项 | 预期值 |
|---|---|
| `cobc -fsyntax-only` 退出码 | `0` |
| `cobc -x` 退出码 | `0`，无编译诊断 |
| 标准输出（stdout） | 见下方四行 |
| 进程退出码（`echo $?`） | `0` |
| 生成文件 | 仅 `build/lesson_05` |

标准输出：

```text
取引参照番号=TXN-00000001
取引コード=D
分類=DEPOSIT
処理=ADD_TO_ACCOUNT
```

**实际观察到的环境细节：** 在本工作区运行 `./build/lesson_05` 时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境链接库版本差异产生的警告，不是本程序的业务输出，触发组件尚未定位。程序的正常输出写在标准输出，退出码为 0。

## 修改练习

从原始 [`lesson.cob`](./lesson.cob) 出发，为接口新增的交易码 `F`（手续费）增加一条 `WHEN "F"` 分支，并把样例代码改为 `F` 以便观察：在 `EVALUATE` 中 `WHEN "T"` 分支之后、`WHEN OTHER` 之前插入输出 `分類=FEE` / `処理=CHARGE_FEE` 的分支，同时把 `WS-TRANSACTION-CODE` 的初值 `VALUE "D"` 改为 `VALUE "F"`。约束是不改动 `D`/`W`/`T` 分支的输出、不改动 `WHEN OTHER` 的语义与输出、保持固定格式。完整题目、预期差异与原因见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

## 举一反三练习

为一个批处理记录分类支付方式：`C` 现金、`B` 银行转账、`K` 支票；契约之外的代码统一输出待人工核对。只使用本课学过的字段、`EVALUATE`、`WHEN`、`WHEN OTHER`、`DISPLAY` 和 `STOP RUN`，用 `EVALUATE` 映射代码并输出类别与处理建议。题目见 [`exercise.md`](./exercise.md)，本题不提供答案。

## 在企业中的位置

批处理程序把上游代码映射到处理路径时，映射必须来自稳定、受版本控制的接口约定；上线前要核对生产者与消费者对代码、大小写、空值、保留值和新增值的处理方式。本课演示的是“多值分类”这一步：已知码得到明确的处理类别，未知码走待人工核对，而不是继续按正常路径处理。

它还没有真正处理这些类别：[第 06 课](../06_perform-loops/README.md)在循环里按索引复用本课的分类思路，[第 08 课](../08_control-flow-practice/README.md)把多笔交易的接受/拒绝计数汇总起来，[第 16 课](../16_file-writing/README.md)才把拒绝明细写成文件，[第 26 课](../26_error-handling/README.md)才区分业务拒绝与系统故障，[第 27 课](../27_logging/README.md)记录批次号与原始代码以便重放。`REJECT_FOR_REVIEW` 目前只是程序输出的处理标签，不代表真实系统已经完成拒绝。本课不声称任何生产、审计或监管保证。

## 参考资料

- [GnuCOBOL Programmer’s Guide：EVALUATE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#EVALUATE)
- [GnuCOBOL Manual：EVALUATE TRUE 与 WHEN OTHER 示例](https://gnucobol.sourceforge.io/doc/gnucobol.html)
- 仓库课程总目录：[DIRECTORY.md](../DIRECTORY.md)
