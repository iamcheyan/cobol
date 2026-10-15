# 第 28 课：综合练习——多程序批处理工程

> 状态：课程草稿。目录已确认；主程序 188 行固定格式，针对 GnuCOBOL 3.2.0 默认方言。

## 一、课程目标

学完本课后，你可以：

- 将共享记录和结果状态放进 Copybook，供主程序与子程序复用。
- 将批次控制、交易过账与账户报告拆成独立程序单元。
- 通过 `CALL ... USING BY REFERENCE` 传递可更新记录和返回状态。
- 用一个构建脚本分别编译模块、链接主程序，并运行项目。
- 检查日志文件状态、子程序返回状态和整批过账计数。

本课把第 23–27 课的 Copybook、CALL/USING、业务错误分类与批次日志组合成小型工程。交易样例在主程序中明确列出，重点是模块接口和可重复构建；不再引入新的外部输入格式。

## 二、项目文件

- [`lesson.cob`](./lesson.cob)：初始化账户、准备五笔样例交易、调用过账模块、汇总返回状态并写批次日志。
- [`post_transaction_28.cob`](./post_transaction_28.cob)：按账户号和交易类型校验交易；成功时修改调用方余额，通过状态字段返回处理结果。
- [`report_account_28.cob`](./report_account_28.cob)：读取最终账户与批次计数并显示报告。
- [`copybooks/ACCOUNT-REC.CPY`](./copybooks/ACCOUNT-REC.CPY)：账户号、客户号和余额的共享记录布局。
- [`copybooks/TRANSACTION-REC.CPY`](./copybooks/TRANSACTION-REC.CPY)：账户号、类型和金额的交易输入布局。
- [`copybooks/POST-STATUS.CPY`](./copybooks/POST-STATUS.CPY)：主程序与过账模块共用的返回状态字段。
- [`copybooks/BATCH-COUNTS.CPY`](./copybooks/BATCH-COUNTS.CPY)：主程序与报告模块共用的计数布局。
- [`build.sh`](./build.sh)：语法检查、模块目标文件编译、链接、运行和清理入口。

每个 Copybook 只描述一个接口的数据形状。`POST-TRANSACTION28` 和 `REPORT-ACCOUNT28` 的 `LINKAGE SECTION` 按相同顺序引入对应声明；主程序用完全相同的字段顺序进行 CALL。

## 三、构建和运行

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
BUILD_DIR="$scratch_dir/build" ./build.sh check
BUILD_DIR="$scratch_dir/build" ./build.sh build
BUILD_DIR="$scratch_dir/build" ./build.sh run
```

`check` 对主程序和两个子程序做组合语法检查。`build` 单独将两个子程序编译为目标文件，再将主程序与这两个目标文件链接成可执行文件。`run` 从构建目录启动程序，因此 `batch.log` 和目标文件都留在该临时目录。`clean` 删除由当前 `BUILD_DIR` 指定的构建目录；省略 `BUILD_DIR` 时，默认是本课的 `build/`。

本课没有指定严格 `-std=cobol85`，使用 GnuCOBOL 默认方言。编译时若出现环境级 `libxml` 版本警告，它属于标准错误，不是批次输出。

标准输出应与 [`expected-output.txt`](./expected-output.txt) 逐行一致；构建目录下的 `batch.log` 应与 [`expected-batch.log`](./expected-batch.log) 一致。

## 四、交易规则与预期结果

账户起始余额为 1000.00。样例依次执行：存款 125.50、取款 25.25、超余额取款 2000.00、未知类型 `X` 和不存在账户的存款。只有前两笔成功：

```text
ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=0001100.25
SUMMARY POSTED=002 REJECTED=003
```

超额取款返回 `INSUFFICIENT` 且不修改余额；未知类型返回 `BAD_TYPE`；账户号不匹配返回 `NO_ACCOUNT`。这些是业务结果，不是构建或文件系统故障。若日志无法打开，程序在处理交易前报告文件状态并以返回码 1 结束。

## 五、模块调用顺序

1. `build.sh check` 验证所有源文件和 Copybook 路径。
2. `build.sh build` 先编译两个被调用程序的目标文件，再把它们与主程序链接。
3. 主程序打开 `batch.log`，记录 `EVENT=BATCH_START`，然后初始化账户和计数。
4. 每笔交易都重用同一个 `WS-TRANSACTION-RECORD`，并显式通过 `BY REFERENCE` 传递账户、交易和状态字段。
5. `POST-TRANSACTION28` 更新账户余额或返回拒绝状态；主程序拥有计数和日志事件。
6. `REPORT-ACCOUNT28` 接收共享账户与计数结构，显示批次结果。
7. 主程序写批次结束事件、检查文件状态并关闭日志。未知的子程序状态也令进程返回非零码。

`BINARY-LONG` 等平台二进制布局不在本课接口中使用；金额以 `PIC 9(7)V99` 展示十进制字段契约。共享声明让所有模块从同一 Copybook 编译，降低 PIC 或字段顺序不一致的风险。

## 六、构建错误与日志错误

- `./build.sh unknown` 返回 64 并打印用法说明。
- 缺少 `cobc` 时，shell 返回 127；可用 `COBC` 指定编译器命令。
- 日志路径无法打开时，主程序报告 `ERROR=OPEN_LOG STATUS=37`，返回 1，且不会调用过账子程序。
- 日志 WRITE 或 CLOSE 状态失败也会设置系统错误并返回 1。`BATCH_END` 在关闭日志前写入，因此若日志 CLOSE 随后失败，最后一条日志仍可能显示 `IO_ERROR=N`；此时标准输出与进程返回码为准。日志自身的 OPEN 失败无法写入日志，因此通过标准输出和退出码报告。

已实际验证 clean scratch 构建、正常运行、日志精确输出和日志打开失败。当前环境可能在标准错误打印 `Warning: program compiled against libxml 212 using older 209`；它不属于程序的标准输出。

## 七、修改练习（有答案）

1. 在 `1300-POST-OVERDRAFT` 中把金额从 2000.00 改为 1000.00。重新运行，确认这笔取款成功、余额和 posted/rejected 计数随之变化，且日志状态与 CALL 返回一致。
2. 在 `1400-POST-UNKNOWN-TYPE` 中把类型从 `X` 改为 `D`。重新运行，确认未知类型拒绝变成有效存款，并检查账户报告和第四条交易日志。

答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；步骤见 [`exercise.md`](./exercise.md)。

## 八、举一反三（无答案）

将账户记录与交易记录改为由文件模块逐条装载；定义文件状态如何区分 EOF、坏记录和 I/O 故障。为每个子程序调用加入可关联的批次号与记录序号，说明目标文件重编译后如何触发重新链接。

本题不提供答案。不要把业务拒绝伪装成编译失败，也不要重复定义 Copybook 中已有的记录布局。

## 九、企业实战补充

主程序拥有批次流程和计数；过账程序拥有业务规则；报告程序只消费最终状态。Copybook 是模块接口的一部分，必须和每个目标文件一起纳入构建依赖。生产构建还需固定编译器版本、编译选项、ABI、模块清单和产物版本；本例的单脚本仅演示可重复的本地构建。

## 参考资料

- [GnuCOBOL Programmer’s Guide：COPY](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#COPY)
- [GnuCOBOL Programmer’s Guide：CALL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#CALL)
- [GnuCOBOL Programmer’s Guide：PROCEDURE DIVISION USING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-USING)
- [GnuCOBOL Programmer’s Guide：FILE STATUS](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SELECT)
