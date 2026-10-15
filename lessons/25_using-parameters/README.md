# 第 25 课：USING——调用参数的数据方向与接口契约

银行批次把校验和显示逻辑拆成独立子程序后，主程序和子程序之间必须说清"哪个参数是输入、哪个由子程序写回"。本课用一个共享的接口 Copybook 和一个由三个源文件链接而成的可执行程序，把同一个 `BINARY-LONG` 参数分别按 `BY REFERENCE`、`BY CONTENT`、`BY VALUE` 传给两个子程序，观察子程序能否改动调用方存储，并把观察结果固化成后续编码批次要遵守的参数方向约定。

## 为什么现在学

[第 24 课](../24_call-subprograms/README.md) 你已经会用 `CALL`、`LINKAGE SECTION`、`PROCEDURE DIVISION USING` 和 `GOBACK` 传递字段。但那一课只用了默认传递方式，回答不了三个实际问题：子程序只想读参数时，怎样避免它改到调用方存储？参数是二进制数值而不是显示字段时，接口怎么写？子程序内部看到的值和调用方看到的值是什么关系？

缺口就是**数据方向**：`USING` 的参数到底是地址还是数值、谁负责更新、调用方什么时候能看到变化。不先定清这一点，后面用 `CALL ... USING` 拆分子程序、共享记录定义时（[第 28 课](../28_modular-batch-project/README.md)），每个参数的读写责任只能靠猜；猜错的后果本课会用实测结果展示（见下文"主题边界"）。

## 本课完成后的能力与边界

学完本课后，你可以：

- 让同一个 `AMOUNT-ARGUMENT` 分别按三种方式传给子程序，读出调用方字段在调用后分别是 `11`、`20`、`30`，并说明每个数字来自"子程序改了调用方存储 / 子程序只改了临时副本 / 子程序只收到数值"。
- 指出 `ADD-ONE` 的 `PROCEDURE DIVISION USING` 没写方式即等价于 `BY REFERENCE`，而 `REPORT-BINARY` 写的是 `BY VALUE`，两者的调用方写法必须对应。
- 用一份 Copybook 让调用方（`WORKING-STORAGE`）和两个子程序（`LINKAGE`）共享同一份参数声明，并说明宽度或符号不一致时接口为什么会失效。
- 读出自检输出与退出码：三项检查全部通过时 `集計 合格=003 不合格=000` 且退出码为 `0`；任一项不符时出现 `確認=失敗` 且退出码为 `1`。
- 复述 GnuCOBOL 3.2.0 对 `BY VALUE` 的编译警告原文，并说明为什么本课只把它当作"在已验证工具链上的演示"，而不是稳定的跨平台契约。

边界：本课不实现业务规则，只演示三种传递方式的数据方向——不校验金额、不读写任何数据文件、不返回业务状态字段。参数个数、类型或传递方式不匹配时的行为不属于本课承诺，本课也不保证跨编译器或跨平台的 ABI 兼容。用参数写回业务结论（`VALID`/`REJECTED`）的做法放在举一反三练习；[第 28 课](../28_modular-batch-project/README.md) 会用 `CALL ... USING` 组织多程序、多 Copybook 的工程。

## 运行环境

- GnuCOBOL 3.2.0，默认方言（不加 `-std=cobol85`），源文件为固定格式。
- Linux 终端；不需要数据库或第三方工具。
- 三个源文件必须一起编译链接：主程序 `lesson.cob` 调用 `add_one_25.cob`（`PROGRAM-ID. ADD-ONE`）和 `report_binary_25.cob`（`PROGRAM-ID. REPORT-BINARY`）。
- 参数声明来自 `copybooks/AMOUNT-INTERFACE.CPY`，编译时需要能解析 `COPY "AMOUNT-INTERFACE.CPY"`，因此命令里必须加 `-I copybooks`。
- 程序不读也不写业务文件，运行结果只有标准输出；可执行文件放进 `build/`。

## 业务场景与知识点

### 三种传递方式各解决什么问题

主程序要在同一个参数上做三次实验，观察不同传递方式下"谁拥有这份存储"：

| 传递方式 | 调用方写什么 | 子程序看到什么 | 子程序能否改到调用方字段 | 本课调用后调用方字段 |
|---|---|---|---|---|
| `BY REFERENCE` | 把字段的存储地址交出去 | 同一个存储区 | 能 | `11` |
| `BY CONTENT` | 交出内容的一份临时副本 | 一份临时副本 | 不能（只改副本） | `20` |
| `BY VALUE` | 交出完整字长的数值本身 | 数值参数 | 不适用：`REPORT-BINARY` 只读 | `30` |

三种结果对应三种接口用途：需要子程序写回结果用 `BY REFERENCE`；只希望子程序消费输入、不允许它污染调用方存储用 `BY CONTENT`；参数是二进制数值（例如与 C 侧共享的整数）时才能考虑 `BY VALUE`。

### 位置匹配与共享声明

`USING` 的参数按**位置次序**匹配，名字不参与匹配：第 1 个实参对应子程序 `PROCEDURE DIVISION USING` 列出的第 1 个形参。子程序还需要在 `LINKAGE SECTION` 里用同样的声明"接住"这块存储，所以调用方和子程序必须 `COPY` 同一份 `AMOUNT-INTERFACE.CPY`。本课这个参数声明为：

```cobol
       01 AMOUNT-ARGUMENT USAGE BINARY-LONG.
```

它不带 `PIC`，是 GnuCOBOL 的完整字长二进制用法：本课用 `LENGTH OF` 探针实测为 **4 字节有符号**（可保存 `-5` 并正确往返），因此 `BY VALUE` 传的就是一个 4 字节整数。

### 与第 24 课的区别

第 24 课只有一种隐式的 `BY REFERENCE`，子程序总是就地改写调用方的结果字段；本课把"数据方向"变成**显式选择**，并给出核对手段：三种方式各自跑一遍，再比较调用方字段是否等于程序里写死的预期值。

## 输入与规则

- **输入：** 没有外部文件，也没有命令行参数。三个测试值 `10`、`20`、`30` 和对应预期值 `11`、`20`、`30` 都硬编码在 `lesson.cob` 的 `1100/1200/1300` 段落里，属于演示数据，不是业务数据。
- **参数：** 只有一个参数 `AMOUNT-ARGUMENT`，类型 `USAGE BINARY-LONG`（4 字节有符号整数，无隐含小数）。它的含义是"一个待加一或待显示的整数"。
- **前提：** 调用方写法和子程序 `PROCEDURE DIVISION USING` 的声明方式必须一致；子程序对 `AMOUNT-ARGUMENT` 的修改只有在 `BY REFERENCE` 下才会回到调用方存储。
- **由代码校验的规则：** `8100-CHECK-ACTUAL` 比较"调用后调用方字段"与 `WS-EXPECTED`。相等 → `合格` 且按 `WS-MODE` 计入对应方式的计数；不等 → `不合格` 且**不计入**任何方式计数。
- **由代码保证的结论：** `WS-FAIL-COUNT` 不为零时 `MOVE 1 TO RETURN-CODE`。
- **未校验的前提：** 子程序实际读到的值是否等于调用方字段，程序不做检查（`BY CONTENT`/`BY VALUE` 的语义只能靠外部观察）；传递方式是否匹配也无人检查，编译器同样不会报错。

## 运行与观察

**执行目录：** 本课目录。程序不依赖相对文件名，编译产物放进 `build/`。

**命令及作用：**

```sh
mkdir -p build
cobc -fsyntax-only -I copybooks lesson.cob add_one_25.cob report_binary_25.cob   # 只做语法检查
cobc -x -Wall -I copybooks -o build/lesson_25 \
  lesson.cob add_one_25.cob report_binary_25.cob                                 # 编译并链接三个程序
./build/lesson_25                                                                # 运行
echo $?                                                                          # 查看退出码
rm -rf build                                                                     # 清理可执行文件
```

- `-fsyntax-only` 只解析语法，**不**生成也不运行程序；它不能替代编译和运行观察。
- `-x` 要求 `cobc` 生成可执行程序，`-o` 指定输出路径；三个源文件在同一条命令里一起交给 `cobc`，链接成一个可执行文件。
- `-I copybooks` 让 `COPY "AMOUNT-INTERFACE.CPY"` 能被找到。漏掉它会直接编译失败：`lesson.cob:12: error: AMOUNT-INTERFACE.CPY: そのようなファイルやディレクトリはありません`，随后 `lesson.cob:35: error: 'AMOUNT-ARGUMENT' is not defined` 等共 6 条 `error`，编译命令退出码 `1`。
- `rm -rf build` 只删除本课自己生成的可执行文件；本课不产生业务数据文件。

**预期结果（正常路径）：**

| 观察项 | 预期值 |
|---|---|
| `cobc -fsyntax-only` 退出码 | `0`，标准错误有 1 条 `BY VALUE` 未完成功能的警告 |
| `cobc -x -Wall` 退出码 | `0`，标准错误仍只有同一条警告，无其他诊断 |
| 标准输出 | 11 行、540 字节（UTF-8），见下方代码块 |
| 进程退出码（`echo $?`） | `0` |
| 生成文件 | 仅 `build/lesson_25` |

```text
呼出側=呼出前 方式=BY REFERENCE 値=000000010
被呼出側=加算後 値=000000011
呼出側=呼出後 方式=BY REFERENCE 値=000000011 確認=合格
呼出側=呼出前 方式=BY CONTENT 値=000000020
被呼出側=加算後 値=000000021
呼出側=呼出後 方式=BY CONTENT 値=000000020 確認=合格
呼出側=呼出前 方式=BY VALUE 値=000000030
被呼出側=受取値=000000030
呼出側=呼出後 方式=BY VALUE 値=000000030 確認=合格
集計 合格=003 不合格=000
方式 BY REFERENCE=001 BY CONTENT=001 値=001
```

**编译警告（原文与含义）：** 语法检查和 `-Wall` 编译都会在标准错误打印同一条警告（行号取自本课当前源码 `report_binary_25.cob` 第 11 行）：

```text
report_binary_25.cob:11: warning: handling of parameters passed BY VALUE is unfinished; implementation is likely to be changed [-Wunfinished]
```

含义：GnuCOBOL 3.2.0 认为 `BY VALUE` 的实现尚未定稿、后续版本可能改变行为，所以它不适合作为"已经稳定的"接口约定。`-Wunfinished` 是它的警告类别；编译仍然成功（退出码 `0`），程序在本工具链上按上面的结果运行。本课保留这种写法是为了用可观察结果讲清数据方向，而不是推荐把它用于生产接口；真实的跨语言或长期接口应先针对选定的 GnuCOBOL 版本验证，或改用本课另两种方式。

**逐条核对（这个例子说明什么）：**

1. `BY REFERENCE`：调用前调用方是 `10`，`ADD-ONE` 把 `AMOUNT-ARGUMENT` 加一后显示 `11`，调用返回后调用方也读到 `11`。子程序改的就是调用方的存储。
2. `BY CONTENT`：调用前是 `20`，子程序内部显示 `21`，但调用返回后调用方仍是 `20`。子程序加的是临时副本，改动被丢弃。
3. `BY VALUE`：`REPORT-BINARY` 显示 `30`，只读不写，调用方字段保持 `30`。
4. 三项自检全部通过（`合格=003`），三种方式各计入一次，退出码 `0`。

**输出字段对照（输出标签 → 含义）：** `呼出側=呼出前` 调用方在 `CALL` 之前的字段值；`被呼出側=加算後` `ADD-ONE` 内部看到的值（`BY CONTENT` 时是副本）；`被呼出側=受取値` `REPORT-BINARY` 收到的数值；`呼出側=呼出後` 调用返回后调用方的字段值；`確認=合格/失敗` 该次自检结论；`集計 合格/不合格` 三项自检的通过/失败数。

注意最后一行 `方式 BY REFERENCE=001 BY CONTENT=001 値=001` 的标签有词不达意之处：这一行分别打印三种方式的自检通过次数，但程序把第三列（`BY VALUE` 的计数）标成了 `値=`（"值"），而不是 `BY VALUE=`。所以这里的 `値=001` 是**次数**，不是前面那个数值 `30`。以本节对照表为准。

**主题边界：传递方式写错会怎样（实测，不是预期行为）**

`USING` 的方式由调用方和子程序各自声明，编译器**不核对两者是否一致**。本课在已验证的工具链上做了两组反例：

- 调用方写 `BY VALUE`、子程序仍是默认 `BY REFERENCE`：编译退出码仍为 `0`（只有原有的 `BY VALUE` 警告），但运行时立即中止，标准错误出现 `attempt to reference invalid memory address (signal)`，进程退出码 `139`，标准输出只打印到第一行 `BY REFERENCE` 的调用前值。
- 调用方写 `BY REFERENCE`、子程序声明 `BY VALUE`：编译和运行都"成功"（退出码 `0`），子程序却把地址当成数值打印，`被呼出側=受取値=` 在四次运行中分别出现 `802200896`、`631190208`、`646650048`、`937214656` 等互不相同的垃圾值，而调用方的自检仍然显示 `合格`——因为 `8100-CHECK-ACTUAL` 只看调用方自己的存储，看不到子程序那边发生了什么。

这就是接口契约为什么必须靠 Copybook、命名和评审固定，而不能指望编译器或自检拦住。**本课不把这些观察当作跨平台结论**：它们只说明在 GnuCOBOL 3.2.0 / 本仓库工具链上，方式不一致既可能崩溃也可能静默给出错误数值。

**失败路径：自检不合格时的退出码**

把 `1100-TEST-REFERENCE` 的 `WS-EXPECTED` 从 `11` 改成 `99`（不做其他修改）后重编译运行，实际观察：

| 观察项 | 实际值 |
|---|---|
| `cobc -x -Wall` 退出码 | `0` |
| 该行输出 | `呼出側=呼出後 方式=BY REFERENCE 値=000000011 確認=失敗` |
| 汇总行 | `集計 合格=002 不合格=001` |
| 方式计数行 | `方式 BY REFERENCE=000 BY CONTENT=001 値=001` |
| 进程退出码 | `1` |

两个细节值得记住：失败的那一项**不会**计入方式计数（`BY REFERENCE=000`），而 `RETURN-CODE` 被置为 `1`，调用它的脚本或批次构建可以据此判定接口行为不符合预期。

**标准错误不是业务输出：** 运行时标准错误会出现 `Warning: program compiled against libxml 212 using older 209`。这是本工作区链接库版本差异产生的环境警告，与编译期那条 `BY VALUE` 警告是两条不同的信息，都不属于本程序的业务输出。

## 源码阅读路径

按"数据方向"读，而不是逐行读：

1. `copybooks/AMOUNT-INTERFACE.CPY`：只有一行有效声明，`01 AMOUNT-ARGUMENT USAGE BINARY-LONG.`。它不做 `PIC` 编辑，三份程序共用同一份声明是接口成立的前提。
2. `lesson.cob` 的 `WORKING-STORAGE SECTION` 以 `COPY "AMOUNT-INTERFACE.CPY".` 引入参数：调用方把参数放进 `WORKING-STORAGE`。`WS-EXPECTED`、`WS-ACTUAL` 都是同类型的 `BINARY-LONG`，`WS-EDITED-ACTUAL` 是 `PIC 9(9)`，只负责把二进制值格式化成 9 位数字显示。
3. `1100-TEST-REFERENCE`：先写入 `10` 和预期 `11`，显式写 `BY REFERENCE` 调用 `ADD-ONE`。这里的"显式"是教学用；不写方式时默认也是 `BY REFERENCE`。
4. `1200-TEST-CONTENT`：同一子程序、同一实参，只把方式换成 `BY CONTENT`，预期值设为 `20`（调用方不应被改动）。
5. `1300-TEST-VALUE`：调用另一个子程序 `REPORT-BINARY`，方式 `BY VALUE`，预期值 `30`。
6. `add_one_25.cob`：`LINKAGE SECTION` 里 `COPY` 同一份声明，`PROCEDURE DIVISION USING AMOUNT-ARGUMENT` 未写方式即 `BY REFERENCE`，`ADD 1 TO AMOUNT-ARGUMENT` 直接写进调用方（或副本）的存储。
7. `report_binary_25.cob`：唯一差别是 `PROCEDURE DIVISION USING BY VALUE AMOUNT-ARGUMENT`；`AMOUNT-ARGUMENT` 在这里是"数值参数"，程序只用 `MOVE` 读出它。
8. `8100-CHECK-ACTUAL`：把调用后的调用方字段搬进 `WS-ACTUAL` 与 `WS-EXPECTED` 比较，相等则计数并显示 `合格`，不等则只加 `不合格`；`9000-DISPLAY-SUMMARY` 打印汇总，`0000-MAIN` 在 `WS-FAIL-COUNT` 非零时把 `RETURN-CODE` 置 `1`。

## 固定格式核对（按字节）

`cobc` 3.2.0 在 UTF-8 源文件中按**字节**计算列位置，所以中文注释也要量字节。用下面三条命令核对本课四个源文件（`LC_ALL=C` 让 `awk` 按字节计数）：

```sh
for f in lesson.cob add_one_25.cob report_binary_25.cob copybooks/AMOUNT-INTERFACE.CPY; do
  LC_ALL=C awk 'length($0)>72 {print "over72", FILENAME, FNR, length($0)}' "$f"
  LC_ALL=C awk '/^      \*/ {next} {i=match($0,/[^ ]/); if (i>0 && (i<8 || (i>=9 && i<=11))) print "bad column", FILENAME, FNR, i}' "$f"
  LC_ALL=C awk '{if (length($0)>m) {m=length($0); n=FNR}} END {print FILENAME, "max bytes", m, "line", n}' "$f"
done
```

实测结果：前两条命令对四个文件都没有输出；第三条分别输出 `lesson.cob max bytes 70`、`add_one_25.cob max bytes 69`、`report_binary_25.cob max bytes 71`、`copybooks/AMOUNT-INTERFACE.CPY max bytes 70`（都在第 1 行，即最长的中文注释行）。所有可执行程序文本只从第 8 列（Division、`01` 级、段落名）和第 12 列（语句）开始；本课只有一个 `01` 级参数、没有 `05` 级字段，若以后在 Copybook 里给参数增加从属层级，按仓库约定 `05` 级写在第 11 列。注释一律在第 7 列写 `*`。`-fsyntax-only` 不会报出列位置问题，列位置是否合规要看上面的命令，不能指望编译器报错。

## 修改练习（有答案）

两项都从**当前源码**（即上面的三个 `.cob` 和 Copybook）开始，改完都要重新执行同一条 `cobc -x -Wall -I copybooks ...` 命令。完整题目与初始值见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

1. **把子程序增量改成 2**：在 `add_one_25.cob` 中把 `ADD 1 TO AMOUNT-ARGUMENT` 改成 `ADD 2 TO AMOUNT-ARGUMENT`，并在 `lesson.cob` 的 `1100-TEST-REFERENCE` 中把 `WS-EXPECTED` 从 `11` 改成 `12`，其余不动。预期：`BY REFERENCE` 调用后调用方变为 `12`、`BY CONTENT` 调用后调用方仍为 `20`（但子程序内部显示 `22`）、`BY VALUE` 段不变，`集計 合格=003 不合格=000`、退出码 `0`。
2. **把第二次调用改成 `BY REFERENCE`**：在 `lesson.cob` 的 `1200-TEST-CONTENT` 中把 `CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT` 改成 `BY REFERENCE`，把该段 `WS-EXPECTED` 从 `20` 改成 `21`，并把该段 `WS-MODE` 从 `"BY CONTENT"` 改成 `"BY REFERENCE"`。预期：调用后调用方变为 `21`，该次成功被计入 `BY REFERENCE`，汇总变为 `方式 BY REFERENCE=002 BY CONTENT=000 値=001`，退出码 `0`。

## 举一反三（无答案）

扩展接口：给 `AMOUNT-INTERFACE.CPY` 增加第二个参数——一个由子程序写回 `VALID` 或 `REJECTED` 的状态字段。让子程序只通过 `BY REFERENCE` 把这个状态写回调用方，`CALL` 后用状态字段决定分支；然后**单独**把状态参数改成 `BY CONTENT`、重新编译运行，记录调用方是否还能收到状态。要求写清参数顺序、两个字段的 `PIC`/`USAGE`、调用前后各字段的值，并用至少两个输入值（一个合法、一个不合法）验证。作为边界核对，再故意让状态参数的传递方式和子程序声明不一致，记录你观察到的现象（编译是否报错、运行是否正常、状态字段是否可信）。

本题不提供答案。不要把 `BY VALUE` 用在 group item 或任意长度数据上，也不要假设三种传递方式具有相同的存储布局或跨平台行为。题目见 [`exercise.md`](./exercise.md)。

## 实战位置

批次工程的模块边界本质上是二进制接口：客户校验、金额校验、日志和报表子程序都靠 `USING` 约定"谁提供数据、谁写回结果"。真实项目固定接口的做法正是本课展示的三件事——共享 Copybook 固定参数布局、在接口处写清数据方向和前提、用可执行检查（本课的自检与退出码）验证接口行为，而不是靠口头约定。第 26 课把业务拒绝与系统故障分流成不同的状态与退出码，第 27 课为批次留下可追溯的日志，第 28 课用 `CALL ... USING` 把多个子程序和多份 Copybook 组织成可重复构建的工程，第 32 课的对账项目会在这些模块边界上传递真实记录。

本课尚未实现的部分：没有业务规则、没有输入输出文件、没有错误码定义，`RETURN-CODE` 只表示"自检是否通过"。真实接口还需要错误码版本、可空/缺失值策略和部署时的同步编译保证。

## 证据来源与验证范围

本文的每条观察都来自在当前仓库按上面命令实际执行的结果，范围如下：

| 场景 | 实际执行的命令 | 观察结果 |
|---|---|---|
| 正常路径 | 见"命令及作用"整段（`-fsyntax-only`、`-x -Wall`、运行、`echo $?`） | 编译 `0`、运行 `0`、标准输出 11 行 540 字节，与上方代码块逐字一致 |
| 缺 `-I` 的失败路径 | `cobc -fsyntax-only lesson.cob add_one_25.cob report_binary_25.cob`（去掉 `-I copybooks`） | 三个 `COPY` 全部报文件不存在、`AMOUNT-ARGUMENT` 未定义，退出码 `1` |
| 自检失败路径 | 把 `WS-EXPECTED` 改成 `99` 后重编译运行 | `確認=失敗`、`合格=002 不合格=001`、`BY REFERENCE=000`、退出码 `1` |
| 主题边界（方式不一致） | 分别把一处 `CALL` 改成与子程序声明相反的方式 | 一种组合运行中止（退出码 `139`），另一种运行给出变化不定的数值；详见"主题边界" |
| 修改练习 1、2 | 在临时目录复制本课源码后按题目修改并重编译运行 | 预期输出见 [`answer.md`](./answer.md)，与实测逐字一致 |

未纳入验证的范围：`BY VALUE` 与 C 侧函数、其他编译器或其他平台上的一致性；参数个数或 `PIC` 不匹配时的行为；`BY CONTENT` 副本在子程序内被修改后是否留有可观察痕迹。这些都不在本课承诺之内。

## 参考资料

- [GnuCOBOL Programmer's Guide：PROCEDURE DIVISION USING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-USING)
- [GnuCOBOL Programmer's Guide：CALL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#CALL)
- [GnuCOBOL Programmer's Guide：USAGE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#USAGE)
- [第 24 课：CALL——把校验逻辑拆成子程序](../24_call-subprograms/README.md)
- 仓库课程主页：[README.md](../../README.md)
