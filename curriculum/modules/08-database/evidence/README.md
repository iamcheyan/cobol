# 模块08 学员证据模板

完成模块08 后，把下列内容填入本节（不要在这里写“通过”，只放事实与命令）。失败判定见
模块 [README](../README.md) 第 8 节。

## 环境

- 提交/工作副本版本：
- OS/架构（仅 Linux x86-64 已实测）：
- GnuCOBOL 版本（`cobc -V` 原文）：
- 工具镜像 id（`image-id.txt`）：
- P1 补丁 sha256（`p1-patches.sha256`）：

## 命令与原始 RC

| 命令 | 原始 RC | 备注 |
|---|---:|---|
| `python3 scripts/check.py` |  |  |
| `bash scripts/check.sh` |  |  |
| `bash scripts/run.sh OUT 20261009` |  |  |
| `COURSE_SOURCE=starter/DBBATCH.COB bash scripts/run.sh OUT2 20261009` |  | 应 RC12 且无 OUT2 |

## 08.1 / 08.2 证据

- `probe.out` 关键行（NULL 指示器、空字符串、`02000`、`23514`、`23505`）：
- `probe-fail.out` 的连接 SQLSTATE 与 RC：

## 08.3 证据

- `snapshot.dat` 的 `sha256sum` 与 `expected/snapshot-20261009.dat` 比对结果：
- `snapshot-control.txt` 的控制总数：
- `snapshot-reconcile.txt` 差异行（field/offset/old/new）：
- 快照元数据的业务日 / schema 版本 / 布局版本 / 截止点：

## 08.4 证据

- `db-after-first.txt`（余额/账本/提交）：
- `db-after-retry.txt` 与首次是否一致（证明重跑不重复扣款）：
- `db-after-dup.txt`（运行内重复应回滚）：
- 回滚模式前后余额对比：

## 独立核算

- 你如何在不看程序输出的情况下推导 08.3 差异与 08.4 余额：
- 与 [expected/README.md](../expected/README.md) 的核算是否一致；不一致点：

## 动手修改与故障复现

| 课次 | 我改了什么 | 观察到的故障 | 恢复到何状态 |
|---|---|---|---|
| 08.1 |  |  |  |
| 08.2 |  |  |  |
| 08.3 |  |  |  |
| 08.4 |  |  |  |

## 限制与未验证项

- 明确列出未验证项（例如 macOS/WSL/ARM、真实网络断线、并发锁、其它 DB 错误码）：

## 完整性

- `inputs.sha256` 与 `manifest.sha256` 校验结果：
- 原始夹具是否被改动（应否）：
