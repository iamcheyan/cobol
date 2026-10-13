# 影響調査書：企业客户区分 1 位 → 2 位

调查日期：20261010（先于任何代码修改）。所有结论来自只读检索与字节核对。

## 1. 需求

把**企业客户区分**从 1 位扩为 2 位。区分住在独立的、版本化的
`CAP-CUSTOMER-FEED` 布局里。该布局内嵌 canonical 27 字节 CUSTOMER v1
（第 27 字节 = 记录状态 status），**区分是紧随其后的独立字段**：

- v1（31 字节，layout `001`）：区分在**第 28 字节**，取值 `A`/`B`/`C`/`D`。
- v2（32 字节，layout `002`）：区分在**第 28–29 字节**，取值 `A1`..`D1`。

变更使企业布局记录由 31 字节变为 **32 字节**。canonical CUSTOMER v1 的
27 字节与第 27 字节语义**完全不动**。

## 2. 字段定义（调查起点）

| 布局 | 位置 | 长度 | 名称 | 规则 |
|---|---|---|---:|---|---|
| v1 | 27 | 1 | record_status | `A` 有效 / `D` 停用 |
| v1 | 28 | 1 | customer_classification | `A`/`B`/`C`/`D` |
| v1 | 29-31 | 3 | layout_version | `001` |
| v2 | 27 | 1 | record_status | `A`/`D`（不变） |
| v2 | 28-29 | 2 | customer_classification | `A1`/`B1`/`C1`/`D1` |
| v2 | 30-32 | 3 | layout_version | `002` |

区分在**记录内第 27 字节之后**，加宽只影响其后的偏移与总长；第 1–27 字节
（含状态）偏移不变，因此"只读企业布局前 27 字节"的旧读者仍读到正确的
CUSTOMER v1 前缀。这是选择"追加而非改写"布局的原因。

## 3. 使用位置（检索命令与命中）

```bash
rg -n 'customer|CUSTOMER|classification|CLASSIFICATION|status' \
  curriculum/modules/12-capstone/system \
  curriculum/modules/12-capstone/maintenance \
  curriculum/modules/12-capstone/fixtures
```

命中并分类：

| 位置 | 用法 | 影响 |
|---|---|---|
| `system/copybooks/CUSTOMER-V1.CPY` | canonical 接口定义（27B，第 27 字节 = status） | **不改** |
| `system/copybooks/CAP-CUSTOMER-FEED-V1.CPY` | 企业布局 v1（31B） | 参考基线 |
| `system/copybooks/CAP-CUSTOMER-FEED-V2.CPY` | 企业布局 v2（32B） | 新交付 |
| `system/cobol/CUSTV2.COB` | 读入并归一化企业客户 | 需支持 32B 与 31→32 升级 |
| `system/cobol/NIGHTRPT.COB` | 客户日报 join | 需按 declared layout 校验宽度 |
| `system/lib/capdb.py` | 客户表/快照（v2 存储） | customer.table 改存 32B |
| `system/lib/validate.py` | 原始字节宽度守卫 | 企业布局宽度 31/32 |
| `system/jobs/job002-validate.sh` | 调用 CUSTV2 | 无改动，随 CUSTV2 |
| `fixtures/*/customer.dat` | 合成输入 | 重新生成 31B/32B |
| `incidents/incident-01` | 事故材料 | 客户文件同布局，但不得回退 |

## 4. 依赖图

```mermaid
flowchart LR
  UP[上游 enterprise customer extract] -->|v1/v2| J1[JOB001 接收]
  J1 --> J2[JOB002d CUSTV2 归一化 v2]
  J2 --> DB[(customer.table v2)]
  J2 --> J7[JOB007 NIGHTRPT 客户日报]
  DB --> J7
  J7 --> DOWN[customer-day.dat 下游]
```

## 5. 未知项（必须由证据消除）

- 上游是否可能同时送 v1 与 v2（混合投递）？——本课程按"整份文件同布局"处理，
  混合投递在 JOB002a 以宽度不符拒绝（RC8），列为显式边界。
- 下游是否消费 v1 旧视图？——`NIGHTRPT` 同时支持 v1/v2 读取，v1 日仍可用。
- DB 中已存在的 31B 客户行如何迁移？——见 change-policy 的迁移步骤。

## 6. 结论

改动面：2 个 COBOL、1 个 DB 存储、若干接口/夹具/JOB 说明；**不改** 06/07/10
canonical 组件，也**不改** canonical CUSTOMER v1 的 27 字节或第 27 字节状态
语义。风险集中在"宽度来源"和"v1 兼容"。
