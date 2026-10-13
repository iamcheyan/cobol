# 独立预期与核算

`expected/<case>.txt` 只对 RC0/RC4（发布）用例存在，由业务规则与人工微算例确定，**先于**运行
参考程序写出，再由 `scripts/oracle.py`（独立 Python 参考模型，非 COBOL 输出回抄）生成，
最后必须与参考 COBOL 输出逐字节一致。RC8 用例没有 expected 报告，因为正确结果就是“无发布
目录”。各用例 RC 汇总见 [cases.json](cases.json)。

## normal（RC0）

| 账户 | 期初 | 交易 | 期末 |
|---|---:|---|---:|
| 0000000001 | +1000 | T01 `C`500→1500；T02 `D`200→1300 | +1300 |
| 0000000002 | +500 | T03 `C`100→600 | +600 |

客户 2/2 通过。交易守恒 `3 = 接收 3 + 拒绝 0`；账户守恒 `2 = 有交易 2 + 无交易 0`；
金额守恒：期初 1500 + 贷方 600 − 借方 200 = 期末 1900。计数为 12 位零填充，金额为带符号
定宽（13/18 位）。

## 边界用例

- `empty-customers`：客户文件为空，客户控制为 `0/0/0`，账户与交易照常处理，RC0。
- `no-transactions`：交易为空，两账户各自输出期末=期初，`TX=0`、`NOTX=2`，RC0。
- `max-amount`：账户1 期初 0 入账 13 位全 9 得到余额 13 位上限；账户2 期初 13 位全 9 出账 1。
  全局 `OPENING + CREDIT − DEBIT = CLOSING` 用 18 位精确核算，RC0。
- `all-empty`：三文件皆空，全部计数 0、金额 0，RC0。

## 业务拒绝（RC4，仍发布）

| 用例 | 触发 | 原因码 | 关键预期 |
|---|---|---|---|
| customer-bad-status | 客户状态 `Z` | `CUST-BAD-STATUS` | 客户拒绝，无交易 |
| customer-bad-id | 客户 ID `ABCD0001` | `BAD-ID` | 同上 |
| customer-no-name | 姓名全空格 | `CUST-NO-NAME` | 同上 |
| zero-amount | 交易金额 0 | `ZERO-AMOUNT` | 余额不变 |
| overdraft | 出账 2000 > 期初 1000 | `OVERDRAFT` | 余额保持 1000 |
| overflow | 13 位全 9 入账 1 | `OVERFLOW` | 余额保持上限 |
| unknown-direction | 方向 `X` | `BAD-DIRECTION` | 余额不变 |
| no-account | 交易账户不在账户文件 | `NO-ACCOUNT` | 账户文件无此账户 |
| frozen-account | 账户状态 `F` | `ACCOUNT-STATUS` | 该账户**有交易**，故 `NOTX=0` |

拒绝金额不进入任何余额或贷/借累计；被拒交易计入 `TX` 与 `REJECT`，保持
`TX = ACCEPT + REJECT`。

## 契约错误（RC8，不发布）

| 用例 | 触发 | 预期 |
|---|---|---|
| bad-layout-version | 账户布局版本 `002` | 无输出目录，stderr `CONTRACT-FAIL` |
| short-account | 账户行 46 字节 | 同上 |
| bad-account-date | 账户业务日 ≠ 营业日 | 同上 |
| unsorted-transactions | 交易未按账户/序号/ID 升序 | 同上 |
| dup-global-txid | 同账户不同序号重复 `transaction_id` | JOB 全局唯一性校验：RC8，无输出目录，stderr `duplicate global transaction_id` |
| dup-cross-account | 跨账户重复 `transaction_id` | 同上 |

全局重复用例在**文件内仍严格有序**（同账户不同序号、账户升序），因此只能由全局唯一性
校验发现，顺序突合会漏检；`oracle.py` 用独立集合复核，`run.sh` 用外排（`sort`）在入账前
拦截。

## 逐字节比对说明

`check.py` 对 RC0/RC4 用例逐字节比对 `report.txt` 与 `expected/<case>.txt`，不做整文件
`trim`，以暴露定宽字段错误。日志因 GnuCOBOL `LINE SEQUENTIAL` 裁剪行尾空格，模型同样裁剪。
