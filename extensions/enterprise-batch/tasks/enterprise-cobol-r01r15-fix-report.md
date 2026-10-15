# R01–R15 返工报告（执行代理，待主代理独立复验）

日期：2026-10-10。依据：`tasks/enterprise-cobol-final-review-2026-10-10.md`。基线 HEAD `ad058c5`。
执行代理**不宣布验收**。工作树历史改动保留；未 `git add/commit/push/reset/clean/stash`。

## 复验总入口与独立入口（修复后实测）

| 命令 | 原始 RC | 说明 |
|---|---:|---|
| `bash curriculum/check.sh` | **0** | P1 + 12 模块 + 冻结接口宽度 + 课程结构 + R07 学生包回归 + 固定格式（156 源）全通过 |
| `bash curriculum/modules/08-database/scripts/check.sh` | **0** | 真实 Docker/PostgreSQL17/GixSQL 端到端 |
| `bash curriculum/validation/database/check.sh` | **0** | P1 真实 DB 回归 |
| `python3 curriculum/modules/07-matching/labs/05-large-record/scripts/pressure.py` | **0** | 修复后百万完整链路，status=pass |
| `bash curriculum/scripts/package-student.sh` + 隔离包端到端 | **0** | 见 R07 |

---

## R01（P1）真实 DB 与最终 JOB 贯通 — 已修（离线路线保留并标注）

- 新增 `curriculum/modules/10-jobs/scripts/{real-db.sh,check-real-db.sh,lib/realdb_seed.py}` 与
  `curriculum/modules/12-capstone/scripts/{real-db.sh,check-real-db.sh}`：Docker + PostgreSQL17 + GixSQL，复用模块 08 canonical ESQL 程序做 JOB004 游标抽取与 JOB006 单事务入账；独立 `psql` 核对余额/账本/commit；覆盖首次提交、提交结果未知重试（`ALREADY-APPLIED`，不重复入账）、并发重试、回滚原子性。
- 离线文件检查点仍为默认教学路线并标注 `real_db_verified=false`；环境缺失时 `check-real-db.sh` 返回 UNVERIFIED(2)，不冒充通过。
- 实测：模块10 `BALANCES=400,150,0` 账本4 commit1；模块12 `BALANCES=1450,100,300` 账本6 commit1。证据：`instructor/modules/{10-jobs,12-capstone}/evidence/REAL-DB-SUMMARY-*.txt`。
- 未验证：企业布局中超出 27B canonical 前缀的扩展由离线 `CUSTV2` 推导，未单独 ESQL 实现。

## R02（P1）余额与账本非原子 — 已修

- `10-jobs/lib/db.py`、`12-capstone/system/lib/capdb.py`：改为**先写账本（source of truth）再派生余额**（`derive_balances` 自愈），新增 `--inject ledger` 边界。
- 原反例（已存证）：ledger 写失败后余额前移、重跑 RC8 卡死 → 现在 ledger I/O 失败 **RC12 且余额不变**，恢复一次入账。
- 永久回归 `check_persistence_boundaries`。证据：`curriculum/modules/10-jobs/evidence/review-r02-r03/`。

## R03（P1）发布后失败删除正式结果 — 已修

- `10-jobs/scripts/run.sh`、`12-capstone/scripts/run.sh` + `lib/common.sh`：新增 `has_committed_or_published()`；仅删除真正未发布/未提交的暂存。JOB009 调整顺序使次日准备先于完成标记（可恢复）；新增 `registry|complete|nextday` 注入。
- 原反例：during-publish 后注册写失败 → 现在 **RC12 且保留已发布产物与 DB commit**，重跑 RC0/4 且账本不变（不重复扣款）。
- 永久回归 `check_publish_failure_preserved`。

## R04（P1）模块09 全局重复交易ID — 已修

- `09-modular/scripts/run.sh` 入账前用**有界外排**（`cut|sort|uniq -d`）拦全局重复，`oracle.py` 独立集合复核，新增同账户不同序号/跨账户夹具。
- 独立复现：第3条交易ID替换为第1条 → **RC8、不发布**，`FAIL: duplicate global transaction_id: TX00000000000001`。证据：`curriculum/modules/09-modular/evidence/REVIEW-R04-2026-10-10.md`。

## R05（P1）模块03/04 只改完成标志即可发布 — 已修

- 03/04 各新增 `scripts/verify.py` 独立语义核验（记录/解码值/符号/原始字节/记录数/布局），`run.sh` 发布前调用。
- 独立复现：把 `WS-EXERCISES-DONE` 改 `Y` → 现在 **RC8、不发布**（此前 RC0 发布 TODO/错误结果）。证据：`curriculum/modules/{03-bytes,04-structures}/evidence/REVIEW-R05-2026-10-10.md`。

## R06（P1）模块08 正确学生源码也失败 — 已修

- `08-database/scripts/run.sh`：移除“设 `COURSE_SOURCE` 即要求 RC12”；参考源与学员源走同一业务验证；负向 starter 检查分离。
- 独立复现 review 命令：`COURSE_SOURCE=.../instructor/.../SNAPSHOT.COB ... run.sh` → **RC0、正常发布**（此前 RC12）。未完成 `DBBATCH.COB` 仍 RC12 不发布。证据：`.../08-database/evidence/REVIEW-R06-2026-10-10.md`。

## R07（P1）学生包缺依赖 + 泄漏答案 — 已修（含 1 项残留交裁定）

- `package-student.sh`：按**角色 + 内容 sha256** 排除当前练习答案（改名/搬移不可绕过）；模块01/05/06 及后续全部模块 build/run/check 改为**模式感知**（有 `instructor/` 用参考，隔离包用学员 starter/`COURSE_SOURCE`）。
- 新增隔离包端到端回归 `curriculum/validation/student-bundle/check.py`（已接入总入口）：真实打包→解包→无 `instructor/` 路径→17 个答案内容不出现→11 模块 RED（starter 失败关闭）+ GREEN（学员完成源 build/run/check 全 0）。实测 **`PASS: student bundle runnable and answer-free (11 modules, 17 classified answers)`**。
- **残留（交主代理裁定）**：`instructor/modules/10-jobs/BANKVAL.COB`（模块10 JOB002 练习答案）被模块11 的既存系统逐字节 vendored（`curriculum/modules/11-incidents/system/cobol/M11VAL.COB` 及 7 个场景 `source/`）。隔离包回归已将其登记为仅允许出现在这些路径的 `VENDORED` 组件并打印 NOTE；跨模块“既存系统复用 vs 练习答案外泄”属设计冲突。建议二选一：将 BANKVAL 明确为 canonical 既有组件（模块10 练习改为编排/恢复），或给模块11 独立验证器。

## R08（P1）CUSTOMER/企业接口同名不同布局 — 已修

- CUSTOMER V1 恒 27B 且第 27 字节 = status（模块02 文字、DESIGN、错误布局实验改述已修）。
- 企业大记录名称去重：模块07 L4 canonical `ENTERPRISE-CUSTOMER-V1`（1778B/175字段）；模块11 改 `ENTERPRISE-CLASS-V1/V2`；模块12 改 `CAP-CUSTOMER-FEED-V1/V2`；模块04 经 `-I` 复用 07 L4 canonical。
- 新增**黄金字节校验**（偏移/PIC/语义）于模块12 `check.py::check_copybook_golden_bytes` 与 `grade.py::check_byte_layout`；模块11 `verify-layout.py` 用 GnuCOBOL `ADDRESS OF/LENGTH OF` 实测。

## R09（P1）B04 差异报告缺记录上下文 — 已修

- 报告改为 `FIELD,<run_id>,<layout_version>,<old_seq>,<new_seq>,<redacted_key>,<field_id>,<cobol_name>,<offset>,<length>,<rule>[,REDACTED]`，`AUDIT` 同构；同步 `instructor/.../BATCHL4.COB`、`verify.py`、DESIGN、expected（人工重算）。
- 独立断言（两客户同字段不同变化）证明每条差异唯一归属。证据：`.../05-large-record/evidence/B04-R09-R11-evidence-2026-10-10.md`。
- 待裁定：字段名用 catalog canonical `cobol_name`（业务名可经 CSV 解析）；若须内联业务名再改。

## R10（P1）B04 reset 不检查真实运行锁 — 已修

- reset 改用与 runner 相同的原子 `mkdir OUTPUT.lock` 并持锁删除（关闭 check-then-delete 竞争）；目录/文件/符号链接锁一律 **RC12 且不改动**。
- 独立复现：`output.lock` 存在 → 现在 **RC12、保留 output 与锁**（此前 RC0 删 output）。永久回归在 `check.py`。

## R11（P1）压力 RC0 不能证明通过、磁盘证据不足 — 已修

- `pressure.py`：`scenario` 断言 RC/发布/verifier/无泄漏锁，违约即非零并写 `evidence/B04-pressure-FAILURE.json`；显式 scratch 契约（root 按空间选择并记录，所有 TMPDIR 强制指向该 root）；10ms 采样磁盘高水位；新增 `space_exhaustion`（oracle 临时写 `RLIMIT_FSIZE` → RC12、不发布、无锁；真实 ENOSPC 无 root 无法构造，已标注）。
- 独立复跑：`pressure.py` 原始 **RC0**，status=pass；百万高差异 runner RC4/发布、core 5300KiB、verifier 20920KiB、报告 113MB、磁盘高水位 **3.79GB**；failure_boundary/space_exhaustion 均 RC12 无发布无锁。证据：`evidence/B04-pressure-author.json`。

## R12（P1）覆盖矩阵声称完成但无实验 — 已修

- 模块02：新增 `experiments/types/TYPESLAB.COB`（78/77/88/VALUE/01-05/`PIC A` vs `PIC X`）+ 夹具 + expected + `check.py` 断言。
- 模块05：新增 `scripts/control-flow-probe.COB`（PERFORM VARYING/内联 TIMES/段落作用域/THRU 跌落）并断言逐行输出。
- 模块06：新增 `scripts/indexed-hold-probe.COB`（两进程 `OPEN I-O` 争锁实测，证明句柄层无跨进程互斥）与 `scripts/sort-sd-probe.COB`（`SD`）；强化 JOB 锁断言。
- 模块11：`maintenance/README` 命令改 `python3`（原 `bash` 调用 RC2）；新增 11.2 记录错位实操 `INC-2026-007`；新增讲师 `COVERAGE.md` 逐条对应表。
- 各模块 README/DESIGN/evidence 更新；总入口通过。

## R13（P1）毕业评分把空文件当完成 — 已修

- `grade.py`：空/占位/仅标题文件 **0 分**；影响调查/修改边界/测试证据/事故恢复/组成清单列为**人工审核**项；G6 报 `PASS(substance)/PENDING(manual)` 且永不自动 PASS；PASS 需人工 `MANUAL-REVIEW-SIGNOFF`（明确仅覆盖参考、不代表学生通过）；无 signoff 返回 PENDING。
- 独立复现：8 个空维护文件 → maintenance 得分 **0**；占位内容同样 0（此前 20）。

## R14（P2）事故材料泄露根因 — 已修

- 学生事件目录/夹具改为中性 `INC-2026-001…007`；根因/分级提示集中在讲师 `INSTRUCTOR.md`（含映射表）；学生 README/DESIGN 只留症状与时间线；脚本/证据引用同步；调查所需源文件与业务证据保留。

## R15（P2）系统组成清单 — 已修

- 新增 `curriculum/modules/12-capstone/COMPOSITION.md`：按唯一路径去重的组成清单与 JOB/程序/COPY/表使用关系与统计方法；`grade.py` 要求其存在。
该清单按实际调用关系区分运行依赖与参考材料。

---

## 未完成 / 阻塞 / 交主代理裁定

1. **R07 残留**：模块10 练习答案 BANKVAL 被模块11 既存系统逐字节 vendored（见 R07）。隔离包回归仅允许其在既定路径出现，其余位置失败并打印 NOTE。
2. **R01 范围**：真实 DB 已接入 JOB004/JOB006；模块07 L3 的真实 DB 抽取属模块07 归属，未在本次范围。
3. **R09 待裁定**：字段名用 catalog `cobol_name` 而非内联业务名。
4. **平台**：仅 Linux x86-64 + GnuCOBOL 3.2.0；真实磁盘 ENOSPC（无 root）用 `RLIMIT_FSIZE` 代表；macOS/WSL/ARM 未验证。
5. 未 `git add/commit/push`；工作树历史改动保留。
