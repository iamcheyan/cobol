# 第 24 课：CALL——把金额校验拆成可独立调用的子程序

银行夜间批次里“金额能否入账”这条上限规则会被多个批次共用；把同一段判断抄进每个主程序，规则就会分叉。本课把这条规则搬进独立的程序单元 `CHECK-AMOUNT`，主程序用 `CALL ... USING` 传入金额、从第二个参数取回校验状态，并统计 8 笔演示金额的分类结果。

## 为什么现在学

你已经会用段落把流程拆成命名步骤（第 07 课），也会用 Copybook 让多个程序共享同一份数据声明（第 23 课）。缺口在过程代码一侧：段落只在本程序单元内可调用，Copybook 只复制声明、不复制逻辑。当另一个批次也要用同一条金额规则时，没有任何机制能复用它——除非把这段判断做成**可以单独编译、单独部署、被多个主程序调用**的程序单元。`CALL` 就是这条接口：调用方与被调方通过明确的位置参数交换数据，调用方在子程序返回后继续执行自己的流程。

## 本课完成后的能力与边界

学完本课后，你可以：

- 用 `CALL "PROGRAM-ID" USING ...` 把控制交给另一个程序单元，并说明控制怎样回到 `CALL` 的下一条语句。
- 用 `LINKAGE SECTION` 声明接收字段、用 `PROCEDURE DIVISION USING` 按位置把调用方字段与子程序字段绑定。
- 用 `GOBACK` 从子程序返回，并说明为什么主程序仍用 `STOP RUN` 结束整个运行单元。
- 把主程序与子程序源文件一起编译链接成一个可执行文件；也能把子程序单独编译成模块并说明运行时查找方式与漏编译时的实际现象。
- 读出 `VALID` / `ZERO-AMOUNT` / `LIMIT-EXCEEDED` 三种返回状态，并核对 8 笔用例的分类计数（`008 = 005 有效 + 003 拒绝`）。

边界：本课只使用默认的 `BY REFERENCE`。参数方向、`BY CONTENT` / `BY VALUE`、接口 Copybook 与 ABI 风险在第 25 课展开。子程序只返回**业务结果字段**，本课没有系统故障返回码（第 26 课）、没有日志（第 27 课）、不读文件也不读数据库。

## 运行环境

- GnuCOBOL 3.2.0，默认方言（不加 `-std=cobol85`），源文件为固定格式。
- Linux 终端；本课不依赖数据库或附加工具。
- 主程序通过标准输出报告结果，**不读写业务数据文件**；编译产物放在 `build/`（已被仓库忽略），运行完成后可整个删除。

## 主程序、子程序与调用契约

| 文件 | 角色 |
|---|---|
| [`lesson.cob`](./lesson.cob) | 主程序，`PROGRAM-ID. LESSON24`：准备 8 笔演示金额、执行 `CALL`、按状态计数、显示汇总 |
| [`amount_check_24.cob`](./amount_check_24.cob) | 子程序，`PROGRAM-ID. CHECK-AMOUNT`：按三条规则判定金额并把状态写回调用方字段 |

调用点只有一处，参数布局如下（次序即 `USING` 的位置，名字不参与匹配）：

| 位置 | 调用方字段 | 子程序 LINKAGE 字段 | PIC | 字节 | 数据方向 |
|---:|---|---|---|---:|---|
| 1 | `WS-AMOUNT` | `LK-AMOUNT` | `9(7)V99` | 9 | 调用方传入，子程序只读 |
| 2 | `WS-CHECK-RESULT` | `LK-CHECK-RESULT` | `X(15)` | 15 | 子程序写入，调用方读回 |

```cobol
           CALL "CHECK-AMOUNT" USING WS-AMOUNT WS-CHECK-RESULT
```

`BY REFERENCE` 是省略传递方式时的默认行为：子程序收到的是**调用方字段的地址**，不是副本。所以子程序执行 `MOVE "VALID" TO LK-CHECK-RESULT` 等于直接改调用方的 `WS-CHECK-RESULT`，不存在“返回值”这一说——结果是通过第二个参数带回来的。

这也是本课最需要记住的接口风险：`USING` 只按位置对齐，界面上没有参数名、没有类型、没有个数检查。在本工作区实测，`cobc -fsyntax-only` 与 `cobc -x -Wall` 对“调用方少传一个参数”和“子程序把结果声明成 `X(20)` 而调用方只给 15 字节”这两种错误**都不报错、退出码都是 0**；问题只在运行期暴露——少传参数时子程序解引用不存在的地址，程序以信号中止（实测退出码 `139`，标准错误 `attempt to reference invalid memory address`），多写字节则可能只是静默覆写相邻字段。生产接口要求把参数声明抽成共享 Copybook，由第 25 课处理。

## 校验规则

子程序 [`amount_check_24.cob`](./amount_check_24.cob) 用 `EVALUATE TRUE` 自上而下判断第一条成立的条件：

1. 金额等于零 → `ZERO-AMOUNT`。
2. 金额大于 1000.00 → `LIMIT-EXCEEDED`。
3. 其余情况 → `VALID`。

因此 **1000.00 本身是有效值**：它不满足 `> 1000.00`，落在第 3 条分支。这是本课的边界语义，也是练习 1 要观察的规则。金额字段是 `PIC 9(7)V99`，无符号，表示不了负数，所以不需要“负金额”检查；`9(7)V99` 的 `V` 是隐含小数点，不占字节，字段物理宽度是 9 字节。

## 八笔演示金额与可独立核算的结果

主程序 [`lesson.cob`](./lesson.cob) 的 `1000-RUN-CHECK-CASES` 依次执行 8 个段落，每个段落只负责设置一笔金额，然后交给共用的 `2000-CALL-AMOUNT-CHECK`。

| # | 段落 | 金额 | 期望状态 | 手工依据（对照上面三条规则） |
|---:|---|---:|---|---|
| 1 | `1100` | 125.50 | `VALID` | 非零且 ≤ 1000.00 |
| 2 | `1200` | 0.00 | `ZERO-AMOUNT` | 等于零 |
| 3 | `1300` | 1000.00 | `VALID` | 边界：不满足 `> 1000.00` |
| 4 | `1400` | 1000.01 | `LIMIT-EXCEEDED` | 超上限一分 |
| 5 | `1500` | 0.01 | `VALID` | 最小正金额 |
| 6 | `1600` | 999.99 | `VALID` | 上限前一分 |
| 7 | `1700` | 9999999.99 | `LIMIT-EXCEEDED` | `PIC 9(7)V99` 的最大值 |
| 8 | `1800` | 500.00 | `VALID` | 区间内 |

计数不变量：`检查总数 8 = 有效 5 + 拒绝 3`，且 `拒绝 3 = 零金额 1 + 超限 2`。第 3、4 笔是同一上限的两侧，第 2 笔是零金额的唯一来源。

## 运行与观察

**输入：** 无外部输入。8 笔金额是写在 `lesson.cob` 里的常量，`amount_check_24.cob` 不含数据夹具。

**命令及作用：**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob amount_check_24.cob                 # 语法检查两个源文件，不生成可执行文件
cobc -x -Wall -o build/lesson_24 lesson.cob amount_check_24.cob   # 两个源文件一起编译链接成一个可执行文件
./build/lesson_24                                                 # 运行，结果写标准输出
echo $?                                                           # 查看退出码
rm -rf build                                                      # 清理可执行文件
```

`-fsyntax-only` 只验证语法路径，不能替代编译与运行。子程序不是可执行入口，因此用 `-x` 时必须把两个源文件放在同一条命令里：`cobc` 把 `CHECK-AMOUNT` 一起装进 `build/lesson_24`。

**预期结果：**

| 观察项 | 预期值 |
|---|---|
| `cobc -fsyntax-only` 退出码 | `0` |
| `cobc -x` 退出码 | `0`，无编译诊断 |
| 标准输出 | 20 行，见下方代码块 |
| 进程退出码 | `0` |
| 生成文件 | 仅 `build/lesson_24` |

```text
调用方：开始
调用前 金额=0000125.50
调用返回 状态=VALID
调用前 金额=0000000.00
调用返回 状态=ZERO-AMOUNT
调用前 金额=0001000.00
调用返回 状态=VALID
调用前 金额=0001000.01
调用返回 状态=LIMIT-EXCEEDED
调用前 金额=0000000.01
调用返回 状态=VALID
调用前 金额=0000999.99
调用返回 状态=VALID
调用前 金额=9999999.99
调用返回 状态=LIMIT-EXCEEDED
调用前 金额=0000500.00
调用返回 状态=VALID
调用方：子程序返回后继续
检查总数=008 有效=005 拒绝=003
零金额拒绝数=001 超限拒绝数=002
```

**输出标签对照：** `调用前 金额=` 是调用方在 `CALL` 之前显示的金额；`调用返回 状态=` 是子程序写回后的结果字段；`调用方：子程序返回后继续` 证明控制回到了调用方；`检查总数`/`有效`/`拒绝`/`零金额拒绝数`/`超限拒绝数` 是主程序维护的计数。金额按 `PIC 9(7).99` 编辑格式显示，所以 `125.50` 打印成 `0000125.50`。

**实际观察到的环境细节：** 在本工作区运行 `./build/lesson_24` 时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境的链接库版本警告，不是本程序的业务输出；程序的标准输出与退出码不受影响。

## 源码阅读路径

按数据流读，比逐行读更容易看出主/子程序的职责分界：

1. `0000-MAIN` 显示开始标记 → `PERFORM 1000-RUN-CHECK-CASES` → 显示“子程序返回后继续” → `PERFORM 3000-DISPLAY-SUMMARY` → `STOP RUN`。
2. `1100`–`1800` 八个段落各自只做一件事：`MOVE <金额> TO WS-AMOUNT`，然后 `PERFORM 2000-CALL-AMOUNT-CHECK`。测试数据的顺序就是上一节表格的顺序。
3. `2000-CALL-AMOUNT-CHECK` 是调用方的接口包装：先 `MOVE SPACES TO WS-CHECK-RESULT`，再把金额移到 `WS-EDITED-AMOUNT`（`PIC 9(7).99`，只为带小数点显示），然后 `DISPLAY` 金额并 `CALL`。返回后它显示状态并 `PERFORM 2100-COUNT-CHECK-RESULT`。
4. `2100-COUNT-CHECK-RESULT` 用 `EVALUATE WS-CHECK-RESULT` 把状态映射到计数：`VALID` 计入有效，另外两种计入拒绝并各自累加原因计数，`WHEN OTHER` 作为兜底也计入拒绝。
5. 子程序 [`amount_check_24.cob`](./amount_check_24.cob) 只有 0000 一个段落：`EVALUATE TRUE` 判断 `LK-AMOUNT`，把字符串写进 `LK-CHECK-RESULT`，然后 `GOBACK`。它不显示任何内容，也没有自己的计数——**显示与统计全部归调用方，判定规则全部归子程序**。
6. 回到调用方后打印 `调用方：子程序返回后继续`，说明控制确实从 `CALL` 的下一条语句继续，程序没有被 `GOBACK` 提前结束；`STOP RUN` 才是整个运行单元的终点。

两处不直观的写法值得单独说明：

- **为什么调用前要清空结果字段。** 本版子程序三个分支都会写结果，清空只是防御性约定；若将来新增分支漏写，空值会落进 `WHEN OTHER` 被计为拒绝，而不会沿用上一笔的状态。
- **为什么显示时要 `FUNCTION TRIM(... TRAILING)`。** 结果字段是 15 字节定长，`MOVE "VALID"` 会右补空格；`TRIM` 去掉尾随空格后输出才对齐。`WHEN "VALID"` 这类比较则不需要处理：字母数字比较会把短的一方补空格到等长，所以 `"VALID"` 能匹配 15 字节的 `WS-CHECK-RESULT`。

## 退出码：业务拒绝不是系统故障

本课的结果字段与退出码是两条独立通道。`ZERO-AMOUNT`、`LIMIT-EXCEEDED` 是**业务拒绝**，它们只改变计数；主程序照常走完 8 笔用例并以 `STOP RUN` 正常结束，退出码仍是 `0`。子程序的 `GOBACK` 也不携带状态码——状态全部通过第二个参数传递。

真正产生非零退出码的是**系统故障**。一个可复现的例子是漏编译子程序：

```sh
cobc -x -Wall -o build/lesson_24 lesson.cob   # 只给主程序
./build/lesson_24
```

链接仍会成功，因为字面量 `CALL` 在 GnuCOBOL 里按 `PROGRAM-ID` 做**运行时模块查找**，不是把两个源文件静态绑死。运行到第一笔 `CALL` 时查找失败：

- 标准输出停在 `调用前 金额=0000125.50`（第 2 行）后中止；
- 标准错误输出 `libcob: error: module 'CHECK-AMOUNT' not found`；
- 退出码为 `1`。

可以把它和上面的正常运行对比：业务拒绝给出 `0`，模块缺失给出 `1`。区分这两类结果正是第 26 课错误处理要落实的契约。

## 主程序与子程序分别编译（可执行）

除了一起编译，也可以先把子程序编译成模块，再让主程序在运行时加载。模块文件名必须与 `PROGRAM-ID` 同名（是 `CHECK-AMOUNT.so`，不是 `amount_check_24.so`）：

```sh
mkdir -p build
cobc -m -Wall -o build/CHECK-AMOUNT.so amount_check_24.cob   # 子程序编译为可动态加载模块
cobc -x -Wall -o build/lesson_24 lesson.cob                  # 主程序单独编译
COB_LIBRARY_PATH=build ./build/lesson_24                     # 让运行时在该目录查找模块
rm -rf build
```

这种方式的标准输出与退出码和一起编译完全相同。它带来部署上的好处（模块可以单独替换），代价是多一层查找路径和命名契约；第 28 课会把这类构建固定成可重复的工程脚本。

## 修改练习

两项练习都在原始两个源文件上做，都需要**同时重新编译主程序与子程序**，因为判定规则在子程序里。

1. 把子程序的业务上限从 `1000.00` 提到 `1500.00`，观察 `1000.01` 的结果变化，并核对总计、有效数和超限数。
2. 从原始源码出发，把主程序 `1200-CHECK-ZERO-AMOUNT` 的金额从 `ZERO` 改成 `0.01`，观察“零金额”这一路的来源怎样消失。

完整题目、改动位置与预期结果见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

## 举一反三练习

为客户活动状态写第二个子程序：主程序传入一个客户状态字段，子程序让 `ACTIVE`、`FROZEN` 和未知状态产生三种不同结果；再调整主流程，使客户校验失败的交易不会进入金额校验子程序。要点是这个新接口的 `LINKAGE` 布局与调用位置都要由你自己定义，并说明在什么条件下才执行第二次 `CALL`。只使用本课学过的 `CALL`/`LINKAGE`/`GOBACK`/`EVALUATE`，不要引入文件或数据库。题目见 [`exercise.md`](./exercise.md)，本题不提供答案。

## 在企业中的位置

把可复用规则做成独立程序单元，是批处理系统里让多个主批次共享同一套判定的常规做法：金额上限、账户资格、交易码有效性都可能被抽成模块。它同时引入新的维护责任——`PROGRAM-ID`、参数次序、PIC 宽度、返回状态取值和部署时模块是否齐备，都必须由调用方与被调方共同遵守；参数类型不匹配在 COBOL 里往往是静默的存储覆写，而不是编译错误。

真实系统还需要本课没有的东西：显式的参数方向与传递方式、稳定的错误码版本与向后兼容策略、模块缺失/版本错配的告警与回退、以及判定过程的日志。参数方向与接口 Copybook 见第 25 课，系统故障与返回码分类见第 26 课，日志见第 27 课，把多个程序与 Copybook 组织成可重复构建的工程见第 28 课。

## 参考资料

- [GnuCOBOL Programmer’s Guide：CALL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#CALL)
- [GnuCOBOL Programmer’s Guide：PROCEDURE DIVISION USING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-USING)
- [GnuCOBOL Programmer’s Guide：GOBACK](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#GOBACK)
- [GnuCOBOL Programmer’s Guide：LINKAGE SECTION](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#LINKAGE-SECTION)
- 仓库课程主页：[README.md](../../README.md)
