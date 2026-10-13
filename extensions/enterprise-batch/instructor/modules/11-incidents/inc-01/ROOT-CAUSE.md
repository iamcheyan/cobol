# inc-01 讲师根因（非法数字 / 结构错误）

## 触发条件
`input/transaction.dat` 第 1 条记录的**账户号第 10 位为字母 `X`**
（`000000000X…`），其余记录合法。JOB002 的校验器在“数字键/金额”检查处
判定为**结构错误**。

## 逐层提示阶梯（对应 student/hints.md）
1. 失败在 JOB002，RC8 → 区分 RC8（业务/契约）与 RC12（系统）。
2. 读 `M11VAL.COB` `2000-PROCESS`：`IS NOT NUMERIC` 触发 `WS-STRUCT='Y'`，
   整批中止（不是业务拒绝）。
3. 用 `TRANSACTION-V1.CPY` 冻结布局定位：账户 1–10 位含非数字。
4. 根因是**源数据**错误，非程序缺陷；修复在源头，禁止放宽校验。

## 误导线索
- “RC8 = 数据被拒绝，重跑即可”：重跑同一坏数据仍 RC8。
- “把 `IS NOT NUMERIC` 去掉就能过”：会把坏键当合法数据，属篡改断言。
- 日志里同时存在“结构错误”和“业务拒绝”两种措辞，容易误判为 RC4。

## 证据
- `scene/logs/JOB002.log`：`M11VAL: non-numeric key/amount`；
  `BANKVAL: structural error, batch failed`；原始 RC=8（`scene/rc.txt`）。
- `scene/scheduler-status.txt`：JOB002 FAILED rc=8，JOB003+ NOT_RUN。
- 无 `publish/<run_id>`，锁释放。

## 最小修复
源数据：把该记录账户号改为合法 10 位数字后重新交付。程序侧**不需要且
不应**修改；校验器行为与冻结契约一致。

## 恢复 / 重跑
以修正后的输入、**新 run_id 与新输出目录**重跑；不得覆盖失败目录。

## 防再发
上游数字域校验、传输前字段级校验、接收后结构哨兵与告警。

## 评分点
- 正确判定为结构错误（RC8）而非业务拒绝（RC4）。
- 以原始字节/偏移证明，而非只贴日志。
- 明确“不改数据、不放宽校验”；恢复使用新 run_id。
