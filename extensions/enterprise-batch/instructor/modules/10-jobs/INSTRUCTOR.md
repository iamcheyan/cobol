# 讲师参考实现与事故/恢复说明 — 模块 10

学员包只含任务、可用资料与逐层提示。本文件保存参考实现位置、根因、
崩溃边界触发条件、最小修复与评分点。公开仓库无法保密答案；自学者须知
答案位于此处。

## 1. 参考实现位置

| 组件 | 学员起点 | 参考实现 |
|---|---|---|
| JOB002 校验器 | `curriculum/modules/10-jobs/starter/BANKVAL.COB` | `instructor/modules/10-jobs/BANKVAL.COB` |
| 离线 DB/幂等账本 | `curriculum/modules/10-jobs/lib/db.py` | 同文件（本模块即参考） |
| JOB003 SORT | — | 复用 `instructor/modules/07/01-sort/SORTTX.COB`（经其 runner） |
| JOB005 突合/余额 | — | 复用 `instructor/modules/07/03-one-to-many/BATCHL2.COB`（经其 runner） |
| DB seed | `fixtures/*/account_seed.dat` | `instructor/modules/10-jobs/db-seed/` |
| 夹具/预期生成器 | — | `instructor/modules/10-jobs/tools/gen_course.py` |

## 2. BANKVAL 参考实现的要点与常见错误

参考实现的判定顺序：**长度 → 数字键/金额 → 空交易 ID → 方向 → 状态 →
营业日 → 零金额**。跳过其中一步会把该异常误分类。

| 现象 | 根因 | 最小修复 |
|---|---|---|
| 短/长记录被当有效 | LINE SEQUENTIAL 读入后空间填充，未取原始长度 | 用 `FUNCTION LENGTH(FUNCTION TRIM(...))` 还原原始字节长度 |
| CRLF 输入未报错 | LF-only 契约，CR 成为数据 | 长度不等于 55 即结构错误 |
| 结构错误却发布了 accepted | 结构错误应在写出前中止并 RC8 | 立即置 WS-STRUCT，`GOBACK` 前不再 `3000-CONTROL` |
| 业务拒绝导致整批失败 | 混淆业务拒绝（RC4）与结构错误（RC8） | 只对结构错误 RC8 |
| 系统失败落成成功 | 文件打开失败未置 RC12 | `FILE STATUS` 非 00 → RC12 |

## 3. RC 与放行策略

- JOB002/JOB005 允许 RC4 继续（逐笔业务拒绝），但其结果必须经 JOB007
  守恒核对后才发布。
- JOB003/JOB004/JOB007/JOB008/JOB009 只允许 RC0。
- 任何非 0/4/8/12 的子进程码在 Shell 边界映射 RC12。
- 前置失败（RC8/12）时 nightly 立即停止，下游不执行，`run.sh` 删除未发布
  的运行目录。

## 4. 幂等与“无重复扣款”根因

- 幂等键 `(business_date, transaction_id)`，写在 `ledger.dat`。
- 重跑时先读账本；已存在键的交易不再累加，账户余额不变。
- 候选期末与更新后余额做独立交叉核对；不一致 → RC8，不发布。
- **提交结果未知先查账本**：`db.py status` 是恢复第一步；`--inject mid`
  模拟“账本已写、commit 标记未写”的现场，恢复时账本即事实来源，不盲重试。

## 5. 四个强制崩溃边界

| 边界 | 触发 | 崩溃后现场 | 恢复 |
|---|---|---|---|
| DB 提交前 | `--crash-at before-db-commit` | 无新账本行、无 commit | 续跑 JOB006 正常入账 |
| 提交后发布前 | `--crash-at after-db-commit` | 账本/余额/commit 已写 | 续跑 JOB007/008，只恢复发布 |
| 发布期间 | `--crash-at during-publish` | 仅暂存，无 `publish/<run_id>` | 重新暂存并切换 |
| 发布后完成标记前 | `--crash-at after-publish` | 已发布，无完成标记 | 续跑 JOB009 |
| （附加）提交中 | `--crash-at mid-db-commit` | 账本已写、无 commit | 先查账本再续跑 |

每个边界的实测原始证据见 `evidence/B02-recovery-2026-10-10.txt`：崩溃
RC97、恢复 RC4、`ledger_lines=4`、余额 400/150/0、commit/complete/current
齐全且一致。

## 6. RED→GREEN 回归记录（防重复扣款）

证据：`evidence/B03-red-green-2026-10-10.txt`。

- **RED**：移除 `lib/db.py` 的账本守卫与候选交叉核对后，同营业日重跑
  得到 `rerun_rc=8`、账本 8 行、余额被二次扣减（acc1 = −200、acc2 = 250）。
- **GREEN**：恢复守卫后 `rerun_rc=4`、账本 4 行、余额 400/150/0 不变。
- 捕获该缺陷的断言：`check.py` 中
  `assert second.returncode == 4` 与
  `assert (db/'account.table').read_bytes() == before`。

## 7. DB 真实性（必须在评分中如实标注）

本模块**未接入真实 GixSQL/PostgreSQL**，`lib/db.py` 是离线文件检查点。
`curriculum/validation/database/` 的 Docker 工具链**未被本模块调用**。
`publish/<run_id>/manifest.json` 与完成标记均写
`real_db_verified: false`。若学员声称真实 DB 已验证而无独立 psql 证据，
按未通过处理。

## 8. 评分点与误区

评分点：RC 传播正确；锁与并发拒绝；输入不可变与输出不覆盖；四边界恢复
且状态一致；同营业日重跑无重复扣款；失败不发布。

误区（用于设置误导线索）：把工作日当自然日；把 `publish/CURRENT` 的
存在当作本次成功；凭 Shell 日志最后一行判断事务状态；用 sleep 或删除
完成标记来“修复”重跑；把 JCL/JP1 示意当作已在大型机执行。
