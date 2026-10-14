# 企业 COBOL 课程独立验收与返工要求

日期：2026-10-10。审查对象：当前工作树，基线 HEAD `ad058c5334d08d4f426f7a378ef567ad3f0cd2e9`。

## 结论

**暂不通过最终验收。** 实现已有相当成果：12 模块接入总检查，模块08与P1具备真实 PostgreSQL/GixSQL 验证，B04 oracle 已采用流式处理。但现有绿色检查没有覆盖下列反例，不能据此认定全部课程满足设计。

本文件只提出审查意见和修复验收要求，不修改实现。保留已接受的 B00–B03 成果，不要求推倒重做。P1 是验收阻塞项；P2 应修复，或者逐项提交明确差距供主代理裁定，不能自行降低原规格。

依据：`tasks/enterprise-cobol-implementation-goal.md`、`tasks/prd-enterprise-cobol-course.md`、`tasks/enterprise-cobol-remaining-course-handoff.md`、`../docs/curriculum/SYLLABUS.md`、`../docs/curriculum/BANK-SYSTEM.md`、`../docs/curriculum/AUTHORING-STANDARD.md`、`curriculum/validation/B04-INDEPENDENT-ACCEPTANCE.md`。

## 已独立执行的验证与边界

| 命令 | 原始 RC | 说明 |
|---|---:|---|
| `bash curriculum/check.sh` | 0 | 12模块和当前门禁通过；模块08在此入口走快速检查 |
| `bash curriculum/modules/08-database/scripts/check.sh` | 0 | 真实 Docker/PostgreSQL17/GixSQL，并有独立 psql 验证 |
| `bash curriculum/validation/database/check.sh` | 0 | P1真实数据库回归 |
| 模块08以正确参考源码设置 COURSE_SOURCE 运行 | 12 | 正确实现被学生入口拒绝，见 R06 |
| 学生包生成 | 0 | 打包成功不代表可用或无答案泄漏，见 R07 |

本次未重跑百万条完整压力链路；作者所报百万规模数值不能标为本次独立复验通过。已审查相关代码、作者证据及针对性失败反例。

本机总检查日志：`/tmp/cobol-final-primary-review-check.log`；模块08：`/tmp/cobol-final-primary-review-db08.log`；P1：`/tmp/cobol-final-primary-review-p1db.log`。临时日志不是永久交付材料，修复代理应保存自己的可复现实验与证据。检查脚本可能重写作者 evidence；这不等于审查者修改了课程实现。

## R01 · P1 · 最终 JOB 与真实 DB 没有贯通

**位置：** 模块10/11/12 README 的离线声明；模块08作者证据 `AUTHOR-EVIDENCE-2026-10-10.md`；目标文档 B10/B11。

模块08真实 DB 实验确实存在，但10/11/12仍是 Python 文件检查点，标为 `real_db_verified=false`。B03早期允许离线种子，不代表 B10/B11 最终真实抽取、更新、提交与恢复可以全部由离线模型替代。模块08普通成功后再运行一次，也不能证明 COMMIT 结果未知时恢复正确。

**要求：** 把真实抽取接入 L3 与最终 JOB004/JOB006，保留明确标注的离线教学路线；增加真实提交中断、提交结果未知、并发重试的验证，用独立数据库查询检查余额与幂等记录。数据库环境不可用时应报告未验证，不得用离线 RC0 代表真实端到端验收。

**验收：** 真实数据库运行完整 JOB；故障后重跑不重复入账，独立查询证明结果；保存原始 RC、数据库前后状态与实际故障发生边界。

## R02 · P1 · 余额与幂等账本分开持久化，重跑不安全

**位置：** `curriculum/modules/12-capstone/system/lib/capdb.py` 约319–321行；模块10 `lib/db.py` 约271行。

先 `write_balances`，再 `atomic_write(ledger.dat)`，两个原子文件写不是一个原子业务事务。当前 mid 注入在两者之后，没有覆盖危险窗口。

**反例：** 正常业务日停在 before-db-commit 后，让仅写 ledger 的 atomic_write 抛 I/O 异常。账户1余额已变1450，账本没有记录；再次 apply 尝试计算1900，与候选1450不符并返回8。不能安全恢复。

**要求/验收：** 真实 DB 用同一事务提交余额与幂等账本；保留离线模型时采用可恢复的版本切换或日志协议。逐个持久化边界注入故障，证明重跑一次入账、状态一致，不能只验证几个命名 hook。

## R03 · P1 · 发布后的失败会删除正式结果和调查证据

**位置：** 模块12 `scripts/run.sh` 约206–210行；模块10 `scripts/run.sh` 约210行。

错误处理遇8/12直接删除 output，未判断正式发布是否已经完成。

**反例：** during-publish 中断原始RC97；将 `db/publish_registry.dat` 置为目录造成登记写失败；恢复后正式发布已发生，随后RC12，整个 output 被删除，DB提交仍在。

**要求/验收：** 按实际状态区分未发布暂存、已提交、已发布、登记待恢复。保留正式产物和日志；对发布登记、完成标记、次日准备分别注入 I/O 故障，证明可恢复且不重复扣款。禁止通过删除已经发布的目录制造“失败无发布”的表象。

## R04 · P1 · 模块09接受全局重复交易 ID

**位置：** `instructor/modules/09-modular/BATCH09.COB` 约299行；`scripts/oracle.py` 约103行。

按账户/序号/交易ID排序不能保证全局交易ID唯一，oracle也没有拒绝同类问题。

**反例：** 正常交易第3条的第11–26字节替换为第1条交易ID，保留账户和序号。运行RC0并发布，两条均 ACCEPT。

**要求/验收：** 按银行契约做全局重复检测，采用已有外排或其他有界内存机制；独立 oracle 覆盖同账户不同序号及跨账户重复。明确业务 RC，不允许同一交易重复入账。

## R05 · P1 · 模块03/04只改完成标志即可发布错误答案

**位置：** 模块03 `scripts/run.sh` 约52–70行；模块04约49–66行；`starter/M03BYTES.COB`、`starter/M04SHAPE.COB` 等。

运行入口依赖完成标志和自身文件散列，没有独立验证结果含义。

**反例：** 只把 `WS-EXERCISES-DONE` 从 N 改 Y，03.3 可RC0发布 `TODO,03.3 packed parser`，04.1可RC0发布 `REDEFINES,WRAP-LEN,000`。

**要求/验收：** 对输入记录、解码值/符号、原始字节、记录数与布局做独立语义核验。仅改标志、跳过记录、错误金额/符号、占位报告均应失败且不发布。不得把参考实现的同一计算复制成 oracle 后宣称独立。

## R06 · P1 · 模块08正确学生源码也必定失败

**位置：** `curriculum/modules/08-database/scripts/run.sh` 约122–128行。

设置 COURSE_SOURCE 后，代码要求 snapshot RC12并无条件失败。参考 SNAPSHOT 的合法RC4也被拒绝。

**已实跑反例：** 在仓库根目录执行：

```sh
review_out=$(mktemp -d)
COURSE_SOURCE="$PWD/instructor/modules/08-database/SNAPSHOT.COB" \
  bash curriculum/modules/08-database/scripts/run.sh "$review_out/output" 20261009
```

结果RC12，日志 `FAIL: student snapshot RC=4 (want 12)`，未发布。本次日志 `/tmp/cobol-primary-m08-source-QEFtkc2Z/run.log`。

**要求/验收：** 未完成 starter 的负向检查与正常学生入口分离。所有源码走相同业务验证；正确参考作为 COURSE_SOURCE 应完成正常流程，错误学生实现应被实际语义检查拒绝。

## R07 · P1 · 学生包缺运行依赖，同时泄漏练习答案

**位置：** `curriculum/scripts/package-student.sh` 约19–34行；模块01 build/run；模块12 README约106–107行。

打包只按 instructor 路径/文件名排除。独立临时目录解包后，模块01默认 build/run 均RC12，因为依赖已被排除的 `instructor/modules/01-foundations/BANK-ENTRY.COB`。包中却保留 `modules/12-capstone/system/cobol/CUSTV2.COB`，README明确将它列为 starter/CUSTV2 的参考答案。部分校验清单还引用已排除文件。

**要求/验收：** 明确区分学生必需的既存系统、构建依赖和需隐藏的练习解答。不可简单把 instructor 整体放回去。全新隔离包按 README 完成构建、运行、检查和提交；完成后的学生源码可验收。检查答案泄漏按任务角色与内容进行，不能只有文件名扫描。既存系统调查所需源码可以提供，当前练习完整答案不能同时发给学生。

## R08 · P1 · CUSTOMER教学仍错，企业接口同名不同布局

**位置：** 模块02 README约22–24行、DESIGN约37–38行；模块07 L4、模块11 maintenance、模块12 system copybooks。

模块02仍将 CUSTOMER 第27字节称为区分/状态，并讲27→28迁移；冻结契约规定它仅为 status A/D。

`ENTERPRISE-CUSTOMER-V1` 在课程中实际存在三种布局：L4是175字段1778字节，模块11是23字节，模块12是31字节。相同接口名与版本不能代表互不兼容的记录；仅检查总宽度无法防止语义错误。

**要求/验收：** CUSTOMER V1持续27字节且末字节status。企业大记录维护复用已有 canonical 接口；如确需另设小型练习，采用独立明确名称并解释关系，仍须完成真实大记录维护任务。增加字段偏移、PIC和语义黄金字节验证，禁止同名版本漂移。检查全部教学文字与示例，不只改程序。

## R09 · P1 · B04差异报告无法定位客户记录

**位置：** L4 DESIGN约38行；`instructor/modules/07/05-large-record/BATCHL4.COB` 约345行；verify.py约124–150行。

当前报告形如 `FIELD,B04-HEA-008,55,4,NUMERIC`、OLD/NEW，没有客户标识/记录边界。多客户产生同字段差异时无法对应业务记录。设计要求运行号、输入版本、旧新序号、脱敏客户键、字段ID/名称等上下文。

**要求/验收：** FIELD和AUDIT输出包含所需上下文且保持脱敏；独立验证至少两个客户同字段不同变化，证明每条差异均能唯一归属。同步规范、oracle、示例和压力证据。

## R10 · P1 · B04 reset 不检查真实运行锁

**位置：** B04 reset约7–8行，runner约12行。

reset检查 running.lock/.b04-run.lock，runner实际使用 `OUTPUT.lock`。

**反例：** workspace已有正常输出，创建 workspace/output.lock 后执行 reset，RC0删除输出但保留锁。

**要求/验收：** 使用统一锁协议；真实目录锁和符号链接锁均拒绝 reset、返回12，保留全部原内容。考虑检查与删除之间的竞争，不能只增加一个文件名判断而不处理运行互斥。

## R11 · P1 · 压力程序的RC0不能证明通过，磁盘证据不足

**位置：** B04 pressure.py scenario约159–191行、main约225–254行；verify.py约195行。

scenario记录 runner_rc/expected_rc/published，却不强制断言；main写JSON后正常结束。独立导入后将 run_runner 替换为返回12，执行 expected_rc4 的 scenario，仍正常返回 runner_rc12、publishedFalse。这表明作者引用的CLI RC0不足以证明场景通过。

oracle还使用默认 NamedTemporaryFile，压力环境未固定 TMPDIR，可能在/tmp产生约49MB expected；说明却声称不使用/tmp。dir_bytes只测最终逻辑大小，不能证明暂存/快照/oracle的磁盘峰值。

**要求/验收：** 不符合RC、发布状态、verifier或故障边界不变量时，CLI必须非零并保存失败证据。明确全部 scratch 位置与清理规则；实测磁盘高水位及空间不足行为。补充 oracle临时空间耗尽测试：RC12、不发布、不遗留锁。流式内存实现可保留，不要求重新全量读内存。

## R12 · P1 · 覆盖矩阵声称完成的知识没有对应实验

**例证：** 模块02 PIC A/78主要停留文字；模块05缺实际 PERFORM VARYING、作用域/顺序跌落实验；模块06.4同进程重复OPEN得到41，不能代替两个进程争锁实验。后者即使后端不支持互斥，也应以实测证明限制并验证JOB锁方案。

目录存在、README含“插件/终端”不是课程内容完成证据。

**要求/验收：** 为原 syllabus 每条要求建立源码、输入、学生修改/故障、expected/check、证据对应表，缺项补实操。检查学生按文档能执行，不能只添加空文件或关键词。模块11 maintenance README约76行还用 bash执行Python迁移脚本，应校正文档并实际走一遍。

## R13 · P1 · 毕业评分把空文件当作影响调查完成

**位置：** `instructor/modules/12-capstone/grading/grade.py` 约47–48行、131–132行。

独立构造8个要求路径的空文件，`check_maintenance_files` 返回 `(20, [])`；空 `evidence/README.md` 配合存在的调查文件即可满足G6表达式。无法证明先调查再修改，也无法证明内容合格。

**要求/验收：** 区分自动业务验证与需要人工审核的学习成果。空文件、未填写模板不能得完成分；影响调查、修改边界、测试证据、事故恢复必须审核实质内容。调查先于修改需可审查的过程记录，无法自动证明时标为待人工审核，不得自动PASS。参考答案自测通过不等于学生毕业。

## R14 · P2 · 事故初始材料直接透露根因

**位置：** 模块11 incident目录如 inc-01-bad-digit、inc-02-dup-txid、inc-04-unsorted-master及起始说明。

名字已经回答调查题，不符合只给症状、日志和既存系统的要求。

**要求/验收：** 对学生使用中性事件ID和症状描述；根因与分级提示留给教师/按需提示。盲测初始材料不直接披露答案，调查所需源文件和业务证据仍完整提供。

## R15 · P2 · 规模统计不能等同于综合系统复杂度已达标

模块12作者报告将多个未接入编排的课程程序计入约9968行；模块内668行还包括未完成starter。DESIGN承认部分仅作为可读材料。

**不是要求模块12新写8000行，也禁止灌水凑行数。** 复用既存 canonical系统是允许的，但应区分实际运行依赖、维护调查依赖、独立教学参考、starter与生成文件。

**要求/验收：** 提供去重的系统组成清单、JOB/程序/COPY/表的使用关系与统计方法；让毕业需求确实需要追踪这些依赖。尚有差距如实记录供裁定，不得仅凭仓库总行数宣布“差距：无”。

## 建议修复顺序

1. R01–R03：真实DB、事务、发布恢复安全，先防止业务状态损坏。
2. R04–R06、R10–R11：重复交易、学生语义验证、入口与压力失败判定。
3. R08–R09、R12：统一接口、可定位差异、补齐课程实操。
4. R07、R13–R15：隔离学生交付、真实评分、盲事故、组成证据。

每项先保存反例，再修复并补针对性回归；同源oracle、完成标志、目录存在检查不得替代业务验证。不要为保持绿色而修改原规格或降低断言。数据库离线路线仍可保留，但不得冒充真实验证。

## 执行代理交回要求

按 R01–R15 逐项提供：处理状态、修改文件、原反例现在的结果、执行命令、原始RC、是否发布、独立业务断言、证据路径、仍未验证的平台/场景。无法完成要明确阻塞与差距，不自行豁免。

复验总入口、真实模块08、P1、修复后百万完整压力及隔离学生包；压力失败本身必须可被非零RC识别。保留工作树历史修改，不reset/clean/stash覆盖其他工作，不git add/commit/push。完成后交回主代理独立验收；执行代理不得自行宣布最终验收通过。

## 可转发的执行 prompt

请在 `/home/tetsuya/development/cobol` 按 `tasks/enterprise-cobol-final-review-2026-10-10.md` 修复 R01–R15。先阅读原设计和交接文档，逐项复现审查反例，再修实现、文档与有效回归。优先事务/发布恢复与真实DB贯通，其次学生入口、接口、课程深度和打包评分。不得降低原规格或断言、以离线DB冒充真实链路、用删除正式产物掩盖发布后故障、凑代码行数。保留已有脏工作树，不提交或推送。逐项保存命令、原始RC、发布状态、独立断言和证据，完成后按R编号汇报已修/未修及限制，等待主代理独立复验。
