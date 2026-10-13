# 模块08 执行证据（作者实测记录，2026-10-10）

本文件记录模块08 交付时的真实执行。环境：Debian 13 (trixie) x86-64，Docker 29.8.1，
GnuCOBOL 3.2.0，工具镜像 `cobol-course-gixsql:m08`（与 P1 同 digest/层）。

## 1. 完整性检查

```bash
python3 curriculum/modules/08-database/scripts/check.py
# -> PASS: module08 offline contracts (4 COBOL sources)   RC=0

bash curriculum/modules/08-database/scripts/check.sh
# -> PASS: module08 full check (...)                       RC=0
```

`check.sh` 内部：离线契约 → 真实 DB 端到端（`run.sh`）→ 发布产物与 `expected/` 逐字节
对照 → 独立 psql 状态 → 学员起始代码 RC12 不发布。

## 2. 真实 DB 实验（run.sh）

```bash
bash curriculum/modules/08-database/scripts/run.sh "/tmp/m08out test" 20261009
# -> PASS: module08 real-DB run published                 RC=0
```

发布产物关键值（独立 psql 连接读出）：

| 场景 | 原始 RC | DB 状态 |
|---|---:|---|
| probe | 0 | `PROBE=PASS`（NULL 指示器 -1、空串、02000、23514、23505） |
| fail-connect | 12 | `SQL-FAIL=+0000000001:08001` |
| snapshot vs 上游 | 4 | DIFFS=3（MATCH2/FIELD-DIFF1/DB-ONLY1/FILE-ONLY1） |
| snapshot vs 无差异上游 | 0 | 全 MATCH |
| apply rollback | 0 | 余额 100,200,300；账本 0 |
| apply 首次提交 | 0 | 余额 130,270,300；账本 3；提交 1 |
| apply 重试（新 run_id） | 0 | 余额不变 130,270,300；账本 3；提交 1；`ALREADY-APPLIED=` |
| 运行内重复（23505） | 8 | 余额 100,200,300；账本 0；提交 0（整批回滚） |

## 3. RED → GREEN（72 列截断）

把 `APPLY.COB` 的 `INSERT` 列表排到第 73 列（`sequence_no` 被截断）：

- RED：构建 RC0，运行 RC12，`LOAD-FAIL=-0000010007:42601`（PostgreSQL 语法错误），
  DB 未变（余额 `100,200,300`，账本 0）。
- GREEN：参考实现 RC0，`COMMITTED=YES`，DB 变为 `130,270,300`，账本 3。

另一条已实测的 RED→GREEN：`23505` 后同事务内再查询得 `25P02`
（`current transaction is aborted`）；改用 `SAVEPOINT`/`ROLLBACK TO SAVEPOINT` 后恢复为
可分类的重复检测（SKIP / RC8）。

## 4. 未验证项（不得声称通过）

- macOS / WSL / ARM 未验证；仅 Linux x86-64。
- 真实网络断线中断、并发锁竞争、其它数据库（DB2/Oracle）错误码未验证；
  仅验证“错误端口连接失败（08001）”与“提交后重跑幂等”。
- 时间/RSS 性能阈值未测量（本模块不含压力验收）。
