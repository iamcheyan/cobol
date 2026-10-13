# 模块 09 设计：可调用模块与接口契约

## 1. 业务动机

夜间批处理里同一段逻辑会被多个 JOB 反复需要：金额入账校验、客户有效性校验、统一格式日志。
如果每个 JOB 各抄一份，规则一改就会漂移，事故调查时无法判断“到底哪个副本是对的”。
本模块把这三段逻辑抽成**可调用子程序**，让调用者通过**版本化接口**复用它们，并演示当接口
长度/版本不匹配、或子程序内部有未初始化残留状态时，故障如何在调用者与被调用者之间传回。

GnuCOBOL 多程序编译：`cobc` 可一次链接多个源文件，其中含 `PROCEDURE DIVISION`（无 `USING`）
者为主程序，其余 `PROGRAM-ID` 成为可按名 `CALL` 的子程序。本模块命令：

```bash
cobc -Wall -I curriculum/modules/09-modular/copybooks \
     -I curriculum/bank/copybooks -x -o batch09 \
     BATCH09.COB AMTCALC.COB CUSTVAL.COB LOGGER.COB
```

## 2. 文件契约（冻结，不变）

沿用 `BANK-SYSTEM.md`，本模块不修改：

| 记录 | 长度 | 关键字段 |
|---|---:|---|
| CUSTOMER v1 | 27B | `customer_id`(8) `name`(10) `balance_demo`(8) `status`(1) |
| ACCOUNT v1 | 47B | 账户/客户/币种/符号/期初(13)/状态/业务日/`layout_version`(45–47=`001`) |
| TRANSACTION v1 | 55B | 账户/交易ID/业务日/序号/方向/金额(13)/状态 |

均为 ASCII、LF 结尾、LF 不计逻辑宽度。账户按 `account_id` 升序，交易按
`account_id`、`sequence_no`、`transaction_id` 严格升序。`transaction_id` 还是**全局业务
幂等键**：整份交易流中不得出现两次（同账户不同序号、跨账户重复都不允许），否则 JOB 返回
RC8 且不发布。本模块较 v1 收紧/裁掉了 07 的冲正、
账本等，只保留“客户校验 + 金额入账 + 日志”三件事，以聚焦 CALL 语义。

## 3. 版本化调用接口（`copybooks/`）

所有接口第一段固定为 **长度头 + 版本头**。调用者填自己认为的记录长度与版本，被调用者用
`LENGTH OF` 实测自己的期望值并比较；不匹配即返回 RC8（接口错误），不进入业务逻辑。
这就是“参数长度/版本不匹配”的可检测入口，替换掉“靠约定、错了就崩”的做法。

长度为本机 GnuCOBOL 3.2 默认方言实测（`LENGTH OF`）：

| 接口 | 长度 | 字段（顺序即偏移） | 语义 |
|---|---:|---|---|
| `AMT-CALC-INTERFACE` v1 | 45 | LENGTH(2,`COMP-5`) VERSION(3) OP(3) DIRECTION(1) AMOUNT-IN(13) BALANCE(`S9(13) COMP-3`,7) REASON(16) | 入账计算；BALANCE 双向 |
| `CUST-VAL-INTERFACE` v1 | 40 | LENGTH(2) VERSION(3) CUSTOMER-ID(8) NAME(10) STATUS-IN(1) REASON(16) | 客户校验 |
| `LOG-INTERFACE` v1 | 54 | LENGTH(2) VERSION(3) SEVERITY(1) EVENT(8) MESSAGE(40) | 追加日志 |

`VERSION` 固定为 `001`；`AMT-IFACE-OP` 本课固定 `PST`。调用者必须写
`MOVE LENGTH OF <接口> TO <接口>-LENGTH`，不得硬编码魔数（除非刻意做故障实验）。

## 4. 传参语义与返回码

| 语义 | 本模块用法 | 观察点 |
|---|---|---|
| `BY REFERENCE`（默认） | AMTCALC、CUSTVAL 的接口 | 接口中的 BALANCE/REASON 由被调用者回写，调用者可见 |
| `BY CONTENT` | LOGGER 的接口 | 被调用者拿到副本，改不动调用者的字段 |
| `BY VALUE` | 仅 `scripts/ifaceprobe.COB` 演示 | 数值按值传入，被调用者修改不回传 |
| `RETURNING` | 三个模块都在调用处 `... RETURNING WS-SUB-RC` | 取回被调用者设置的 `RETURN-CODE` |

**平台事实（GnuCOBOL 3.2 实测）**：被调用者若在 `PROCEDURE DIVISION` 上写
`RETURNING <项>`，编译给出 `warning: program RETURNING is not implemented`，运行时会访问非法
内存。因此**被调用者统一 `MOVE <rc> TO RETURN-CODE` 后 `GOBACK`**，调用者用 `RETURNING`
接收。这与仓库既有实现一致。`BY VALUE` 也会给 `-Wunfinished` 警告，故生产模块不用它，
只在探针里演示。

RC 约定（与课程一致）：

| RC | 含义 | 输出政策 |
|---:|---|---|
| 0 | 全部接收、守恒通过 | 发布 |
| 4 | 有逐笔业务拒绝 | 发布已核对结果，调用 JOB 须显式允许 RC4 |
| 8 | 接口长度/版本/操作、文件布局/日期/排序等契约错误 | 整批失败，不发布 |
| 12 | 文件系统、打开/写入、构建、发布等系统故障 | 整批失败，不发布 |

主程序在每次 CALL 后立即用 `EVALUATE` 检查返回值；遇 8/12 走 `STOP RUN`，因此失败状态
**由被调用者产生、由调用者准确传回进程退出码**。

## 5. 工作区生命周期与状态泄露

- 子程序 `WORKING-STORAGE SECTION` **默认是静态的**：同一进程内多次 CALL 之间保持上次的值。
  LOGGER 正是利用这一点维护递增的 `WS-SEQ`（这是有意状态）。
- 若把“每次调用都应是全新”的逻辑也放在静态区，第二次调用会看到上次残留，产生“第二次
  调用未初始化残留”事故。`IS INITIAL` 让每次调用前重置该程序的 `WORKING-STORAGE`。
- `scripts/ifaceprobe.COB` 用两个最小子程序同题对比：`STATIC-ACC` 第 1/2 次返回 `0001/0002`，
  `INIT-ACC`（`IS INITIAL`）两次都返回 `0001`。这就是可复现的状态泄露实验与最小修复。
- 三个业务模块自身无跨调用业务状态（AMTCALC/CUSTVAL 每次重算），因此“多次调用结果正确、
  无隐含共享状态”可被 `check.py` 的重复用例证明。

## 6. 业务规则

**CUSTVAL**（返回 0/4）：ID 非数字→`BAD-ID`；姓名全空格→`CUST-NO-NAME`；状态 `A` 通过、
`D`→`CUST-DISABLED`、其他→`CUST-BAD-STATUS`。接口不符→8。

**AMTCALC**（返回 0/4）：接口不符→8；金额非数字→`AMT-NOT-NUMERIC`；金额 0→`ZERO-AMOUNT`；
方向非 `C/D`→`BAD-DIRECTION`；`new = balance ± amount`，超过 13 位（`±9999999999999`）→
`OVERFLOW`；出账后为负→`OVERDRAFT`；否则回写新余额、`OK`。金额为日元最小单位整数，无浮点。

**主程序**（决定 4）：交易状态非 `N`→`TX-STATUS`；账户状态非 `A`→`ACCOUNT-STATUS`；
找不到账户→`NO-ACCOUNT`。业务拒绝逐笔记录，全部不影响守恒校验；契约错误（长度/日期/布局
版本/排序）立即 RC8。

业务拒绝原因优先级：`TX-STATUS` < `ACCOUNT-STATUS` < AMTCALC 内部顺序。接口结构错误始终
RC8，不降级为逐笔拒绝。

**JOB 全局交易唯一性**（`run.sh`，在 CALL/入账之前）：按 `account/sequence/id` 的流式突合
只能保证有序，**不能**保证 `transaction_id` 全局唯一。JOB 用外部排序
（`cut -c11-26 | sort | uniq -d`；`sort` 为外部归并、内存有界）检测全局重复，命中即
RC8、不发布。这是 **JOB 级**唯一性校验：不把整份交易读进内存数组（不替代被教的顺序突合
算法），也不因学员替换 `COURSE_SOURCE` 而被绕过。`oracle.py` 用独立集合复核同类重复
（同账户不同序号、跨账户），夹具见 `fixtures/invalid/dup-global-txid` 与
`fixtures/invalid/dup-cross-account`。

## 7. 输出格式

`report.txt`（stdout，逐行）：

```text
CUST|<id>|OK|<name>                       CUST|<id>|REJECT|<reason>
CUST-CONTROL|READ=<12>|OK=<12>|REJECT=<12>
POST|<acct>|<txid>|ACCEPT|<sign13>        POST|<acct>|<txid>|REJECT|<reason>
ACCT|<acct>|<sign13>
POST-CONTROL|ACCTS=<12>|NOTX=<12>|TX=<12>|ACCEPT=<12>|REJECT=<12>
  |OPENING=<sign18>|CLOSING=<sign18>|CREDIT=<18>|DEBIT=<18>
```

计数为 12 位零填充；金额 `<sign13>`/`<sign18>` 为显式符号加定宽数字；CREDIT/DEBIT 为 18 位
无符号。派生文件：`ledger.dat`（47B 期末 Master，仅改符号与期初/余额字段）、
`customers-valid.dat`（27B 通过记录）、`customers-rejected.dat`（27B 原记录 + `|` + 原因）、
`batch09.log`、两个 SHA256 清单、`run.txt`、`compiler.txt`、`source.sha256`。

`batch09.log` 每行由 LOGGER 写：`<YYYYMMDD>|<seq:6>|<sev>|<event:8>|<message>`。因 GnuCOBOL
`LINE SEQUENTIAL` 会裁掉记录尾部空格，行尾不定宽；这是平台实际行为，独立模型同样裁剪。

## 8. 人工微算例（normal）

客户 1/2 均 `A` 通过。账户1 期初 1000：T01 入账 500→1500，T02 出账 200→1300。账户2 期初
500：T03 入账 100→600。故期末 1300/600；期初合计 1500，贷方 600、借方 200，期末
`1500+600-200=1900`。输入交易 3=接收 3+拒绝 0；账户 2=有交易 2+无交易 0。冻结账户用例中
该账户**有交易**（全部被拒），故 `NOTX` 不计，正确口径是“账户是否收到过交易”，不是“是否有
交易被接收”。

## 9. 关键审查点

- 不接受硬编码接口长度/版本以外的魔数；故障实验必须显式改接口头而非改数据冒充。
- 被调用者只回写接口字段 + `RETURN-CODE`；不得读写调用者的私有工作区。
- 每个 CALL 后必须检查返回码；把 8/12 当业务拒绝处理、或失败仍发布，均属关键缺陷。
- `transaction_id` 必须做**全局**唯一性校验（同账户不同序号、跨账户重复都致命 RC8）。
  仅按 `account/sequence/id` 有序突合会漏掉全局重复；不得用全量内存数组替代有界机制。
- 状态泄露必须能通过 `ifaceprobe` 复现，并有 `IS INITIAL`/显式初始化的最小修复。
