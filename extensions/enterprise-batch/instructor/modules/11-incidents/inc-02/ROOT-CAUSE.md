# inc-02 讲师根因（DB 唯一约束未落实 → RC0 但余额错误）

## 触发条件
同一批次 `input/transaction.dat` 内出现两条相同业务键
`(business_date, transaction_id) = (20261009, A000000000000001)`（重送/重复
投递）。两条结构均合法，JOB002 不会拒绝。

## 根因
上游 DDL（`scene/db-schema.sql`）声明
`UNIQUE(business_date, transaction_id)`，但入账路径 `lib/db.py` 的
`cmd_apply` **没有落实该约束**：

- `ledger_index()` 用 dict 装载账本，重复键被后者覆盖；
- 批内也**没有去重**，两条相同键都被写入 `new_rows` 并各自入账。

结果：`ledger.dat` 出现两行同键，账户 `0000000001` 被重复贷记，
余额 2000 ≠ 期望 1500；`control.py` 的所有数字都取自同一份“已接受集合”，
**内部自洽**，因此 JOB007 PASS 并以 RC0 发布。

## 逐层提示阶梯（对应 student/hints.md）
1. 独立重算 6 个余额，确认仅账户 1 差 500。
2. 列出该账户输入交易，发现同键两条。
3. 对照 `db-schema.sql` 的 `ux_ledger_key` 与 `ledger-victim.dat`：键出现
   两次；`db.py` 入账前只做“键是否已存在”的跳过，未做批内唯一性判定。
4. `control.py` 的输入全部来自已接受的错误集合 → 内部一致无法发现。
5. 修复落在入账前唯一性判定；恢复须先查账本，必要时走业务更正运行。

## 误导线索
- “账本和余额一致，所以是对的”：账本本身已被写错。
- “JOB002 会拒绝重复交易”：校验器逐条校验，不做跨记录去重。
- “重跑一次就好”：同键已在账本，重跑 `status` 会跳过，余额不会回退。

## 证据
- `scene/ledger-victim.dat`：两行同键。
- `scene/db-account.table` / `scene/published-closing-master.dat`：
  `0000000001` 期末 2000（期望 1500）。
- `scene/published-control-report.txt`：`closing_total=2175`。
- `scene/logs/JOB006.log`、`scene/sql-log.txt`。

## 最小修复
`inc-02/fix/db.py`：`cmd_apply` 增加批内 `seen` 集合，批内重复键 → RC8
（唯一约束违反），已存在键仍按幂等跳过。RED→GREEN 见
`../tools/red-green.sh`：RED 账本 4 行、2 行同键、发布错误结果；GREEN
RC8、不发布、`account.table` 未被部分修改。

## 恢复 / 重跑
- **提交结果未知先查账本**（`db.py status`）。
- 已提交且已发布：不得删除完成标记重跑；应按幂等账本决定是否需要
  业务更正运行（新业务版本 + 审计关系），或对重复行开具冲正。
- 未提交/未发布：修正来源后新 run_id 重跑。

## 防再发
在真实 DB 建立并依赖 `UNIQUE` 约束；应用层按批做唯一性前置校验；
发布前对账须包含跨来源（上游声明）项目。

## 评分点
- 根因定位在**入账/约束**而非匹配算法。
- 用账本原始内容与余额对照证明，而非只贴 RC。
- 修复不改原始输入、不放宽断言；说明内部核对的局限与恢复边界。
