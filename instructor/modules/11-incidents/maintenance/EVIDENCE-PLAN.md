# Evidence 计划（维护 11.5，企业客户布局）

| 测试 | 期望 | 证据位置 | 状态 |
|---|---|---|---|
| T1 正常 V2 抽取 | RC0；`CLASS\|id\|A1/B1` | `expected/enterprise-class-v2.txt`；`maintenance/check.sh` 输出 → `evidence/A03` | 已执行 |
| T1b V1 基线抽取 | `CLASS\|id\|A/B` | check.sh 步骤 3b；`expected/enterprise-class-v1.txt` | 已执行 |
| T2 单条 V2 | RC0；1 行 | check.sh 步骤 9 | 已执行 |
| T3 空 V2 | RC0；0 行 | check.sh 步骤 8 | 已执行 |
| T4 企业 V1 喂给 V2 程序 | RC8 | check.sh 步骤 7 | 已执行 |
| T5 非法 v1 分类（`Z`）迁移 | RC8 | check.sh 步骤 10 | 已执行 |
| T6 CUSTOMER v1 状态抽取不回退 | RC0；与 `customer-v1.txt` 一致 | check.sh 步骤 4 | 已执行 |
| T7 企业 V2→V1 回滚 | 字节等于原始 V1 | check.sh 步骤 6 | 已执行 |
| T8 并行验证 | RC0 | check.sh 步骤 5 | 已执行 |
| T9 错误版本（`003`）迁移 | RC8 | check.sh 步骤 11 | 已执行 |
| T10 CUSTOMER v1（27B）喂 V2 程序 | RC8 | check.sh 步骤 7b | 已执行 |
| T11 恢复/重跑 | 新 run_id 一致、无重复应用 | 参照模块 10 崩溃边界方法 | **未在本 harness 执行** |

## 证据清单（切换门禁）

- 修改前后布局：`INFLUENCE-INVESTIGATION.md` 第 1 节 + `LAYOUT-V1-V2.md`。
- 生成文件：企业 V1/V2 客户文件、抽取（`expected/enterprise-class-v1.txt`、
  `enterprise-class-v2.txt`；canonical 回归 `expected/customer-v1.txt`）。
- DB 结果：离线检查点；真实 DB **未验证**。
- 上下游测试：T4/T10（跨版本/隔离）、T6（canonical 回归）、T8（并行）；
  外部消费方**未验证**。
- 回滚证据：T7 字节级还原（`check.sh` 步骤 6）。
- RED→GREEN：见模块 `evidence/A02`（事故修复）；维护侧无 RED 需求。

## 未验证与限制

- 真实 PostgreSQL/DB2 列迁移、外部消费方解析、非 Linux 平台：**未验证**。
- T11 未在本维护 harness 内执行，执行方法已在 `TEST-CASES.md` 给出。
