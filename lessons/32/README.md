# 第 32 课：银行账户对账批处理

> 毕业项目：读取账户主档和交易文件，校验并应用交易，写出接受/拒绝明细，再将最终账户状态同步到 SQLite。示例使用 GnuCOBOL 固定格式和第 29 课验证过的 GixSQL 工具链。

## 一、课程目标

完成本课后，能够：

- 把多个 COBOL 程序、Copybook、固定宽度文件和 Embedded SQL 组合成一个可构建的批处理项目。
- 区分业务拒绝与系统失败。透支、未知交易类型和未知账户进入拒绝文件；文件或 SQL 故障令进程返回非零。
- 以账户号为键将文件计算结果与数据库快照比较，并分别处理更新、保持不变和插入。
- 检查批次计数不变量，验证重跑结果，并解释文件与数据库之间的恢复边界。

预备知识：完成第 20、23–31 课；会使用 `cobc`、Bash、SQLite 和 `CALL` / `COPY` / Embedded SQL。预计用时：3–4 小时。

## 二、项目输入与业务规则

程序读取两个行顺序文件。每条记录固定宽度，不含分隔符：

| 文件 | 宽度 | 字段位置 | 规则 |
|---|---:|---|---|
| `accounts.txt` | 27 字符 | 1–10 账户号；11–18 客户号；19–27 余额分 | 账户号必须唯一；最多 20 个账户；余额必须为数字 |
| `transactions.txt` | 20 字符 | 1–10 账户号；11 交易类型；12–20 金额分 | `D` 入账；`C` 出账；金额必须为数字 |

金额用整数分传输，例如 `000012550` 表示 125.50。程序把金额转换到 `S9(7)V99 COMP-3`，在结果中用编辑字段显示两位小数。

处理规则：

1. 账户主档先全部载入内存表。重复账户、超过 20 个账户或非法主档余额属于批次失败。
2. 每条交易必须找到主档账户。`D` 增加余额；`C` 只有在余额足够时才扣减。
3. 非数字交易金额、未知账户、透支和未知类型是业务拒绝，写入 `rejected.txt`，批次仍可成功结束。
4. 接受的交易写入 `accepted.txt`。数据库同步仅在文件处理没有系统错误时开始。
5. 对每个主档账户，用账户号查询 `ACCOUNT_SNAPSHOT`。客户号和余额均相同则 `UNCHANGED`；记录存在但至少一项不同则 `UPDATED`；查询返回 SQLCODE 100 则插入并记为 `INSERTED`。

这是一份教学用的单向同步：从文件主档和本次交易计算最终余额，再把它写到数据库快照。输入重放会从固定的主档余额重新计算，因此不会把同一笔交易重复加到数据库余额上。

## 三、构建和运行

需要 Linux、GnuCOBOL (`cobc`)、GCC、SQLite (`sqlite3`) 和第 29 课验证过的 GixSQL 1.0.20b precompiler、SQLite driver 与运行库。若尚未安装，先在本课目录运行 `../29/install-toolchain.sh`；默认路径为 `../29/build/toolchain/usr`。自定义安装时设置 `GIXSQL_ROOT`。

```sh
../29/install-toolchain.sh
./build.sh check
./build.sh build
./build.sh run
./build.sh run-existing
```

- `check` 用 `gixpp` 预处理 SQL，再让 `cobc` 检查驱动程序、文件模块和 SQL 模块。
- `build` 编译两个子程序并链接 `lesson_32`。
- `run` 重新建立 `build/lesson32.db`，应用 `schema.sql`，复制输入夹具到 `build/run/` 后执行程序。
- `run-existing` 保留数据库，只重置运行目录中的输入文件并重跑，用于检查数据库状态的重放行为。
- `./check.sh` 在临时目录执行正常、拒绝、更新/不变/插入、SQL 错误、恢复和缺少输入文件场景。
- `./build.sh clean` 删除本课 `build/` 生成物。

修改 `fixtures/` 中的数据后运行 `./build.sh run`；它会复制新的夹具并重建数据库。`run-existing` 也会重新复制夹具，但保留数据库，用于重放检查。`build/run/` 仅用于查看生成的文件；下一次脚本运行会重建该目录。生成物由 `.gitignore` 排除。

## 四、标准运行结果

`./build.sh run` 的标准输出：

```text
POSTED TX=001 ACCOUNT=A000000001 TYPE=D BALANCE=0001125.50
POSTED TX=002 ACCOUNT=A000000001 TYPE=C BALANCE=0001100.25
REJECTED TX=003 ACCOUNT=A000000003 REASON=INSUFFICIENT
REJECTED TX=004 ACCOUNT=A000000005 REASON=BAD_TYPE
REJECTED TX=005 ACCOUNT=A000000009 REASON=NO_ACCOUNT
CONNECT=OK
SYNC UPDATED ACCOUNT=A000000001 BALANCE=0001100.25
SYNC UNCHANGED ACCOUNT=A000000003 BALANCE=0000002.00
SYNC UNCHANGED ACCOUNT=A000000005 BALANCE=0000250.75
DISCONNECT=OK
SUMMARY ACCOUNTS=03 TX=005 POSTED=002 REJECTED=003 UPDATED=001 UNCHANGED=002 INSERTED=000
```
GixSQL 运行库在某些环境会把 libxml 版本警告写到标准错误；它不属于程序标准输出，`check.sh` 只比较 stdout。

生成文件位于 `build/run/`：`accepted.txt` 有两条成功入账，`rejected.txt` 有三条业务拒绝，`account-report.txt` 有三条数据库同步结果，`batch.log` 按顺序记录批次开始、交易决定、数据库连接和同步结束。SQLite 表 `ACCOUNT_SNAPSHOT` 的最终账户 A000000001 余额为 1100.25。

第二次执行 `./build.sh run-existing` 时，账户余额不变，摘要变为：

```text
SUMMARY ACCOUNTS=03 TX=005 POSTED=002 REJECTED=003 UPDATED=000 UNCHANGED=003 INSERTED=000
```

若数据库中缺少 A000000005，第一次同步会输出 `SYNC INSERTED`；再重跑后同一账户变为 `UNCHANGED`。

## 五、源码与内存/控制流解析

源码保持传统固定格式：第 7 列为指示符区，第 8 列起是 Area A，第 12 列起是 Area B，有效文本不超过第 72 列。用下表按声明和段落阅读每条语句；程序中相邻的 `MOVE` / `COMPUTE` / `IF` / `WRITE` 分别完成字段搬运、金额换算、分支决策和持久化。

### `lesson_32.cob`：主程序

- 第 1–8 行声明程序名并引入 `BATCH-INTERFACE.CPY`。`WS-ACCOUNT-TABLE` 是固定 20 行的共享账户表；`WS-BATCH-COUNTS` 保存交易和数据库同步计数；`WS-CHECK-COUNT` 是校验时的临时数值。
- 第 10–28 行是主流程。`INITIALIZE` 清空表和计数，然后明确把失败标志置为 `N`。`CALL ... BY REFERENCE` 把同一块数据交给 `LOADPOST32`；只有共享失败标志不是 `Y` 才调用 `SYNCDB32`。随后校验计数、打印摘要、设置进程返回码。
- 第 29–37 行打印固定格式摘要，编辑的 `PIC 99` / `PIC 999` 计数显示前导零。
- 第 38–44 行把系统失败映射到 `RETURN-CODE` 1；业务拒绝不改变失败标志，因此可返回 0。
- 第 45–62 行检查两个不变量：`POSTED + REJECTED = TX`；成功同步时 `UPDATED + UNCHANGED + INSERTED = ACCOUNTS`。任一不成立都会报告错误并令进程失败。
- 第 63–100 行的注释记录文件契约、模块责任、计数不变量、查表成本和恢复边界；第 101 行显式结束主程序。

### `load_post_32.cob`：文件校验与交易过账

- 第 1–32 行声明五个行顺序文件：两个输入、接受输出、拒绝输出和共享批次日志。每个 `FILE STATUS` 都有自己的 `PIC XX` 字段。
- 第 33–57 行声明交易解析 Copybook、文件状态、EOF/打开标志、查找索引、金额和输出缓冲区。`LINKAGE SECTION` 的两个组与主程序布局相同，子程序通过 `PROCEDURE DIVISION USING` 收到调用方的数据。
- `1000-OPEN-FILES`（第 68–113 行）按顺序打开文件。每次成功都记录打开标志，以便后续只关闭已打开资源；发生失败后不再继续打开其余文件。
- `1100-LOAD-ACCOUNTS`（第 114–127 行）逐条读取主档，EOF 时设置标志；有效记录交给 `1110-STORE-ACCOUNT`。
- `1110-STORE-ACCOUNT`（第 128–154 行）先检查 20 行容量，再把 10 字符账户号、8 字符客户号和 9 位分金额移入表格。余额先通过 `IS NUMERIC` 验证，再用 `NUMVAL(...) / 100` 转成隐含小数格式。循环检查新账户号是否重复；重复属于系统输入错误，设置共享失败标志。
- `2000-POST-TRANSACTIONS`（第 155–168 行）读取交易文件；每条有效记录交给 `2100-POST-ONE`。
- `2100-POST-ONE`（第 169–206 行）增加交易序号，按固定位置拆出账户号、类型和金额文本；用 `PERFORM VARYING` 在线性账户表中查找。金额先验数字，再转为 packed decimal。缺少账户、非法金额或业务规则产生的原因进入 `WS-REASON`。无拒绝原因就调用 `2300-WRITE-POSTED`，否则调用 `2400-WRITE-REJECTED`；最后把该条决定复制到日志缓冲区。
- `2200-APPLY-TRANSACTION`（第 207–220 行）以 `EVALUATE` 分派类型。`D` 加余额；`C` 先比较金额和余额，只有不透支才扣款；其他类型记为 `BAD_TYPE`。
- `2300-WRITE-POSTED` 和 `2400-WRITE-REJECTED`（第 221–251 行）各自递增对应计数，把账户、序号、结果余额或拒绝原因格式化进 80 字符缓冲区，显示并写入对应输出文件。写失败时设置系统失败标志。
- `8000-CLOSE-FILES`（第 252–293 行）按打开标志关闭文件；每次关闭都检查状态。日志在关闭前追加 `EVENT=POSTING_COMPLETE`。
- `8200-WRITE-LOG`（第 294–300 行）把 100 字符日志缓冲区写出，并把写错误升级为系统失败。

### `sync_db_32.cob`：Embedded SQL 与同步报告

- 第 1–17 行声明报告与日志文件。第 18–37 行声明 GixSQL host variables、数据库连接状态、同步状态和 SQLCA。
- 第 38–55 行在 linkage 中再次声明与调用方一致的账户表和批次计数布局。保持字段顺序，因为 `CALL ... BY REFERENCE` 按位置传递整块数据。末尾预留字节用于 GixSQL：预处理会把 linkage 最后一项输出为注释；移除预留项后 `WS-FAILED` 会变成未定义字段，编译失败。
- `MAIN-SYNC`（第 56–102 行）打开报告并追加批次日志；只有文件打开正常才连接数据库。数据库和文件分别关闭，连接成功时执行 `9000-DISCONNECT`。
- `1000-CONNECT-DATABASE`（第 103–122 行）从环境读取 `DATASRC`、用户和密码，执行 GixSQL `CONNECT`。运行脚本将 SQLite 路径传入环境；程序源代码不包含机器路径或口令。
- `2000-SYNC-TABLE`（第 123–127 行）逐个处理内存表中的账户，失败时停止后续账户。
- `2100-SYNC-ACCOUNT`（第 128–157 行）把当前账户字段复制到独立 host variables，再执行 `SELECT ... INTO`。SQLCODE 0 时比较客户号与余额；100 表示无匹配行，转到插入；其他 SQLCODE 设为失败。只有成功分类才写报告和日志。
- `2200-UPDATE-ACCOUNT`（第 158–171 行）以账户号作为 `WHERE` 键更新客户号和余额；SQLCODE 0 才增加 `UPDATED` 计数。
- `2300-INSERT-ACCOUNT`（第 172–185 行）插入数据库不存在的账户，并增加 `INSERTED` 计数。
- `2400-REPORT-SYNC`（第 186–203 行）把决策、账户号和最终余额写入报告文件和批次日志。
- `8100-WRITE-LOG`（第 204–210 行）检查每条日志写入状态。`9000-DISCONNECT`（第 211–221 行）关闭 GixSQL 连接；SQL 或断开失败以状态 1 结束进程。第 222 行注释标记 GixSQL preprocessor 生成的 cursor footer 边界。

Java/Python 程序常把账户表写成对象列表、字典或 DataFrame，把 `CALL` 看作函数调用，把 `FILE STATUS` 看作显式 I/O 异常分支。本例的差别在于数据布局由 `PIC` 和层级号定义，`LINKAGE SECTION` 接收调用方内存，文件与 SQL 状态由程序显式检查。不要假设一条 COBOL 记录等同于任意语言对象，也不要把 `BY REFERENCE` 的共享修改误当作值拷贝。

## 六、失败、恢复和生产边界

`check.sh` 用 SQLite trigger 注入实际 UPDATE 错误，确认 SQLSTATE 被报告、程序返回 1；移除 trigger 后重跑，文件重放把数据库恢复到相同最终余额。缺少账户主档也会返回 1，并阻止数据库同步。

这个样例没有把文件输出和数据库写入包装成一个分布式事务，也没有声明整个批次具备原子性。SQL 更新可能在其他账户报错前已经生效；重跑可按完整输入重新核对余额，但不会回滚此前写出的接受/拒绝文件。生产系统还需要批次 ID、输入快照与校验和、审计留存、显式数据库事务提交策略、部分失败恢复流程、并发更新控制和运维告警。不能用这个练习替代这些设计。

GixSQL/SQLite 在本课中执行的是实际 Embedded SQL；`sqlite3` 负责建表和检查数据库，COBOL 模块通过 GixSQL 连接并执行 `SELECT` / `UPDATE` / `INSERT`。SQLite 用于可复现教学，不代表 Oracle/PostgreSQL 的并发、锁、事务或 SQL 方言行为。

## 七、修改练习（有答案）

1. 在 `fixtures/transactions.txt` 增加一笔账户 A000000003 的 1.00 入账。更新后余额应由 2.00 变为 3.00；首次运行应把该账户分类为 `UPDATED`，而不是 `UNCHANGED`。
2. 从 `schema.sql` 删除账户 A000000005，再执行 `./build.sh run`。确认该账户走 SQLCODE 100 插入分支并计入 `INSERTED`；执行 `./build.sh run-existing` 后应变为 `UNCHANGED`。

答案仅覆盖这两项，见 [`answer.md`](./answer.md)。详细操作步骤见 [`exercise.md`](./exercise.md)。

## 八、举一反三（无答案）

为账户表增加批次日期，阻止程序处理日期不一致的主档和交易文件。为 SQL 同步增加乐观并发检查，避免两个批次静默覆盖同一账户。设计可恢复的批次状态表，区分“文件完成”“数据库提交”“报告归档”三个阶段，并说明每个失败点的重跑规则。

本题不提供答案。

## 企业实战补充

银行日终账户过账会将核心系统输出的交易文件按账户校验并汇总，再同步余额、生成差异报告和审计日志。企业还款、保险保费扣收、证券资金结算也会使用类似的文件校验与主数据核对模式。真实批次需要明确业务日期、幂等键、重复文件政策、金额精度、数据库事务范围、锁策略、清算截止时间、差错队列和操作审计；这些控制必须按机构的账务与恢复规则设计。

## 参考资料

- [第 20 课：有序文件匹配](../20/README.md)
- [第 26 课：错误处理](../26/README.md)
- [第 28 课：多模块批处理](../28/README.md)
- [第 29 课：GixSQL Embedded SQL 环境](../29/README.md)
- [第 30 课：SQL Cursor](../30/README.md)
- [第 31 课：文件与数据库快照同步](../31/README.md)
- [GixSQL README](https://github.com/mridoni/gixsql/blob/main/README.md)
- [GnuCOBOL Programmer’s Guide](https://gnucobol.sourceforge.io/HTML/gnucobpg.html)
