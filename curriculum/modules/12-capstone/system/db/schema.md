# Capstone DB schema: 12 logical tables

物理实现见 `system/lib/capdb.py`。DB 层是**离线文件检查点**，不是真实数据库
（真实 PostgreSQL/Embedded-SQL 未接入、未验证）。

| # | 逻辑表 | 物理存储 | 主键/唯一键 | 说明 |
|---:|---|---|---|---|
| 1 | customer | `customer.table` | customer_id | CAP-CUSTOMER-FEED v2，32B（31B v1 自动升级） |
| 2 | account | `account.table` | account_id | ACCOUNT v1，47B |
| 3 | transaction_ledger | `ledger.dat`（值列） | (business_date, transaction_id) | 已入账交易 |
| 4 | batch_run | `run/<date>.table` | (date, run_id, phase) | JOB 运行记录 |
| 5 | batch_commit | `commit/<date>.json` | business_date | 提交标识与账本哈希 |
| 6 | customer_snapshot | `snapshots/<date>/customer_snapshot.dat` | customer_id | 当日冻结视图 |
| 7 | account_snapshot | `snapshots/<date>/account_master.dat` | account_id | 当日冻结视图 |
| 8 | reject_log | `reject_log.dat` | (date, stage, key) | 校验/突合拒绝 |
| 9 | control_total | `control_total.dat` | (date, run_id) | 守恒证据 |
| 10 | publish_registry | `publish_registry.dat` | (date, run_id) | 发布登记 |
| 11 | idempotency_key | `ledger.dat`（键列） | (business_date, transaction_id) | 幂等键 |
| 12 | business_calendar | `business_calendar.dat` | date | 营业日历 |

事务边界：`capdb.py apply` 在单进程内先写余额与账本（`fsync` + `rename`），再
写 commit 标记；崩溃通过“先读账本/提交标识”判断，绝不凭日志最后一行推断。
