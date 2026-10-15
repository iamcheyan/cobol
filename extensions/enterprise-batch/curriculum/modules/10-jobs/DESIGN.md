# 模块 10 设计：夜间 JOB 编排、RC 与恢复

对应大纲 10.1–10.5。本文件定义依赖、RC 政策、锁/快照/Manifest 与恢复
清单；学员任务与验收见 [README](README.md)，讲师根因与答案见
`instructor/modules/10-jobs/`。

## 1. JOB 依赖与 RC 政策

```mermaid
flowchart LR
  J1[JOB001 接收] --> J2[JOB002 校验] --> J3[JOB003 SORT]
  J3 --> J4[JOB004 DB快照] --> J5[JOB005 突合/余额] --> J6[JOB006 幂等入账]
  J6 --> J7[JOB007 控制总数] --> J8[JOB008 发布] --> J9[JOB009 完成]
```

| JOB | 输入（只读） | 输出/检查点 | 允许前置 RC | 失败后 |
|---|---|---|---|---|
| 001 | 接收目录 + MANIFEST | `snapshot/`（不可变）+ 校验和 | — | RC8/12 不进入校验 |
| 002 | 快照 + 布局契约 | `work/validate/`（accepted/rejected/control） | 仅 RC0 | 结构错误 RC8，业务拒绝 RC4 |
| 003 | accepted 交易 | `work/sorted_tx.dat` + 有序性证据 | 仅 RC0 | 临时空间等 RC12，无正式产物 |
| 004 | 营业日 + DB store | `work/db/` 快照（版本/截止点） | 仅 RC0 | 连接/校验失败 RC12，不用过期数据冒充 |
| 005 | 快照账户 + 有序交易 | `work/closing/`（候选，隔离） | RC0、RC4（业务拒绝） | 候选不发布 |
| 006 | 候选 + 幂等键 | 账本 + commit 标记 | RC0、RC4 | 先查账本，再决定是否恢复 |
| 007 | 明细/拒绝/账本 | `work/control/`（核对证据） | 仅 RC0 | 不通过 RC8，不能发布 |
| 008 | 已核对候选 | `publish/<run_id>/` + CURRENT | 仅 RC0 | 已提交则只恢复发布 |
| 009 | 完成证据 | `state/complete.marker` + 次日准备 | 仅 RC0 | 状态可查，不覆盖原运行 |

RC 语义（课程约定，非任何真实产品退出码）：

| RC | 含义 | 是否继续 | 是否正式发布 |
|---:|---|---|---|
| 0 | 正常 | 是 | 是 |
| 4 | 契约允许的 Warning（逐笔业务拒绝） | 是 | 是，但必须经 JOB007 核对 |
| 8 | 业务/契约异常（长度、有序性、守恒不符） | 否 | 否 |
| 12 | 系统异常（权限/磁盘/mktemp/锁/意外子进程码） | 否 | 否 |

非 0/4/8/12 的子进程退出码（含信号）一律在 Shell 边界映射为 RC12 并
记录，不伪装成业务拒绝（BANK-SYSTEM §6）。

## 2. 配置、参数与业务日

- 参数优先级：**CLI > `--config` 文件 > 白名单 `BANK_*` 环境变量 > 内置默认**。
- 环境变量只承担约定配置：`BANK_INPUT／BANK_OUTPUT／BANK_DB_DIR／
  BANK_BUSINESS_DATE／BANK_RUN_ID／BANK_COURSE_SOURCE／BANK_CRASH_AT`。
- 营业日必须由参数显式给出，不使用机器当前日期；非真实 Gregorian 日期
  在入口以 RC8 拒绝。
- 所有脚本 `export LC_ALL=C`，不依赖调用者 locale。
- 临时目录：每个 JOB 在自己的 run 目录内工作；排序节点使用 `mktemp -d`
  并在父目录创建，失败映射 RC12。

**POSIX sh 与 Bash 的差异（10.1）**：本模块脚本使用 Bash 特性
（`[[ ]]`、`${var:-}`、数组无关但需要 `pipefail`、`set -E`、`local`），
因此 shebang 为 `#!/usr/bin/env bash` 且显式 `set -Eeuo pipefail`。POSIX
`sh` 没有 `pipefail`、`[[`、`local` 与 `BASH_SOURCE`；若移植到 `dash`，
须改用 `set -e`、`[ ]`、逐段 `cd -- "$(dirname -- "$0")"`，并自己用
`mktemp` 捕获中间退出码。课程只在 Bash 上验证，迁移到 POSIX sh 属学员
扩展练习，不宣称已验证。

## 3. 锁、输入快照与原子发布

- **输出锁**：`<output>.lock`（`mkdir` 原子获取）。
- **营业日锁**：`<db>/locks/<business_date>.lock`，内含持有者 pid。
  进程存活 → 同日并发启动以 RC12 拒绝；pid 已死 → 视为陈旧锁回收并记录。
- **输入快照**：JOB001 按 MANIFEST 校验 SHA256 后复制到 `snapshot/`；
  之后所有 JOB 只读快照，绝不写原始接收目录。JOB004 冻结当日期初账户/
  客户视图于 `db/snapshots/<date>/`，*当日自身的入账不改写该冻结视图*，
  只校验冻结文件自身校验和（防篡改）。
- **原子发布**：JOB008 先在 `work/publish/<run_id>/` 暂存 → 生成并校验
  `manifest.json`／`MANIFEST.sha256` → `mv -T -n` 切换为
  `publish/<run_id>/` → 最后才移动 `publish/CURRENT` 指针。发布目录和
  CURRENT 都带 run_id；JOB009 确认 CURRENT == 本次 run_id 才写完成标记，
  因此旧结果不能冒充本次结果。
- **Manifest 字段**：`run_id、business_date、engine、real_db_verified=false、
  files{name: sha256}`，以及与之对应的 `MANIFEST.sha256`。

## 4. DB 层：离线文件检查点（默认）+ 真实 DB 路线（R01）

**默认教学路线**：`lib/db.py` 用崩溃安全扁平文件模拟数据库契约：幂等账本
`ledger.dat`（键 = 营业日 + 交易 ID）**先写**（write-ahead，唯一事实来源），
账户表 `account.table` 由「冻结期初快照 + 账本」**推导/自愈**，提交标记
`db/commit/<date>.json`。单文件写入采用临时文件 + `fsync` + `rename`；由于账本
先写且余额可推导，账本与余额之间不再存在“余额已改而账本无记录”的危险窗口，
任一持久化边界崩溃后重跑只入账一次。离线证据仍须写明“DB 未验证”。

**真实 DB 路线（R01）**：`scripts/real-db.sh` 使用 Docker + PostgreSQL17 +
GixSQL，复用模块 08 的 canonical ESQL 程序：JOB004 用真实游标抽取客户视图
（`SNAPSHOT.COB`，与冻结 feed 逐字节核对），JOB006 用 `APPLY.COB` 在**同一事务**
内提交幂等账本 + 余额 + `batch_commit`（重复业务键触发唯一约束 → 跳过或回滚）。
余额/账本/提交行数用**独立 psql 连接**读回。回归 `scripts/check-real-db.sh`
覆盖首次提交、未知提交结果重试（ALREADY-APPLIED 不重复入账）、并发重试与回滚
原子性；真实 DB 不可用时报 `UNVERIFIED`。

## 5. 幂等与重跑

- 幂等键：`(business_date, transaction_id)`。
- JOB006 入账前先 `db.py status` 读账本；已存在键的交易不重复累加。
- 账户余额以“按已接受交易增量累加”更新；重跑时无新键 → 余额不变
  （无重复扣款）。
- 候选期末余额与更新后余额做独立交叉核对，不一致 → RC8 且不发布。
- 三类重跑：失败阶段恢复（marker 续跑）、从冻结快照重建派生文件、
  业务更正运行（需新业务版本，超出本模块范围）。

## 6. 四个强制崩溃边界与恢复清单

注入方式：`run.sh --crash-at POINT`（RC97 并保留现场），随后以同一
`--run-id/--output/--db` 重跑即自动恢复。

| 边界 | 注入点 | 崩溃后事实 | 恢复动作 | 一致性判据 |
|---|---|---|---|---|
| DB 提交前 | `db.py apply --inject before` | 账本无新行、无 commit | 续跑 JOB006 正常入账 | 账本 = 已接受交易数；余额 = 候选 |
| 提交后发布前 | `db.py apply --inject after` | 账本/余额/commit 已写 | 续跑 JOB007/008 | 同上，且发布目录生成 |
| 发布期间 | JOB008 暂存后、切换前 | 仅暂存，无 `publish/<run_id>` | 重新暂存并发布 | CURRENT == run_id |
| 发布后完成标记前 | nightly 在 JOB008 后 | 已发布，无完成标记 | 续跑 JOB009 | 完成标记齐全 |
| （附加）提交中 | `db.py apply --inject mid` | 账本已写、无 commit 标记 | 先查账本再续跑 | 不重复扣款 |

恢复原则：**以幂等账本/提交标识/Manifest/校验和核实事实，绝不凭
Shell 日志最后一行推断事务状态**；已提交但未发布时只恢复发布。

## 7. JOB 节点映射

顶层 9 个 JOB 展开为可追踪的处理节点：

| 节点 | 步骤 | 节点 | 步骤 |
|---|---|---|---|
| 001a | 接收 MANIFEST | 006a | 读账本（先查） |
| 001b | 校验输入 SHA256 | 006b | 幂等入账 |
| 001c | 冻结输入快照 | 006c | 写 commit 标记 |
| 002a | 长度/结构校验 | 007a | 笔数守恒 |
| 002b | 数字字段校验 | 007b | 金额守恒 |
| 002c | 业务规则校验 | 007c | 账本交叉核对 |
| 002d | 拒绝报告 + 控制总数 | 007d | 生成日报 |
| 003a | 构建/校验 | 008a | 暂存产物 |
| 003b | SORT | 008b | 校验 Manifest |
| 003c | 有序性验证 | 008c | 原子切换 |
| 004a | DB 可达性/版本 | 008d | 更新 CURRENT |
| 004b | 冻结客户快照 | 009a | run_id 一致性确认 |
| 004c | 冻结账户快照 | 009b | 完成标记 |
| 005a | Key Break/余额 | 009c | 次日准备 |
| 005b | 接受/拒绝分类 | | |
| 005c | 候选隔离 + 报告 | | |

## 8. 复用与边界

- JOB003 复用模块 07 SORT 参考实现（`instructor/modules/07/.../SORTTX.COB`
  经其 runner）；JOB005 复用模块 07 L2（`BATCHL2.COB` 经其 runner）。
  本模块不复制这些程序，避免各章漂移。
- JCL/JP1 仅作**阅读映射**：`lib/jcl/JOBFLOW.jcl`、`lib/jp1/JOBFLOW.jp1`
  为示意，从未在 z/OS/JES2 或 JP1/AJS 上提交或加载，不声明任何平台可运行。
- 平台：仅 Linux x86-64 实际验证；macOS/WSL/其他架构未验证。
