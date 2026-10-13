# 契约纠错证据：CUSTOMER 状态 vs 企业客户区分（2026-10-10）

纠正一个**冻结契约违规**：模块 12 曾把 27 字节 CUSTOMER v1 的**第 27 字节**
（契约规定为**记录状态 status**，A 有效 / D 停用）当作**客户区分**，并在维护
练习里把它扩成 2 位。现改为：第 27 字节恢复为 status；"客户区分 1→2 位"维护
作用于**独立、版本化的 CAP-CUSTOMER-FEED 布局**。

契约来源：[BANK-SYSTEM.md 第 2 节](../../../../docs/curriculum/BANK-SYSTEM.md)、
[curriculum/bank/README.md](../../../bank/README.md)。

## 1. 修正前后对照

### 1.1 Canonical CUSTOMER v1（27 字节）

| | 修正前 | 修正后 |
|---|---|---|
| 第 27 字节 | `distinction`（被当客户区分） | **`CUSTOMER-STATUS`（A/D 记录状态）** |
| 与 canonical 一致 | 否（违规） | 是 |

修正后 `system/copybooks/CUSTOMER-V1.CPY` 字段：
`CV1-CUSTOMER-ID X(8)` + `CV1-CUSTOMER-NAME X(10)` +
`CV1-BALANCE-DEMO X(8)` + `CV1-CUSTOMER-STATUS X(1)` = **27 B**（未变宽）。

### 1.2 客户区分 1→2 位：作用于独立企业布局

| | 修正前 | 修正后 |
|---|---|---|
| 承载对象 | `CUSTOMER-V2.CPY`（改写 CUSTOMER 的第 27 字节语义） | `CAP-CUSTOMER-FEED-V1/V2.CPY`（独立、版本化企业布局） |
| 分类字段 | `CV2-DISTINCTION X(2)`，取值 `[AD][0-9]` | `CUSTOMER-CLASSIFICATION`：v1 `X(1)` A/B/C/D → v2 `X(2)` A1..D1 |
| 布局版本 | 无 | `LAYOUT-VERSION` `001` → `002` |
| 记录宽度 | 27 → 28 B（直接改 CUSTOMER） | 31 → 32 B（企业布局；CUSTOMER v1 不动） |
| 状态 vs 分类 | 混为同一个第 27 字节 | 分离：第 27 字节 status；分类在其后 |
| 与模块 07 L4 命名/版本 | 不对齐 | 对齐（`CUSTOMER-CLASSIFICATION`、`LAYOUT-VERSION`、A→A1..D→D1） |

企业布局**内嵌** canonical CUSTOMER v1（第 1–27 字节），因此第 27 字节仍是
status；分类字段位于字节 28（v1）/ 28-29（v2）。

### 1.3 可观测输出

| | 修正前 | 修正后 |
|---|---|---|
| `customer.dat` normal/abnormal/rerun/broken | 27 B `...00000100A` | 31 B `...00000100AA001`（status A，class A，ver 001） |
| `customer.dat` extension | 28 B `...00000000D1` | 32 B `...00000000DD1002`（status D，class D1，ver 002） |
| `customer-day.dat` normal 分类 | `A0` | **`A1`** |
| `customer-day.dat` extension 分类 | `A1`/`D1` | `A1`/`D1` |
| 拒绝码 | `BADDIST` | `BADSTATUS` / `BADCLASS` / `BADVERSION` |

## 2. 字节级实测（Linux x86-64 / GnuCOBOL 3.2.0）

```bash
# 企业布局宽度由 grade.py 的 copybook 宽度探针独立核对：
#   CUSTOMER-V1.CPY=27, CAP-CUSTOMER-FEED-V1.CPY=31,
#   CAP-CUSTOMER-FEED-V2.CPY=32, ACCOUNT-V1.CPY=47, TRANSACTION-V1.CPY=55
python3 curriculum/modules/12-capstone/system/lib/validate.py length \
  --tx curriculum/modules/12-capstone/fixtures/extension/transaction.dat \
  --customer curriculum/modules/12-capstone/fixtures/extension/customer.dat \
  --layout v2
# -> tx_records=7 tx_width=55 customer_records=3 customer_width=32
```

## 3. 修正后真实命令与原始 RC

| 命令 | 原始 RC |
|---|---:|
| `bash curriculum/modules/12-capstone/scripts/check.sh` | 0 |
| `python3 instructor/modules/12-capstone/grading/grade.py` | 0（100/100，硬门禁全 PASS） |
| normal（v1） | 0；customer-day `A1` |
| abnormal（v1） | 4 |
| extension（v2） | 0；customer-day 含 `D1` |
| broken | 8，不发布 |
| rerun（同 DB 同 feed） | 0，`new_transactions=0`，账本 6 行不变 |
| crash-at ×5 | 97 → 恢复 0，账本 6，CURRENT 正确 |
| RED→GREEN | RED=12（不发布），GREEN=0 |
| incident reproduce | 8，不发布 |
| incident recovery（业务更正） | 0，账本 6，合计 1850，原输入未改 |

`check.sh` 输出：
`PASS: module 12 capstone -- 4 day types, guard, rerun, recovery, locks, control gate, starter, RED->GREEN`

## 4. 更新范围

- Copybook：`CUSTOMER-V1.CPY`（第 27 字节 status）、新增
  `CAP-CUSTOMER-FEED-V1/V2.CPY`、`CUSTOMER-DAY-V1.CPY`、`CUSTV2-CONTROL.CPY`、
  `NIGHTRPT-CONTROL.CPY`、`DB-CUSTOMER-ROW.CPY`、`DB-CUSTOMER-SNAPSHOT-ROW.CPY`；
  删除错误的 `CUSTOMER-V2.CPY`。
- COBOL：`CUSTV2.COB`（读企业 v1/v2，校验 status+class+version，归一 v2）、
  `NIGHTRPT.COB`（宽度守卫 31/32，输出企业分类）、`starter/CUSTV2.COB`。
- lib/JOB：`validate.py`、`capdb.py`、`report.py`、`job002`、`job009`。
- fixtures/expected/SHA256SUMS、incident feed/MANIFEST/MANIFEST.sha256。
- maintenance 变更包（影響調査/対象/方針/Test/Evidence/patch/red-green）。
- README/DESIGN/grading/GRADING、讲师 INSTRUCTOR 与证据。

## 5. 残余限制

- DB 层仍是离线文件检查点；真实 PostgreSQL/Embedded-SQL 未接入、未验证。
- 企业布局 `CAP-CUSTOMER-FEED` 仅在本模块定义（内嵌 canonical CUSTOMER v1 的
  独立 small layout），**刻意不复用**模块 07 L4 的 1778 字节 / 175 字段
  `ENTERPRISE-CUSTOMER` 名称，以免版本标签掩盖物理布局漂移；二者是不同粒度视图，
  非同一物理接口。
- 模块 11（incidents）存在同类"第 27 字节当分类"的做法，但**超出本任务边界**，
  本次不改。
