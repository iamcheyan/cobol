# 事件 INC-2026-006：夜间批次整体成功，但控制总数与上游声明不一致

> 学员包。**不含根因**。顺序：现象与影响范围 → 时间线 → 假设与证据 →
> 最小复现 → 根因 → 修复/回滚 → 恢复与重跑 → 防再发。
> 逐层提示见 [hints.md](hints.md)。

## 1. 现象与影响范围

- 营业日 `20261009` 的夜间批次 **全部节点 COMPLETE，总体 RC0**，并已
  正式发布 `publish/as-found/`。
- 业务侧独立重算当日**贷方总额**与**期末总额**，与上游随文件声明的控制
  总数（Manifest 中的 `control_*` 声明）**不一致**。
- 影响范围：**错误的控制总数与期末余额已经发布**；下游若据此对账会得到
  与上游不符的日终结果。
- 注意：本次错误是**内部完全自洽**的——JOB007 的自我核对全部通过。

## 2. 时间线

| 时刻（UTC） | 事件 |
|---|---|
| 01:02:xx | JOB001–JOB009 全部 COMPLETE rc=0 |
| — | JOB006 已提交；JOB007 内部核对 PASS；JOB008 已发布 |
| 事后 | 业务侧与上游声明对照，发现控制总数不符 |

原始现场见 `scene/console.txt`、`scene/logs/nightly.log`、
`scene/logs/JOB007.log`、`scene/logs/JOB002.log`、
`scene/published-control-report.txt`、`scene/MANIFEST`、
`scene/scheduler-status.txt`。

## 3. 发放包清单

| 材料 | 位置 |
|---|---|
| 调度器状态 | `scene/scheduler-status.txt` |
| 运行参数 | `scene/run.env` |
| 原始接收清单（含上游声明的 control_*） | `scene/MANIFEST`、`input/MANIFEST` |
| 原始输入（未改动） | `input/transaction.dat`、`input/account_seed.dat`、`input/customer_seed.dat` |
| JOB 日志 | `scene/logs/nightly.log`、`scene/logs/JOB0*.log` |
| DB 台账现场 | `scene/ledger-victim.dat`、`scene/db-account.table` |
| 已发布结果 | `scene/published-control-report.txt`、`scene/published-closing-master.dat` |
| 涉事源码 | `scene/source/control.py`、`scene/source/M11MATCH.COB`、`scene/source/M11VAL.COB` |
| Copybook（冻结接口） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 复现脚本 | `run.sh` |

## 4. 复现

```bash
bash INC-2026-006/student/run.sh /tmp/INC-2026-006-scene /tmp/INC-2026-006-db
echo "rc=$?"                          # 原始 RC
cat /tmp/INC-2026-006-scene/work/control/control.txt
grep '^control_' INC-2026-006/student/input/MANIFEST
```

## 5. 调查任务

1. 复现，确认原始 RC 与“已发布”这一事实。
2. 从 `input/transaction.dat` 独立重算贷方/借方/期末总额，并与
   `scene/published-control-report.txt`、上游声明（Manifest 的
   `control_*`）三方对照。谁和谁不一致？
3. 读 `scene/source/control.py`：JOB007 到底把哪些数字互相比较？它是否
   使用过输入 Manifest 里声明的控制总数？如果没用，为什么“内部自洽”
   不能代替“与上游对账”？
4. 判断差额来源（是某条记录的金额本身被 key 错，还是程序算错）。给出
   定位该记录的方法与偏移。
5. 给出最小修复（JOB007 增加“与声明的上游控制总数对账”，不符即 RC8
   且不发布）、恢复/重跑（数据更正运行、新业务版本）与防再发。

## 6. 提示阶梯

见 [hints.md](hints.md)。

## 7. 插件与终端替代

```bash
cut -b41-54 INC-2026-006/student/input/transaction.dat
awk '{s+=substr($0,42,13)} END{print "sum amount="s}' \
  INC-2026-006/student/input/transaction.dat
rg -n 'control_|declared|MANIFEST|closing_total' \
   INC-2026-006/student/scene/source/control.py \
   INC-2026-006/student/input/MANIFEST
```
