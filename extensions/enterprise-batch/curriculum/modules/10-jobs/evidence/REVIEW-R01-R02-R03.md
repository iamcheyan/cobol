# Review 修复证据：R01 / R02 / R03（模块 10）

日期：2026-10-10。审查依据：`tasks/enterprise-cobol-final-review-2026-10-10.md`。
基线 HEAD `ad058c5334d08d4f426f7a378ef567ad3f0cd2e9`（新课程文件当时未入库，
故反例以工作树实测记录）。

## R02 · 余额与幂等账本分开持久化（已修）

**反例复现（修改前，原始 RC 与状态已存盘）**
`evidence/review-r02-r03/OLD-r02-resume-rc12.log`、`OLD-r02-rerun-rc8.log`：

1. `python3 lib/db.py seed --db DB --account fixtures/normal/account_seed.dat
   --customer fixtures/normal/customer_seed.dat` → RC0。
2. `bash scripts/run.sh --input fixtures/normal --output OUT --db DB
   --business-date 20261009 --run-id r --crash-at before-db-commit` → RC97
   （JOB006 尚未写任何东西）。
3. 把 `DB/ledger.dat.tmp` 置为目录：`atomic_write(ledger)` 在 `write_balances`
   **之后**失败 → 旧顺序产生“余额已改、账本无记录”的半提交。
4. 恢复重跑 → **RC12**；`account.table` 已从 1000/50/0 变为 400/150/0，
   `ledger.dat` 不存在。
5. 去掉故障后重跑 → **RC8**（`DB closing != candidate`）；状态卡在 400/150/0，
   无法安全恢复。

**修复**：`lib/db.py` 改为 write-ahead 协议 —— 幂等账本先写（唯一事实来源），
余额由「冻结期初快照 + 账本」推导并在需要时自愈（`derive_balances`）。新增注入点
`--inject ledger`（`mid-db-commit` 映射到该危险边界）。

**修复后（原始 RC）**
- 账本写 I/O 失败：RC12，余额**保持** 1000/50/0，账本不存在（无半提交）。
  证据：`evidence/review-r02-r03/NEW-r02-ledger-io-rc12-no-partial.log`。
- 解除故障重跑：RC4，账本 4 行，余额 400/150/0 = `expected/normal.closing.txt`，
  仅入账一次。
- 永久回归：`scripts/check.py::check_persistence_boundaries` 逐个边界
  （ledger / mid / after）崩溃后重跑一次，断言账本 4 行、余额 == 候选、二次重跑不增。

## R03 · 发布后的失败删除正式结果（已修）

**反例（审查给出）**：`during-publish` 中断 RC97；把发布登记/完成标记/次日准备的
I/O 置为故障；恢复时正式发布已发生但随后的故障使 `run.sh` 直接 `rm -rf output`，
DB 提交仍在。

**修复**：`scripts/run.sh` 错误处理不再无条件删除 output，改用
`has_committed_or_published()`：当本次 run 的 `publish/CURRENT==run-id`、
`publish/<run-id>` 存在、`complete.marker` 存在，或 DB commit 标记的 `run_id`
等于本次 run 时，**保留** output 并如实返回 RC；仅对真正未提交、未发布的暂存目录
才删除。发布登记/完成标记/次日准备各自新增可注入 I/O 故障点
（`BANK_INJECT_FAIL=complete|nextday`），且 JOB009 次序调整为**次日准备在前、
完成标记最后**，使 these 故障可续跑恢复。

**修复后（原始 RC，实测）**
| 故障点 | 第二步 RC | output 保留 | 已发布产物 | 干净重跑 RC | 账本不变 |
|---|---:|---|---|---:|---|
| complete | 12 | 是 | 是 | 4 | 是 |
| nextday | 12 | 是 | 是 | 4 | 是 |

永久回归：`scripts/check.py::check_publish_failure_preserved`。

## R01 · 真实 DB 贯通（已修，本机已实跑）

**路线**：`scripts/real-db.sh`（Docker + PostgreSQL17 + GixSQL + 模块 08 canonical
ESQL 程序）。
- JOB004 真实抽取：`SNAPSHOT.COB` 游标抽取客户视图，与冻结 27B feed 逐字节核对。
- JOB006 真实入账：`APPLY.COB` 在**同一事务**内提交幂等账本 + 余额 + `batch_commit`。
- 独立核对：`docker exec … psql`（非程序 stdout）。
- 覆盖：首次提交、未知提交结果重试（`ALREADY-APPLIED` 不重复入账）、并发重试、
  回滚原子性。
- 永久回归：`scripts/check-real-db.sh`（Docker 不可用 → `UNVERIFIED` RC2）。

**实测（原始 RC）**：`bash scripts/check-real-db.sh` → RC0；
`real-db-summary.txt`：`BALANCES_FIRST=400,150,0`、`BALANCES_RETRY=400,150,0`、
`LEDGER_CONCURRENT=4`、`COMMIT_CONCURRENT=1`、`EXPECTED_BALANCES=400,150,0`。
离线路线仍为默认并明确标注“真实 DB 未验证”，两者不得混用。
