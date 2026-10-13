# 企业 Legacy Batch COBOL 课程

本扩展按[12 模块/76 小时设计](../docs/curriculum/README.md)制作，统一使用合成银行夜间处理案例。模块 01–12 含教学单元、真实数据、可运行参考实现、starter、独立 expected、故障练习和证据模板。各模块状态区分执行代理自测与主代理独立验收。旧版基础课程另见 [`legacy-workshop/`](../../legacy-workshop/README.md)。

## 模块与验收入口

| 模块 | 内容 | 快速检查入口 | 状态 |
|---|---|---|---|
| [01-foundations](modules/01-foundations/README.md) | Legacy/业务日/JOB、编译链接、固定/自由格式与列截断 | `bash modules/01-foundations/scripts/check.sh` | 执行代理自测完成，待主代理审查 |
| [02-data](modules/02-data/README.md) | PIC/层级/VALUE、MOVE 截断补齐、CUSTOMER v1 27B 字段目录 | `bash modules/02-data/scripts/check.sh` | 执行代理自测完成，待主代理审查 |
| [03-bytes](modules/03-bytes/README.md) | DISPLAY/COMP/COMP-5/COMP-3 原始字节、坏 Packed 解析 | `bash modules/03-bytes/scripts/check.sh` | 执行代理自测完成，待主代理审查 |
| [04-structures](modules/04-structures/README.md) | REDEFINES/OCCURS/ODO/COPY REPLACING、175 字段目录与偏移 | `bash modules/04-structures/scripts/check.sh` | 执行代理自测完成，待主代理审查 |
| [05-control](modules/05-control/README.md) | IF/EVALUATE/PERFORM、SEARCH、STRING/UNSTRING、客户清洗 | `bash modules/05-control/scripts/check.sh` | 执行代理自测完成，待主代理审查 |
| [06-files](modules/06-files/README.md) | FD/FILE STATUS/EOF、定长与 LINE、相对/索引文件与锁 | `bash modules/06-files/scripts/check.sh` | 执行代理自测完成，待主代理审查 |
| [07-matching](modules/07-matching/README.md) | SORT/MERGE、L1/L2/L3/L4 突合标杆（12h，核心） | `bash modules/07-matching/check.sh` | L1/L2/SORT/MERGE/L3 主代理已验收；L4 待主代理验收 |
| [08-database](modules/08-database/README.md) | 真实 ESQL 游标/NULL/事务/幂等（6h） | `bash modules/08-database/scripts/check-quick.sh`（离线）；`.../scripts/check.sh`（真实 DB，需 Docker） | 真实 DB 端到端已实测 RC0，待主代理审查 |
| [09-modular](modules/09-modular/README.md) | CALL/LINKAGE/USING、RETURNING、共通模块与状态生命周期 | `bash modules/09-modular/scripts/check.sh` | 执行代理自测完成，待主代理审查 |
| [10-jobs](modules/10-jobs/README.md) | JOB001–009、RC/锁/快照/Manifest、四崩溃边界恢复（9h，核心） | `bash modules/10-jobs/scripts/check.sh` | 执行代理自测完成，待主代理审查 |
| [11-incidents](modules/11-incidents/README.md) | 六类事故调查、客户区分 1→2 位维护（9h，核心） | `bash modules/11-incidents/scripts/check.sh` | 执行代理自测完成，待主代理审查 |
| [12-capstone](modules/12-capstone/README.md) | 陌生系统综合项目、四类日闭环、隐藏事故与评分（9h） | `bash modules/12-capstone/scripts/check.sh` | 执行代理自测完成，待主代理审查 |

## 本地验收

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
bash curriculum/check.sh                                  # P1 + 全部 12 模块快速验收入口 + 固定格式门禁
bash curriculum/modules/07-matching/check.sh              # 模块07标杆单独入口
bash curriculum/modules/08-database/scripts/check.sh      # 真实 DB 端到端（Docker + PostgreSQL + GixSQL）
bash curriculum/validation/database/check.sh              # P1 ESQL 工具链回归（Docker）
python3 curriculum/modules/07-matching/labs/01-one-to-one/scripts/pressure.py    # L1 内存压力
python3 curriculum/modules/07-matching/labs/04-many-to-many/scripts/pressure.py # L3 多流压力
python3 curriculum/modules/07-matching/labs/05-large-record/scripts/pressure.py # L4 完整链路压力（含 oracle）
bash curriculum/scripts/package-student.sh                # 生成排除 instructor/ 的学生包
```

`curriculum/check.sh` 不需要 Docker，串联 P1 校验、每个模块的快速验收入口，以及三类门禁：冻结银行接口宽度（全部 `copybooks/{ACCOUNT,TRANSACTION,CUSTOMER}-V1.CPY` 实测 47/55/27 字节）、课程材料结构（12 模块的 README/DESIGN/starter/fixtures/expected/scripts/evidence 与双路线）、以及 72 列/ASCII/无 Tab；`08-database` 的快速入口只跑离线契约，真实 DB 实验是可选的独立入口。`curriculum/validation/database/check.sh` 首次联网构建 ESQL 工具，使用一次性数据库/网络，退出清理，无宿主端口或持久化数据库卷。

若本机缺少 Docker、GixSQL 或 PostgreSQL，真实 DB 与部分解释器实验必须记为“未验证”，不得写成通过。

## 平台、ABI 与已验证边界

- 必过平台为 Linux x86-64 + GnuCOBOL 3.2.0；macOS/WSL/ARM 未实测，文档均如实标注“未验证”。
- PIC COMP 在本机实测为 big-endian；COMP-5 native little-endian。二进制表示按锁定 ABI 解释，不跨平台推断。
- 模块 08 使用真实 Embedded SQL（GixSQL 固定 commit + 两个本地补丁 + PostgreSQL）；模块 10/11/12 的 DB 层是明确标注的**离线文件检查点**（`real_db_verified=false`），未接入真实 PostgreSQL。

## 制作进度

| 阶段 | 当前状态 |
|---|---|
| P0 设计 | 已完成并获准实施 |
| P1 技术验证 | 字节/双流/真实DB基线与证据见 `validation/`；平台仅 Linux x86-64 |
| P2 模块07标杆 | L1/SORT/MERGE/L2/L3 主代理已验收；L4 已实现并含完整链路压力证据，待主代理验收 |
| P3 模块01–06、09 | 全部实现并通过执行代理自测；待主代理独立审查 |
| P4 模块08、10 | 实现完成；08 真实 DB 已实测，10 为离线 DB 标注；待主代理审查 |
| P5 模块11、12 | 实现完成；11 六类事故与维护、12 陌生系统与评分；待主代理审查 |
| P6 发布/旧内容过渡 | 学生打包脚本与总入口已就绪；旧版课程素材归档到 `extensions/legacy-workshop/` |

制作基线始终以设计文档为准。每课的输入/业务预期先于实现确定；未验证的平台、恢复边界与 DB 明确保留未完成状态。执行任务与审查协议见[实施 Goal 交接文档](../tasks/enterprise-cobol-implementation-goal.md)。
