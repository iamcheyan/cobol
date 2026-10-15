# 模块 12 系统组成清单与依赖追踪（R15）

本文件说明陌生版本系统的组成及各组件在毕业运行中的角色。组件按唯一路径去重，
并用 `system/lib/common.sh` 与 `system/jobs/*.sh` 的实际调用关系标注角色。

分类口径（互斥，按优先级）：

1. **实际运行依赖（run）**：capstone 夜间链实际调用并产生毕业产物的组件。
2. **维护调查依赖（maint）**：毕业维护任务必须先调查、后修改的既存组件（可能运行，
   也可能仅被读取以完成影響調査）。
3. **独立教学参考（ref）**：随课程提供、供阅读/对照的 canonical 实现，**不**被
   capstone 编排直接调用。
4. **starter**：学员起点，刻意不完整。
5. **生成文件（generated）**：由脚本/工具生成的派生文件，作为生成产物单独标识。



## 1. 实际运行依赖（capstone 夜间链调用）

| 组件 | 路径 | 角色 |
|---|---|---|
| CUSTV2 | 学员 `starter/CUSTV2.COB`（或 `CAPSTONE_STUDENT_CUSTV2`）；参考 `system/cobol/CUSTV2.COB`（讲师仓） | JOB002d 客户归一化 v1/v2 |
| NIGHTRPT | `system/cobol/NIGHTRPT.COB` | JOB007d 客户日报 |
| BANKVAL | 学员模块 10 `starter/BANKVAL.COB`（或 `CAPSTONE_STUDENT_BANKVAL`）；参考 `instructor/modules/10-jobs/BANKVAL.COB` | JOB002c 业务校验 |
| SORTTX | `instructor/modules/07/02-sort-merge/SORTTX.COB` | JOB003b 排序（经其 runner） |
| BATCHL2 | `instructor/modules/07/03-one-to-many/BATCHL2.COB` | JOB005a 1:N 突合（经其 runner） |

其它运行时组件（非 COBOL）：`system/lib/capdb.py`（12 逻辑表离线检查点）、
`system/lib/report.py`（守恒/日报核对）、`system/lib/validate.py`（原始字节结构）、
`system/lib/ordercheck.py`，以及模块 10 的 `lib/db.py`/`lib/manifest.py`/
`lib/verify_publish.py`（被复用，不复制）。

| 类别 | 数量 | 说明 |
|---|---:|---|
| capstone Copybook | 23 | `system/copybooks/` |
| capstone Shell | 17 | 9 个 job + nightly + common + build/run/check/reset + red-green + reproduce |
| JOB 节点 | 32 | 9 JOB 展开 |
| 逻辑表 | 12 | `capdb.py` 头注释 |

## 2. JOB / 程序 / COPY / 表 使用关系

| JOB | 节点动作 | 程序/工具 | COPY | 逻辑表 |
|---|---|---|---|---|
| 001 | 接收+校验 SHA256+冻结 | shell + MANIFEST-RECORD | MANIFEST-RECORD | batch_run |
| 002 | 宽度/数字/业务/客户 | validate.py + BANKVAL + CUSTV2 | TRANSACTION-V1, CUSTOMER-V1, CUSTV2-CONTROL | reject_log |
| 003 | 排序+有序/重复键 | SORTTX（07 runner）+ ordercheck.py | TRANSACTION-V1 | — |
| 004 | DB 快照 | capdb.py | DB-CUSTOMER-SNAPSHOT-ROW, DB-ACCOUNT-SNAPSHOT-ROW | customer, account, customer_snapshot, account_snapshot |
| 005 | 1:N 突合+候选 | BATCHL2（07 runner） | TRANSACTION-V1, ACCOUNT-V1 | — |
| 006 | 幂等入账+commit | capdb.py | DB-LEDGER-ROW, DB-IDEMPOTENCY-KEY-ROW, DB-BATCH-COMMIT-ROW | transaction_ledger, idempotency_key, batch_commit |
| 007 | 守恒/日报核对 | report.py + NIGHTRPT | NIGHTRPT-CONTROL, CONTROL-TOTAL-ROW | control_total, reject_log |
| 008 | 暂存+Manifest+发布 | manifest.py + verify_publish.py | MANIFEST-RECORD | publish_registry |
| 009 | 确认+完成+次日 | shell | — | batch_run, business_calendar |

## 3. 维护调查依赖 / 独立教学参考 / starter

- **维护调查依赖（maint）**：`system/` 被编排组件 + `maintenance/copybooks/`
  的目标接口。学员须先读 `maintenance/impact-investigation.md` 追踪其依赖。
- **独立教学参考（ref）**：`instructor/` 下 23 个 canonical `.COB`
  中，除上表 3 个被 capstone 调用外，其余（模块 01–06、08–12 的参考实现、
  FILEVAL/MATCH/MERGETX/BATCHL3/BATCHL4、模块 08 ESQL 等）**不被本模块编排**，
  只作可读参考。
- **starter**：`starter/CUSTV2.COB`（未完成，v2 feed 返回 RC12 不发布）。
- **生成文件**：`fixtures/` 种子、`expected/*`（由独立 oracle 生成）、
  `__pycache__/` 等，不计入手写实现规模。

## 4. 组件依赖说明

毕业项目的组成以实际调用关系为准。上表列出运行链依赖；本模块只读复用的参考实现、
starter 和生成文件按前文分类，学员可通过 JOB / 程序 / COPY / 表关系追踪各组件职责。
