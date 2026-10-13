# 模块 06 合成夹具

全部为 ASCII、LF 终止的 ACCOUNT v1 文件；逻辑记录 47 字节、**不含 LF**。固定营业日
`20261009`。可由 `python3 scripts/generate-fixtures.py` 确定性重建（只生成数据，不实现校验）。
`SHA256SUMS` 覆盖全部夹具，`check.sh` 前后都校验，绝不在运行器中改写原件。

| 目录 | 夹具 | 目的 |
|---|---|---|
| normal | `valid.dat` | 3 条合法（+1000 A / +50 F / -500 C），BALANCE=550 |
| boundary | `empty.dat` | 0 字节文件（合法，READ=0） |
| boundary | `single.dat` | 单条记录 |
| boundary | `negative-balance.dat` | 负期初余额 `-9999999999999` |
| boundary | `zero-balance.dat` | 期初余额 0 |
| invalid | `bad-account-id.dat` | 账号非数字 → BAD-ACCOUNT-ID |
| invalid | `bad-customer-id.dat` | 客户号非数字 → BAD-CUSTOMER-ID |
| invalid | `unknown-currency.dat` | 币种 `USD` → UNKNOWN-CURRENCY |
| invalid | `bad-sign.dat` | 符号 `*` → BAD-SIGN |
| invalid | `bad-balance.dat` | 余额非数字 → BAD-BALANCE |
| invalid | `bad-date.dat` | `20260230` 非日历日 → BAD-DATE |
| invalid | `date-mismatch.dat` | `20261008` ≠ 营业日 → DATE-MISMATCH |
| invalid | `unknown-status.dat` | 状态 `Z` → UNKNOWN-STATUS |
| invalid | `duplicate-id.dat` | 相邻重复账号 → 第二条 DUPLICATE-ID |
| invalid | `mixed.dat` | 接收+拒绝混合，证明守恒与优先级 |
| invalid | `bad-layout.dat` | layout `002` → RC8 不发布 |
| invalid | `unsorted.dat` | 账号逆序 → RC8 |
| invalid | `short-record.dat` | 逻辑记录 < 47B → RC8 |
| invalid | `long-record.dat` | 逻辑记录 > 47B → RC8 |
| invalid | `no-trailing-lf.dat` | 末条缺 LF → RC8 |
| invalid | `crlf.dat` | CRLF 换行 → RC8 |

业务拒绝夹具按设计 RC4 并发布拒绝明细；结构/契约错误 RC8 不发布。缺失文件无夹具，由
`run.sh` 传入不存在路径触发 RC12。
