# 事故 01 根因与评分（讲师专用）

> 学员包只给现象与材料（`curriculum/modules/12-capstone/incidents/incident-01/`），
> 不含本文件。公开仓库无法保密，自学者需知道答案在此。

## 1. 根因

上游在 20261010 夜间**重复投递**同一批交易数据（值班笔记提到“重复投递过
一次”）。第二次投递**多带了一条**既有交易：它复用了已存在的
`transaction_id = A000000000000001`（仅 `sequence_no` 不同）。

- JOB001 只校验 MANIFEST 声明的文件 SHA256，不校验业务键唯一性 → 通过。
- JOB002（BANKVAL）按业务规则校验，重复 txid 不是它的规则 → 两条都进
  accepted（RC4 的拒绝与此无关）。
- JOB003 排序节点在投给 canonical SORTER 前用 `validate.py keys` 检出
  **duplicate transaction_id**，节点与 canonical SORTER 都以 RC8 失败。

证据（材料内）：
- `materials/logs/003b-sort.log`：
  `validate: duplicate transaction_id A000000000000001x2`
- `materials/feed/transaction.dat`：
  `cut -b 11-26 ... | sort | uniq -d` → `A000000000000001`
- `materials/scheduler-state.txt`：JOB003 FAIL rc=8，其后全 SKIPPED，
  `db_ledger_rows=0`。

## 2. 为什么失败是安全的

JOB006 从未运行，账本 0 行，无 commit 标记，无 `publish/`。因此**没有**
重复扣款、**没有**错误发布。事故是“未能发布”，不是“发布错了”。

## 3. 最小修复 / 防再发

体验层修复：JOB002 增加重复业务键预检，在业务拒绝阶段（RC4）就点名，
而不是等到 JOB003 结构失败。参考实现见 `sol/`（若需）。
运营修复：要求上游按业务更正流程**重新投递去重后的文件**（新业务版本 +
新 run_id），不得直接改原始接收文件。

## 4. 恢复与重跑

```bash
# 用去重后的 feed（业务更正版）与新的 run_id 重跑；账本仍为空，无重复风险
scripts/run.sh --input <corrected-feed> --output <new-out> --db <same-db> \
  --business-date 20261010 --layout v1 --run-id night-20261010-02
```

判据：账本 = 去重后接受笔数；余额 = 候选；`publish/CURRENT` 指向新 run。

## 5. 评分点

- 指出重复 txid 在输入（不是排序算法 bug）：+。
- 说明 MANIFEST/校验/排序各自为什么没拦住：+。
- 用证据（日志 + `uniq -d`）而非猜测：+。
- 不改原始输入、走业务更正重跑：+。
- 只把 JOB003 RC8 报成“排序坏了”而不查输入：−。
