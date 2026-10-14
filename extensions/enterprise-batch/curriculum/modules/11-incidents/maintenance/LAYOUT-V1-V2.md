# 企业客户区分 1 位 → 2 位：接口变更规格（给定）

对象是模块 11 的**独立、版本化企业客户布局** `ENTERPRISE-CLASS`，
**不是** 27 字节 canonical CUSTOMER v1（其第 27 字节是记录状态 A/D）。

> **命名与关系（避免同名漂移）**：课程 canonical 的大记录是模块 07 L4 的
> `ENTERPRISE-CUSTOMER-V1`（175 字段 / 1778 字节）。本练习布局**刻意用
> 独立名称** `ENTERPRISE-CLASS`（23→24 字节），只保留同一 `CUSTOMER-
> CLASSIFICATION` 字段语义，**不复用 canonical 名称**，以免同名却布局不同。

## 1. 布局对照

| 项 | V1（现状，基线） | V2（目标） |
|---|---|---|
| 布局版本 | `001` | `002` |
| 记录宽 | **23 字节** | **24 字节** |
| 客户区分字段 | `CUSTOMER-CLASSIFICATION PIC X(1)` | `CUSTOMER-CLASSIFICATION PIC X(2)` |
| 区分取值 | `A` / `B` / `C` / `D` | `A1` / `B1` / `C1` / `D1` |
| 映射 | — | `A→A1`、`B→B1`、`C→C1`、`D→D1` |

基线定义：`maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY`。

## 2. 字节偏移（1 起算）

| 字节 | V1 长度 | V2 长度 | 字段 |
|---:|---:|---:|---|
| 1–3 | 3 | 3 | `LAYOUT-VERSION`（`001`→`002`） |
| 4–11 | 8 | 8 | `CUSTOMER-ID` |
| 12 | 1 | 1 | `RECORD-STATUS`（A 有效 / I 停用） |
| 13–22 | 10 | 10 | `CUSTOMER-NAME` |
| 23 | 1 | — | `CUSTOMER-CLASSIFICATION`（V1 1 位） |
| 23–24 | — | 2 | `CUSTOMER-CLASSIFICATION`（V2 2 位） |

**关键影响**：区分字段位于记录**末尾**，加宽只使记录变长（+1 字节），
V2 中区分之前的所有字段偏移不变；但**记录总长变化**会影响按定长读取的
文件、文件头/尾处理、校验和、以及下游按字节切片的消费方。`RECORD-STATUS`
是另一业务语义，**不能**被误用成客户区分。

## 3. 兼容与迁移约束

- **V1 文件不得原地改写**：迁移工具写**新文件**（V2），保留原件用于
  并行验证与回滚。
- 读取程序必须按**版本**选择宽度：`001` → 23 字节；`002` → 24 字节；
  遇到不匹配宽度/版本必须 `RC8` 中止，不得静默补齐/截断。
- 下游接口（`CLASS|<id>|<class>`）需版本化：V1 的 class 为 1 字符，
  V2 为 2 字符；切换期间两版需可区分。
- 回滚：V2 → V1 必须无损（要求 V2 第 2 字符为 `1`），且能字节级还原
  原始 V1。

## 4. 需覆盖的外部接口与下游（调查清单，不限于此）

- `maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY`（基线接口定义）
- 企业区分读取/抽取程序（参考 `M11CUST2.COB`）
- `migrate-customer.py`（迁移/回滚/并行验证）
- 下游企业区分抽取（`CLASS|<id>|<class>`）
- `fixtures/enterprise-customer/customer.v1`（V1 输入）
- DB：本课程快照为离线检查点（真实 DB 未验证）；若存在真实 DB 列，
  需评估列宽/迁移，并标注未验证。
- **不受影响**：canonical CUSTOMER v1（27 字节，第 27 字节为状态）；
  夜间流 `M11CUST.COB` 与 `publish/<run_id>/customer-status.txt`。
- 文档：`../../../../docs/curriculum/BANK-SYSTEM.md`（冻结契约的演进说明）
