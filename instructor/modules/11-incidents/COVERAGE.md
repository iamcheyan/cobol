# 模块 11 大纲覆盖矩阵（11.1–11.5）

对应 [docs/curriculum/SYLLABUS.md](../../../docs/curriculum/SYLLABUS.md) 的
模块 11。每条要求给出**源码 / 输入 / 学生操作（修改或故障复现）/ expected /
check / 证据**，缺口已补齐（新增 `INC-2026-007` 记录长度/错位实操）。
所有断言均由独立 expected 或原始证据给出，不以“目录存在”“关键词存在”
替代业务验证。平台：Linux x86-64（其他平台未验证）；真实 DB 未接入。

| 大纲要求 | 源码 | 输入 | 学生操作（故障/复现） | expected | check | 证据 |
|---|---|---|---|---|---|---|
| 11.1 从 Scheduler 状态、JOB Log、RC、输入清单建立时间线，保留原始证据 | `system/jobs/*.sh`、`system/cobol/*.COB` | 各 `INC-2026-00X/student/input/`、`scene/MANIFEST` | 读 `scene/scheduler-status.txt`、`scene/logs/`、`scene/run.env`、`scene/console.txt`、`scene/rc.txt` 复原时间线 | `expected/incidents.txt`（各事件 RC/发布） | `scripts/check.py::check_incidents`（as-found RC、发布状态、夹具前后哈希不变） | 各 `student/scene/`；`evidence/README.md` 模板 |
| 11.2 非法数字：先重现再定位 | `system/cobol/M11VAL.COB`（`2000-PROCESS` 数字校验） | `fixtures/INC-2026-001/`；`INC-2026-001/student/input/transaction.dat` | `bash INC-2026-001/student/run.sh …`；`od -An -tc` 定位非数字键 | as-found RC=8、不发布（`incidents.txt`） | `check.py::check_incidents["INC-2026-001"]` | `INC-2026-001/student/scene/logs/JOB002.log`；`inc-01/ROOT-CAUSE.md` |
| 11.2 记录错位/长度不符：先重现再定位 | `system/cobol/M11VAL.COB`（长度 ≠ 55 → 结构错误） | `fixtures/INC-2026-007/`（首条 54 字节）；`INC-2026-007/student/input/transaction.dat` | `bash INC-2026-007/student/run.sh …`；`awk '{print NR": "length($0)}'` 逐条量长度 | as-found RC=8、不发布（`incidents.txt`） | `check.py::check_incidents["INC-2026-007"]` | `INC-2026-007/student/scene/logs/JOB002.log`（`record length 0054 is not 55`）；`inc-07/ROOT-CAUSE.md` |
| 11.2 运行时异常：先重现再定位 | `system/jobs/job003-sort.sh`（`mktemp`） | `fixtures/INC-2026-005/`（正常输入 + 环境注入） | `bash INC-2026-005/student/run.sh …`（PATH 注入失败 `mktemp`） | as-found RC=12、不发布（`incidents.txt`） | `check.py::check_incidents["INC-2026-005"]`（PATH shim） | `INC-2026-005/student/scene/logs/nightly.log`；`inc-05/ROOT-CAUSE.md` |
| 11.3 DB 唯一约束 | `system/lib/db.py`（幂等键 `(business_date, transaction_id)`） | `fixtures/INC-2026-002/`；`INC-2026-002/student/scene/{db-schema.sql,sql-log.txt,ledger-victim.dat}` | `bash INC-2026-002/student/run.sh …`；`sort\|uniq -d` 查重复键 | as-found RC=0 且**发布**（缺陷），desired RC=8 不发布 | `check.py::check_red_green`（RED 2 行同键/发布 → GREEN `inc-02/fix/db.py` RC8 不发布） | `inc-02/ROOT-CAUSE.md`；`evidence/A02-red-green-2026-10-10.txt` |
| 11.3 0 字节文件 | `system/jobs/job001-receive.sh`（Manifest 校验和） | `fixtures/INC-2026-003/`（0 字节 + Manifest 声明非空） | `bash INC-2026-003/student/run.sh …`；`wc -c`/`sha256sum` 对比 | as-found RC=12、不发布 | `check.py::check_incidents["INC-2026-003"]` | `INC-2026-003/student/scene/logs/JOB001.log`；`inc-03/ROOT-CAUSE.md` |
| 11.3 Master 逆序 | `system/cobol/M11MATCH.COB`（顺序前提检查） | `fixtures/INC-2026-004/`（账户 Seed 逆序） | `bash INC-2026-004/student/run.sh …`；`sort -c -k1.1,1.10` 验证 | as-found RC=8、不发布 | `check.py::check_incidents["INC-2026-004"]` | `INC-2026-004/student/scene/logs/JOB005.log`；`inc-04/ROOT-CAUSE.md` |
| 11.3 临时空间/权限失败 | `system/jobs/job003-sort.sh`、`system/lib/common.sh` | `fixtures/INC-2026-005/` + PATH 注入 | 同 11.2 运行时异常 | as-found RC=12、不发布、锁释放 | `check.py::check_incidents["INC-2026-005"]`；`check_no_clobber_and_lock` | `INC-2026-005/student/scene/`；`inc-05/ROOT-CAUSE.md` |
| 11.4 RC=0 但余额错误 | `system/lib/db.py`（`cmd_apply`） | `fixtures/INC-2026-002/` | 独立重算账户期末 vs `published-closing-master.dat` | 缺陷：RC0+发布；desired RC8 不发布 | `check.py::check_red_green` | `INC-2026-002/student/scene/published-*`；`A02` |
| 11.4 RC=0 但控制总数错误 | `system/lib/control.py`（内部核对） | `fixtures/INC-2026-006/`（Manifest 声明 `control_*`） | 独立重算 vs `published-control-report.txt` 与上游声明 | 缺陷：RC0+发布；desired RC8 不发布 | `check.py::check_red_green`（GREEN `inc-06/fix/control.py` RC8 不发布） | `INC-2026-006/student/scene/MANIFEST`；`inc-06/ROOT-CAUSE.md`；`A02` |
| 11.5 客户区分 1→2 位：先调查再修改 | `maintenance/copybooks/ENTERPRISE-CLASS-{V1,V2}.CPY`、`maintenance/M11CUST2.COB`、`maintenance/migrate-customer.py` | `fixtures/enterprise-customer/customer.v1` | 先交五份调查文档（模板见 `evidence/README.md` 末节），评审后再实现；`maintenance/README.md` §5 给出可复现命令 | `expected/enterprise-class-v{1,2}.txt`、黄金字节（见 check） | `maintenance/check.sh`（迁移/回滚/并行/跨版本/异常 + 偏移/PIC/黄金字节）；`scripts/check.py::check_customer_contract` | `instructor/.../maintenance/{INFLUENCE-INVESTIGATION,CHANGE-LIST,CHANGE-PLAN,TEST-CASES,EVIDENCE-PLAN}.md`；`evidence/A03` |
| 成果：影響調査書／修正対象一覧／修正方針／Test Case／Evidence／事故復盤 | 讲师参考文档 | 同上 | 学员按模板提交 | `TEST-CASES.md` 每项 `输入→期望 RC/输出→证据位置` | `maintenance/check.sh` 覆盖正常/边界/异常/跨版本/恢复 | `instructor/.../maintenance/*.md`、`evidence/README.md` |
| 验收：根因有源码/数据/日志证据 | 各事件 `scene/source/` | 各 `scene/logs/`、`input/` | 定位根因并给偏移/字节 | `inc-0X/ROOT-CAUSE.md` 与 scene 一致 | `check.py`（RC/发布）+ 人工评阅根因 | `evidence/A01`、各 `ROOT-CAUSE.md` |
| 验收：修复不改原始输入 | 只读夹具 | `fixtures/`、`*/student/input/` | 修复用新增校验或重传，**不**改写原输入 | 夹具前后哈希一致 | `check.py::check_fixture_manifest`（SHA256SUMS）+ `check_incidents` 前后哈希 | `evidence/A01` |
| 验收：回滚与重跑边界 | `migrate-customer.py`（`to-v1`）、`system/scripts/run.sh`（新 run_id） | V1/V2 文件 | 回滚字节级还原；失败用新 run_id/新输出目录重跑 | `enterprise-class-v1` 还原比对 | `maintenance/check.sh` step 6（rollback byte-identical） | `evidence/A03` |

## 覆盖缺口与结论

- 11.2“记录错位”原先只有代码路径（`M11VAL.COB` 长度检查），**无夹具/实操**；
  本次新增中性事件 `INC-2026-007`（首条 54 字节）+ student 包 + scene +
  `incidents.txt` 条目，`check.py::check_incidents` 自动断言 RC8/不发布。
- 11.5 企业布局改用独立名称 `ENTERPRISE-CLASS-V{1,2}`（不与 canonical 模块
  07 L4 的 `ENTERPRISE-CUSTOMER-V1` 同名）；偏移/PIC/语义黄金字节由
  `instructor/.../maintenance/verify-layout.py`（GnuCOBOL `ADDRESS OF` 实测）
  与 `scripts/check.py::check_customer_contract` 双重校验。
- **仍未验证**：真实 PostgreSQL/DB2（本模块为离线文件检查点，所有 DB 证据
  标注 `real_db_verified=false`）；macOS/WSL/其他 ABI；1778 字节大记录的
  实际维护变更（canonical 定义在模块 07 L4 / 模块 12，不在本模块文件范围）。
