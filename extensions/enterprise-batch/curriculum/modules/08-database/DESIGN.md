# 模块08 设计：COBOL + 真实数据库

本文件说明模块08 的 schema、金额类型、schema 版本、幂等键与事务边界。字段契约冻结自
[银行系统设计](../../../docs/curriculum/BANK-SYSTEM.md)：CUSTOMER v1 = 27B、ACCOUNT v1 =
47B、TRANSACTION v1 = 55B。

## 1. 工具链（经 P1 验证，未修改 P1）

| 组件 | 版本/固定点 | 说明 |
|---|---|---|
| OS 镜像 | `debian:13-slim@sha256:a29215f6…` | 与 P1 相同 digest |
| GnuCOBOL | 3.2.0（Debian 包 `gnucobol3`） | 默认方言，不用 `-std=cobol85` |
| GixSQL | commit `69e26719ecaca2c31bdf91d7add270b1c0ce2286` | 预编译器 `gixpp` + `libgixsql` |
| PostgreSQL | `postgres:17@sha256:e3841145…` | 建议基线，课程仅此版本实测 |
| 本地补丁 | `gixsql-cursor-null.patch`、`gixsql-closed-cursor.patch` | 模块08 `db/Dockerfile` 直接引用 P1 同名补丁 |

`db/Dockerfile` 与 P1 `curriculum/validation/database/Dockerfile` 指令一致，
`scripts/docker-image.sh` 从 P1 目录复制两份补丁组装构建上下文，**不修改 P1 文件**。
构建产物镜像 `cobol-course-gixsql:m08` 与 P1 镜像共享层。`scripts/check.sh` 记录
`p1-patches.sha256` 作为补丁回归证据。仅 Linux x86-64 实测。

## 2. 逻辑表（db/schema.sql，schema_version = 001）

课程逻辑表：`customer`、`account`、`account_balance`、`transaction_ledger`、
`batch_run`、`batch_commit`，另有 `schema_version` 与教学用 `probe_null`。

| 表 | 关键列 | 约束/说明 |
|---|---|---|
| `customer` | `customer_id CHAR(8) PK`, `customer_name VARCHAR(10)`, `balance_demo NUMERIC(8,0)`, `status CHAR(1)`, `contact_note VARCHAR(20)`, `business_date CHAR(8)`, `layout_version` | 映射 CUSTOMER v1 27B；`business_date` 是快照维度，不入 27B 文件 |
| `account` | `account_id CHAR(10) PK`, `customer_id FK`, `currency`, `balance_sign`, `opening_balance NUMERIC(13,0)`, `closing_balance NUMERIC(13,0)`, `account_status`, `business_date`, `layout_version` | 映射 ACCOUNT v1 47B；期初与期末分离 |
| `account_balance` | `account_id PK`, `balance NUMERIC(13,0)` | 逐账户累计，供独立核对 |
| `transaction_ledger` | `transaction_id CHAR(16)`, `account_id`, `business_date`, `sequence_no`, `direction`, `amount NUMERIC(13,0)`, `status`, `applied_run_id`, **UNIQUE(business_date, transaction_id)** | 映射 TRANSACTION v1 55B；唯一业务键即幂等键 |
| `batch_run` | `run_id PK`, `business_date`, `status` | 每次尝试一行 |
| `batch_commit` | `business_date PK`, `run_id`, `applied_count` | 业务日只成功提交一次 |

### 金额类型

金额一律是最小单位整数（首期 JPY=1 円），使用 `NUMERIC(x,0)`，**绝不用浮点**。
文本接口（47B/55B）中的金额是 13 位右对齐零填充十进制字符串，进入 COBOL 后按
`PIC 9(13)` 处理，再绑定到 DB 的 `NUMERIC(13,0)`。不做隐式换汇。

### schema 版本

`schema_version` 表存储 `'001'`。抽取快照时把 `SCHEMA_VERSION=001` 与
`LAYOUT_VERSION=001` 一同写入元数据；版本不匹配属结构错误（RC8）。

## 3. 幂等键与重跑

- 交易幂等键：`(business_date, transaction_id)`，即 `transaction_ledger` 唯一约束。
- 业务日提交键：`batch_commit.business_date`（主键）。
- 重跑语义：同一业务日的第二次运行对每条交易触发 `23505`（唯一冲突），程序
  `ROLLBACK TO SAVEPOINT` 后读取既有行的 `applied_run_id`：
  - 等于本次 `run_id` → 本次运行内重复输入 → **RC8**，整批回滚；
  - 不等 → 历史运行已记账 → **SKIP**，不重复扣款。
  `batch_commit` 重复插入同样 `23505`，标记 `DAY-ALREADY-COMMITTED` 但不失败。
- 提交结果不明（提交后调用方认为失败）：重跑用**独立连接**核对
  `account.closing_balance`、`transaction_ledger` 行数与 `batch_commit` 行数不变，
  证明未重复应用。

## 4. 事务边界与故障

- 连接显式 `autocommit=off`；PostgreSQL 原生游标需要显式事务块。
- 每条交易包在 `SAVEPOINT SP1` 中：插入唯一键冲突时 `ROLLBACK TO SAVEPOINT`
  恢复事务，再分类重复类型（这是 PostgreSQL “语句失败即中止整个事务”下唯一
  正确的局部恢复方式）。
- `batch_commit` 用 `SAVEPOINT SP2` 包住，`23505` 时局部回滚。
- 正常路径末尾 `COMMIT WORK`；`rollback` 模式、运行内重复与结构错误走 `ROLLBACK WORK`。
- 连接失败：错误端口得到 SQLSTATE `08001`（连接类 08）→ 程序 RC12。
- 游标路径区分“无数据”与“错误”：`FETCH`/`SELECT INTO` 耗尽为 `02000`；其它
  SQLSTATE 视为错误。约束错误用 `23514` 演示真实错误类别。

## 5. RC 约定

| RC | 含义 | 发布 |
|---:|---|---|
| 0 | 无业务差异 / 提交成功 / 重试跳过 | 是 |
| 4 | 快照与上游存在业务差异 | 是（差异报告随附） |
| 8 | 结构错误 / 运行内重复交易 | 否（回滚） |
| 12 | 构建、连接、SQL 系统错误、核对失败、发布失败 | 否 |

## 6. 已知限制（不宣称已验证）

- 仅 Linux x86-64；macOS/WSL/ARM 未验证。
- 仅为 PostgreSQL 17 的错误码；`23505`/`23514`/`02000`/`08001` 等为 PostgreSQL 语义，
  **不得**直接映射为 DB2 的 `-803` 等主机错误码。
- 未做真实网络断线中断与并发锁竞争；仅做“错误端口连接失败”与提交后重跑幂等。
- 快照与 SAVEPOINT 行为依赖 GixSQL 固定 commit + 两个本地补丁；换版本需重新验证。
