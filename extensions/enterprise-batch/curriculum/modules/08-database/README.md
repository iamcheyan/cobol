# 模块08：COBOL + 数据库（Embedded SQL 实战）

本模块使用 **经 P1 验证的真实 Embedded SQL 工具链**（GnuCOBOL 3.2 + GixSQL 固定
commit + 两个本地补丁 + PostgreSQL 17），在 Docker 一次性容器/网络中真实执行 COBOL
游标、更新与事务。不是 mock，不由 `psql` 导出文件代替被教的 COBOL 游标。业务日由参数
给出，不使用机器当前日期。全部数据为合成数据，一次性容器退出即清理，不引用宿主数据库。

课次：**08.1** Host/Indicator Variable、NULL、SQLCODE/SQLSTATE；**08.2**
DECLARE/OPEN/FETCH/CLOSE 游标并区分无数据与错误；**08.3** 按业务日抽取客户快照并与
上游文件突合；**08.4** 更新、唯一约束、COMMIT/ROLLBACK、连接中断与事务重试。

- 设计细节：[DESIGN.md](DESIGN.md)
- 独立预期与核算：[expected/README.md](expected/README.md)
- 学员证据模板：[evidence/README.md](evidence/README.md)
- 讲师参考实现：[instructor/modules/08-database/](../../../instructor/modules/08-database/)

## 1. 业务为什么需要 / 学员需求

夜间批处理要在 **DB 与文件之间**协同：按业务日从 DB 抽取固定客户视图，与上游下发的
客户文件突合，找出一致与差异；再把当日交易**幂等**写入账本并更新余额。值班开发者最怕两件事：
把 NULL 当成空格、重复跑批款。你的需求：读懂并修复这条链路，使“同业务日重跑不重复扣款”，
并能对“无数据、唯一约束冲突、连接失败、提交结果不明”给出可复现证据。

## 2. 输入从哪来、格式、前提

- 上游客户文件：`fixtures/customer-upstream-20261009.dat`，CUSTOMER v1 定宽 **27 字节** + LF。
- 交易文件：`fixtures/transactions-20261009.dat`，TRANSACTION v1 定宽 **55 字节** + LF。
- DB 种子：`db/seed.sql`（合成客户/账户），schema 见 `db/schema.sql`。
- 前提：业务日为 `20261009`；文本为 ASCII；LF 不计入记录长度；金额为最小单位整数。
- 契约冻结：CUSTOMER v1=27B、ACCOUNT v1=47B、TRANSACTION v1=55B。

## 3. 从干净 checkout 构建、运行、复位

需 Docker（隔离 ESQL 工具链）与 Python 3：

```bash
lab=$(cd curriculum/modules/08-database && pwd)
python3 "$lab/scripts/check.py"          # 离线契约 + 独立 oracle（无需 Docker）
bash "$lab/scripts/check.sh"             # 离线 + 真实 DB 端到端 + 学员起始代码
```

单独运行真实实验（产物写入新目录；已存在则拒绝覆盖）：

```bash
bash "$lab/scripts/run.sh" /tmp/m08-out 20261009
(cd /tmp/m08-out && sha256sum -c inputs.sha256 && sha256sum -c manifest.sha256)
```

构建单个 ESQL 源为可执行文件（路径含空格亦可）：

```bash
bash "$lab/scripts/build.sh" /tmp/probe "$lab/system/ESQL-PROBE.COB"
```

复位：`bash "$lab/scripts/reset.sh" --containers`（清理遗留一次性容器/网络）；
`PGHOST=... bash "$lab/scripts/reset.sh" --db`（对运行中课程库重放 schema+seed）。
`run.sh` 每次创建唯一命名的 `m08-*-db` 容器与 `m08-*-net` 网络，退出（含 Ctrl-C）删除；
工具镜像保留复用。派生文件全部写入 `<OUTPUT>`（含 `manifest.sha256`），不写源码目录。

## 4. 预期输出、RC、笔数与金额，如何独立核算

`run.sh 20261009` 的正常结果（**独立核算过程见 [expected/README.md](expected/README.md)**，
不依赖任何程序输出）：

| 场景 | 期望 | 独立核算依据 |
|---|---|---|
| 08.1/08.2 探针 | `PROBE=PASS`，RC0 | 指示器 -1（NULL）、空字符串指示器 0、`02000` 无数据、`23514` 真实错误、`23505` 唯一 |
| 08.3 快照 vs 上游 | RC4，`DIFFS=3`（MATCH2 / FIELD-DIFF1 / DB-ONLY1 / FILE-ONLY1） | 由 seed 与上游文件逐键比对 |
| 08.3 无差异上游 | RC0，全部 MATCH | 上游与 DB 快照逐字节相同 |
| 08.4 回滚模式 | RC0，余额不变 `100,200,300` | 期初余额，事务回滚 |
| 08.4 首次提交 | RC0，余额 `130,270,300`，账本 3 行，提交 1 行 | 期初 + 逐笔 C/D |
| 08.4 重试 | RC0，余额仍 `130,270,300`，账本/提交不增 | 唯一键跳过，幂等 |
| 08.4 运行内重复 | RC8，账本 0、余额不变 | 唯一键冲突 + SAVEPOINT 回滚 |
| 连接失败 | RC12，SQLSTATE `08xxx` | 错误端口 |

发布产物：`snapshot.dat`（27B 快照）、`snapshot-meta.txt`（业务日/schema 版本/布局版本/
截止点/计数）、`snapshot[-nodiff]-reconcile.txt` 与 `-control.txt`、`apply-*.out`、
`db-after-*.txt`（**独立 psql 连接**读出的余额/账本/提交行数）、`probe.out`、
`probe-fail.out`、`p1-patches.sha256`、`manifest.sha256`、`inputs.sha256`。

## 5. 需要改哪里、哪些接口不能破坏

学员从 [starter/DBBATCH.COB](starter/DBBATCH.COB) 起步（可构建但未完成，返回 RC12 且
不发布）。不可破坏：27B/55B 契约、环境变量接口
（`M08_BIZ_DATE/M08_SNAPSHOT/M08_META/M08_UPSTREAM/M08_DIFF/M08_CONTROL`）、RC 约定、
唯一业务键。既存保障程序 `system/ESQL-PROBE.COB`（08.1/08.2 探针）与
`system/APPLY.COB`（08.4 入账）随学生包提供；`run.sh` 自动选用。快照程序是**本题**的
学员交付：`run.sh` 默认编译学员自己的 `starter/DBBATCH.COB`（或用 `COURSE_SOURCE`
指向外部源）；讲师参考 `instructor/modules/08-database/SNAPSHOT.COB` 不随学生包发布。

### 学员快照源入口（`COURSE_SOURCE`）

`run.sh` 用 `COURSE_SOURCE=<你的快照源>` 替换 `bin/snapshot`（08.2/08.3），其余仍用讲师
参考。**该源与讲师参考走完全相同的业务验证**，不因“设置了 `COURSE_SOURCE`”就无条件失败：

- 有差异上游 → RC4；无差异上游 → RC0；且 27B 快照必须与 `expected/snapshot-20261009.dat`
  逐字节一致。全部通过才继续 08.4 并发布。
- 系统级失败（如未完成 `DBBATCH.COB` 返回 RC12）→ RC12，不发布。
- 语义错误但仍返回 RC4/RC0 的实现（金额/符号/状态/少行多行）→ 在字节比对处被拒（RC8），
  不发布。

回归：`scripts/check.sh` 第 4–6 节分别验证“正确参考作为 `COURSE_SOURCE` 正常发布”、
“语义错误的学生源被拒”与“未完成 starter RC12 不发布”。

## 6. 故意破坏哪些条件、如何调查恢复（每课至少一个可复现故障）

| 课次 | 动手修改 | 可复现故障 | 调查与恢复 |
|---|---|---|---|
| 08.1 | 把 `:HV-NOTE:HV-NOTE-IND` 的指示器去掉 | 取 NULL 列得到空格而非 NULL，NULL 与空串混淆 | 用指示器 -1 判定 NULL；改回指示器 |
| 08.2 | 把游标 `FETCH` 后不判 `02000` 就当作成功 | 数据耗尽被当成错误或漏行 | `FETCH` 后 `IF SQLSTATE='02000'` 正常结束，其它才报错 |
| 08.3 | 把上游某客户 `balance_demo` 改一位 | 与 DB 快照出现 `FIELD-DIFF`，RC4，定位字段与偏移 | 修回上游或修 DB 种子，重跑得 RC0；差异报告可定位 `19-26` |
| 08.4 | 在交易文件里复制一条同 `transaction_id` | 唯一键 `23505` → 运行内重复 → RC8 回滚 | 去重后重跑；历史重跑则走 SKIP 分支 |

另有两个强故障实例（已实测）：**72 列溢出**——把多列 `INSERT` 排到第 73 列，GixSQL/
cobra 截断标识符 `sequence_no` → `42601` 语法错误；修法是把 SQL 行控制在第 72 列内。
**PostgreSQL 事务中止**——`23505` 后同一事务内再 `SELECT` 得 `25P02`；修法是用
`SAVEPOINT`+`ROLLBACK TO SAVEPOINT` 做局部恢复（见 DESIGN.md 第 4 节）。

## 7. 插件操作与纯终端替代

- 固定格式安全：用 cobol.nvim 标尺检查 Area A/B 与第 72 列越界红波浪线；终端替代：
  `awk 'length($0)>72{print NR}' <file>.COB`、`:set list`。
- 定位参考实现段落：`gd`/`:CobolGotoDef` 跳到 `1150-ONE`、`1200-DAY-COMMIT`；
  终端替代：`rg -n '1150-ONE|1200-DAY-COMMIT' system/APPLY.COB`（既存保障程序，
  随学生包提供）。
- 预览 `COPY` 的 Copybook：`K`/`:CobolPreview`；终端替代：`cat copybooks/CUSTOMER-V1.CPY`。
- 查看真实字节（校验 LF/宽度）：终端 `od -An -tc fixtures/customer-upstream-20261009.dat`。
- **插件估算不得作为字节布局最终依据**；以 `check.py` 的定宽断言与 `od` 为准。

## 8. 需要交什么证据、何种结果算失败

按 [evidence/README.md](evidence/README.md) 提交：编译器与 DB 工具版本、镜像 id、P1 补丁
sha256、营业日、run_id、命令、**原始 RC**、`inputs.sha256`/`manifest.sha256`、DB 原始状态
（余额/账本/提交）、核对表与限制。以下算失败：任何断言与发布产物不一致；`manifest`/
`inputs` 校验不过；快照 27B 与独立 oracle 不符；重试后余额或账本增加；运行内重复未回滚；
未完成学员源发布了任何产物；把未验证平台/恢复边界写成“已通过”。
