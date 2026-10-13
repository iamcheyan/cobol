# Review 修复证据：R01 / R02 / R08 / R13 / R15（模块 12）

日期：2026-10-10。审查依据：`tasks/enterprise-cobol-final-review-2026-10-10.md`。

## R01 · 真实 DB 贯通（已修，本机已实跑）

`scripts/real-db.sh` 复用 canonical 模块 10 harness（Docker + PostgreSQL17 +
GixSQL + 模块 08 ESQL）：JOB004 真实游标抽取（capstone 31B CAP-CUSTOMER-FEED 的
27B canonical 前缀），JOB006 用 `APPLY.COB` 在**同一事务**提交余额 + 幂等账本 +
`batch_commit`，独立 psql 核对。永久回归 `scripts/check-real-db.sh`（不可用报
UNVERIFIED）。

**实测（原始 RC）**：模块 12 `bash scripts/check-real-db.sh` → RC0；
`real-db-summary.txt`：`BALANCES_FIRST=1450,100,300`（与审查 R02 反例中的 1450
一致）、`BALANCES_RETRY=1450,100,300`、`LEDGER_CONCURRENT=6`、
`COMMIT_CONCURRENT=1`。重试输出 `ALREADY-APPLIED=…`，并发一份 `COMMITTED=YES`
另一份 `ALREADY-APPLIED`/`DAY-ALREADY-COMMITTED`，无重复入账。

## R02 · 余额与账本同事务 / 重跑安全（已修）

位置：`system/lib/capdb.py` 的 `cmd_apply`。修复为 write-ahead：账本先写，
余额由「冻结期初快照 + 账本」推导/自愈（`derive_balances`）；新增 `--inject ledger`
边界（`mid-db-commit` 映射）。永久回归
`scripts/check.py::check_persistence_boundaries`：逐个边界崩溃后重跑一次，
账本 6 行、余额 == 候选、二次重跑不增；账本写 I/O 失败不改变余额。
真实 DB 侧由 R01 的 `APPLY.COB` 以单事务保证。

## R08 · ENTERPRISE-CUSTOMER 同名不同布局（已修）

模块 12 的小型企业客户 feed 重命名为 **`CAP-CUSTOMER-FEED`**
（`CAP-CUSTOMER-FEED-V1.CPY` 31B / `-V2.CPY` 32B），不再与模块 04/07 的
canonical 1778B、175 字段 `ENTERPRISE-CUSTOMER`、模块 11 实验布局同名；头注释、
README、DESIGN、维护文档均说明三者关系（不同粒度视图，非同一物理接口）。
canonical `CUSTOMER-V1.CPY` 仍为 27B，**第 27 字节 = 记录状态 A/D**。

新增**黄金字节验证**（`scripts/check.py::check_copybook_golden_bytes` 与
`grade.py::check_byte_layout`）：解析 copybook 的 PIC 声明，断言
CUSTOMER-V1=27、CAP-CUSTOMER-FEED-V1=31、V2=32、ACCOUNT=47、TRANSACTION=55 的
**字段偏移与长度**（如 `EC2-RECORD-STATUS` 在偏移 26、`EC2-CUSTOMER-CLASSIFICATION`
在 27 长度 2），并断言扩展日 feed 第 27 字节是 A/D、区分在 28–29。

## R13 · 毕业评分把空文件当完成（已修）

`grade.py` 重写：空文件/未填模板（仅标题或 TODO 占位）一律不得分，且列入
`empty/unfilled` → 判 FAIL；影响调查、修改边界、测试证据、事故恢复与组成清单列为
**人工审核项**，脚本只能确认“存在且实质”，报
`PASS(substance)/PENDING(manual)`，**不得自动 PASS**；G6（先调查后修改）同样如此。
只有人类审核签署 (`MANUAL-REVIEW-SIGNOFF`，含 G6 与各交付物) 才把结果转 PASS，
且签署文件明确“只覆盖参考答案，不转移给学员提交”。

永久回归：`scripts/check.py::check_grader_rejects_empty`（直接导入 grader：
8 个空文件得 0 分且被标 unfilled；仅标题/TODO 的 COMPOSITION 与 signoff 不被接受）。

## R15 · 规模统计不能等同复杂度（已修）

新增 `COMPOSITION.md`：按唯一路径去重的系统组成清单、JOB/程序/COPY/表使用关系、
统计方法与**如实差距**。结论：实际运行 COBOL（去重）5 个 / 1,640 行，相对
`AUTHORING-STANDARD §6` 的约 8,000 行目标差距约 **-6,360 行**（Copybook 23 /
Shell 17 / JOB 节点 32 / 逻辑表 12 达标）。旧报告“约 9,970 行”把未接入编排的
canonical 参考与 71 行 starter 计入，属口径放大。README「规模」节与
`grade.py`（要求 `COMPOSITION.md` 实质存在）已同步。
