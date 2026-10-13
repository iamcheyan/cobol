# 事件 INC-2026-003：接收节点中止，当日无发布

> 学员包。**不含根因**。顺序：现象与影响范围 → 时间线 → 假设与证据 →
> 最小复现 → 根因 → 修复/回滚 → 恢复与重跑 → 防再发。
> 逐层提示见 [hints.md](hints.md)。

## 1. 现象与影响范围

- 营业日 `20261009` 的夜间批次在 **JOB001（接收/校验 Manifest）** 中止，
  退出码 **RC12（系统异常）**。
- 净流程立即停止，JOB002+ 未执行，`publish/` 无本次发布。
- 上游传输侧反馈“发送成功”，但接收目录中的当日交易文件为 **0 字节**。

## 2. 时间线

| 时刻（UTC） | 事件 |
|---|---|
| 01:02:09 | 调度器启动 `run_id=as-found`；JOB001 start |
| 01:02:09 | JOB001 ERROR `checksum mismatch for 'transaction.dat'` |
| 01:02:09 | 净流程停止，JOB002+ NOT_RUN，锁释放 |

原始现场见 `scene/console.txt`、`scene/logs/nightly.log`、
`scene/logs/JOB001.log`、`scene/scheduler-status.txt`。

## 3. 发放包清单

| 材料 | 位置 |
|---|---|
| 调度器状态 | `scene/scheduler-status.txt` |
| 运行参数 | `scene/run.env` |
| 原始接收清单 | `scene/MANIFEST`、`input/MANIFEST` |
| 原始输入（未改动，0 字节） | `input/transaction.dat` |
| DB 种子 | `input/account_seed.dat`、`input/customer_seed.dat` |
| JOB 日志 | `scene/logs/nightly.log`、`scene/logs/JOB001.log` |
| 涉事源码 | `scene/source/M11VAL.COB`、`scene/source/job002-validate.sh` |
| Copybook（冻结接口） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 复现脚本 | `run.sh` |

## 4. 复现

```bash
bash INC-2026-003/student/run.sh /tmp/INC-2026-003-scene /tmp/INC-2026-003-db
echo "rc=$?"
wc -c INC-2026-003/student/input/transaction.dat   # 观察实际字节数
cat /tmp/INC-2026-003-scene/logs/JOB001.log
```

## 5. 调查任务

1. 复现并记录原始 RC 与失败节点。
2. 列出 JOB001 在进入 JOB002 之前所做的全部校验（参考 Manifest 的
   声明、校验和、快照）。**是哪一项**最先发现异常？
3. 这属于 RC8（业务）还是 RC12（系统）？说明理由。
4. 关键区分：0 字节文件本身是“合法空文件”还是“损坏的传输”？课程契约
   里“允许空文件”的政策如何界定？不要凭感觉，引用 Manifest 声明的
   期望内容。
5. 给出恢复步骤（重新接收/校验来源、用新 run_id 重跑）与防再发（传输
   校验、接收后长度哨兵、告警）。

## 6. 提示阶梯

见 [hints.md](hints.md)。

## 7. 插件与终端替代

```bash
od -An -tc INC-2026-003/student/input/transaction.dat
sha256sum INC-2026-003/student/input/transaction.dat
cat INC-2026-003/student/scene/MANIFEST
rg -n 'checksum|MANIFEST|snapshot' \
   INC-2026-003/student/scene/source/M11VAL.COB \
   INC-2026-003/student/scene/logs/JOB001.log
```
