# 模块 09 夹具

所有文件为 ASCII、定宽、每行以 LF 结束；LF 不计入逻辑宽度。营业日固定 `20261010`。
布局为冻结契约：CUSTOMER v1 = 27 字节、ACCOUNT v1 = 47 字节、TRANSACTION v1 = 55 字节。
目录布局：`normal/`（主用例，三个 `.dat` 直接位于目录下）、`boundary/<case>/`、
`invalid/<case>/`。夹具由 `../scripts/generate-fixtures.py` 确定性生成；`SHA256SUMS` 覆盖本
文件与全部 `.dat`。

| 目录 | 覆盖点 | 预期 RC | 是否发布 |
|---|---|---|---|
| `normal` | 全接收：8 位客户校验通过、逐笔金额计算正确 | 0 | 是 |
| `empty-customers` | 客户文件为空，账户/交易正常 | 0 | 是 |
| `no-transactions` | 交易文件为空，账户仍输出期末余额 | 0 | 是 |
| `max-amount` | 单笔金额与余额到达 13 位上限，仍合法 | 0 | 是 |
| `all-empty` | 三个文件皆空 | 0 | 是 |
| `customer-bad-status` | 客户状态 `Z`，`CUSTVAL` 返回业务拒绝 | 4 | 是 |
| `customer-bad-id` | 客户 ID 含非数字，`CUSTVAL` 返回业务拒绝 | 4 | 是 |
| `customer-no-name` | 客户姓名全空格，`CUSTVAL` 返回业务拒绝 | 4 | 是 |
| `zero-amount` | 交易金额为 0，`AMTCALC` 返回业务拒绝 | 4 | 是 |
| `overdraft` | 出账超过可用余额，`AMTCALC` 返回业务拒绝 | 4 | 是 |
| `overflow` | 入账使余额超过 13 位上限，`AMTCALC` 返回业务拒绝 | 4 | 是 |
| `unknown-direction` | 交易方向既非 `C` 也非 `D`，`AMTCALC` 返回业务拒绝 | 4 | 是 |
| `no-account` | 交易账户在账户文件中不存在，调用者判定业务拒绝 | 4 | 是 |
| `frozen-account` | 账户状态 `F`，调用者按业务策略逐笔拒绝 | 4 | 是 |
| `bad-layout-version` | 账户布局版本 `002`，文件契约错误 | 8 | 否 |
| `short-account` | 账户记录 46 字节，输入长度契约错误 | 8 | 否 |
| `bad-account-date` | 账户业务日与作业营业日不符，契约错误 | 8 | 否 |
| `unsorted-transactions` | 交易未按账户/序号升序，契约错误 | 8 | 否 |

RC4 夹具仍发布经核对的报告与派生文件（调用 JOB 须显式允许 RC4 继续）。
RC8 夹具整批失败且不产生任何输出目录。
