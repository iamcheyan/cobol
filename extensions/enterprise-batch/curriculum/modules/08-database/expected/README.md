# expected：独立核算与说明

本目录的预期**不是**把程序当前输出直接保存而来，而是由业务契约、种子 SQL 与夹具
**独立推导**，再由程序验证（见制作标准第4节）。`scripts/check.py` 内含可执行的独立
oracle，从 `db/seed.sql` 与 `fixtures/` 重新计算下列预期，任何不符即失败。

## 快照（08.3）

业务日 `20261009` 的 DB 客户（`db/seed.sql`）：C1/C2/C3/C5。按 `customer_id` 升序
组装 CUSTOMER v1 27B（`id(8)+name(10)+balance(8)+status(1)`），写入
`snapshot-20261009.dat`（4 条 × 27B + LF = 112B）。C4 属业务日 `20261010`，被游标
正确过滤。

## 突合（08.3）

上游 `fixtures/customer-upstream-20261009.dat`：C1/C2/C3/C9，其中 C2 余额 260（DB 为
250）、C9 为文件独有；DB 的 C5 为库独有。逐键比对得：

| 键 | 结果 |
|---|---|
| 00000001 | MATCH |
| 00000002 | FIELD-DIFF `balance_demo` 位置 19-26，DB=00000250，上游=00000260 |
| 00000003 | MATCH |
| 00000005 | DB-ONLY |
| 00000009 | FILE-ONLY |

`snapshot-control.txt`：`DATABASE-ROWS=4 FILE-ROWS=4 MATCH=2 FIELD-DIFF=1 DB-ONLY=1
FILE-ONLY=1 DIFFS=3` → RC4。无差异上游 `…-nodiff.dat` 与 DB 逐字节相同 → 全部 MATCH、
`DIFFS=0` → RC0。

## 应用与幂等（08.4）

账户期初（`db/seed.sql`）：A1=100、A2=200、A3=300。交易
`fixtures/transactions-20261009.dat`：A1 +50、A1 −20、A2 +70。

- 首次提交：A1=100+50−20=**130**、A2=200+70=**270**、A3=**300**；账本 3 行、提交 1 行
  → `db-after-first.txt`。
- 重试（同业务日、新 run_id）：唯一键全部命中 → 全部 SKIP，上述值不变
  → `db-after-retry.txt`；`apply-retry.out` 含 `ALREADY-APPLIED=` 与
  `DAY-ALREADY-COMMITTED=YES`。
- 回滚模式：不提交 → 余额 `100,200,300`、账本 0 行 → `db-after-rollback.txt`。
- 运行内重复 `fixtures/transactions-dup-in-run.dat`（复制 T…001）：`23505` → 本运行内
  重复 → RC8 整批回滚 → `db-after-dup.txt`（余额 `100,200,300`、账本 0、提交 0）。

`db-after-*.txt` 由**独立 psql 连接**（`docker exec … psql`）读出，不由 COBOL 打印，
因此能发现“RC0 但金额错误”。

## 元数据键

`snapshot-meta.keys.txt` 列出必须出现的键；`CUTOFF` 取 DB 时钟，故只校验存在与格式，
不参与逐字节比较。
