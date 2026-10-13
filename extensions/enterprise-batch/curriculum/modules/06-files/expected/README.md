# 独立预期（module 06）

`expected/*.txt` 是 `report.txt` 的整文件预期，由 DESIGN.md 的字段契约与人工微算例确定，
再由 `check.py` 用夹具独立重建 accepted/rejected 逐字节比对。命名 `<group>-<case>.txt`。

- `normal-valid.txt`：BALANCE = +1000 + 50 − 500 = **550**；READ=ACCEPT=3、REJECT=0。
- `boundary-empty.txt`：READ=ACCEPT=REJECT=0、BALANCE=0（空文件合法）。
- `boundary-single.txt`：+1。
- `boundary-negative-balance.txt`：BALANCE = −9,999,999,999,999。
- `boundary-zero-balance.txt`：BALANCE = 0。
- `invalid-bad-account-id` / `bad-customer-id` / `unknown-currency` / `bad-sign` /
  `bad-balance` / `bad-date` / `date-mismatch` / `unknown-status`：各 1 条拒绝，原因见
  DESIGN 原因目录；BALANCE=0。
- `invalid-duplicate-id.txt`：接收 1 + 拒绝 1；BALANCE=1000。
- `invalid-mixed.txt`：DESIGN 微算例，READ=6、ACCEPT=2、REJECT=4、BALANCE=1100。

契约错误夹具（`bad-layout`、`unsorted`、`short-record`、`long-record`、`no-trailing-lf`、
`crlf`）**没有** expected 报告，因为预期就是 RC8 且不发布；缺失文件同样无 expected（RC12）。

核算过程（示例，`invalid-mixed.dat`）：记录 1（+1000）与记录 6（+100）被接收，其余 4 条各
因一个字段原因被拒；BALANCE = 1000 + 100 = 1100；读入 6 = 接收 2 + 拒绝 4。
