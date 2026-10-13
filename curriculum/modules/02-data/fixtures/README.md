# 模块 02 合成输入

所有文件为 ASCII 文本、LF 终止，每条逻辑记录 27 字节（与
[银行系统设计](../../../docs/curriculum/BANK-SYSTEM.md) 的 CUSTOMER v1 相同），
LF 不计入记录长度。名称字段先限制 ASCII，避免把字符数误当字节数。可用
`python3 scripts/generate-fixtures.py` 确定性重建；该脚本只生成字节，不实现装载/校验逻辑。
`SHA256SUMS` 覆盖本目录全部文件。

| 路径 | 目的 | 预期 |
|---|---|---|
| `normal/customer.dat` | 3 条合法客户（A/D 两种状态） | RC0，全部接收，余额合计 10012394 |
| `boundary/empty.dat` | 0 字节（允许空文件） | RC0，读入 0 条 |
| `boundary/single.dat` | 只有一条记录（最后一条） | RC0 |
| `boundary/max-balance.dat` | balance_demo 取 8 位最大 99999999 | RC0 |
| `boundary/name-full.dat` | 名称正好 10 字符 | RC0 |
| `boundary/no-final-lf.dat` | 最后一条后缺 LF | RC8，不发布 |
| `invalid/short.dat` | 26 字节短记录 | RC8，不发布 |
| `invalid/long.dat` | 28 字节长记录 | RC8，不发布 |
| `invalid/crlf.dat` | 记录行以 CRLF 结束 | RC8，不发布 |
| `invalid/bad-id.dat` | 客户 ID 含非数字 | RC8，不发布 |
| `invalid/duplicate-id.dat` | 两条相同客户 ID | RC8，不发布 |
| `invalid/unsorted.dat` | 客户 ID 倒序 | RC8，不发布 |
| `invalid/name-missing.dat` | 名称全空格 | RC4，原因 `NAME-MISSING` |
| `invalid/bad-amount.dat` | balance_demo 含非数字 | RC4，原因 `BAD-AMOUNT` |
| `invalid/unknown-status.dat` | 状态为 Z | RC4，原因 `UNKNOWN-STATUS` |
| `types/typeinput.dat` | 类型实验输入：3 条 5 字节记录 `ABCDE`/`AB123`/`AB CD` | `TYPESLAB` 逐字节匹配 `expected/typeslab.txt` |

RC8 夹具没有正式 expected 报告，因为契约要求整批失败、不发布输出目录。绝不在运行器中改写源夹具。
`types/typeinput.dat` 是 5 字节/条的行式输入，供 `experiments/types/TYPESLAB.COB` 使用，不属于
CUSTOMER v1 27 字节契约。
