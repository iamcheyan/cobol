# 修正対象一覧

负责人角色：上游接口（外部）、批处理开发（本仓库）、DB 运维、下游消费方。

| # | 类别 | 对象 | 修正内容 | 负责人 | 回归证据 |
|---:|---|---|---|---|---|
| 1 | Copybook | `system/copybooks/CAP-CUSTOMER-FEED-V2.CPY` | 新增 32B 冻结接口 | 批处理开发 | 格式检查 |
| 2 | 程序 | `system/cobol/CUSTV2.COB` | 接受 31/32B；v1 升级为 v2；BADSTATUS/BADCLASS/BADVERSION 校验 | 批处理开发 | RED→GREEN |
| 3 | 程序 | `system/cobol/NIGHTRPT.COB` | declared layout 与物理宽度一致性校验 | 批处理开发 | layout guard |
| 4 | DB | `system/lib/capdb.py` | `customer.table` 存 32B；`read_customer_records` 接受 31/32B | DB 运维 | 快照/apply |
| 5 | File | `fixtures/extension/` | 新增 v2 合成日 | 批处理开发 | 四类日 |
| 6 | Shell | `system/jobs/job002-validate.sh` | 采用 CUSTV2 输出归一 v2 | 批处理开发 | JOB002d |
| 7 | JOB | `JOB002/JOB004/JOB007` | 说明随布局变化；无拓扑变化 | 批处理开发 | 全夜间流程 |
| 8 | 设计书 | `DESIGN.md`、本变更包 | 布局版本与迁移记录 | 批处理开发 | 文档评审 |
| 9 | 下游接口 | `customer-day.dat` | 区分字段固定为 2 位（v1 日升级 `A→A1`） | 下游消费方 | 兼容测试 |
| 10 | 上游接口 | `customer.extract` | 声明布局版本（001/002） | 上游 | MANIFEST |

不得修改：模块 01–11、canonical runner（SORT/L2/BANKVAL）、冻结的
ACCOUNT v1（47B）/TRANSACTION v1（55B）/CUSTOMER v1（27B，第 27 字节
= 记录状态）。
