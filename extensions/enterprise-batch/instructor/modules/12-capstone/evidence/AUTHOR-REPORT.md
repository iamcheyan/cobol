# 模块 12 作者验收报告（执行代理）

日期：2026-10-10　平台：Linux x86-64　`cobc` GnuCOBOL 3.2.0　Python 3.13.5
git HEAD：ad058c5334d08d4f426f7a378ef567ad3f0cd2e9

> 本报告在 **CUSTOMER 状态 / 企业区分契约纠错** 之后重跑（见
> `CONTRACT-FIX-2026-10-10.md`）：canonical CUSTOMER v1 第 27 字节恢复为
> **记录状态 status**（A/D），"客户区分 1→2 位"维护改为作用于**独立、版本化的
> CAP-CUSTOMER-FEED 布局**（31B→32B，`CUSTOMER-CLASSIFICATION` A/B/C/D→A1..D1，
> 布局版本 001→002）。

## 1. 系统组成（R15 修订）

> 修订（R15）：旧表把**未被本模块编排**的 canonical 参考程序与未完成 starter
> 毕业系统组件按实际角色区分；运行依赖和独立参考实现见
> `curriculum/modules/12-capstone/COMPOSITION.md`。

| 类别 | 数量 | 说明 |
|---|---:|---:|---|
| Copybook | 23 | `system/copybooks/*.CPY` |
| Shell | 17 | 9 个 job + nightly + common + build/run/check/reset + red-green + reproduce |
| JOB 节点 | 32 | 9 个 JOB 展开 |
| 逻辑表 | 12 | `capdb.py` 定义 |

毕业项目复用 canonical 系统；运行依赖与独立参考实现已在组成清单中区分。

## 2. 真实命令与原始 RC

见同目录：`ACCEPTANCE.md`、`CONTRACT-FIX-2026-10-10.md`、`DAYS-AND-RERUN.md`、
`RECOVERY.md`、`RED-GREEN.md`、`INCIDENT-01.md`、`INCIDENT-01-RECOVERY.md`、
`GRADE.txt`。摘要：

| 命令 | 原始 RC |
|---|---:|
| `scripts/check.sh` | 0 |
| `grade.py` | 0（100/100，硬门禁全 PASS） |
| normal（v1） | 0，发布；customer-day `A1` |
| abnormal（v1） | 4，发布 |
| extension（v2） | 0，发布；customer-day 含 `D1` |
| broken（重复键） | 8，不发布 |
| rerun（同 DB 同 feed） | 0，`new_transactions=0`，账本 6 行不变 |
| crash-at ×5 | 崩溃 97 → 恢复 0，账本 6，CURRENT 正确 |
| RED→GREEN | RED=12（不发布），GREEN=0 |
| incident reproduce | 8，不发布 |
| incident recovery（业务更正重跑） | 0，账本 6，合计 1850，原输入未改 |

## 3. 限制 / 未验证

- DB 层为离线文件检查点；**真实 PostgreSQL/Embedded-SQL 未接入、未验证**。
- 平台仅 Linux x86-64 实测；macOS/WSL/其他架构**未验证**。
- JCL/JP1 仅阅读映射，未在任何调度器提交。
- 结业现场"未知事故"需讲师另备，本模块只交付 incident-01。
- `grade.py` 对参考实现给满分；对学员提交按同一命令评分，未做模糊/人工项。

## 4. 未解决项

- 模块 11（incidents）由并行代理生成，未纳入本模块声明；本次纠错**不改**
  模块 11（超出本任务边界）。
- 未做时间/RSS 压力档位（BANK-SYSTEM §9 的中型/压力），本模块用微型夹具。
