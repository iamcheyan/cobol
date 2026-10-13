# 维护变更包：企业客户区分 1 位 → 2 位

本目录是 `AUTHORING-STANDARD` 第 6 节要求的 Legacy Maintenance 变更包。
变更**先调查后修改**：下面的顺序即提交顺序，评审通过后才能动代码。

| 顺序 | 文件 | 交付物 |
|---:|---|---|
| 1 | [impact-investigation.md](impact-investigation.md) | 影響調査書 |
| 2 | [change-list.md](change-list.md) | 修正対象一覧 |
| 3 | [change-policy.md](change-policy.md) | 修正方針（布局 v1/v2、兼容、迁移、回滚） |
| 4 | [test-cases.md](test-cases.md) | Test Case |
| 5 | [evidence-plan.md](evidence-plan.md) | Evidence 计划 |
| 6 | [copybooks/CAP-CUSTOMER-FEED-V2.CPY](copybooks/CAP-CUSTOMER-FEED-V2.CPY) | 冻结接口 v2（32 字节） |
| 7 | [regression/red-green.sh](regression/red-green.sh) | 修改前后回归（RED→GREEN） |

需求（原文）：**客户区分由 1 位扩展为 2 位。**

## 变更对象：独立、版本化的企业客户布局

变更对象**不是** 27 字节的 canonical CUSTOMER v1。该冻结接口的第 27 字节是
**记录状态 status**（A 有效 / D 停用），与客户区分无关，本仓库**不改动**
（见 [curriculum/bank/README.md](../../../bank/README.md) 与
[BANK-SYSTEM.md 第 2 节](../../../../docs/curriculum/BANK-SYSTEM.md)）。

客户区分住在**独立的、版本化的 capstone 客户 feed** 里，命名为
`CAP-CUSTOMER-FEED`。它**刻意不与**模块 04/07 的 canonical 1778 字节、
175 字段 `ENTERPRISE-CUSTOMER` 大记录共用名称：二者物理长度与字段互不
兼容，共用同名会让版本标签掩盖布局漂移（模块 11 的实验布局同理另名）。

| 布局 | 版本 | 宽度 | `CUSTOMER-CLASSIFICATION` | 取值 |
|---|---|---:|---|---|
| CAP-CUSTOMER-FEED v1 | `001` | 31 B | `PIC X(1)` | `A`/`B`/`C`/`D` |
| CAP-CUSTOMER-FEED v2 | `002` | 32 B | `PIC X(2)` | `A1`/`B1`/`C1`/`D1` |

企业布局**内嵌** canonical 27 字节 CUSTOMER v1（第 1–27 字节），因此第 27 字节
仍是记录状态；区分是其后追加的独立字段。

参照接口：`system/copybooks/CAP-CUSTOMER-FEED-V1.CPY`（31 字节）与
`system/copybooks/CAP-CUSTOMER-FEED-V2.CPY`（32 字节）；canonical
`system/copybooks/CUSTOMER-V1.CPY`（27 字节，第 27 字节 = status）保持不动。
