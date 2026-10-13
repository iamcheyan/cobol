# 讲师参考与事故说明 — 模块 11

学员包只含任务、可用资料与逐层提示。本文件索引参考位置、根因、RED→GREEN
与评分点。公开仓库无法保密答案；自学者须知答案位于此处。

> **中性事件 ID**：学员侧目录/README 已改为中性事件 ID `INC-2026-001`…
> `INC-2026-007`，只给症状与时间线，不披露根因（2026-10-10 由
> `inc-0X-<root-cause>` 形式改名）。事件 ID ↔ 讲师编号映射见 §2。

## 1. 参考位置

| 组件 | 学员侧 | 讲师侧 |
|---|---|---|
| 冻结系统快照 | `curriculum/modules/11-incidents/system/` | 同（canonical 副本源自模块 10） |
| 事件复现 | `INC-2026-00X/student/run.sh` | 现场由 `tools/capture-scenes.sh` 采录 |
| 事件根因 | `INC-2026-00X/student/{README,hints}.md`（不含根因） | `inc-0X/ROOT-CAUSE.md` |
| 事件 ID ↔ 讲师编号 | `INC-2026-001`…`007` | `inc-01`…`inc-07`（见 §2） |
| inc-02 修复 | — | `inc-02/fix/db.py` |
| inc-06 修复 | — | `inc-06/fix/control.py` |
| RED→GREEN | — | `tools/red-green.sh` |
| 夹具/预期生成 | — | `tools/gen_course.py` |
| 维护 11.5 调查 | `maintenance/README.md` | `maintenance/{INFLUENCE-INVESTIGATION,CHANGE-LIST,CHANGE-PLAN,TEST-CASES,EVIDENCE-PLAN}.md` |
| 维护企业布局基线 | `maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY` | 同 + 目标 `ENTERPRISE-CLASS-V2.CPY` |
| 布局偏移/PIC/黄金字节校验 | — | `maintenance/verify-layout.py`（由 `check.sh` 调用） |
| 维护参考实现 | `starter/M11CUST2.COB` | `maintenance/M11CUST2.COB`、`migrate-customer.py`、`check.sh` |
| 大纲 11.1–11.5 覆盖矩阵 | — | `COVERAGE.md`（源码/输入/学生操作/expected/check/证据） |

> 维护变更 11.5 作用于**独立、版本化的企业客户布局** `ENTERPRISE-CLASS`
> （`curriculum/modules/11-incidents/maintenance/copybooks/`），**不是** 27
> 字节 canonical CUSTOMER v1 的第 27 字节（那是记录状态 A/D）。课程
> canonical 的大记录是模块 07 L4 的 `ENTERPRISE-CUSTOMER-V1`（175 字段 /
> 1778 字节）；本练习刻意改用独立名称 `ENTERPRISE-CLASS`，避免同名却布局
> 不同的版本漂移。企业区分与记录状态必须始终分开；`check.sh` 与
> `verify-layout.py` 以回归保护该边界。

## 2. 事件 ID ↔ 讲师编号 ↔ 根因速查（教师/按需）

| 事件 ID | 讲师编号 | 根因 | 最小修复 | 恢复 |
|---|---|---|---|---|
| INC-2026-001 | inc-01 | 源数据账户号含非数字 → 结构错误 RC8 | 修正源数据（不改程序） | 新 run_id 重跑 |
| INC-2026-002 | inc-02 | `db.py` 未落实 `UNIQUE(date, txid)`（dict 覆盖 + 批内未去重） | 批内 `seen` 去重 → RC8 | 先查账本；已发布则业务更正运行 |
| INC-2026-003 | inc-03 | 传输截断为 0 字节，校验和不符 | 重传（无代码缺陷） | 校验通过后新 run_id 重跑 |
| INC-2026-004 | inc-04 | 账户 Seed 逆序 + 快照边界未校验顺序 | 抽取端排序 + 边界前置有序性校验 | 从快照边界重建 |
| INC-2026-005 | inc-05 | `mktemp` 失败（临时空间/权限） | 修环境；可选前置资源检查 | 新 run_id 重跑 |
| INC-2026-006 | inc-06 | JOB007 只做内部守恒，未与上游声明 `control_*` 对账 | 增加声明控制总数对账 → RC8 | 数据更正运行（新业务版本） |
| INC-2026-007 | inc-07 | 交付记录长度不符（54≠55）/字段错位 → 结构错误 RC8 | 修正源数据长度（**不**放宽长度检查） | 新 run_id 重跑 |

严重度排序（对教学）：INC-2026-002、INC-2026-006 是**静默错误（RC0 却错）**，
最危险；INC-2026-001/003/004/005/007 是“失败即停、不发布”，相对安全。

## 3. RED→GREEN（要求至少一个）

`tools/red-green.sh` 提供两个：

- **inc-02**：RED 账本 4 行含 **2 行同键**、acc1=2000、RC0 且发布；
  GREEN 应用 `inc-02/fix/db.py` 后 **RC8、不发布**、`account.table` 未被
  部分修改。
- **inc-06**：RED 以 RC0 发布 `closing_total=1025`（声明应为 1475）；
  GREEN 应用 `inc-06/fix/control.py` 后 **RC8、不发布**。

原始输出见 `evidence/A02-red-green-2026-10-10.txt`。

## 4. 评分点与误区

**评分点**：原始 RC 与现场（是否发布）判断正确；用源码/数据/日志证据定位
根因（非只贴日志）；区分 RC8/RC12 与“结构错误 vs 业务拒绝”；修复不改坏
数据、不放宽断言；恢复边界清晰；INC-2026-002/006 说明“内部自洽 ≠ 业务正确”。

**误区（误导线索设置）**：把 RC0 当业务正确；把系统失败写成业务拒绝；
用删除完成标记或 `sleep` “修复”重跑；声称真实 DB 已验证；维护未先调查
即改 PIC；原地改写 v1 文件。

## 5. DB 真实性（必须如实标注）

模块 11 **未接入真实 PostgreSQL/DB2**；`system/lib/db.py` 是离线文件
检查点，`INC-2026-002/student/scene/db-schema.sql` 只是**契约文档**。任何
“真实 DB 已执行”的结论按未通过处理。`manifest.json` 与完成标记均写
`real_db_verified: false`。

## 6. 作者证据

`evidence/` 下：`A01`（六事件真实复现与原始 RC）、`A02`（RED→GREEN）、
`A03`（维护 11.5）、`A04`（模块 `check.sh`）、`A05`（R08/R12/R14 反例）、
`A06`（修复后重跑）。全部为 Linux x86-64 实测；未验证平台/真实 DB 已在
各文件顶部标注。
