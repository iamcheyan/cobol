# 预期结果与独立核算

本目录的 expected **先由业务规则独立计算**，再运行参考实现验证；不是把
程序输出保存成 expected（AUTHORING-STANDARD 第 4 节）。

- 生成器：`instructor/modules/12-capstone/tools/gen_course.py`。它**独立
  重实现** BANKVAL 业务规则与模块 07 L2 的 1:N 透支规则，从不读取任何
  课程实现输出，也不 import 模块 10 的生成器。
- 固定、确定性数据（FR-10），营业日 20261010。

| 文件 | 含义 |
|---|---|
| `<case>.control.txt` | 笔数/金额守恒指标（`k=v`） |
| `<case>.closing.txt` | `account_id=±13位期末余额` |
| `<case>.customerday.txt` | `customer_id|区分|账户数|±13位客户合计` |
| `<case>.rc` | 该日类型期望的进程 RC |

## 独立核算过程

- **接受/拒绝**：方向非 C/D→BADDIR；status≠N→BADSTATUS；营业日不符
  →BADDATE；金额为 0→BADZERO。
- **余额**：按 `(account_id, sequence_no, transaction_id)` 排序逐笔应用；
  出账若使余额 <0 则该笔拒绝（OVERDRAFT），不进金额累计。
- **守恒**：`期初 + 贷记 − 借记 = 期末`（逐账户与合计）。
- **客户日报**：按 customer_id 归集账户数与期末合计；企业 v1 的
  A/B/C/D 区分升级为 `<code>1`（A1..D1）。

## 日类型期望

| case | RC | 要点 |
|---|---:|---|
| normal | 0 | 6 笔全部入账 |
| abnormal | 4 | 4 笔校验拒绝 + 1 笔透支拒绝 |
| rerun | 0 | 与 normal 同 feed，第二次入账 0 笔 |
| extension | 0 | v2 区分，含 `D1` 客户 |
| broken | 8 | 重复 transaction_id，不发布 |
