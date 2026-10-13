# 独立预期（module 05）

`expected/*.txt` 是 `report.txt` 的整文件预期，由 DESIGN.md 的业务政策**人工微算例**确定，
再由 `check.py` 用夹具独立重建 accepted/rejected 逐字节比对。不得把参考实现的输出直接当作
正确答案。命名规则 `<group>-<case>.txt`。

- `normal-clean.txt`：3 条全接收；状态 `a`→`A`、`D` 保留；AMOUNT=60。
- `boundary-empty.txt`：READ=ACCEPT=REJECT=0，AMOUNT=0（空文件合法）。
- `boundary-min-amount.txt`：金额 0 合法，AMOUNT=0。
- `boundary-max-amount.txt`：金额 50,000,000 合法；两条合计 50,000,001。
- `boundary-single.txt`：单条，AMOUNT=1。
- `invalid-missing-name.txt` / `bad-id` / `non-numeric-amount` / `amount-over-cap` /
  `unknown-status` / `duplicate-id`：各 1 条拒绝，原因与上表一致；`duplicate-id` 为
  接收 1 + 拒绝 1、AMOUNT=50。
- `invalid-mixed.txt`：DESIGN 微算例，READ=6、ACCEPT=1、REJECT=5、AMOUNT=50。

结构/契约错误夹具（`unsorted`、`short-record`、`long-record`、`no-trailing-lf`、`crlf`）
**没有** expected 报告，因为预期就是 RC8 且不发布任何输出目录。

核算过程（示例，`boundary-max-amount.dat`）：记录 1 金额 50,000,000、记录 2 金额 1，
两条均合法，故 AMOUNT = 50,000,000 + 1 = 50,000,001；读入 2 = 接收 2 + 拒绝 0。
