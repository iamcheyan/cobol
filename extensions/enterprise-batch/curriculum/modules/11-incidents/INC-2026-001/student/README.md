# 事件 INC-2026-001：校验节点中止，当日无发布

> 学员包。**不含根因**。请按「现象与影响范围 → 时间线 → 假设与证据 →
> 最小复现 → 根因 → 修复/回滚 → 恢复与重跑 → 防再发」的顺序调查，
> 并在 `evidence/` 提交证据。逐层提示见 [hints.md](hints.md)。

## 1. 现象与影响范围

- 营业日 `20261009` 的夜间批次在 **JOB002（校验）** 中止，退出码
  **RC8**。
- 净流程立即停止：JOB003 以后的节点 **未执行**，`publish/` 下
  **没有任何本次发布目录**，CURRENT 指针未更新。
- 影响范围：当日下游文件全部缺失，下游尚未拿到错误数据（没有发布）。

## 2. 时间线

| 时刻（UTC） | 事件 |
|---|---|
| 01:02:08 | 调度器启动 `run_id=as-found`，JOB001 接收 COMPLETE |
| 01:02:08 | JOB002 校验 start |
| 01:02:09 | JOB002 校验 ERROR `validator failed rc=8` |
| 01:02:09 | 净流程停止，JOB003+ NOT_RUN，锁释放 |

原始现场见 `scene/console.txt`、`scene/logs/nightly.log`、
`scene/logs/JOB002.log`、`scene/scheduler-status.txt`。

## 3. 发放包清单

| 材料 | 位置 |
|---|---|
| 调度器状态 | `scene/scheduler-status.txt` |
| 运行参数（营业日/run_id/路径） | `scene/run.env` |
| 原始接收清单（Manifest） | `scene/MANIFEST`、`input/MANIFEST` |
| 原始输入（未改动） | `input/transaction.dat`、`input/account_seed.dat`、`input/customer_seed.dat` |
| JOB 日志 | `scene/logs/nightly.log`、`scene/logs/JOB0*.log` |
| 涉事源码 | `scene/source/M11VAL.COB`、`scene/source/job002-validate.sh` |
| Copybook（冻结接口） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 复现脚本 | `run.sh` |

## 4. 复现

```bash
# 在任意目录执行；使用本包的 input/ 副本，不修改共享夹具
bash INC-2026-001/student/run.sh /tmp/INC-2026-001-scene /tmp/INC-2026-001-db
echo "rc=$?"
cat /tmp/INC-2026-001-scene/logs/JOB002.log
```

预期复现出与现场相同的原始 RC（见 `scene/rc.txt`）。

## 5. 调查任务（先重现，再定位）

1. 复现并记录原始 RC 与出错节点。
2. 用 `od -An -tc` / `cut` 逐字节查看 `input/transaction.dat`，与
   `copybooks/TRANSACTION-V1.CPY` 的冻结布局逐字段对照；判断这是
   **结构错误** 还是 **业务拒绝**，并说明课程 RC 约定为何如此分类。
3. 说明为什么净流程没有发布任何下游文件是正确的行为。
4. 在 `evidence/` 写出根因、最小修复（数据侧 vs 代码侧）、恢复与重跑
   步骤、防再发措施。修复不得通过放宽校验或改写原始输入来“掩盖”。

## 6. 提示阶梯

见 [hints.md](hints.md)。先只看第 1 层。

## 7. 插件与终端替代

- 插件：在 `source/M11VAL.COB` 上用 `gd` 跳到校验段落；用
  `K`/`:CobolPreview` 预览 Copybook；保存时用诊断确认 72 列/Area A/B。
- 纯终端替代：
  ```bash
  awk '{print NR": "length($0)" cols"}' INC-2026-001/student/input/transaction.dat
  od -An -tc INC-2026-001/student/input/transaction.dat
  rg -n 'WS-STRUCT|2000-PROCESS' \
     INC-2026-001/student/scene/source/M11VAL.COB
  ```
