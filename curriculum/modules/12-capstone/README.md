# 模块 12：毕业综合项目 — 陌生版本银行系统

建议 9 小时。先修：模块 06（文件契约）、07（排序与顺序突合）、10（JOB 运维）。
本模块把 06/07/08/10 的 canonical 组件**编排**成一个“陌生版本”的夜间批处理
系统，要求你亲手复原架构、完成客户区分扩展、跑通四类业务日，并调查一次
**隐藏根因**事故。

> 平台：仅 Linux x86-64 实际验证（GnuCOBOL 3.2.0、Bash、GNU coreutils、
> Python 3）。macOS/WSL/其他架构**未验证**。
>
> **DB 层说明（两条路线，不得混用）**：
> 1. **默认教学路线（离线）**：`system/lib/capdb.py` 用离线文件检查点模拟 12 个
>    逻辑表的数据库契约。此路线证据必须注明“DB 层 = 离线文件检查点；真实 DB
>    未验证”，不得用离线 RC0 冒充真实端到端。
> 2. **真实 DB 路线（R01）**：`scripts/real-db.sh` 复用 canonical 模块 10 harness
>    （Docker + PostgreSQL17 + GixSQL + 模块 08 ESQL），做真实游标抽取与**单事务**
>    幂等入账（余额 + 账本 + `batch_commit` 同事务），并用独立 psql 核对；永久回归
>    `scripts/check-real-db.sh`。真实 DB 不可用时报 `UNVERIFIED`，绝不冒充通过。

## 1. 业务为什么需要它 / 你接到什么需求

银行每晚必须接收上游交易、校验、排序、与账户期初突合、幂等入账、核对
控制总数、生成并发布下游客户日报。文件、DB 与下游发布之间**没有原子提交**，
所以“失败不发布、重跑不重复扣款、崩溃可恢复”是硬要求。

你被交来的是**陌生版本**：文档不全、组件来自不同章节。任务分四段：
12.1 复原架构与依赖；12.2 完成客户区分 1→2 位扩展并跑正常/异常/重跑日；
12.3 跑通全夜间流程；12.4 调查隐藏根因事故并给出恢复。

## 2. 输入、来源、格式与已保证前提

接收目录含 `transaction.dat`（TRANSACTION v1，55B/条+LF）、`customer.dat`
（企业客户布局 CAP-CUSTOMER-FEED v1 31B 或 v2 32B）、`account_seed.dat`
（ACCOUNT v1 47B）与 `MANIFEST`（营业日、布局版本、各文件 SHA256）。

冻结接口（`system/copybooks/`）：CUSTOMER **v1 27B（第 27 字节 = 记录状态
status，仅 A/D）** / ACCOUNT **v1 47B** / TRANSACTION **v1 55B**。客户区分住在
**独立、版本化的** CAP-CUSTOMER-FEED 布局里：v1 **31B**（区分第 28 字节
A/B/C/D）、v2 **32B**（区分第 28-29 字节 A1..D1）；canonical CUSTOMER v1 的
27 字节不改。企业布局内嵌 canonical CUSTOMER v1 的 27 字节前缀。

**命名说明**：capstone 的小型客户 feed 命名为 `CAP-CUSTOMER-FEED`，**不是**模块
04/07 的 canonical 1778 字节、175 字段 `ENTERPRISE-CUSTOMER` 大记录，也不是模块
11 的事故实验布局。三者物理长度与字段互不兼容，绝不可共用同一 `ENTERPRISE-CUSTOMER-Vx`
名称，否则版本标签会掩盖布局漂移。本布局与 canonical 大记录只是“同一业务概念的不同
粒度视图”，关系是：本布局第 1–27 字节逐字节等于 canonical CUSTOMER v1，其后追加
capstone 自己的区分与版本字段。真正的企业大记录维护（150+ 字段差异）在模块 07 L4 完成。
LF 不计入逻辑长度；ASCII；营业日由参数显式给出，不取机器日期。

已保证：上游按整份文件同布局投递（混合布局属结构错误）；重复
`transaction_id`、短/长记录、非法数字属必须被发现的异常。

## 3. 从干净 checkout 构建、运行、复位

```bash
cd /home/tetsuya/development/cobol
mod=curriculum/modules/12-capstone

# 可选：单独特意构建 capstone COBOL
bash "$mod/scripts/build.sh" /tmp/capstone-bin

# 正常日（v1）
bash "$mod/scripts/run.sh" --input "$mod/fixtures/normal" \
  --output /tmp/c12-normal --db /tmp/c12-db \
  --business-date 20261010 --layout v1 --run-id n1
echo "rc=$?"            # 预期 0

# 异常日（业务拒绝，仍发布）
bash "$mod/scripts/run.sh" --input "$mod/fixtures/abnormal" \
  --output /tmp/c12-abn --db /tmp/c12-db-abn \
  --business-date 20261010 --layout v1 --run-id a1
echo "rc=$?"            # 预期 4

# 字段扩展日（v2 区分，含 D1 客户）
bash "$mod/scripts/run.sh" --input "$mod/fixtures/extension" \
  --output /tmp/c12-ext --db /tmp/c12-db-ext \
  --business-date 20261010 --layout v2 --run-id e1
echo "rc=$?"            # 预期 0

# 重跑日：对同一 DB 再跑 normal 的同一 feed（新输出目录）
bash "$mod/scripts/run.sh" --input "$mod/fixtures/rerun" \
  --output /tmp/c12-rerun --db /tmp/c12-db \
  --business-date 20261010 --layout v1 --run-id r1
echo "rc=$?"            # 预期 0；apply 显示 new_transactions=0，余额不变

# 状态与复位
bash "$mod/scripts/run.sh" --input "$mod/fixtures/normal" \
  --output /tmp/c12-normal --db /tmp/c12-db --business-date 20261010 \
  --layout v1 --command status
bash "$mod/scripts/reset.sh" /tmp/c12-normal
```

会覆盖的派生文件：仅 `--output` 目录内内容。输入目录、fixtures、DB seed
**永不被覆盖**；已存在的输出目录以 RC12 拒绝。

## 4. 预期输出、RC、笔数与金额（独立核算）

`normal`：3 账户（期初 1000/50/0），6 笔全部入账。

| 指标 | normal | abnormal | extension |
|---|---:|---:|---:|
| received | 6 | 9 | 7 |
| validate 接受/拒绝 | 6/0 | 5/4 | 7/0 |
| match 接受/拒绝 | 6/0 | 4/1 | 7/0 |
| 期初 / 贷记 / 借记 / 期末 | 1050/1050/250/**1850** | 1050/900/200/**1750** | 1250/1150/250/**2150** |
| 期望 RC | 0 | 4 | 0 |

完整数值见 `expected/*.control.txt`（笔数与金额）、`expected/*.closing.txt`
（期末余额）、`expected/*.customerday.txt`（客户日报）。它们由
`instructor/modules/12-capstone/tools/gen_course.py` 的**独立 oracle**计算，
不复制任何课程实现输出（见 `expected/README.md`）。

RC：normal/rerun/extension=0；abnormal=4；`broken`（重复 transaction_id）=8
且**无正式发布**；系统失败=12 且**无正式发布**。

## 5. 需要修改哪里、哪些接口不能破坏

- 学员起点：`starter/CUSTV2.COB`（可编译，遇 v2 feed 返回 RC12、不发布）。
  补成支持 32 字节企业 v2 与 31→32 升级。
- **学员接入综合系统**：夜间链默认就编译并运行**学员自己的** `starter/CUSTV2.COB`
  （在 starter 内就地完成即可；如需用外部文件，设
  `CAPSTONE_STUDENT_CUSTV2=<你的源>` 覆盖）。JOB002c 的交易校验器同样默认用学员完成的
  模块 10 `starter/BANKVAL.COB`（或 `CAPSTONE_STUDENT_BANKVAL` 覆盖）。参考实现
  `system/cobol/CUSTV2.COB` 只在题库/讲师仓存在，**不随学生包发布**。
- 不能破坏：CUSTOMER v1 27B（第 27 字节 = 状态）/ ACCOUNT v1 47B /
  TRANSACTION v1 55B 的宽度与
  偏移；`work/`、`publish/`、`state/` 目录契约；RC 语义；幂等键
  `(business_date, transaction_id)`；`customer-day.dat` 30B 布局。
- JOB003/JOB005 复用模块 07 参考实现（不复制）；考点是**接入**（学员需先完成模块 07
  的 SORT/MERGE 实验，综合链才能排序/突合）。
- 变更包与顺序见 `maintenance/`（先影響調査，后修改）。

## 6. 故意破坏与恢复（每个实验至少一个可复现故障）

| 实验 | 破坏方式 | 现象 | 恢复 |
|---|---|---|---|
| 12.1 依赖 | 覆写某 `work/` 产物 | 后续节点语义不符 | 从快照重建派生文件 |
| 12.2 布局 | 声明 layout 与物理宽度不符 | JOB002a RC8，无发布 | 修正 layout/上游文件 |
| 12.3 崩溃 | `--crash-at {before,mid,after}-db-commit / during-publish / after-publish` | 原始 RC 97，保留现场 | 同 run-id 重跑自动恢复 |
| 12.3 重跑 | 同 DB、同营业日、新输出目录 | RC0，余额/账本不变 | — |
| 12.4 事故 | 见 `incidents/incident-01/` | JOB003 RC8，无发布 | 业务更正后重跑 |

## 7. 插件操作与纯终端替代

- 插件：用 `gd`/`:CobolGotoDef` 在 JOB 脚本与 COBOL 间跳转追依赖；对
  `COPY "CAP-CUSTOMER-FEED-V2.CPY"` 用 `:CobolGotoCopybook` 校验接口；保存 COBOL 时
  用诊断确认 72 列/Area A/B；用 Aerial 大纲看 NIGHTRPT/CUSTV2 结构。
- 纯终端替代：

```bash
rg -n 'CUSTV2_|NIGHTRPT_|c12_step|duplicate transaction' \
  curriculum/modules/12-capstone
od -An -tc curriculum/modules/12-capstone/fixtures/extension/customer.dat | head
cut -b 11-26 curriculum/modules/12-capstone/fixtures/broken/transaction.dat \
  | sort | uniq -d
```

## 8. 需要交什么证据、什么算失败

按 [evidence/README.md](evidence/README.md) 提交四类日、五类崩溃边界、事故
调查的原始命令与 RC。判为**失败**：任何 JOB 失败却产生正式发布；同日重跑
重复扣款；崩溃恢复后 DB/账本/文件/状态不一致；把旧 `publish/<run_id>` 冒充
本次；把系统失败落成业务拒绝；声称真实 DB 已验证。

## 验收自检

```bash
bash curriculum/modules/12-capstone/scripts/check.sh
```

（讲师评分器仅存在于讲师仓，不随学生包发布：`instructor/modules/12-capstone/grading/grade.py`。）

`check.sh` 覆盖四类日、layout 守卫、重跑幂等、五类崩溃恢复、锁/no-clobber、
系统失败、控制门禁、starter 与 RED→GREEN。

## 规模

陌生系统规模**不**以仓库总行数宣布。去重的系统组成、JOB/程序/COPY/表的使用关系、
统计方法与**实事求是的差距**见 [COMPOSITION.md](COMPOSITION.md)：

- **实际运行依赖（去重）**：5 个 COBOL / 1,640 行、23 个 capstone Copybook、
  17 个 capstone Shell、32 个 JOB 节点、12 个逻辑表。
- **独立教学参考（不被本模块编排）**：`instructor/` 下共 23 个 `.COB`（11,612 行），
  其中仅 3 个被 capstone 调用。
- **差距（如实记录）**：相对 `AUTHORING-STANDARD §6` 的约 8,000 行有意义 COBOL 目标，
  本模块**实际运行** COBOL 为 1,640 行，差距约 -6,360 行；Copybook/Shell/JOB/表达标。
  本模块是编排/维护型毕业项目，不靠灌水凑行数；该差距供主代理裁定。
