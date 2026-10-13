# 模块 11 预期结果说明（独立核算）

`expected/` 由 `instructor/modules/11-incidents/tools/gen_course.py` 生成，
该生成器**重新实现**冻结契约（CUSTOMER 27B / ACCOUNT 47B / TRANSACTION
55B）的校验与 1:N 透支/孤立规则，**不读取任何课程程序输出**。规则说明：

- **JOB002 校验**：长度≠55 或键/金额非数字或交易号全空格 → 结构错误
  （整批 RC8）；方向非 C/D、状态非 N、营业日不符、金额为 0 → 业务拒绝
  （RC4，逐条记录）。
- **JOB005 突合**：账户不存在 → ORPHAN；出账导致期末 <0 → OVERDRAFT；
  否则 `closing = opening + credit − debit`。账户/交易流须有序，否则 RC8。
- **控制总数**：`opening_total + credit_total − debit_total = closing_total`。

| 文件 | 内容 |
|---|---|
| `normal.control.txt` | 基线控制总数（received=4，closing_total=1475） |
| `normal.closing.txt` | 基线期末 Master（acc1 1300／acc2 150／acc3 25） |
| `incidents.txt` | 各事件 `as_found_rc / desired_rc / publish_before / publish_after` |
| `customer-v1.txt` | CUSTOMER v1 状态抽取（`STATUS\|id\|A/D`） |
| `enterprise-class-v1.txt` | 企业客户区分 v1 抽取（`CLASS\|id\|A`） |
| `enterprise-class-v2.txt` | 企业客户区分 v2 抽取（`CLASS\|id\|A1`） |

`incidents.txt` 中 `as_found_rc=0` 且 `publish_before=yes` 的事件表示
**现状缺陷**：系统以 RC0 发布了错误结果；对应的 `desired_rc=8` 与
`publish_after=no` 是**修正后必须达到**的契约行为。哪些事件属此类别由
契约数据本身决定，不在此点名（根因见讲师包）。

`check.py` 以这些独立预期为断言来源，绝不把程序自身 stdout 当正确答案。
