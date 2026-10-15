# 第 27 课：日志系统——批次、记录与错误事件

> 面向 GnuCOBOL 3.2.0 和 Linux。

## 一、课程目标

学完本课后，你可以：

- 将批次开始、记录处理、业务拒绝、系统故障和批次结束写入独立日志文件。
- 用递增记录号、账户号和拒绝原因定位输入记录。
- 将业务事件与文件 I/O 错误分别记录。
- 检查日志文件自己的 OPEN、WRITE、CLOSE 状态。
- 根据日志末尾计数判断批次是否完整结束。

## 二、日志格式与生命周期

[`lesson.cob`](./lesson.cob) 从第 26 课复用交易校验流程，并新增 `batch.log`。日志采用稳定、逐行的 `KEY=VALUE` 文本格式，使用固定训练批次 ID `TRAINING-001`，使夹具和预期结果可以逐字比较。生产作业应使用唯一批次 ID。

一次成功运行依序记录：

1. `EVENT=BATCH_START`：日志打开成功后、业务输入打开前写入。
2. `EVENT=RECORD_READ`：输入记录成功读取后写入，包含从 `001` 开始的记录号与账户号。
3. `EVENT=RECORD_ACCEPTED` 或 `EVENT=BUSINESS_REJECT`：业务输出成功写入后记录；拒绝事件包含原因。
4. `EVENT=SYSTEM_ERROR`：输入或业务输出文件操作失败时，记录操作名和文件状态。
5. `EVENT=BATCH_END`：数据文件关闭后、日志关闭前写入最终输入、接受、拒绝计数和系统错误标志。

日志在读取业务输入前打开。若日志无法打开，程序不启动批次；若日志 WRITE 失败，程序停止后续处理且不再尝试追加日志。日志关闭失败会令进程返回非零状态，但该故障发生在最后一条日志之后，只能由标准输出与进程状态报告。日志无法记录自身的 OPEN、WRITE 或 CLOSE 故障。

## 三、业务与系统事件

业务拒绝（坏宽度、非数字金额、零金额）是完成处理的结果：写入 `rejected.txt`，在日志中标记 `BUSINESS_REJECT`，批次可返回 0。文件打开、读取、写入、关闭或日志操作失败属于系统错误：日志记录 `SYSTEM_ERROR`（若日志仍可写），停止后续读取，返回 1。

文件事件只有在相应 WRITE 状态为 `00` 时才计入成功数。README 的固定批次 ID 只适合教学；生产日志还应包含唯一运行标识、时间、环境、输入签名和操作员/调度上下文。

## 四、编译与运行

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_27" lesson.cob
cp transactions.txt "$scratch_dir/"
(cd "$scratch_dir" && ./lesson_27)
```

标准输出与第 26 课相同：

```text
受理口座=A00001
拒否口座=A00002 REASON=BAD_AMOUNT
拒否口座=A00003 REASON=ZERO_AMOUNT
受理口座=A00004
拒否口座=A00005 REASON=BAD_WIDTH
集計 入力=005 受理=002 拒否=003
システムエラー=N
```

`batch.log` 应与 [`expected-batch.log`](./expected-batch.log) 逐行一致。`accepted.txt` 包含 `A00001|00125` 与 `A00004|00999`；`rejected.txt` 包含 `A00002|BAD_AMOUNT`、`A00003|ZERO_AMOUNT` 和 `A00005|BAD_WIDTH`。

缺失输入场景：在运行目录不复制 `transactions.txt`。预期标准输出以 `ERROR=OPEN_INPUT STATUS=35` 开始，进程返回 1；日志仍记录批次开始、输入错误和批次结束（系统错误为 `Y`）。日志无法打开场景：创建目录 `batch.log`，进程输出 `エラー=ログオープン 状態=37` 并返回 1，不会打开业务文件。

## 五、逐步读代码

1. `9000-OPEN-LOG` 是主程序的第一个文件操作；只有状态 `00` 才将日志标记为可用。
2. 主程序写批次开始事件，再打开业务输入与两个输出文件。
3. `2100-READ-ONE-RECORD` 在每次成功读取后增加输入序号、取得账户号并调用 `2200-LOG-RECORD-READ`。
4. `3000-VALIDATE-RECORD` 负责业务规则。它不会把坏输入设置为系统错误，而是转到接受或拒绝写入段落。
5. 两个业务 WRITE 成功后分别记录接受或拒绝事件；失败则调用 `9300-REPORT-SYSTEM-ERROR`。
6. `9300-REPORT-SYSTEM-ERROR` 向标准输出报告操作与状态，并尝试将同一故障写入日志。
7. `8000-CLOSE-DATA-FILES` 只关闭已成功打开的数据文件，并把关闭错误纳入系统错误标志。
8. `9200-LOG-BATCH-END` 在关闭日志前写出批次计数，供后续审计和调度判断。

`STRING ... DELIMITED BY SIZE` 组装事件，`WS-LOG-MESSAGE` 在每次组装前清空，避免上一个较长事件的尾部残留。

## 六、修改练习（有答案）

1. 把输入中 `A00002|00X50` 改为 `A00002|00150`。检查该记录由业务拒绝变为接受；日志中对应事件从 `BUSINESS_REJECT` 变为 `RECORD_ACCEPTED`，批次结束计数随之改变。
2. 在空临时运行目录运行程序，不提供 `transactions.txt`。核对控制台返回码与 `batch.log` 中 `SYSTEM_ERROR` 事件的先后顺序。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；操作步骤见 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

设计一条重复账户号业务拒绝规则，并在日志中写入首次与重复记录序号。再设计一个多批次输入方案，使每次运行都有唯一批次 ID；说明如何防止批次结束事件被误当作全部输出已原子交付。

本题不提供答案。不要在日志事件中写完整客户隐私资料，也不要省略失败批次的结束状态。

## 八、企业实战补充

批处理日志服务于生产定位、审计和调度，不应只靠屏幕输出。记录序号、业务键、错误类别和结束计数让运维人员能快速定位坏数据及不完整运行。生产系统还要定义日志保留、访问权限、脱敏、批次重跑和日志/结果文件之间的交付关系。

## 参考资料

- [GnuCOBOL Programmer’s Guide：LINE SEQUENTIAL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#ORGANIZATION-LINE-SEQUENTIAL)
- [GnuCOBOL Programmer’s Guide：STRING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#STRING)
- [GnuCOBOL Programmer’s Guide：FILE STATUS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SELECT)
