# 银行 canonical 接口（单一来源）

本目录是全部模块共用的**冻结银行接口**的 canonical 定义。任何实验、课程或
JOB 都必须复用这里的定义或按版本引用，**不得各自复制出漂移的同名接口**。字段
语义与字节布局以 [BANK-SYSTEM.md](../../docs/curriculum/BANK-SYSTEM.md) 为准。

| 文件 | 记录 | 宽度 | 说明 |
|---|---|---:|---|
| [ACCOUNT-V1.CPY](copybooks/ACCOUNT-V1.CPY) | ACCOUNT v1 | 47 B | 账户主档；account_id/customer/currency/sign/opening_balance/status/date/version |
| [TRANSACTION-V1.CPY](copybooks/TRANSACTION-V1.CPY) | TRANSACTION v1 | 55 B | 当日交易；account/txid/date/sequence/direction/amount/status |
| [CUSTOMER-V1.CPY](copybooks/CUSTOMER-V1.CPY) | CUSTOMER v1 | 27 B | 客户基础教学对象；id/name/balance_demo/**status** |

文本定宽接口使用 ASCII，每条逻辑记录后跟 LF，LF 不计入记录长度；金额为明确的
最小单位整数；日期为 `YYYYMMDD` 并按课程日历校验。

## 关于“客户区分 1 位 → 2 位”维护

CUSTOMER v1 的第 27 字节是**记录状态 status**（A 有效 / D 停用），**不是**客户
区分（distinction/classification）。BANK-SYSTEM 第 2 节明确：现有 27 字节
CUSTOMER 中**没有**客户区分字段，维护课必须**先定义独立、版本化的企业客户布局
及其 1 位基线**，保留 27 字节教学接口，说明两者关系后再做 v2 迁移；**不得把
状态字段擅自当客户区分**。

本仓库既有的合法先例是模块 07 L4 的 `ENTERPRISE-CUSTOMER-V1`（1778 字节固定
二进制），其 `CUSTOMER-CLASSIFICATION` 在 v1 为 `PIC X(1)`（A/B/C/D），在 v2
加宽为 `PIC X(2)`（A1/B1/C1/D1），布局版本 001→002。模块 11/12 的客户区分维护
练习必须引用这样一个**独立版本化企业布局**（可复用或对齐该命名/版本约定），
而不是改写 CUSTOMER v1 的第 27 字节。

## 解释器实测摘要（Linux x86-64 / GnuCOBOL 3.2.0）

- `ACCOUNT-V1` = 47 B，`TRANSACTION-V1` = 55 B，`CUSTOMER-V1` = 27 B（`LENGTH OF` 实测）。
- PIC COMP 实测 big-endian；COMP-5 native little-endian；COMP-3 每半字节校验、
  仅接受 C/D 符号。二进制/ Packed 原始字节不得当文本解析。
