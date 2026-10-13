# 模块 01 合成输入

所有文件为 ASCII 文本、LF 终止，每条逻辑记录 47 字节（与
[银行系统设计](../../../docs/curriculum/BANK-SYSTEM.md)的 ACCOUNT v1 相同），
LF 不计入记录长度。固定营业日 20261009。可用
`python3 scripts/generate-fixtures.py` 确定性重建；该脚本只生成字节，不实现任何批处理逻辑。
`SHA256SUMS` 覆盖本目录全部文件。

| 路径 | 目的 | 预期 |
|---|---|---|
| `normal/account.dat` | 3 条合法账户（A/F/C 三种状态） | RC0，全部接收 |
| `boundary/empty.dat` | 0 字节输入（契约允许的空文件） | RC0，读入 0 条 |
| `boundary/single.dat` | 只有一条记录（最后一条） | RC0，读入 1 条 |
| `boundary/no-final-lf.dat` | 最后一条记录后缺 LF | RC8，不发布 |
| `invalid/short.dat` | 46 字节短记录 | RC8，不发布 |
| `invalid/long.dat` | 48 字节长记录 | RC8，不发布 |
| `invalid/crlf.dat` | 记录行以 CRLF 结束 | RC8，不发布 |
| `invalid/bad-id.dat` | 账号含非数字字符 | RC8，不发布 |
| `invalid/bad-layout.dat` | 布局版本为 002 | RC8，不发布 |
| `invalid/bad-date.dat` | 记录日期与营业日不一致 | RC8，不发布 |
| `invalid/duplicate-id.dat` | 两条相同账号（重复键） | RC8，不发布 |
| `invalid/unsorted.dat` | 账号倒序 | RC8，不发布 |
| `invalid/unknown-status.dat` | 状态为 Z 的未知状态 | RC4，发布拒绝明细 |

RC8 夹具没有 `expected/` 正式报告，因为契约要求整批失败、不发布任何输出目录。
业务拒绝夹具的 expected 见 `expected/unknown-status.control.txt`。绝不在运行器中改写源夹具。
