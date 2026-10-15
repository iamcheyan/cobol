# 第 27 课：日志系统——记录批次、记录与错误事件

标准输出在批次跑完就消失了，运维拿到一个“成功”的退出码也无法回答“哪一条记录被拒、为什么”。本课在第 26 课的校验流程上增加一个独立的 `batch.log`：批次开始、每条记录、每次业务拒绝、每个系统故障和批次结束都写进日志，并用固定格式让日志可以逐字比对。

## 为什么现在学

第 26 课已经能把业务拒绝和系统故障分开处理，但两者的痕迹只出现在屏幕和两个结果文件里。缺口是“可追溯”：调度器要按日志末尾的计数判断批次是否完整结束，运维要按记录号和账户号定位坏数据。日志本身也是一个文件，它有自己的文件状态——这一点让“日志失败该怎么报告”成为必须正面回答的问题。

## 本课完成后的能力与边界

学完本课后，你可以：

- 把批次开始、记录读取、业务拒绝、系统故障和批次结束写进独立的日志文件。
- 用记录号、账户号和拒绝原因定位一条输入记录。
- 把业务事件与文件 I/O 故障分别记录为 `BUSINESS_REJECT` 和 `SYSTEM_ERROR`。
- 检查日志自身的 OPEN/WRITE/CLOSE 状态，并说明日志为什么记不下自己的故障。
- 用日志末尾的计数与标准输出、结果文件三方对照，判断批次是否完整结束。

边界：日志格式是固定的教学 `KEY=VALUE` 行，批次 ID 固定为 `TRAINING-001`，不含时间戳、运行标识、环境、输入签名和操作员上下文，也不做脱敏、保留期或访问控制。日志/结果文件之间**没有**原子交付保证，本课也不实现重跑。

## 运行环境

- GnuCOBOL 3.2.0，默认方言（不加 `-std=cobol85`），源文件为固定格式。
- Linux 终端；本课不依赖数据库或附加工具。
- `SELECT` 使用相对文件名，程序在当前工作目录读写 4 个文件：读 `transactions.txt`，写 `accepted.txt`、`rejected.txt`、`batch.log`。
- 三个输出用 `OPEN OUTPUT`，每次运行都会覆盖同名旧文件。因此本课在 `build/` 里放输入副本再运行，输出也落在 `build/`；`build/` 已被仓库忽略，最后 `rm -rf build` 一次清干净。

## 日志格式与生命周期

日志是逐行的 `KEY=VALUE` 文本，一条事件一行。一次成功运行按顺序写出：

| 事件 | 何时写 | 关键字段 |
|---|---|---|
| `EVENT=BATCH_START` | 日志打开成功后、业务文件打开前 | `ID=TRAINING-001` |
| `EVENT=RECORD_READ` | 输入记录成功读取后 | `NO=` 从 `001` 开始的记录号、`ACCOUNT=` 账户号 |
| `EVENT=RECORD_ACCEPTED` | 接受记录的 WRITE 成功之后 | `NO=`、`ACCOUNT=` |
| `EVENT=BUSINESS_REJECT` | 拒绝记录的 WRITE 成功之后 | `NO=`、`ACCOUNT=`、`REASON=` |
| `EVENT=SYSTEM_ERROR` | 输入或业务输出文件操作失败时（若日志仍可写） | `OP=`、`STATUS=` |
| `EVENT=BATCH_END` | 数据文件关闭之后、日志关闭之前 | `INPUT=`、`ACCEPTED=`、`REJECTED=`、`SYSTEM_ERROR=` |

日志在读取业务输入**之前**打开：日志打不开，批次不启动。`STRING ... DELIMITED BY SIZE` 组装每行事件，`WS-LOG-MESSAGE` 在组装前清空，避免上一条较长事件的尾部残留；`WS-LOG-MESSAGE` 是 `PIC X(100)`，本课最长事件 66 个字符。

**日志记不下自己的故障。** OPEN 失败时连第一行都写不出去，只能靠标准输出与退出码；WRITE 失败时程序停止后续处理、不再尝试追加日志；CLOSE 失败发生在 `BATCH_END` 之后，只能由标准输出和进程状态报告。这是日志系统的固有边界，不是本课的实现缺陷。

## 业务事件与系统事件

| 类别 | 典型情形 | 结果文件 | 日志事件 | 退出码 |
|---|---|---|---|---|
| 业务拒绝 | 坏宽度（`BAD_WIDTH`）、非数字金额（`BAD_AMOUNT`）、零金额（`ZERO_AMOUNT`） | 写 `rejected.txt` | `BUSINESS_REJECT` | `0` |
| 系统故障 | 输入/输出/日志的 OPEN、READ、WRITE、CLOSE 失败 | 不保证完整 | `SYSTEM_ERROR`（若日志可写） | `1` |

业务拒绝是“处理完成”的结果，批次照常收尾并返回 `0`；系统故障会停止后续读取并返回 `1`。文件事件只有在对应的 WRITE 状态为 `00` 时才计入成功数——这一点保证了日志里的 `ACCEPTED`/`REJECTED` 计数与结果文件的实际行数一致。

## 计数不变量与可核对结果

| 不变量 | 代入本课 | 含义 |
|---|---|---|
| `INPUT = ACCEPTED + REJECTED` | `005 = 002 + 003` | 每条读到的记录都有唯一去向 |
| `ACCEPTED` = `accepted.txt` 行数 | `002` = 2 行 | 日志计数与实际写出吻合 |
| `REJECTED` = `rejected.txt` 行数 | `003` = 3 行 | 同上 |

三方（标准输出、日志、结果文件）同时对上，才算这条链路自洽。

## 运行与观察

**输入：** 本课目录下的 `transactions.txt`（5 行，每行 `账户号|金额分`）。它被复制进 `build/`，程序在 `build/` 里运行并写出三个文件。

**命令及作用：**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                    # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_27 lesson.cob      # 编译，可执行文件也放进 build/
cp transactions.txt build/                       # 输入副本放进同一个工作目录
(cd build && ./lesson_27)                        # 在 build/ 里运行，输出落在那里
echo $?                                          # 查看退出码
diff build/batch.log expected-batch.log          # 与预期日志逐行比对
rm -rf build                                     # 一次清掉全部产物
```

**预期结果（正常路径）：**

| 观察项 | 预期值 |
|---|---|
| `cobc -fsyntax-only` 退出码 | `0` |
| `cobc -x` 退出码 | `0`，无编译诊断 |
| 标准输出 | 7 行，见下方代码块 |
| 进程退出码 | `0` |
| 生成文件 | `build/accepted.txt`（2 行）、`build/rejected.txt`（3 行）、`build/batch.log`（12 行） |

```text
受理口座=A00001
拒否口座=A00002 REASON=BAD_AMOUNT
拒否口座=A00003 REASON=ZERO_AMOUNT
受理口座=A00004
拒否口座=A00005 REASON=BAD_WIDTH
集計 入力=005 受理=002 拒否=003
システムエラー=N
```

`build/batch.log` 应与 [`expected-batch.log`](./expected-batch.log) **逐行一致**（用上面的 `diff` 验证）：

```text
EVENT=BATCH_START ID=TRAINING-001
EVENT=RECORD_READ NO=001 ACCOUNT=A00001
EVENT=RECORD_ACCEPTED NO=001 ACCOUNT=A00001
EVENT=RECORD_READ NO=002 ACCOUNT=A00002
EVENT=BUSINESS_REJECT NO=002 ACCOUNT=A00002 REASON=BAD_AMOUNT
EVENT=RECORD_READ NO=003 ACCOUNT=A00003
EVENT=BUSINESS_REJECT NO=003 ACCOUNT=A00003 REASON=ZERO_AMOUNT
EVENT=RECORD_READ NO=004 ACCOUNT=A00004
EVENT=RECORD_ACCEPTED NO=004 ACCOUNT=A00004
EVENT=RECORD_READ NO=005 ACCOUNT=A00005
EVENT=BUSINESS_REJECT NO=005 ACCOUNT=A00005 REASON=BAD_WIDTH
EVENT=BATCH_END INPUT=005 ACCEPTED=002 REJECTED=003 SYSTEM_ERROR=N
```

`build/accepted.txt` 为 `A00001|00125`、`A00004|00999`；`build/rejected.txt` 为 `A00002|BAD_AMOUNT`、`A00003|ZERO_AMOUNT`、`A00005|BAD_WIDTH`。

**失败路径（两条都已实测）：**

- **输入缺失：** 在 `build/` 里删掉 `transactions.txt` 后运行。标准输出以 `エラー=OPEN_INPUT STATUS=35` 开始，`集計` 全为 `000`、`システムエラー=Y`，退出码 `1`；日志仍写出 `BATCH_START`、`SYSTEM_ERROR OP=OPEN_INPUT STATUS=35`、`BATCH_END ... SYSTEM_ERROR=Y` 三行。
- **日志打不开：** 在 `build/` 里把 `batch.log` 建成目录后运行。标准输出为 `エラー=ログOPEN 状態=37`／`集計 入力=000 受理=000 拒否=000`／`システムエラー=Y`，退出码 `1`，业务文件不会被打开。

**实际观察到的环境细节：** 在本工作区运行可执行文件时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境的链接库版本警告，不是本程序的业务输出；其触发组件尚未定位。

## 修改练习

两项都在 `build/` 工作目录里做，不要改动仓库内的夹具：

1. 把输入中 `A00002|00X50` 改成 `A00002|00150`。确认该记录由业务拒绝变为接受，日志中对应事件从 `BUSINESS_REJECT` 变为 `RECORD_ACCEPTED`，`BATCH_END` 计数随之改变。
2. 删掉 `build/transactions.txt` 后运行，核对退出码与 `batch.log` 里 `SYSTEM_ERROR` 事件的位置（在 `BATCH_START` 之后、`BATCH_END` 之前）。

完整题目与预期见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

## 举一反三练习

设计一条“重复账户号”业务拒绝规则，并在日志中同时写出首次与重复记录的记录号；再设计一个多批次输入方案，使每次运行都有唯一批次 ID，并说明如何避免把 `BATCH_END` 误当成“全部输出已原子交付”。不要在日志事件里写完整客户隐私资料，也不要省略失败批次的结束状态。题目见 [`exercise.md`](./exercise.md)，本题不提供答案。

## 在企业中的位置

生产日志服务于定位、审计和调度：记录号与业务键让运维快速找到坏数据，结束计数让调度判断这次运行是否完整。这些都不是屏幕输出能替代的。

本课的固定 `ID=TRAINING-001`、固定格式、无时间戳，只够教学比对。生产系统还要定义唯一运行标识、日志保留与访问权限、脱敏、批次重跑，以及日志与结果文件之间的交付关系；模块化工程见第 28 课，数据库批次的日志与恢复见第 31、32 课。

## 参考资料

- [GnuCOBOL Programmer’s Guide：LINE SEQUENTIAL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#ORGANIZATION-LINE-SEQUENTIAL)
- [GnuCOBOL Programmer’s Guide：STRING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#STRING)
- [GnuCOBOL Programmer’s Guide：FILE STATUS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SELECT)
- 仓库课程主页：[README.md](../../README.md)
