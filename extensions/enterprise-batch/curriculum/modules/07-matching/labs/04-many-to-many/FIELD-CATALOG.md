# 07.5 文件字段目录

所有文本文件为ASCII、LF结尾，LF不计字段宽度；不得CRLF、短行、长行、缺末尾LF或控制字符。金额为JPY整数最小单位，不是浮点或小数元。既有 `ACCOUNT-V1.CPY` / `TRANSACTION-V1.CPY` 不修改。新增布局分别版本化，不重定义BANK-SYSTEM中27B CUSTOMER v1教学记录。

## CUSTOMER-SNAPSHOT v1（36B）

唯一键：customer_id；严格升序，每客户最多一行。该离线文件是模块08真实DB抽取前的固定种子快照，不代表数据库连接或一致性读取已完成。

| 字节 | 宽度 | 字段 | 规则/使用 |
|---:|---:|---|---|
| 1–8 | 8 | customer_id | ASCII数字，非空唯一，关联ACCOUNT customer_id |
| 9–16 | 8 | snapshot_business_date | 有效Gregorian YYYYMMDD，必须等于作业日 |
| 17–19 | 3 | layout_version | 仅`001` |
| 20 | 1 | customer_status | `A`有效；`D`停用，业务隔离 |
| 21–23 | 3 | max_account_count | ASCII数字；客户关联账户数上限。计数包含所有账户状态A/F/C的Master记录 |
| 24–36 | 13 | max_customer_balance | ASCII数字；客户总期末余额上限，JPY整数 |

物理记录宽度36B；COBOL布局由 `copybooks/CUSTOMER-SNAPSHOT-V1.CPY` 定义，字段总长由编译期 `LENGTH OF` 及检查器实测。

## PREVIOUS-DAY v1（39B）

唯一键：customer_id；严格升序，每客户最多一行。日期必须是作业营业日之前一个真实Gregorian日历日，不考虑周末/日本银行假日。昨日摘要为该客户所有关联账户（A/F/C全部状态）的合计，不可逐账户重复套用。

| 字节 | 宽度 | 字段 | 规则/使用 |
|---:|---:|---|---|
| 1–8 | 8 | customer_id | ASCII数字，非空唯一 |
| 9–16 | 8 | previous_business_date | 有效Gregorian YYYYMMDD，等于job日的前一calendar day |
| 17–19 | 3 | layout_version | 仅`001` |
| 20–25 | 6 | account_count | ASCII数字，昨日客户关联账户数，包含所有账户状态A/F/C |
| 26 | 1 | closing_sign | `+`或`-`，负值仅用于总余额 |
| 27–39 | 13 | closing_total | ASCII数字，昨日客户汇总期末余额 |

物理记录宽度39B；COBOL布局由 `copybooks/PREVIOUS-DAY-V1.CPY` 定义，字段总长由编译期 `LENGTH OF` 及检查器实测。

## 四个业务流与来源

| 流 | 上游接口 | 排序/基数 | 本阶段作用 |
|---|---|---|---|
| ACCOUNT | canonical v1 47B | account_id唯一升序；同customer可多账户且customer_id不保证随account_id单调 | 当前期初、customer关联；与L2候选master逐账户核对 |
| TRANSACTION | canonical v1 55B + 独立REVERSAL-LINK v1 | account/sequence/id严格序；id全局唯一；0..N/账户 | 原始交易先送真实L2，L3只消费L2 accepted流并保留L2 rejects/控制 |
| CUSTOMER-SNAPSHOT | 本课v1 36B | customer_id唯一升序 | 状态、账户数上限、期末总余额上限；离线DB快照种子 |
| PREVIOUS-DAY | 本课v1 39B | customer_id唯一升序 | 昨日期末客户账户数量/余额总计 |
