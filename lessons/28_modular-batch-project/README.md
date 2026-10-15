# 第 28 课：综合练习——把批次拆成多程序工程

第四阶段之前，所有逻辑都写在一个程序里；真实批次要把共享记录、过账规则和结果报告分给不同程序单元，并由一个可重复的构建入口把它们组装起来。本课用四个 Copybook 定义模块接口，把过账和报告拆成两个独立子程序，用 `CALL ... USING BY REFERENCE` 传递可更新记录，最后用一个 `build.sh` 完成语法检查、分别编译、链接和运行。

## 为什么现在学

第 23–27 课你分别学过 Copybook 共享声明、`CALL`/`USING` 的参数方向、业务错误分类和批次日志，但它们都在单文件程序里演示。缺口是“工程化”：模块接口必须是一份共享的、可编译验证的声明；改了字段宽度，所有消费者都要重新编译；构建步骤必须可重复。本课把这些收进一个小工程，让接口不一致在构建期或运行期立刻暴露。

## 本课完成后的能力与边界

学完本课后，你可以：

- 把共享记录与状态放进 Copybook，供主程序和子程序以同一份声明编译。
- 把批次控制、过账规则与报告拆成三个程序单元，并说明各自拥有什么状态。
- 用 `CALL ... USING BY REFERENCE` 传递可更新记录，说明状态字段由谁写入、计数由谁维护。
- 用 `build.sh check|build|run|clean` 完成语法检查、模块编译、链接、运行与清理。
- 用 `expected-output.txt` 与 `expected-batch.log` 逐行核对标准输出与日志。

边界：样例交易固定写在主程序里，不读外部输入文件；构建脚本是本地单机脚本，不固定编译器版本、ABI 或产物版本。文件输入见第 15–22 课，日志与错误分类见第 26、27 课，数据库批次见第 29–32 课。

## 运行环境

- GnuCOBOL 3.2.0，默认方言（不加 `-std=cobol85`），源文件为固定格式。
- Linux 终端 + `bash`；`build.sh` 需要 PATH 里有 `cobc`（可用 `COBC` 环境变量指定其他编译器命令）。
- 构建目录默认是课内 `build/`（可用 `BUILD_DIR` 覆盖）；`build/` 已被仓库忽略，`./build.sh clean` 即可清除。程序在构建目录里运行，`batch.log` 与目标文件都落在那里。

## 项目文件

| 文件 | 职责 |
|---|---|
| [`lesson.cob`](./lesson.cob) | 主程序：开日志、初始化账户、准备五笔样例交易、`CALL` 过账模块、汇总状态并写日志 |
| [`post_transaction_28.cob`](./post_transaction_28.cob) | 过账模块 `POST-TRANSACTION28`：按账户号与类型校验，成功时更新调用方余额，用状态字段返回结果 |
| [`report_account_28.cob`](./report_account_28.cob) | 报告模块 `REPORT-ACCOUNT28`：读取最终账户与批次计数并显示 |
| `copybooks/ACCOUNT-REC.CPY` | 账户记录：账户号 `X(10)`、客户号 `X(8)`、余额 `9(7)V99`（共 27 字节） |
| `copybooks/TRANSACTION-REC.CPY` | 交易记录：账户号 `X(10)`、类型 `X`、金额 `9(7)V99`（共 20 字节） |
| `copybooks/POST-STATUS.CPY` | 过账结果状态 `X(12)`：`POSTED`、`INSUFFICIENT`、`BAD_TYPE`、`NO_ACCOUNT` |
| `copybooks/BATCH-COUNTS.CPY` | 批次计数：`POSTED-COUNT`、`REJECTED-COUNT`（各 `9(3)`） |
| [`build.sh`](./build.sh) | 构建与运行入口（`check` / `build` / `run` / `clean`） |

每个 Copybook 只描述**一个**接口的数据形状。`POST-TRANSACTION28` 与 `REPORT-ACCOUNT28` 的 `LINKAGE SECTION` 按相同顺序 `COPY` 对应声明，主程序用完全相同的字段顺序发起 `CALL`——字段顺序或宽度对不上，接口就是错的，而共享声明让这种不一致立刻暴露。

## 模块调用顺序

1. `./build.sh check`：对主程序和两个子程序做组合语法检查（`cobc -I copybooks -fsyntax-only`）。
2. `./build.sh build`：先把两个子程序各自编译成 `.o`，再把主程序与两个目标文件链接成 `build/lesson_28`。
3. 主程序打开 `batch.log` 并写 `EVENT=BATCH_START`，然后 `INITIALIZE` 账户与计数。
4. 每笔交易重用同一个 `WS-TRANSACTION-RECORD`，显式 `BY REFERENCE` 传递账户、交易与状态。
5. `POST-TRANSACTION28` 更新调用方账户余额或写入拒绝状态；**计数与日志事件仍由主程序拥有**。
6. `REPORT-ACCOUNT28` 接收共享账户与计数结构，显示最终余额与计数。
7. 主程序写 `EVENT=BATCH_END`、检查 `FILE STATUS` 并关闭日志；出现未知状态或 I/O 故障时返回非零码。

接口不使用 `BINARY-LONG` 等平台二进制布局；金额一律以 `PIC 9(7)V99` 的十进制字段契约传递。

## 交易规则与预期结果

账户起始余额 `1000.00`，五笔样例依次为：存款 `125.50`、取款 `25.25`、超余额取款 `2000.00`、未知类型 `X`、不存在账户 `A000000099` 的存款。只有前两笔成功：

| 序 | 类型 | 金额 | 结果状态 | 原因 |
|---:|---|---:|---|---|
| 1 | `D` | 125.50 | `POSTED` | 存款成功 |
| 2 | `C` | 25.25 | `POSTED` | 余额足够 |
| 3 | `C` | 2000.00 | `INSUFFICIENT` | 超过当前余额，余额不变 |
| 4 | `X` | 1.00 | `BAD_TYPE` | 类型不在 `D`/`C` 之内 |
| 5 | `D` | 1.00 | `NO_ACCOUNT` | 账户号与主记录不匹配 |

计数不变量：`記帳 + 拒否 = 5`，本课为 `2 + 3 = 5`。

这些都是**业务结果**，不是构建或文件系统故障：超额取款返回 `INSUFFICIENT` 且不修改余额，未知类型返回 `BAD_TYPE`，账户号不匹配返回 `NO_ACCOUNT`。

## 构建、运行和观察

**输入：** 无外部输入。五笔样例在主程序里固定写出。

**命令及作用：**

```sh
./build.sh check    # 组合语法检查，不生成任何产物
./build.sh build    # 编译两个子程序为 .o，再链接出 build/lesson_28
./build.sh run      # 构建后在 build/ 里运行，输出与 batch.log 都落在 build/
echo $?             # 查看退出码
./build.sh clean    # 删除 build/（可执行文件、目标文件与日志）
```

`./build.sh unknown` 会返回 `64` 并打印用法；`cobc` 不在 PATH 时返回 `127`（可用 `COBC` 指定）。

**预期结果：**

| 观察项 | 预期值 |
|---|---|
| `./build.sh check` 退出码 | `0`，无诊断 |
| `./build.sh build` 退出码 | `0`，无编译警告 |
| `./build.sh run` 退出码 | `0` |
| 标准输出 | 12 行，与 [`expected-output.txt`](./expected-output.txt) 逐行一致 |
| `build/batch.log` | 7 行，与 [`expected-batch.log`](./expected-batch.log) 逐行一致 |
| 生成文件 | `build/lesson_28`、两个 `.o`、`build/batch.log` |

```text
呼出=過帳 口座=A000000001 TYPE=D 金額=0000125.50
呼出=戻り 状態=POSTED
呼出=過帳 口座=A000000001 TYPE=C 金額=0000025.25
呼出=戻り 状態=POSTED
呼出=過帳 口座=A000000001 TYPE=C 金額=0002000.00
呼出=戻り 状態=INSUFFICIENT
呼出=過帳 口座=A000000001 TYPE=X 金額=0000001.00
呼出=戻り 状態=BAD_TYPE
呼出=過帳 口座=A000000099 TYPE=D 金額=0000001.00
呼出=戻り 状態=NO_ACCOUNT
口座=A000000001 CUSTOMER=C0001001 BALANCE=0001100.25
集計 記帳=002 拒否=003
```

**输出对照（实际标签 → 含义）：** `呼出=過帳` = 发出过账调用（`口座` 账户号、`TYPE` 类型、`金額` 金额）；`呼出=戻り 状態` = 调用返回状态；`口座`/`CUSTOMER`/`BALANCE` = 最终账户报告；`集計 記帳=.. 拒否=..` = 过账/拒绝计数汇总。余额可手算：`1000.00 + 125.50 − 25.25 = 1100.25`。

`build/batch.log`：

```text
EVENT=BATCH_START ID=TRAINING-001
EVENT=TRANSACTION NO=001 ACCOUNT=A000000001 TYPE=D STATUS=POSTED
EVENT=TRANSACTION NO=002 ACCOUNT=A000000001 TYPE=C STATUS=POSTED
EVENT=TRANSACTION NO=003 ACCOUNT=A000000001 TYPE=C STATUS=INSUFFICIENT
EVENT=TRANSACTION NO=004 ACCOUNT=A000000001 TYPE=X STATUS=BAD_TYPE
EVENT=TRANSACTION NO=005 ACCOUNT=A000000099 TYPE=D STATUS=NO_ACCOUNT
EVENT=BATCH_END POSTED=002 REJECTED=003 IO_ERROR=N
```

**实际观察到的环境细节：** 在本工作区运行可执行文件时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境的链接库版本警告，不是本程序的标准输出；其触发组件尚未定位。

## 构建错误与日志错误

- 日志无法打开时，主程序报告 `エラー=ログOPEN 状態=37`，退出码 `1`，**不会调用过账子程序**。
- 日志 WRITE 或 CLOSE 失败同样设置系统错误并返回 `1`。
- `BATCH_END` 在关闭日志**之前**写出，所以若日志 CLOSE 随后失败，最后一条日志仍可能写着 `IO_ERROR=N`；此时以标准输出与退出码为准。日志自身的 OPEN 失败写不进日志，只能靠标准输出和退出码报告。
- 过账模块返回未知状态时主程序记为拒绝，并令退出码非零。

## 修改练习

两项都从原始源码开始，用 `./build.sh run` 重跑，以便子程序重新编译并重新链接：

1. 把 `1300-POST-OVERDRAFT` 的金额从 `2000.00` 改为 `1000.00`，确认这笔取款成功、最终余额与 `記帳`/`拒否` 计数随之变化，且日志状态与调用返回一致。
2. 把 `1400-POST-UNKNOWN-TYPE` 的类型从 `X` 改为 `D`，确认未知类型拒绝变成有效存款，并检查账户报告与第四条交易日志。

完整题目与预期见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

## 举一反三练习

把样例交易改为文件输入，并把“读取 / EOF / 坏记录分类”放进一个独立模块；保持账户、交易与状态 Copybook 是唯一接口定义。说明 Copybook 改动后如何保证所有受影响的模块都被重新编译和链接。不要把业务拒绝伪装成编译失败，也不要重复定义 Copybook 里已有的记录布局。题目见 [`exercise.md`](./exercise.md)，本题不提供答案。

## 在企业中的位置

模块职责可以这样划线：主程序拥有批次流程与计数，过账程序拥有业务规则，报告程序只消费最终状态。Copybook 是**接口的一部分**，必须和目标文件一起纳入构建依赖——这正是本课把接口抽成 4 个 Copybook 并由 `build.sh` 统一编译的原因。

生产构建还要固定编译器版本、编译选项、ABI、模块清单和产物版本；本课的单脚本只演示本地可重复构建，不提供产物版本管理、增量构建或依赖图自动推导。数据库批次的构建与工具链见第 29–32 课。

## 参考资料

- [GnuCOBOL Programmer’s Guide：COPY](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#COPY)
- [GnuCOBOL Programmer’s Guide：CALL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#CALL)
- [GnuCOBOL Programmer’s Guide：PROCEDURE DIVISION USING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-USING)
- [GnuCOBOL Programmer’s Guide：FILE STATUS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SELECT)
- 仓库课程主页：[README.md](../../README.md)
