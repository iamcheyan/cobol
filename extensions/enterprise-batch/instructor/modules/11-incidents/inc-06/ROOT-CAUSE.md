# inc-06 讲师根因（RC0 但控制总数错误 / 只做内部对账）

## 触发条件
`input/transaction.dat` 中账户 `0000000001` 的第一条贷记金额被 key 成
`50`（正确值应为 `500`）。记录结构完全合法，JOB002 不会拒绝。

## 根因
JOB007（`control.py`）只做**内部守恒**：把 validate 控制、match 已接受、
ledger 三者互相比对。这些数字**全部来自同一份已接受交易集合**，因此
一条金额被 key 错但内部一致的批次会“自洽通过”，以 RC0 发布。

JOB007 **从未读取**输入 `MANIFEST` 中上游声明的控制总数
（`control_credit_total / control_debit_total / control_closing_total`），
所以无法发现“与上游不一致”。

## 逐层提示阶梯（对应 student/hints.md）
1. 独立重算贷方/期末总额，与已发布报告对照。
2. 找外部期望：`input/MANIFEST` 的 `control_*` 声明。
3. 读 `control.py`：比较对象全部来自已接受集合；未读 Manifest。
4. 定位被 key 错的记录（金额 50 应为 500）。
5. 修复=在 JOB007 增加“与声明控制总数对账”，不符即 RC8 且不发布；
   恢复=数据更正运行（新业务版本）。

## 误导线索
- “JOB007 PASS 就代表业务正确”：内部自洽 ≠ 与上游一致。
- “ledger delta == closing−opening 就没事”：两边都错时该等式仍成立。
- “金额是 50，所以本来就该是 50”：需要独立业务来源（Manifest）裁定。

## 证据
- `scene/published-control-report.txt`：`credit_total=175`、
  `closing_total=1025`；`input/MANIFEST` 声明
  `control_credit_total=625`、`control_closing_total=1475`。
- `scene/logs/JOB007.log`：内部核对 PASS。
- `scene/logs/JOB002.log`：该记录通过校验（合法）。

## 最小修复
`inc-06/fix/control.py`：新增 `parse_declared_control()`，把计算出的
received/credit/debit/closing 与 Manifest 声明的 `control_*` 对账，任一
不符 → RC8，阻断发布。RED→GREEN 见 `../tools/red-green.sh`：RED 以 RC0
发布 `closing_total=1025`；GREEN 以 RC8 阻断且无发布。

## 恢复 / 重跑
数据更正运行需**新业务版本**与审计关系；若已提交，先查账本，必要时
冲正后再以新版本入账。不得删除完成标记直接重跑。

## 防再发
把上游声明的控制总数纳入**接收即校验**的契约（JOB001/JOB007 都要对账），
发布前对账必须包含跨来源项目。

## 评分点
- 用上游声明做三方对账（输入→已接受→发布），指出差额与偏移。
- 说明内部守恒的不充分性。
- 修复为“与上游对账并阻断发布”；恢复体现业务更正与新版本。
