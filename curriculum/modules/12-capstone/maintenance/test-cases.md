# Test Case（企业客户区分 1 位 → 2 位）

| # | 类别 | 输入 | 期望 |
|---:|---|---|---|
| T1 | 正常 v1 | `fixtures/normal`（31B 企业客户） | RC0，区分升级为 `A1` |
| T2 | 正常 v2 | `fixtures/extension`（32B 企业客户，含 `D1`） | RC0，`customer-day.dat` 含 `D1` |
| T3 | 正常（业务拒绝） | `fixtures/abnormal` | RC4，发布；控制总数守恒 |
| T4 | 边界 | 单客户 / 0 账户 | RC0，空客户日报合法 |
| T5 | 异常 | v1 声明但文件为 32B（或反之） | JOB002a RC8，无发布 |
| T6 | 异常 | v2 区分非法（如 `AX`） | JOB002d RC4，行进 reject（BADCLASS） |
| T7 | 跨版本 | 同一 v1 日新旧版本并行 | `customer-day.dat` 与控制总数一致 |
| T8 | 全流程 | 四类日（normal/abnormal/rerun/extension） | 各自 RC 与发布符合契约 |
| T9 | 恢复 | 五类崩溃边界 + 同日重跑 | 账本不重复、余额不变、CURRENT 正确 |
| T10 | 安全修改 | 恢复事故不得改原始输入 | 业务更正单独审计 |

RED→GREEN 证据由 `regression/red-green.sh` 生成：RED 用未完成的 v1-only
starter 对 v2 夹具，GREEN 用 `system/cobol/CUSTV2.COB`。
