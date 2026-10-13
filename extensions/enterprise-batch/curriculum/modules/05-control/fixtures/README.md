# 模块 05 合成夹具

全部为 ASCII、LF 终止的 CUSTOMER v1 文件；逻辑记录 27 字节、**不含 LF**。固定营业日
`20261009`。可由 `python3 scripts/generate-fixtures.py` 确定性重建（只生成数据，不实现清洗）。
`SHA256SUMS` 覆盖全部夹具，`check.sh` 运行前与运行后都校验，绝不在运行器中改写原件。

| 目录 | 夹具 | 目的 |
|---|---|---|
| normal | `clean.dat` | 3 条全合法，含小写状态 `a` 的规范化 |
| boundary | `empty.dat` | 0 字节文件（合法，READ=0） |
| boundary | `single.dat` | 单条记录 |
| boundary | `min-amount.dat` | 金额下界 0 |
| boundary | `max-amount.dat` | 金额上界 50,000,000（含） |
| invalid | `missing-name.dat` | 必填名字为空 → MISSING-NAME |
| invalid | `bad-id.dat` | ID 非数字 → MISSING-ID |
| invalid | `non-numeric-amount.dat` | 金额非数字 → BAD-AMOUNT |
| invalid | `amount-over-cap.dat` | 金额 > 上限 → AMOUNT-RANGE |
| invalid | `unknown-status.dat` | 状态 `X` → UNKNOWN-STATUS |
| invalid | `duplicate-id.dat` | 相邻重复 ID → 第二条 DUPLICATE-ID |
| invalid | `mixed.dat` | 接收+拒绝混合，证明守恒与原因优先级 |
| invalid | `unsorted.dat` | ID 逆序 → RC8 不发布 |
| invalid | `short-record.dat` | 逻辑记录 < 27B → RC8 |
| invalid | `long-record.dat` | 逻辑记录 > 27B → RC8 |
| invalid | `no-trailing-lf.dat` | 末条缺 LF → RC8 |
| invalid | `crlf.dat` | CRLF 换行 → RC8 |

业务拒绝（前 12 组中的 invalid 业务项）按设计 RC4 并发布拒绝明细；结构/契约错误 RC8 不发布。
