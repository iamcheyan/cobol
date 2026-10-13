# TRANSACTION v1 固定字段目录

规范源文件：[TRANSACTION-V1.CPY](../../../../../bank/copybooks/TRANSACTION-V1.CPY)。SORT 与 MERGE 的 SD 记录直接 `COPY` 此版本；不得为课程复制或另造一份字段定义。输入/输出是55个ASCII字节，行结束LF不计入记录长度。

| 字节（1起） | 字段 | PIC | 契约 |
|---|---|---|---|
| 1–10 | TX-ACCOUNT-ID | X(10) | ASCII数字 |
| 11–26 | TRANSACTION-ID | X(16) | ASCII `A-Z` / `0-9`；全局唯一 |
| 27–34 | TRANSACTION-DATE | X(8) | 必须等于JOB业务日，并为Gregorian有效日期 |
| 35–40 | TRANSACTION-SEQUENCE | X(6) | ASCII数字；排序键第二段 |
| 41 | TRANSACTION-DIRECTION | X | `C`或`D` |
| 42–54 | TRANSACTION-AMOUNT | X(13) | ASCII数字；零合法，留待下游业务规则分类 |
| 55 | TRANSACTION-STATUS | X | 仅`N`；冲正关系在独立REVERSAL-LINK v1中表达 |

排序全键为(account 1–10, sequence 35–40, ID 11–26)，每个组件升序。MERGE源严格升序；同账户同sequence但ID不同的记录合法。
