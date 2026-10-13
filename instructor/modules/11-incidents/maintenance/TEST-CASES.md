# Test Case（企业客户区分 1 位 → 2 位）

参考实现：`instructor/modules/11-incidents/maintenance/M11CUST2.COB`（企业
v2 抽取）、`migrate-customer.py`（迁移/回滚/并行验证）。自检脚本：
`instructor/modules/11-incidents/maintenance/check.sh`。

| ID | 类别 | 输入 | 期望 | 证据位置 |
|---|---|---|---|---|
| T1 | 正常 | 企业 V2 文件（A1/B1） | RC0；抽取 `CLASS|00000001|A1`、`CLASS|00000002|B1` | `expected/enterprise-class-v2.txt`；`check.sh` 步骤 3 |
| T2 | 边界 | 单条企业 V2 | RC0；1 行抽取；报表 TOTAL=1 | check.sh 步骤 9 |
| T3 | 边界 | 空企业 V2 文件 | RC0；0 行 | check.sh 步骤 8 |
| T4 | 异常 | 企业 V1（23B）喂给 v2 抽取 | **RC8**；报宽度/版本不符 | `check.sh` 步骤 7 |
| T5 | 异常 | 合法 V1 但分类字符非法（如 `Z`）迁移 | **RC8**（不猜测映射） | `check.sh` 步骤 10 |
| T6 | 跨版本 | canonical CUSTOMER v1（27B）状态抽取不回退 | RC0；与 `customer-v1.txt` 一致 | `check.sh` 步骤 4 |
| T7 | 跨版本 | 企业 V2 → V1 回滚 | 字节级等于原始 V1 | `check.sh` 步骤 6 |
| T8 | 并行 | `verify v1 v2` | RC0（head 相同、版本 001/002、分类满足映射） | `check.sh` 步骤 5 |
| T9 | 异常 | 企业 V1 但版本错（`003`）迁移 | **RC8** | `check.sh` 步骤 11 |
| T10 | 异常 | canonical CUSTOMER v1（27B）喂给企业 v2 抽取 | **RC8** | `check.sh` 步骤 7b |
| T11 | 恢复 | 迁移中断/回滚后重跑 | 新 run_id 重跑一致；无重复应用 | 参照模块 10 崩溃边界方法 |

## 与冻结契约的关系

- **企业布局** V1（23B）保留、V2（24B）新增。T4/T10 证明 v2 程序拒绝 v1
  与企业外记录，T6 证明 canonical CUSTOMER v1 状态抽取未受影响。
- **canonical CUSTOMER v1**（27B，第 27 字节 = 记录状态）不受本变更影响；
  T6 是回归门禁：区分维护禁止寄生到该字节。
- T8 的并行验证是切换门禁：不一致即不得切换。

## 未验证

- 真实 DB 迁移、外部消费方解析**未验证**；涉及真实 DB 的部分以离线检查点
  替代，须标注“未验证”。
