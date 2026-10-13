# 模块 10：Shell / JCL / Scheduler — 夜间 JOB 运维

建议 9 小时。先修：模块 06（文件契约）、模块 07（SORT 与顺序突合）。
本模块把“程序”提升为“作业”：接收 → 校验 → 排序 → DB 快照 → 突合 →
幂等入账 → 控制总数 → 发布 → 完成，并演练 RC、锁、快照、Manifest 与
四个崩溃边界的恢复。

> 平台：仅 Linux x86-64 实际验证（GnuCOBOL 3.2、Bash、GNU coreutils、
> Python 3）。macOS/WSL/其他架构未验证。
>
> **DB 层说明（两条路线，不得混用）**：
> 1. **默认教学路线（离线）**：JOB004/JOB006 使用 `lib/db.py` 的崩溃安全文件
>    检查点模拟数据库事务语义。其证据必须注明“DB 层 = 离线文件检查点；真实 DB
>    未验证”，不得用离线 RC0 冒充真实端到端。
> 2. **真实 DB 路线（R01）**：`scripts/real-db.sh` 用 Docker + PostgreSQL17 +
>    GixSQL，复用模块 08 的 canonical ESQL 程序做 JOB004 真实游标抽取与
>    JOB006 单事务幂等入账，并用**独立 psql 连接**核对余额与账本；永久回归
>    `scripts/check-real-db.sh`。真实 DB 不可用时该脚本报 `UNVERIFIED`
>    （RC2），绝不冒充通过。

## 1. 业务为什么需要它 / 你接到什么需求

银行每晚必须把当日交易安全地入账、核对并发布给下游，而**文件、DB 与
下游发布之间没有原子提交**（FR-08）。你接到的是值班运维需求：把 9 个
JOB 串成一条夜间流，做到
**前置失败下游不执行、并发启动被拒绝、同营业日重跑不重复扣款、四个崩溃
边界都能恢复且状态一致**。

## 2. 输入、来源、格式与已保证前提

接收目录包含 `transaction.dat`（TRANSACTION v1，55 字节/条 + LF）与
`MANIFEST`（营业日、布局版本、每条文件的 SHA256）。DB 层由
`account_seed.dat`（ACCOUNT v1，47 字节）与 `customer_seed.dat`
（CUSTOMER v1，27 字节）首次播种到一个离线 store 目录。

固定接口（canonical 定义在 `curriculum/bank/copybooks/`，模块 10 另带
`copybooks/CUSTOMER-V1.CPY`）：

- CUSTOMER v1：27 字节 — id/name/demo_balance/status。
- ACCOUNT v1：47 字节 — id/customer/currency/sign/balance/status/date/version。
- TRANSACTION v1：55 字节 — account/txid/date/sequence/direction/amount/status。

已保证：ASCII 合成数据、LF 换行、LF 不计入逻辑长度、营业日不默认取机器
日期。重复 `transaction_id`、短/长记录、非法数字属于必须被发现的异常。

## 3. 从干净 checkout 构建、运行、复位

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
mod=curriculum/modules/10-jobs

# 构建 JOB002 校验器（可选，run.sh 会自行构建）
bash "$mod/scripts/build.sh" /tmp/bankval

# 运行完整夜间流（输入目录、输出目录、DB store、营业日必填）
set +e
bash "$mod/scripts/run.sh" \
  --input  "$mod/fixtures/normal" \
  --output /tmp/bank-night-20261009 \
  --db     /tmp/bank-db \
  --business-date 20261009 \
  --run-id n1
rc=$?
set -e
echo "nightly rc=$rc"      # 本夹具预期 4（含逐笔业务拒绝）

# 查看状态与证据
bash "$mod/scripts/run.sh" \
  --input "$mod/fixtures/normal" --output /tmp/bank-night-20261009 \
  --db /tmp/bank-db --business-date 20261009 --command status
cat /tmp/bank-night-20261009/work/control/control.txt
python3 "$mod/lib/verify_publish.py" \
  --dir /tmp/bank-night-20261009/publish/n1 --run-id n1 --business-date 20261009

# 复位（仅接受带 run.env 的课程运行目录，拒绝仓库路径/符号链接/未标记目录）
bash "$mod/scripts/reset.sh" /tmp/bank-night-20261009
```

会覆盖的派生文件：仅 `--output` 目录内内容。**输入目录、fixtures、
DB seed 与已有输出永不被覆盖**；重复输出目录以 RC12 拒绝。

## 4. 预期输出、RC、笔数与金额（独立核算）

`normal` 夹具：3 账户（期初 1000 / 50 / 0），10 条接收交易。

| 指标 | 值 | 来源 |
|---|---:|---|
| 接收 | 10 | 夹具行数 |
| JOB002 接受 / 拒绝 | 6 / 4 | 业务规则 |
| JOB003 排序 | 6 条 | accepted |
| JOB005 接受 / 拒绝（透支） | 4 / 2 | 期末余额规则 |
| JOB006 账本入账 | 4 | 幂等键 |
| 期初/贷/借/期末总额 | 1050 / 600 / 1100 / **550** | 守恒式 |
| 期末余额 | acc1 400、acc2 150、acc3 0 | `closing = opening + C − D` |

完整数值见 `expected/normal.control.txt` 与 `expected/normal.closing.txt`。
本模块预期由 `instructor/modules/10-jobs/tools/gen_course.py` 中的
**独立 oracle**（重新实现 BANKVAL 业务规则与 1:N 透支规则）计算，不复制
任何课程实现输出。`boundary-empty-tx`（RC0，期末=期初 1050）与
`boundary-single`（RC0，期末 1150）同样有独立 expected。

RC：`normal`/`boundary-*` 为 RC4/RC0；三个 `invalid-*` 为 RC8 且**无正式
发布**；系统失败（mktemp/权限/磁盘/锁）为 RC12 且**无正式发布**。

## 5. 需要修改哪里、哪些接口不能破坏

- 学员起点：`starter/BANKVAL.COB`（可编译，返回 RC12，不发布）。把它补成
  真正的 JOB002 校验器。参考实现在
  `instructor/modules/10-jobs/BANKVAL.COB`。
- 不能破坏：三种固定记录宽度与字段偏移；`work/` 与 `publish/` 的目录契约；
  `control.txt` 的键；返回 RC 语义（0/4/8/12）；幂等账本键
  `(business_date, transaction_id)`。
- JOB003/JOB005 复用模块 07 参考实现（不复制）：考试点在于**接入**而不是
  重写匹配算法。

## 6. 故意破坏与恢复（每个实验至少一个可复现故障）

| 实验 | 破坏方式 | 现象 | 恢复 |
|---|---|---|---|
| 10.1 参数 | 不传 `--business-date` | RC12 拒绝 | 显式传营业日 |
| 10.2 RC | 用 `invalid-short-record` 夹具 | JOB002 RC8，无发布 | 修记录长度 |
| 10.2 RC12 | `PATH` 注入失败的 `mktemp` | RC12，无发布，无锁残留 | 恢复正常环境 |
| 10.3 锁 | 预建 `<db>/locks/<date>.lock`（活 pid） | 同日并发 RC12 | 释放锁 |
| 10.3 快照 | 篡改 `db/snapshots/<date>/account_master.dat` | JOB004 RC12 | 从 DB 重取 |
| 10.4 崩溃 | `--crash-at {before,mid,after}-db-commit / during-publish / after-publish` | RC97 保留现场 | 同 run-id 续跑自动恢复 |
| 10.4 重跑 | 同一 DB、同营业日、新输出目录重跑 | RC4，余额/账本不变 | — |
| 10.5 JCL | 读 `lib/jcl/JOBFLOW.jcl` 映射到本地节点 | — | 仅阅读，不声明可运行 |

```bash
# 一键跑四个（含附加）崩溃边界的恢复实验，输出原始证据
bash "$mod/scripts/recovery-lab.sh" /tmp/m10-recovery-lab
```

## 7. 插件操作与纯终端替代

- 插件：在 `lib/db.py`／JOB 脚本定位问题用 `gd`/`:CobolGotoDef`；对
  `COPY "ACCOUNT-V1.CPY"` 用 `:CobolGotoCopybook` 校验 canonical 接口；
  保存 COBOL 时用诊断波浪线确认 72 列/Area A/B。
- 纯终端替代（插件缺失也能完成）：
  ```bash
  rg -n 'BANKVAL_|--crash-at|ledger|Manifest|complete.marker' curriculum/modules/10-jobs
  od -An -tc curriculum/modules/10-jobs/fixtures/normal/transaction.dat | head
  (cd /tmp/bank-night-20261009/publish/n1 && sha256sum -c MANIFEST.sha256)
  ```

## 8. 需要交什么证据、什么算失败

按 [evidence/README.md](evidence/README.md) 提交：营业日、run_id、命令、
原始 RC、输入/输出校验和、控制总数、四个崩溃边界的 ledger/余额/状态、
重跑前后对比、修改点与回归。

判为**失败**的情形：任何 JOB 失败却产生正式发布；同营业日重跑导致重复
扣款；崩溃恢复后 DB/账本/文件/状态不一致；把旧 `publish/<run_id>` 或
CURRENT 冒充本次结果；把系统失败落成成功；声称 DB 已真实验证。

验收自检：

```bash
bash curriculum/modules/10-jobs/scripts/check.sh
```

讲师参考实现、根因与 RED→GREEN 记录见 `instructor/modules/10-jobs/`。
