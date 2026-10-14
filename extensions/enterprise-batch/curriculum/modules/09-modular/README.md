# 模块 09：模块化程序（CALL / LINKAGE / 共通模块）

建议 4 小时。先修：模块 06 文件处理、模块 07 金额与守恒。运行环境：Linux x86-64、GnuCOBOL
3.2.0、Bash、GNU coreutils、Python 3（仅验收驱动）。macOS/WSL 未验证。

覆盖大纲 09.1–09.3：`CALL`/`LINKAGE`/`USING`、`BY REFERENCE`/`BY CONTENT`/`BY VALUE`、
`RETURNING`、`GOBACK`；工作区生命周期、共通 Copybook、参数长度/版本及接口不匹配；抽取金额
计算（AMTCALC）、客户校验（CUSTVAL）、日志（LOGGER）三个共通模块，并演示调用者与被调用者
如何共同影响一次故障调查。接口布局、字段偏移、RC 传播与人工算例见 [DESIGN.md](DESIGN.md)。

## 1. 业务为什么需要这一处理

夜间批处理里“金额能不能入账”“客户是否有效”“如何写统一日志”会被多个 JOB 重复需要。
若各 JOB 各写一份，规则一改就出现版本漂移，事故调查无法判断哪个副本正确。学习者接到的
需求是：把这三段逻辑抽成**版本化可调用子程序**，主程序通过 `CALL` 复用它们；当参数长度/
版本对不上、或被调用模块留有未初始化状态时，能够复现并定位故障，且失败状态被准确传回。

## 2. 输入从哪来、格式、哪些前提已保证

`fixtures/normal/`、`fixtures/boundary/<case>/`、`fixtures/invalid/<case>/` 下三个定宽文件：
`customer.dat`(27B)、`account.dat`(47B)、
`transaction.dat`(55B)，ASCII、LF 结尾。字段与规则见 `../../../docs/curriculum/BANK-SYSTEM.md`；
营业日由参数给出（夹具用 `20261010`）。前提：上游 JOB 已保证记录定长与 LF；账户升序、
交易按账户/序号/交易ID 升序，且 `transaction_id` 全局唯一（重复即 RC8，见 DESIGN 第 6 节）。
本模块不重新实现 07 的突合/冲正，只聚焦 CALL 与共通模块。

## 3. 从干净 checkout 构建、运行、复位

```bash
lab=curriculum/modules/09-modular
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/customer.dat" \
  "$lab/fixtures/normal/account.dat" "$lab/fixtures/normal/transaction.dat" \
  /tmp/bank09-run 20261010
rc=$?
set -e
test "$rc" -eq 0            # normal 无业务拒绝
diff -u "$lab/expected/normal.txt" /tmp/bank09-run/report.txt
python3 "$lab/scripts/check.py"    # 全部正常/边界/异常与失败路径
```

`run.sh` 支持任意 cwd、含空格的新输出目录、立刻拒绝已存在的输出与并发锁；失败（RC8/12）
不发布任何目录。发布目录含 `report.txt`、`ledger.dat`、`customers-valid.dat`、
`customers-rejected.dat`、`batch09.log`、`inputs.sha256`、`outputs.sha256`、`run.txt`、
`compiler.txt`、`source.sha256`。复位：

```bash
bash "$lab/scripts/build.sh" /tmp/batch09         # 仅编译练习
bash "$lab/scripts/reset.sh" /tmp/bank09-run      # 只删带标记的课程输出目录
```

`reset.sh` 拒绝符号链接、未标记目录与仓库内路径；手动练习请先复制夹具，不要改 fixtures 原件。

## 4. 预期输出、RC、笔数金额与独立核算

`expected/normal.txt` 由业务规则独立演算（微算例见 DESIGN 第 8 节），不是程序输出回抄。
normal：客户 2/2 通过；交易 3=接收 3+拒绝 0；账户 2=有交易 2+无交易 0；期初 1500、贷方 600、
借方 200、期末 1900，逐账户 `closing = opening + credit − debit`。各用例 RC 汇总在
`expected/cases.json`（RC0 干净、RC4 逐笔业务拒绝且发布、RC8 契约错误不发布），
`expected/README.md` 说明各夹具的独立核算依据。

`scripts/oracle.py` 是**独立于 COBOL 的 Python 参考模型**，由它生成 `expected/`；`run.sh`
发布前用 `scripts/verify-publish.py` 调同一模型对**原始输入**重算并逐字节比对报告、账本、
两个客户输出与日志，任何漂移即 RC12 且不发布。`run.sh` 还会在入账前用外部排序做
`transaction_id` **全局唯一性** JOB 校验：命中重复即 RC8、不发布，且不因 `COURSE_SOURCE`
而被绕过（夹具 `fixtures/invalid/dup-global-txid`、`dup-cross-account`）。

## 5. 需要改哪里、哪些接口不能破坏

- 在 `starter/BATCH09.COB` 补齐 TODO：客户校验、按账户 Key Break 入账、日志三处。
- 三个共通模块（AMTCALC / CUSTVAL / LOGGER）是**既存依赖、随学生包提供**，位于
  `lib/{AMTCALC,CUSTVAL,LOGGER}.COB`；接口 Copybook 在 `copybooks/*-V1.CPY`。仓库内
  以 `instructor/modules/09-modular/` 为参考，`build.sh`/`run.sh` 自动二选一。
- **冻结契约**：CUSTOMER 27B / ACCOUNT 47B / TRANSACTION 55B 与接口头 `VERSION='001'`
  不得擅自更改；需要演进时新增 `-V2` 并保留旧版本可解释。
- 不能破坏：`RETURN-CODE`（0/4/8/12）语义、发布前守恒与独立校验、失败不发布。

## 6. 故意破坏哪些条件、如何调查恢复

按顺序做，每步先预测再运行：

1. **接口版本不匹配**：把主程序送 AMTCALC 的 `MOVE '001' TO AMT-IFACE-VERSION` 改成 `002`，
   预期被调用者返回 8、主程序 `INTERFACE-MISMATCH`、进程 RC8 且无发布。根因在**调用者**：
   被调用者行为正确，是调用者用了旧/新版本头。恢复：改回 `001`。
2. **参数长度不匹配**：把 `MOVE LENGTH OF AMT-CALC-INTERFACE TO AMT-IFACE-LENGTH` 改成
   `MOVE 1`，预期 AMTCALC 返回 8 `IFACE-LENGTH`、无发布。
3. **状态泄露**：运行 `ifaceprobe`，看到 `STATIC CALL1=0001 CALL2=0002`（第二次残留）与
   `INITIAL CALL1=0001 CALL2=0001`。根因：子程序静态工作区跨调用保留；最小修复：`IS INITIAL`
   或每次显式初始化。
4. **业务/契约边界**：`fixtures/` 提供 0 金额、透支、13 位溢出、未知方向、无账户、冻结账户
   （RC4 发布）与短记录、布局版本 `002`、错误业务日、交易逆序、**全局交易 ID 重复**
   （RC8 不发布）。
5. **全局重复交易 ID**：把 normal 第 3 条交易的第 11–26 字节改写成第 1 条的
   `transaction_id`（保留账户与序号），文件仍按 `account/sequence/id` 有序，旧的顺序突合
   会 RC0 误发布并重复入账；修复后的 JOB 用外排全局校验，RC8 且不发布。夹具
   `dup-global-txid`（同账户不同序号）与 `dup-cross-account`（跨账户）覆盖两类。

`check.py` 的 `check_starter_and_faults` 会把上述 1–2 号故障自动注入参考源码运行，断言
RC8 且不发布；`check_probe` 断言 3 号的确定输出。

## 7. 插件操作与终端替代

终端替代并列，插件缺失不阻断课程：

- `:CobolGotoDef` 复核调用接口：光标放到主程序 `CALL 'AMTCALC' USING AMT-CALC-INTERFACE`，
  跳到 `lib/AMTCALC.COB` 核对 `USING` 项；`:CobolGotoCopybook` 在
  `COPY "AMTCALC-INTERFACE-V1.CPY"` 行打开接口 Copybook，确认长度/版本头。
  终端替代：`rg -n 'CALL .|USING|LINKAGE|RETURNING|GOBACK' lib/`。
- 用 Aerial/大纲查看主程序 `1000-MAIN/2000-.../3000-.../6000-...` 段落层次，理解调用边界。
  终端替代：`rg -n '^       1|^       2|^       3|^       6|^       8' \
  starter/BATCH09.COB`（完成后）或 `instructor/modules/09-modular/BATCH09.COB`。
- 用 P1 的 PIC 计算器核对接口字段字节（`AMT-BALANCE` 为 `S9(13) COMP-3`=7B）。终端替代：
  `AMTCALC-INTERFACE` 实测 `LENGTH OF`=45，字段偏移见 DESIGN 第 3 节。

插件估算不得作为字节布局最终依据；以 `cobc` 实测 `LENGTH OF` 与 `check.py` 为准。

## 8. 完成需要交什么证据、何种结果算失败

按 [evidence/README.md](evidence/README.md) 提交：源码修改、normal 报告与 `ledger.dat`、
至少一个 RC4（发布）和一个 RC8/RC12（不发布）的原始 RC 与“无发布目录”证据、`ifaceprobe`
的字节/RC 输出、输入与输出 SHA256、独立核算的计数/金额守恒、接口前后版本说明。以下任一即
失败：失败仍发布、把 8/12 当业务拒绝、硬编码接口长度/版本冒充契约、被调用者改写调用者私有
区域、状态泄露无法复现或无法修复、**漏检全局重复交易 ID 导致重复入账**。

## 分课动手与可复现故障（09.1–09.3）

- **09.1 CALL/LINKAGE/USING、BY REFERENCE/CONTENT/VALUE、RETURNING、GOBACK**
  - 动手修改：在 `ifaceprobe.COB` 把 `BYREF-SUB` 的调用改成 `BY CONTENT`，观察 `AFTER=` 值
    不再回写（对照 `BY REFERENCE`）；再把某个 `CALL ... USING ... RETURNING` 的 `RETURNING`
    去掉，观察主程序读不到返回码。
  - 可复现故障：把主程序里 `CALL 'BYCTR-SUB' USING BY CONTENT WS-A` 改成 `USING WS-A`
    （默认 `BY REFERENCE`），被调用者就能改写调用者的 `WS-A`，`BY-CONTENT AFTER` 会从
    `BBBBB` 变成 `CCCCC`——证明调用处的传参语义直接影响结果。
- **09.2 工作区生命周期、共通 Copybook、参数长度/版本/接口不匹配**
  - 动手修改：把 `INIT-ACC` 的 `IS INITIAL` 去掉，`INITIAL CALL2` 会从 `0001` 变成 `0002`；
    加回即恢复。
  - 可复现故障：`check_starter_and_faults` 自动把接口版本改成 `002`、或把 `LENGTH OF` 改成
    `1`，被调用者返回 RC8、主程序 RC8 且不发布；也可手动 `sed` 后重跑 `run.sh` 复现。
- **09.3 抽取金额计算/客户校验/日志，调用者与被调用者共同影响调查**
  - 动手修改：把 `AMTCALC` 里 `OVERDRAFT` 判定临时挪到主程序，观察 `fixtures/invalid/overdraft`
    的报告/RC 变化，再还原；体会“责任边界变更”如何改变 RC 与原因归属。
  - 可复现故障：版本不匹配时被调用者行为正确，根因却在调用者（发送了旧/新版本头）。调查要求
    同时查看 `AMTCALC.COB` 的接口校验与 `BATCH09.COB` 的 `MOVE ... TO AMT-IFACE-VERSION`，
    即“调用者与被调用者共同影响调查”。


```bash
lab=curriculum/modules/09-modular
bash "$lab/scripts/check.sh"                 # 全量验收（含失败注入与探针）
COURSE_SOURCE="$lab/starter/BATCH09.COB" bash "$lab/scripts/run.sh" \
  "$lab/fixtures/normal/customer.dat" "$lab/fixtures/normal/account.dat" \
  "$lab/fixtures/normal/transaction.dat" /tmp/bank09-starter 20261010   # 预期 RC12，无目录
cobc -Wall -I "$lab/copybooks" -x -o /tmp/ifaceprobe \
  "$lab/scripts/ifaceprobe.COB" "$lab/lib/AMTCALC.COB" && /tmp/ifaceprobe
```

讲师参考实现、根因表与评分在 `instructor/modules/09-modular/`。
