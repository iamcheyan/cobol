# 事件 INC-2026-005：排序节点中止，无发布

> 学员包。**不含根因**。顺序：现象与影响范围 → 时间线 → 假设与证据 →
> 最小复现 → 根因 → 修复/回滚 → 恢复与重跑 → 防再发。
> 逐层提示见 [hints.md](hints.md)。

## 1. 现象与影响范围

- 营业日 `20261009` 的夜间批次在 **JOB003（排序与有序性验证）** 中止，
  退出码 **RC12（系统异常）**。
- JOB001/JOB002 已 COMPLETE；JOB003 失败后 JOB004+ 未执行，无发布。
- 操作侧备注：该窗口内主机临时空间曾出现异常情况。
- 影响范围：排序文件未生成，下游无数据；**无正式发布**，锁已释放。

## 2. 时间线

| 时刻（UTC） | 事件 |
|---|---|
| 01:02:xx | JOB001/JOB002 COMPLETE rc=0 |
| 01:02:xx | JOB003 sort start |
| 01:02:xx | JOB003 ERROR（系统异常）rc=12 |
| 01:02:xx | 净流程停止，JOB004+ NOT_RUN，锁释放 |

原始现场见 `scene/console.txt`、`scene/logs/nightly.log`、
`scene/scheduler-status.txt`。

## 3. 发放包清单

| 材料 | 位置 |
|---|---|
| 调度器状态 | `scene/scheduler-status.txt` |
| 运行参数 | `scene/run.env` |
| 原始接收清单 | `scene/MANIFEST`、`input/MANIFEST` |
| 原始输入（未改动） | `input/transaction.dat`、`input/account_seed.dat`、`input/customer_seed.dat` |
| JOB 日志 | `scene/logs/nightly.log`、`scene/logs/JOB0*.log` |
| 涉事源码 | `scene/source/job003-sort.sh`（排序节点）、`scene/logs/JOB003.log`、`scene/source/nightly.sh` |
| Copybook（冻结接口） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 复现脚本 | `run.sh`（在 PATH 上注入一个失败的 `mktemp`，仅本次运行） |

## 4. 复现

```bash
bash INC-2026-005/student/run.sh /tmp/INC-2026-005-scene /tmp/INC-2026-005-db
echo "rc=$?"
cat /tmp/INC-2026-005-scene/logs/nightly.log
```

## 5. 调查任务

1. 复现并记录原始 RC 与失败节点。
2. 该节点做什么？它依赖哪些**系统资源**（临时目录、写权限、磁盘空间、
   子进程）？读 `system/jobs/job003-sort.sh` 找到它创建临时工作区的地方。
3. 为什么本失败是 **RC12 而非 RC8**？区分“数据错误”与“环境/资源失败”。
4. 关键证据：失败后运行目录内**是否有**临时目录残留、`publish/` 是否
   存在、业务日锁是否释放？逐项给出命令与结果。
5. 给出恢复（修复临时空间/权限后，用新 run_id 重跑）与防再发（前置资源
   检查、磁盘水位告警、失败不发布与锁清理）。

## 6. 提示阶梯

见 [hints.md](hints.md)。

## 7. 插件与终端替代

```bash
ls -la /tmp/INC-2026-005-scene/work/ 2>/dev/null
ls -la /tmp/INC-2026-005-scene/publish 2>/dev/null
ls -la /tmp/INC-2026-005-db/locks 2>/dev/null
df -h /tmp
rg -n 'mktemp|temp space|system failure' \
   INC-2026-005/student/scene/source/job005-match.sh \
   INC-2026-005/student/scene/logs/nightly.log
```
