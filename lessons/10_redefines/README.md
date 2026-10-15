# 第 10 课：REDEFINES——用两个视图解释同一段交易负载字节

夜间批次收到的报文常常是「1 字节交易码 + 一段定长负载」，类型不同，负载里每个字段的含义就不同。本课把一份固定样例放在程序内，用 `REDEFINES` 让存款视图与转账视图共用同一段 27 字节负载，先各自写入并打印，再用**错误的视图**读同一批字节，确认重定义既不复制数据，也不校验交易码或内容。

## 为什么现在学

第 [09](../09_group-items/README.md) 课已经能把客户、账户、交易字段组织成一棵层级记录，但那份记录只有一种固定解释。当同一条物理记录要按交易类型切换布局时，把两个 `05` 负载组并列声明会各占 27 字节、把记录撑成 55 字节，而且没有任何语法表示「这两组其实在同一位置」。本课补上 `REDEFINES`：在同一偏移上再声明一个视图，并给出它的长度与声明位置约束。第 [11](../11_occurs-tables/README.md) 课用 `OCCURS` 把「交易码 + 金额」出现项重复成表、第 [14](../14_data-structures-practice/README.md) 课要把这份 27 字节负载放进内存账户匹配、第 [17](../17_fixed-length-files/README.md) 课要把它落成真实定长文件、第 [23](../23_copybooks/README.md) 课要用 Copybook 把布局共享给多个程序——它们都以「一段字节、多种解释」为前提。

## 本课完成后的能力与边界

学完本课后，你可以：

- 在一个 `01` 记录内为负载区声明两个同层 `05` 视图，说明它们从同一偏移开始、不额外占用存储。
- 用本课的字节清单核对 28 字节记录的偏移与长度，并解释 `9(5)V99` 为什么存储 7 字节却显示 8 个字符。
- 预测按第二个视图写入后，12 行输出里哪几行改变、哪几行不变，并用字节位置算出新值。
- 复现两类边界：重定义项更长会让编译失败；把字母放进 `9(5)V99` 覆盖的字节不会报错。
- 说明 `REDEFINES` 不拷贝、不转换、不校验——交易码与负载内容的相符关系只能由接口契约保证。

边界：本课不读终端、文件或数据库，样例值全是程序内常量；程序不按交易码分支，只是把两个视图各打印一次。`OCCURS` 表格见第 [11](../11_occurs-tables/README.md) 课，真实定长报文的读取见第 [17](../17_fixed-length-files/README.md) 课，共享布局见第 [23](../23_copybooks/README.md) 课，而负载内容的校验与拒绝策略要到第 [15](../15_sequential-file-read/README.md) 课之后有了真实输入、并在第 [26](../26_error-handling/README.md) 课才系统处理。

## 运行环境

- GnuCOBOL 3.2.0，默认方言（不加 `-std=cobol85`），源文件为固定格式：第 7 列指示符、Area A 从第 8 列、Area B 从第 12 列起，程序文本不越过第 72 列。
- Linux 终端，无需数据库、附加工具或第三方库。
- 命令在本课目录 `lessons/10_redefines/` 下执行；源码参数写的是 `lesson.cob`，换目录执行要自己改路径。

## 业务与知识点

### 一份字节，两种布局

`lesson.cob` 只有一条 `01` 记录：第 1 字节是交易码（不在重定义区内），第 2–28 字节是 27 字节负载区。存款（`D`）的负载是「账户号、金额、参考号」，转账（`T`）是「来源账户、目标账户、金额」；两个视图都从负载区第 1 字节开始、都占 27 字节。

`REDEFINES` 让重定义项（object）占用被重定义项（subject）的同一段物理存储。它不是第二份存储，也不是转换：**同一批字节，看你用哪个字段名去读**。

与第 [09](../09_group-items/README.md) 课的差别也在这里：那一课讲层级本身（组项、基本项、用 `OF` 限定同名子项），本课讲**同一层级位置上的两种解释**——两个视图的字段名之间没有 `OF` 前缀关系，读同一批字节会得到两组完全不同的值。

### REDEFINES 的硬性约束

GnuCOBOL Programmer's Guide 6.9.37 列出以下规则，本课逐条满足：

- subject 与 object 层级号必须相同（本例同为 `05`），且不能是 66、78、88 级。
- object 必须紧邻 subject：两者之间不得插入同级的其他数据项（除非它们也是该 subject 的 `REDEFINES`），也不得插入层级号更小的项；本机把 `REDEFINES` 挪到其他数据项之后，诊断是 `error: REDEFINES 句は参照元の項目の直後になければなりません`，返回码 `1`。
- 两者的**总分配字节数必须相同**。本机实测这台 GnuCOBOL 3.2.0 只在 **object 更大**时报错：把 `WS-TARGET-ACCOUNT` 改成 `X(11)`（28 字节 > 27 字节）后 `cobc -fsyntax-only` 返回码 `1`，诊断 `error: larger REDEFINES used`；改成 `X(9)`（26 字节）却能编译通过（返回码 `0`），此时 subject 尾部多出的字节不在第二个视图的声明范围内。所以「等长」是**你要自己保证**的规则，编译通过不等于合规。
- subject 和 object 自身不得带 `OCCURS`；两者都是组项时，组内子项可以有。
- object 及其从属项不得写 `VALUE`（88 级条件名除外）。本机实测对 `WS-TRANSFER-PAYLOAD` 加 `VALUE "X"` 并未在编译期被拒绝（返回码 `0`），但同一段共享字节由两个视图初始化是含混的，所以本课把负载初值留在过程部用 `MOVE` 显式写入。

### 视图不会自动校验

`REDEFINES` 只声明布局，它不做三件事：不拷贝（第二次写入直接覆盖第一次的 27 字节）、不转换（`9(5)V99` 不会把 `X` 视图里的字母变成数字）、不校验（没人检查交易码与哪个视图相符）。本课最后 4 行输出就是故意破坏契约的后果：转账的字节被当成存款读，程序照样正常结束、退出码仍是 `0`。**谁来选择视图？** 业务类型码，也就是上游接口契约；本课程序只把交易码原样打印出来，一个字都没有用它做判断。

## 输入与规则

**输入：** 无外部输入。样例值全部是 `lesson.cob` 过程部里的 `MOVE` 字面量，不读键盘、文件或数据库，所以每次运行结果完全一样。

**字节布局（本机用 `FUNCTION LENGTH` 实测）：** 记录 28 字节 = 交易码 1 字节 + 负载区 27 字节；`WS-DEPOSIT-PAYLOAD` 与 `WS-TRANSFER-PAYLOAD` 都是 27 字节。位置按负载区（或记录）第 1 字节起算：

| 视图 | 基本项 | `PIC` / 字节 | 负载区内位置 | 记录内位置 |
|---|---|---|---:|---:|
| 存款 `D` | `WS-ACCOUNT-NUMBER` | `X(10)` / 10 | 1–10 | 2–11 |
| 存款 `D` | `WS-DEPOSIT-AMOUNT` | `9(5)V99` / 7 | 11–17 | 12–18 |
| 存款 `D` | `WS-REFERENCE` | `X(10)` / 10 | 18–27 | 19–28 |
| 转账 `T` | `WS-SOURCE-ACCOUNT` | `X(10)` / 10 | 1–10 | 2–11 |
| 转账 `T` | `WS-TARGET-ACCOUNT` | `X(10)` / 10 | 11–20 | 12–21 |
| 转账 `T` | `WS-TRANSFER-AMOUNT` | `9(5)V99` / 7 | 21–27 | 22–28 |

`PIC 9(5)V99` 存 7 个数字位，`V` 是隐含小数点、**不占存储**，只在 `DISPLAY` 时按位置渲染，所以显示成 8 个字符的 `00125.50`。本课金额是两位小数的演示记账单位，没有币种字段；程序只做 `MOVE` 和 `DISPLAY`，不做算术，因此不涉及舍入与溢出。

**规则、前提与校验责任人：**

| 规则 / 前提 | 由谁保证 | 本课是否校验 |
|---|---|---|
| 两个视图总长相同（27 字节） | 手册规则；本工具链只在 object 更大时报错 | 部分——更长会编译失败，更短会静默通过 |
| object 紧邻 subject 且同为 `05` 级 | 编译器 | 是，违反则编译失败 |
| 交易码与负载布局的对应（`D`=存款、`T`=转账） | 上游接口契约 | **否**，程序只回显交易码 |
| 负载字节内容符合所选视图的字段类型 | 上游接口契约 | **否**——把字母放进 `9(5)V99` 覆盖的字节不会报错 |
| 存款负载被转账负载覆盖后不再是有效存款记录 | 使用者的解读纪律 | **否**，程序不做任何判断 |

演示数据说明：账户号、金额和参考号都是教学演示值，不代表任何真实业务政策。

## 完整示例源码

完整源码见 [`lesson.cob`](./lesson.cob)，按固定格式编写。

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. REDEF10.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-RECORD.
          05 WS-TRANSACTION-CODE PIC X.
          05 WS-DEPOSIT-PAYLOAD.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-DEPOSIT-AMOUNT PIC 9(5)V99.
             10 WS-REFERENCE PIC X(10).
          05 WS-TRANSFER-PAYLOAD REDEFINES WS-DEPOSIT-PAYLOAD.
             10 WS-SOURCE-ACCOUNT PIC X(10).
             10 WS-TARGET-ACCOUNT PIC X(10).
             10 WS-TRANSFER-AMOUNT PIC 9(5)V99.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-LOAD-DEPOSIT
           PERFORM 2000-LOAD-TRANSFER
           STOP RUN.
       1000-LOAD-DEPOSIT.
           MOVE "D" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER
           MOVE 125.50 TO WS-DEPOSIT-AMOUNT
           MOVE "TXN-000001" TO WS-REFERENCE
           DISPLAY "取引種別=" WS-TRANSACTION-CODE
           DISPLAY "入金口座=" WS-ACCOUNT-NUMBER
           DISPLAY "入金額=" WS-DEPOSIT-AMOUNT
           DISPLAY "入金参照番号=" WS-REFERENCE.
       2000-LOAD-TRANSFER.
           MOVE "T" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-SOURCE-ACCOUNT
           MOVE "0007654321" TO WS-TARGET-ACCOUNT
           MOVE 250.75 TO WS-TRANSFER-AMOUNT
           DISPLAY "取引種別=" WS-TRANSACTION-CODE
           DISPLAY "振込元口座=" WS-SOURCE-ACCOUNT
           DISPLAY "振込先口座=" WS-TARGET-ACCOUNT
           DISPLAY "振込金額=" WS-TRANSFER-AMOUNT
           DISPLAY "同じバイト列の入金ビュー:"
           DISPLAY "口座=" WS-ACCOUNT-NUMBER
           DISPLAY "金額=" WS-DEPOSIT-AMOUNT
           DISPLAY "参照番号=" WS-REFERENCE.
```

上面省略了源码中的注释行。源码注释只写规则与契约（样例值固定在程序内、交易码由接口契约保证且 `REDEFINES` 不校验也不选择视图、重定义项必须紧邻且不得更长、最后 4 条 `DISPLAY` 是故意错读），不逐条复述 `DISPLAY` 的文本。

## 源码阅读路径

1. `01 WS-TRANSACTION-RECORD`（28 字节）：第 1 字节是交易码，第 2 字节起才是负载区；两个视图都从负载区第 1 字节开始，所以后来改交易码不会破坏负载字节。
2. `05 WS-DEPOSIT-PAYLOAD` 与紧邻的 `05 WS-TRANSFER-PAYLOAD REDEFINES ...`：同为 `05` 级、连续声明、都是 27 字节。这一步是「同长」的书面依据。
3. `1000-LOAD-DEPOSIT`：按存款视图写入 4 个值并打印。此时转账视图的字段名已经指向同一批字节，只是还没有人这样读。
4. `2000-LOAD-TRANSFER`：先改交易码（独立字节），再按转账视图写入负载——这一次写入把第一次的 27 字节**逐字节覆盖**，负载存储区始终只有一份。
5. 最后 4 条 `DISPLAY`：交易码仍是 `T`，却用存款视图读同一批字节。为什么读到 `00076.54` 和 `3210025075`，见下一节。

## 运行与观察

**命令及作用：**

```sh
mkdir -p build                                   # 先建输出目录，否则 -o 会因目录不存在而失败
cobc -fsyntax-only lesson.cob                    # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_10 lesson.cob      # 编译并生成可执行文件
./build/lesson_10                                # 运行，两个视图的输出写到标准输出
echo $?                                          # 查看上一条命令的退出码
rm -rf build                                     # 清理编译产物
```

`-fsyntax-only` 只证明源码能通过语法解析；`-x`/`-o` 才生成可执行文件，返回码 `0` 且无诊断才表示编译通过；运行可执行文件才能看到两个视图对同一批字节的解释；`rm -rf build` 只删编译产物，本课不产生业务数据文件。

**预期结果（原始初值）：**

| 观察项 | 预期值 |
|---|---|
| `cobc -fsyntax-only` 退出码 | `0` |
| `cobc -x -Wall` 退出码 | `0`，无编译诊断 |
| 标准输出 | 下面 12 行 |
| 进程退出码（`echo $?`） | `0` |
| 生成文件 | 仅 `build/lesson_10` |

```text
取引種別=D
入金口座=0001234567
入金額=00125.50
入金参照番号=TXN-000001
取引種別=T
振込元口座=0001234567
振込先口座=0007654321
振込金額=00250.75
同じバイト列の入金ビュー:
口座=0001234567
金額=00076.54
参照番号=3210025075
```

中文对照：`取引種別` = 交易码，`入金口座` = 存款账户号，`入金額` = 存款金额，`入金参照番号` = 存款参考号，`振込元口座` = 转账来源账户，`振込先口座` = 转账目标账户，`振込金額` = 转账金额，`同じバイト列の入金ビュー:` =「同一字节序列的存款视图：」，`口座` = 账户号，`金額` = 金额，`参照番号` = 参考号（业务输出沿用仓库的日文约定；判断程序行为以实际输出与本节换算为准）。

最后 3 行由字节位置决定，可以手算核对：目标账户 `0007654321` 占负载区 11–20，存款视图的金额读 11–17 位得 `0007654` → 显示 `00076.54`；参考号读 18–27 位，即目标账户最后三位 `321` 接上转账金额的 7 个数字 `0025075` → `3210025075`。这不是有效存款记录，只是同一批字节的另一种读法。

**实际观察到的环境细节：** 在本工作区运行 `./build/lesson_10` 时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境链接库版本差异产生的警告，不是本程序的业务输出，触发组件尚未定位。业务输出全部在标准输出，退出码为 `0`。

### 证据来源与验证范围

本课所有可执行结论都在本工作区用 GnuCOBOL 3.2.0 实际执行过：`-fsyntax-only` 与 `-x -Wall` 返回码均为 `0`、无编译诊断，运行退出码为 `0`，标准输出与上面逐字节一致（12 行）。字节数（28 / 27 / 27 / 10 / 7 / 10 / 10 / 10 / 7）与两个视图的起始偏移由单独的 `FUNCTION LENGTH` 程序实测。四个边界各改一处实测：object 改成 `X(11)`（更长）编译返回码 `1`、诊断 `larger REDEFINES used`；改成 `X(9)`（更短）返回码 `0`；把 `REDEFINES` 挪到其他数据项之后编译返回码 `1`；把交易码改成 `X` 后 12 行里只有 `取引種別=` 一行变化，其余逐字节相同。另把 `WS-TARGET-ACCOUNT` 改成 `ABC7654321`（非数字）后程序仍返回 `0`，`金額=ABC76.54` 被原样打印——视图确实不做校验。**未验证**的场景：文件或数据库输入、按交易码分支选择视图、负载内容与记录长度的校验逻辑——本课程序里都没有这些路径，所以无从运行。

## 实战位置

真实系统里这类记录通常还会带版本号、记录长度、校验位和交易码的合法值域，接收方要先按长度和类型码选定布局，再校验各字段格式，校验失败要拒收而不是照原样解释。`REDEFINES` 只负责「同一段字节可以有多个视图」，上面这些保证一条都不提供。

本课的 28 字节布局是后面几课的公共素材：第 [11](../11_occurs-tables/README.md) 课用 `OCCURS` 把「交易码 + 金额」的 8 字节出现项重复成表（容量、已装载数量、遍历上界），第 [14](../14_data-structures-practice/README.md) 课用同样的「交易码 + 27 字节负载」做内存中的账户匹配，第 [17](../17_fixed-length-files/README.md) 课要把它落成真实定长文件（宽度、偏移、换行必须一起冻结），第 [23](../23_copybooks/README.md) 课用 Copybook 把这份布局共享给匹配程序，第 32 课的综合批次负责版本与内容校验。

## 练习与参考

### 修改练习（有答案）

从本课原始 [`lesson.cob`](./lesson.cob) 开始，把 `2000-LOAD-TRANSFER` 中转账金额的 `MOVE` 值由 `250.75` 改为 `99.99`，只允许改这一处。预期 12 行输出里**只有两行变化**：`振込金額=00250.75` → `00099.99`，`参照番号=3210025075` → `3210009999`；`金額=00076.54` 保持不变，因为它只由目标账户的前七位决定。完整题目（基线、改动约束、命令、逐行预期差异、需要回答的问题）见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

### 举一反三练习（无答案）

为「现金取款」和「账户间转账」设计两个共用同一段负载的 `05` 视图：先写出每个基本项的 `PIC` 和总字节数，确认两个视图等长，再设置交易码、按所选视图写入样例值并打印；最后用另一个视图读一次，解释为什么那份输出不能当作有效的原交易。自己记录命令、输出和退出码。题目见 [`exercise.md`](./exercise.md)，本题不提供答案。

## 参考资料

- [GnuCOBOL Programmer's Guide：REDEFINES（6.9.37）](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#REDEFINES)
- [GnuCOBOL Programmer's Guide：Data Definition Principles（6.1）](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Data-Definition-Principles)
- [课程总目录](../DIRECTORY.md)
- [仓库课程主页](../../README.md)
