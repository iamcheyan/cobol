# 事件 INC-2026-002：夜间批次整体成功，但账户期末余额与业务台账不一致

> 学员包。**不含根因**。调查交付顺序：现象与影响范围 → 时间线 →
> 假设与证据 → 最小复现 → 根因 → 修复/回滚 → 恢复与重跑 → 防再发。
> 逐层提示见 [hints.md](hints.md)。

## 1. 现象与影响范围

- 营业日 `20261009` 的夜间批次 **全部节点 COMPLETE，总体 RC0**，并已
  正式发布 `publish/as-found/`。
- 业务侧复核发现：账户 `0000000001` 的期末余额为 **2000**，而业务台账
  期望 **1500**；账户 `0000000002` 期末 150、`0000000003` 期末 25 与
  期望一致。
- 影响范围：**错误结果已经发布给下游**（比“没有发布”更危险）。下游若
  据此入账会产生实际差额。

## 2. 时间线

| 时刻（UTC） | 事件 |
|---|---|
| 01:02:xx | JOB001–JOB009 全部 COMPLETE rc=0 |
| — | JOB006 已写 DB 账本与 commit；JOB008 已发布 `publish/as-found/` |
| 事后 | 业务侧独立重算发现账户 0000000001 期末差 500 |

原始现场见 `scene/console.txt`、`scene/logs/nightly.log`、
`scene/logs/JOB006.log`、`scene/ledger-victim.dat`、
`scene/published-control-report.txt`、`scene/scheduler-status.txt`。

## 3. 发放包清单

| 材料 | 位置 |
|---|---|
| 调度器状态 | `scene/scheduler-status.txt` |
| 运行参数 | `scene/run.env` |
| 原始接收清单 | `scene/MANIFEST`、`input/MANIFEST` |
| 原始输入（未改动） | `input/transaction.dat`、`input/account_seed.dat`、`input/customer_seed.dat` |
| JOB 日志 | `scene/logs/nightly.log`、`scene/logs/JOB0*.log` |
| DB 台账现场（离线检查点） | `scene/ledger-victim.dat`、`scene/db-account.table` |
| DB 契约（DDL / SQL Log） | `scene/db-schema.sql`、`scene/sql-log.txt` |
| 已发布结果 | `scene/published-control-report.txt`、`scene/published-closing-master.dat` |
| 涉事源码 | `scene/source/db.py`、`scene/source/control.py`、`scene/source/M11MATCH.COB` |
| Copybook（冻结接口） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 复现脚本 | `run.sh` |

> DB 说明：本课程快照**未接入真实 PostgreSQL**；`lib/db.py` 是离线文件
> 检查点，`db-schema.sql` 记录上游声明的契约（含 UNIQUE 约束）。
> 任何“真实 DB 已验证”的结论都属未验证。

## 4. 复现

```bash
bash INC-2026-002/student/run.sh /tmp/INC-2026-002-scene /tmp/INC-2026-002-db
echo "rc=$?"                 # 复现出的原始 RC
cat /tmp/INC-2026-002-db/ledger.dat
cat /tmp/INC-2026-002-scene/work/control/control.txt
```

## 5. 调查任务

1. 复现，确认原始 RC 与“已发布”这一事实。
2. 从 `input/transaction.dat` 出发，独立核算账户 `0000000001` 的期末，
   与 `scene/published-closing-master.dat` 对照，指出差额来源。
3. 对照 `scene/db-schema.sql` 声明的唯一键与 `scene/ledger-victim.dat`
   的实际内容：契约要求什么？实际发生了什么？程序有没有把这个契约
   落到代码里？
4. 说明为什么内部守恒核对（JOB007 自比对）**不能**发现这个差额。
5. 给出最小修复、恢复/重跑（已发布 + 已提交的情况下如何纠正，
   是否需要业务更正运行与新业务版本）、防再发。

## 6. 提示阶梯

见 [hints.md](hints.md)。

## 7. 插件与终端替代

```bash
cut -b1-26 INC-2026-002/student/input/transaction.dat | sort | uniq -d
sort INC-2026-002/student/scene/ledger-victim.dat | cut -d'|' -f1,2 | uniq -d
rg -n 'ledger_index|new_rows|in index|UNIQUE' \
   INC-2026-002/student/scene/source/db.py \
   INC-2026-002/student/scene/db-schema.sql
```
