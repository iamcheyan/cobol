# 修正対象一覧（企业客户区分 1 位 → 2 位）

| # | 类别 | 对象 | 修改内容 | 风险 | 负责人角色 |
|---|---|---|---|---|---|
| C1 | Copybook | `maintenance/copybooks/ENTERPRISE-CLASS-V2.CPY`（新增） | 23B→24B，`X(1)`→`X(2)`，版本 `001`→`002` | 后续字段偏移/总长变化 | 数据架构 |
| C2 | Copybook | `maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY` | **不改**（保留 v1 基线） | 误改会破坏兼容 | 数据架构 |
| C3 | 程序 | 企业区分读取程序（参考 `M11CUST2.COB`） | 读 24B/版本 `002`，取 `(23:2)` | 宽度/版本校验遗漏会静默截断 | 应用开发 |
| C4 | 程序 | `starter/M11CUST2.COB` | 学员完成的骨架 | — | 应用开发 |
| C5 | 迁移工具 | `migrate-customer.py` | enterprise v1↔v2 转换、回滚、并行验证 | 映射/版本错误 | 数据运维 |
| C6 | 文件（输入） | `fixtures/enterprise-customer/customer.v1` | 迁移出新 V2 文件；保留 V1 | 原地改写会丢原件 | 数据运维 |
| C7 | 文件（输出） | 企业区分抽取 `CLASS\|<id>\|<class>` | 行格式 1→2 字符 | 下游解析失败 | 接口方 |
| C8 | DB（离线） | 若缓存企业布局的检查点宽度 | 23→24（离线） | 真实 DB 列宽未验证 | DB/DBA |
| C9 | DB（真实，未验证） | 企业客户分类列 | 加宽/迁移 | **未验证** | DBA |
| C10 | 设计书 | `docs/curriculum/BANK-SYSTEM.md` | 记录演进与迁移 | 漏记导致契约漂移 | 文档 |
| C11 | 下游接口 | 消费 `CLASS\|<id>\|<class>` 的系统 | 版本协商与解析更新 | 未确认消费方 | 接口方 |
| C12 | 全流程 | 维护 harness 端到端 | 正常/异常/跨版本/回滚回归 | 遗漏边界 | QA |
| C13 | **不受影响** | canonical CUSTOMER v1（27B，状态字节）、夜间流 `M11CUST.COB`/`customer-status.txt` | **保持不变** | 误改会破坏冻结契约 | 数据架构 |

未能确认真实 DB 与外部消费方者，登记为**未验证项**，切换前必须由对应
负责人书面确认。**任何情况下都不得**把企业区分寄生到 CUSTOMER v1 第 27
字节（那是记录状态，见 C13）。
