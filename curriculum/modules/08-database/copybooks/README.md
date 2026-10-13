# copybooks：版本化接口

| Copybook | 契约 | 说明 |
|---|---|---|
| `CUSTOMER-V1.CPY` | CUSTOMER v1 = **27B** | 本模块 08.3 快照与突合的接口（`customer_id 8 + name 10 + balance_demo 8 + status 1`） |

`ACCOUNT v1 = 47B` 与 `TRANSACTION v1 = 55B` 的 canonical source 仍是
[`curriculum/bank/copybooks/`](../../../bank/copybooks/)（`ACCOUNT-V1.CPY`、
`TRANSACTION-V1.CPY`），**不在此重复维护**，避免同名接口分叉。`scripts/build.sh`
同时把本目录与 canonical 目录加入 `cobc -I`，因此程序可 `COPY ACCOUNT-V1` /
`COPY TRANSACTION-V1`。

`APPLY.COB` 直接以数字偏移读取 55B 交易（`account 1-10`、`transaction_id 11-26`、
`date 27-34`、`sequence 35-40`、`direction 41`、`amount 42-54`、`status 55`），
其字节布局由 `scripts/check.py` 的定宽断言与 [DESIGN.md](../DESIGN.md) 冻结。
