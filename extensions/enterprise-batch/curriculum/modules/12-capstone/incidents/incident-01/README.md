# 事故 01：20261010 夜间流程未发布（发放材料）

> 本文件是**发放材料**，只描述现象与可用证据，**不包含根因、不包含修复**。
> 根因、最小修复与评分点在 `instructor/modules/12-capstone/INCIDENT-01.md`。

## 现象（值班接到的报告）

营业日 20261010 的夜间流程在**发布之前失败**：下游没有收到当日的
`closing-master.dat` / `customer-day.dat`，`publish/CURRENT` 未更新。前段
节点（接收、校验、排序）从日志上看都像正常完成，流程却在后面停下。

## 影响范围

- 当日无正式发布；下游对账等待。
- 数据库store 的账本**没有**被污染（需要你自己核实，不要凭日志最后一行下结论）。
- 未发生重复扣款（同样需要证据）。

## 你收到的材料

| 文件 | 内容 |
|---|---|
| `materials/params.txt` | 当夜的营业日、layout、输入目录、run_id |
| `materials/feed/` | 收到的输入快照（TRANSACTION/CUSTOMER/ACCOUNT + MANIFEST） |
| `materials/scheduler-state.txt` | 排程器记录的 JOB 状态与 RC |
| `materials/logs/` | JOB 日志与 `nightly.log` 摘录 |
| `materials/operator-notes.md` | 值班交接笔记 |
| `reproduce/reproduce.sh` | 用同样参数重放该夜，并导出原始证据 |

## 你的任务

按 `AUTHORING-STANDARD` 第 5 节的顺序交付：现象与影响范围 → 时间线 →
假设与证据 → 最小复现 → 根因 → 修复/回滚 → 恢复与重跑 → 防再发。

硬性要求：

- **不得修改原始输入**来“修好”事故；恢复必须是可审计的业务更正。
- 根因必须能由材料复现，并指出具体是哪条数据/哪一步。
- 说明为什么账本没有（或没有）被污染，用证据而不是日志最后一行。
- 给出在不重复扣款前提下的恢复命令与原始 RC。

## 建议的查看方式（终端，插件可选）

```bash
incident=curriculum/modules/12-capstone/incidents/incident-01
cat "$incident/materials/scheduler-state.txt"
sed -n '1,80p' "$incident/materials/logs/nightly.log"
bash "$incident/reproduce/reproduce.sh" /tmp/m12-incident-01
```

提交证据见 `curriculum/modules/12-capstone/evidence/README.md`。
