# 第 27 课：日志系统——把这一夜发生了什么写进一份能过夜的文件

夜间批次的屏幕输出第二天什么都不剩。本课给第 26 课的校验流程加一个独立的 `batch.log`：批次开始、每读一条记录、每次业务拒绝、每个系统故障、批次结束，全部按固定的 `KEY=VALUE` 一行一条写下去；值班的人第二天只靠这个文件，就能回答“跑没跑完、坏在哪一条、要不要重跑”。

## 业务现场

周三凌晨 2:40，值班手机响了。夜里那批日终校验跑完，退出码是 `1`。可屏幕早就没了——终端窗口跟着作业一起关掉，昨天那一次运行打出来的每一行，第二天一个字都找不到。

把你叫起来的第一个问题不是“代码哪错了”，而是三个更土的问题：**这批到底跑没跑完？坏在哪一条？还值不值得重跑？** 如果程序只会往屏幕上打字，你就只能把整份输入再喂一遍、盯着屏幕重跑一次——而重跑本身会把上一次的结果文件覆盖掉，等于你亲手把现场踩掉。凌晨三点做这种判断，出错几乎是必然的。

所以真实作业都会在屏幕之外另开一个**独立的日志文件**。它要能回答：批次开始了（`BATCH_START`）、读到了第几条记录（`RECORD_READ NO=004 ACCOUNT=A00004`）、哪一条被业务拒绝以及为什么（`BUSINESS_REJECT ... REASON=BAD_AMOUNT`）、有没有系统故障（`SYSTEM_ERROR`）、最后到底收了多少、拒了多少（`BATCH_END INPUT=005 ACCEPTED=002 REJECTED=003`）。值班的人不看你的代码，就看这几行。

这一课还有一件不太舒服的事必须讲清楚：日志自己也是个文件，它要打开、要写、要关。**它坏了，就没法在自己的文件里告诉你它坏了。** 听着像绕口令，但它是真的——下面你会看到这条边界具体卡在哪三个点上。

（场景是教学演示，机构、时间和笔数是为了把问题说清楚，不代表某家真实机构的真实数据。）

## 为什么现在学

第 26 课你已经能把“业务拒绝”和“系统故障”分开了：坏记录分流进 `rejected.txt`，遇到真正的 I/O 故障就停下、返回非零码。分类是对的，但这些痕迹只留在两个地方——屏幕，和两份结果文件。

问题是它们都答不全你要问的话。`rejected.txt` 里只有账户号和原因（`A00002|BAD_AMOUNT`），**没有记录号**，你不知道它在输入里是第几行；两份结果文件里**没有批次边界**，你看不出这次运行是正常收尾还是跑到一半断了；至于系统故障，一个字的记录都没有。屏幕更干脆，它活不过今晚。

你可能会说：那我让程序把输出重定向到一个文件里，不就有个“日志”了吗？能留痕，但留下的是给人读的句子：`拒否口座=A00002 REASON=BAD_AMOUNT`，字段之间靠空格，没有记录号。日志的另一半用途是**让机器读**——调度脚本、值班脚本要能一眼抓到 `REJECTED=003`，而不是拿正则去猜一句话的哪一段是数字。所以格式得先定下来：一行一个事件、`KEY=VALUE`、字段顺序固定。

还有一层区别值得记住：结果文件是**交付物**，日志是**过程记录**。`accepted.txt` 要交给下游继续过账，`batch.log` 是留给人和调度器查案的，两者不能互相顶替。

## 这个知识点是什么，它解决什么问题

**这个知识点是什么。** 给程序加一条“说话”的通道：把批次开始、每读一条记录、每次业务拒绝、每个系统故障、批次结束，都写进一个**独立文件**，一行一个事件、固定 `KEY=VALUE` 格式。做法上还是本课之前的那些工具——`SELECT` + `OPEN OUTPUT` + `WRITE`，只是这次写的不是业务数据，而是“这一夜发生了什么”。

**它在业务里解决什么问题。** 把事实从内存和屏幕搬到磁盘上，而且搬成机器也能读的样子。落到三个具体问题上就是：跑没跑完（`BATCH_END` 那一行的输入/受理/拒否计数）、坏在哪一条（`NO=` 记录号 + `ACCOUNT=` 账户号 + `REASON=` 原因）、下一次要不要重跑（`SYSTEM_ERROR` 标志）。

这里有个副作用你必须知道：**日志自己也是个文件**。它有自己的 OPEN/WRITE/CLOSE 状态，也会打不开、写不进去、关不掉。而它**没法在自己的文件里报告自己的故障**——那三个故障只能落在屏幕和退出码上（具体卡在哪一处，见下面“日志格式与生命周期”）。这不是本课偷懒，是日志系统的固有边界。

**什么时候不该用它、用错会怎样。** 业务上误用日志比写错语法贵得多：

- **拿日志当结果文件。** 下游要的是 `accepted.txt` 里的接受明细，日志不是交付物；反过来把日志内容当业务数据去对账，就是把“过程”和“产品”搞混了。
- **期待它自带生产日志的那套东西。** 本课的批次 ID 是写死的 `TRAINING-001`，没有时间戳、没有运行标识、不做脱敏、没有保留期和访问权限。两天的日志放一起，光看文件你分不出谁是谁；真要用这个文件追责，得先补这些。
- **以为“有 `BATCH_END` 就万事大吉”。** `BATCH_END` 是在日志 CLOSE **之前**写出的，所以它存在不代表日志文件已经成功关闭，更不代表日志和结果文件是原子交付的——重跑一次，`OPEN OUTPUT` 就把上一个现场整个盖掉了。

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
- 三个输出用 `OPEN OUTPUT`，每次运行都会覆盖同名旧文件。所以本课在 `build/` 里放输入副本再运行，输出也落在 `build/`；`build/` 已被仓库忽略，最后 `rm -rf build` 一次清干净。

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

顺序上有一处设计要记住：**日志在读取业务输入之前就打开**。日志打不开，批次根本不启动——这样才不会出现“业务数据已经动过、日志却没记上”的现场。

每行是 `STRING ... DELIMITED BY SIZE` 拼出来的，拼之前先把 `WS-LOG-MESSAGE` 清空，免得上一条更长的事件在尾巴上留下残字（`WS-LOG-MESSAGE` 是 `PIC X(100)`，本课最长的事件 66 个字符，够用）。

**日志记不下自己的故障**，三个位置分别是：

- **OPEN 失败**：第一行都写不出去，只能靠标准输出和退出码报告。本课实测过这条路径（把 `batch.log` 建成目录，见下文失败路径）。
- **WRITE 失败**：程序停止后续处理，不再尝试往日志追加；只能靠标准输出和退出码报告。**本课没有注入过这条路径**，行为只有源码依据（见“证据来源与验证范围”）。
- **CLOSE 失败**：发生在 `BATCH_END` 之后，只能由标准输出和进程状态报告。同样**未注入**。

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

**输出对照（实际标签 → 含义）：** `受理口座` = 被接受的账户；`拒否口座` = 被拒绝的账户，`REASON=` 给出原因（`BAD_WIDTH`/`BAD_AMOUNT`/`ZERO_AMOUNT`）；`集計 入力/受理/拒否` = 输入/接受/拒绝计数；`システムエラー` = 系统错误标志（`N` 无、`Y` 有）。日志事件名与字段名是英文接口标记：`EVENT=BATCH_START`/`RECORD_READ`/`RECORD_ACCEPTED`/`BUSINESS_REJECT`/`SYSTEM_ERROR`/`BATCH_END`，字段 `ID`/`NO`/`ACCOUNT`/`REASON`/`OP`/`STATUS`/`INPUT`/`ACCEPTED`/`REJECTED`/`SYSTEM_ERROR` 的含义见上文事件表。

**失败路径（两条都已实测）：**

- **输入缺失：** 在 `build/` 里删掉 `transactions.txt` 后运行。标准输出以 `エラー=OPEN_INPUT STATUS=35` 开始，`集計` 全为 `000`、`システムエラー=Y`，退出码 `1`；日志仍写出 `BATCH_START`、`SYSTEM_ERROR OP=OPEN_INPUT STATUS=35`、`BATCH_END ... SYSTEM_ERROR=Y` 三行。输入文件一次都没打开成功，所以 `INPUT=000`——`BATCH_END` 里的 `SYSTEM_ERROR=Y` 就是在提醒你：别把“没有记录”误读成“成功的空批次”。
- **日志打不开：** 在 `build/` 里把 `batch.log` 建成目录后运行。标准输出为 `エラー=ログOPEN 状態=37`／`集計 入力=000 受理=000 拒否=000`／`システムエラー=Y`，退出码 `1`，而且业务文件**根本不会被打开**——日志立不起来，这一夜就当作没开始。

**证据来源与验证范围：** 上面三条路径都在本工作区用 GnuCOBOL 3.2.0 实际跑过，可执行文件与三个输出文件都留在 `build/` 工作目录里，课程目录只保留源文件与夹具。

| 场景 | 从何种干净输入开始 | 预期与实际 |
|---|---|---|
| 正常路径 | 空的 `build/`，复制 `transactions.txt` 进去 | 语法检查/编译退出码 `0`；标准输出 7 行；退出码 `0`；`accepted.txt` 2 行、`rejected.txt` 3 行、`batch.log` 12 行；`diff batch.log expected-batch.log` 无差异。吻合 |
| 输入缺失 | `build/` 里不放 `transactions.txt`（先删掉上次的结果文件） | 退出码 `1`；标准输出 3 行（错误行 + 全 `000` 的集計 + `システムエラー=Y`）；日志恰好 3 行：`BATCH_START`、`SYSTEM_ERROR OP=OPEN_INPUT STATUS=35`、`BATCH_END ... SYSTEM_ERROR=Y`。吻合 |
| 日志打不开 | `build/` 里把 `batch.log` 建成目录，输入副本照常放着 | 退出码 `1`；标准输出 `エラー=ログOPEN 状態=37` + 全 `000` 集計 + `システムエラー=Y`；`accepted.txt`/`rejected.txt` 都没有被创建。吻合 |

**未验证项（如实说明，不作为结论）：**

- **日志 WRITE / CLOSE 失败没有被注入过。** 要让日志的 `WRITE`/`CLOSE` 返回非 `00`，得先让底层写操作失败；本课没有实现可靠的注入手段，也没有做过这样的实测。因此“WRITE 失败 → 打印状态 → 停止后续记录 → 返回 1”和“CLOSE 失败 → 打印状态 → 置错误标志 → 返回 1”这两段目前只有源码依据。
- **`FILE STATUS = "00"` 不等于数据已经落盘。** 本课代码里没有任何刷盘手段，所以状态 `00` 同样只能说明“这次写调用被接受了”。这一条是从源码得出的推断，本课没有为它单独做实验；第 16 课的验证范围里对这类缓冲边界有实测记录。
- 日志的 OPEN 失败是实测过的（上面证据表里“日志打不开”那一行）；`READ` 类故障本课能触发的只有“输入打不开”，读取过程中途出错同样没有注入。

**实际观察到的环境细节：** 在本工作区运行可执行文件时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境的链接库版本警告，不是本程序的业务输出；其触发组件尚未定位。

## 修改练习

两项都在 `build/` 工作目录里做，不要改动仓库内的夹具。做之前先把 `build/` 准备干净（`mkdir -p build`、编译、`cp transactions.txt build/`）：

1. 把输入中 `A00002|00X50` 改成 `A00002|00150`。确认该记录由业务拒绝变为接受，日志中对应事件从 `BUSINESS_REJECT` 变为 `RECORD_ACCEPTED`，`BATCH_END` 计数随之改变。
2. 删掉 `build/transactions.txt` 后运行，核对退出码与 `batch.log` 里 `SYSTEM_ERROR` 事件的位置（在 `BATCH_START` 之后、`BATCH_END` 之前）。

做完别急着关：用计数不变量自查一遍（`INPUT = ACCEPTED + REJECTED`，且两个计数分别等于两份结果文件的行数）。完整题目与预期见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

## 举一反三练习

设计一条“重复账户号”业务拒绝规则，并在日志中同时写出首次与重复记录的记录号；再设计一个多批次输入方案，使每次运行都有唯一批次 ID，并说明如何避免把 `BATCH_END` 误当成“全部输出已原子交付”。不要在日志事件里写完整客户隐私资料，也不要省略失败批次的结束状态。题目见 [`exercise.md`](./exercise.md)，本题不提供答案。

## 走一遍真实流程

把本课的日志放进一整条夜间链路，它站在“校验”和“交付”之间：

1. **上游是第 26 课。** 那个校验程序逐条读交易、把坏记录分流进 `rejected.txt`、遇到 I/O 故障就停下返回非零码。它已经把“业务拒绝”和“系统故障”分开了，只是没留下过夜痕迹——本课就是给它配的“日记本”。
2. **本课这一步。** 校验结果照旧写进两份结果文件，同时把每个事件按固定格式写进 `batch.log`。注意这里没有第二个程序：日志是同一个批次顺手写的，代价只有多一次 `OPEN OUTPUT` 和几次 `WRITE`。
3. **凌晨谁看它。** 调度器只认退出码；被叫醒的值班的人先看退出码，再看 `batch.log`：最后一行是不是 `BATCH_END`、里面的计数对不对、有没有 `SYSTEM_ERROR`。屏幕输出这时候早就没了，日志是他唯一的现场。
4. **白天谁看它。** 对账的人把 `BATCH_END` 的 `INPUT=005` 拿去和上游文件的行数核；复核岗按 `NO=` 记录号回输入文件里把坏数据捞出来（这里记录号才真正有用，光有账户号定位不到“第几行”）。
5. **往下走是第 28 课。** 那里把这套校验、日志和结果报告拆成多程序、多 Copybook 的可重复工程，日志也照样用 `expected-batch.log` 逐行核对；再往后第 31、32 课把同一套“批次 + 计数 + 失败痕迹”的思路延伸到文件与 SQLite 两侧对账，日志里还会多出数据库连接、同步结果这类事件。

一句话：本课是这条链上**唯一一处把“过程”留在纸上**的地方。判断对不对，结果文件能证明；跑得完不完整、断在哪一步，只有日志能证明。

## 这份代码进了生产会怎样

- **谁调度它**：夜间批处理调度器，按顺序排在“上游交易文件就绪”之后。它只认可执行文件路径和退出码，不看你的屏幕，也不读你的日志。
- **谁看日志**：被电话叫起来的值班的人。他先看退出码，再看 `BATCH_END` 那一行和 `SYSTEM_ERROR`。日志写得清不清楚，直接决定他今晚要熬多久。
- **出事谁被叫起来**：退出码非 `0` 时一定有人起来；退出码 `0` 但计数和上游笔数对不上时，第二天对账岗会来问。后一种更麻烦，因为它没有报警。
- **下一个系统怎么接**：日志本身很少被下游程序消费，它服务的是“人和调度”。真正的业务产物还是 `accepted.txt`/`rejected.txt`，交给下一课起的模块化工程和最终项目。
- **第一个月最容易出的事故**：把日志当成不变的证据。`batch.log` 是 `OPEN OUTPUT` 覆盖重建的，重跑一次就把上一次的现场抹掉了；本课又没有运行 ID 和时间戳，两天甚至同一天两次运行的日志在外形上一模一样。有人拿着上午调出来的日志去和下午的结果文件对计数，两边当然对不上——这类事故不吵不闹，但很耗人。
- **它还没做的事**：唯一运行标识、时间戳、日志保留期与访问权限、脱敏、批次重跑、日志与结果文件的交付关系（谁先谁后、断了怎么补），一项都没有。生产要真正拿它当审计痕迹，得先补这些。

## 参考资料

- [GnuCOBOL Programmer’s Guide：LINE SEQUENTIAL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#ORGANIZATION-LINE-SEQUENTIAL)
- [GnuCOBOL Programmer’s Guide：STRING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#STRING)
- [GnuCOBOL Programmer’s Guide：FILE STATUS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SELECT)
- [课程总目录](../DIRECTORY.md)
- 仓库课程主页：[README.md](../../README.md)
