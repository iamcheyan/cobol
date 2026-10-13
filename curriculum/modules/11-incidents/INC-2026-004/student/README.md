# 事件 INC-2026-004：突合节点中止，候选未生成

> 学员包。**不含根因**。顺序：现象与影响范围 → 时间线 → 假设与证据 →
> 最小复现 → 根因 → 修复/回滚 → 恢复与重跑 → 防再发。
> 逐层提示见 [hints.md](hints.md)。

## 1. 现象与影响范围

- 营业日 `20261009` 的夜间批次在 **JOB005（顺序突合与余额计算）** 中止，
  退出码 **RC8**。
- JOB003/JOB004 已 COMPLETE；JOB005 失败后 JOB006+ 未执行，无发布。
- 影响范围：候选期末 Master 未生成，下游无数据（未发布错误结果）。

## 2. 时间线

| 时刻（UTC） | 事件 |
|---|---|
| 01:02:xx | JOB001–JOB004 COMPLETE rc=0 |
| 01:02:xx | JOB005 match start |
| 01:02:xx | JOB005 ERROR `match failed rc=8`，日志含 out-of-order 提示 |
| 01:02:xx | 净流程停止，JOB006+ NOT_RUN，锁释放 |

原始现场见 `scene/console.txt`、`scene/logs/nightly.log`、
`scene/logs/JOB005.log`、`scene/scheduler-status.txt`。

## 3. 发放包清单

| 材料 | 位置 |
|---|---|
| 调度器状态 | `scene/scheduler-status.txt` |
| 运行参数 | `scene/run.env` |
| 原始接收清单 | `scene/MANIFEST`、`input/MANIFEST` |
| 原始输入（未改动） | `input/transaction.dat`、`input/account_seed.dat`、`input/customer_seed.dat` |
| JOB 日志 | `scene/logs/nightly.log`、`scene/logs/JOB0*.log` |
| 涉事源码 | `scene/source/M11MATCH.COB`、`scene/source/job005-match.sh`、`scene/source/db.py` |
| Copybook（冻结接口） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 复现脚本 | `run.sh` |

## 4. 复现

```bash
bash INC-2026-004/student/run.sh /tmp/INC-2026-004-scene /tmp/INC-2026-004-db
echo "rc=$?"
cat /tmp/INC-2026-004-scene/logs/JOB005.log
cat -A /tmp/INC-2026-004-scene/work/db/account_master.dat   # 突合实际读到的 Master
```

## 5. 调查任务

1. 复现并记录原始 RC 与失败节点。
2. 突合是**顺序**算法，对两条输入流各有排序前提（Master 按
   account_id；交易按 account_id, sequence, transaction_id）。读
   `M11MATCH.COB` 的读入段落：它对哪一条流的“顺序”做了检查并中止？
3. 从 `input/account_seed.dat` 出发，独立验证各输入流是否满足各自的排序
   前提；若有违反，给出第一个违反位置（账户值与前后记录）。
4. 追根因：Seed → JOB004 快照 → JOB005 读取，哪一环丢失/破坏了顺序？
   为什么“候选未生成”而不是“生成错误候选”是正确的失败方式？
5. 给出恢复（在**哪个边界**重新排序/重新抽取）与防再发（上游抽取排序、
   边界有序性前置校验、快照与源一致性校验）。

## 6. 提示阶梯

见 [hints.md](hints.md)。

## 7. 插件与终端替代

```bash
cut -b1-10 INC-2026-004/student/input/account_seed.dat
sort -c -k1.1,1.10 INC-2026-004/student/input/account_seed.dat \
  && echo "sorted" || echo "NOT sorted"
rg -n 'out of order|PREV-ACCT|1000-READ-ACCOUNT' \
   INC-2026-004/student/scene/source/M11MATCH.COB
```
