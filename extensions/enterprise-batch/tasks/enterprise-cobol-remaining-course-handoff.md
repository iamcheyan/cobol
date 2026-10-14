# 企业 COBOL 课程：即时接手交接

日期：2026-10-10  
仓库：`/home/tetsuya/development/cobol`（公开仓库 `iamcheyan/cobol`）

## 当前进度与接手边界

用户因当前代理额度有限，要求尽快将课程剩余工作交给另一 agent。新 agent 可立即开始；不必等待本代理完成模块07。接手的第一步是收尾模块07，再完成全部其余课程，最后交回主代理做统一独立验收。

| 范围 | 状态 |
|---|---|
| B00 基线与工具链 | 已验收；记录见 `tasks/enterprise-cobol-progress.md` |
| B01 模块07.4 L2 1:N | 已验收，commit `d4ca202`（后续缓存忽略修复 `8895ce5`） |
| B02 模块07.1/07.2 SORT/MERGE | 已验收，commit `2affe66` |
| B03 模块07.5 L3 多流 | 已验收，commit `ad058c5` |
| B04 模块07.6 L4 大记录 | 实现包已完成，未验收、未提交；独立审查发现验收脚本 `scripts/verify.py` 将整个输入读入内存并构造整份预期报告。当前正式压力证据只测 COBOL 核心，未覆盖带 Python 校验器的完整 runner。必须先改为流式/有界内存校验，并按完整执行链测内存和失败发布边界，再由独立验收决定是否放行。 |
| B05 模块07整体收口 | 尚未开始。需整合七节课程、总目录与回归，验收完整模块07。 |
| 模块01–06、08–12与毕业项目 | 尚未完成；以课程规格及大纲为准。 |

B04文件主要位于 `curriculum/modules/07-matching/labs/05-large-record/`，canonical参考程序和Copybook位于 `instructor/modules/07/05-large-record/`。验收具体要求、已知探针和过程记录见 `tasks/enterprise-cobol-review.md`。B04设计已获“可进入实现”批准，不代表实现验收通过。不要把作者报告中的总入口RC0当作主代理验收。

## 必读文件

按顺序阅读 `AGENTS.md`、本交接、`tasks/enterprise-cobol-implementation-goal.md`、`tasks/enterprise-cobol-progress.md`、`tasks/enterprise-cobol-review.md`、`tasks/prd-enterprise-cobol-course.md`、`../docs/curriculum/SYLLABUS.md`、`../docs/curriculum/BANK-SYSTEM.md`、`../docs/curriculum/AUTHORING-STANDARD.md`、`curriculum/README.md` 和数据库验证说明。完整交付合同及模块细项以这些文件为准；本交接不缩减原课程要求。

## 工作区保护

接手时 `git status --short` 已有历史未提交内容：`Makefile`、`course/` 旧课程、`curriculum/README.md`、`curriculum/check.sh`、实施 goal/progress/review，以及新增的新版课程文件。逐项保留，不执行 `git reset`、`git clean`、覆盖性 checkout/stash；禁止 `git add .`。先记录状态，再只操作新课程的明确路径。执行 agent 不提交、不推送、不宣布验收通过；把文件清单、真实命令/原始返回码、证据和未解决问题交给主代理。

## 立即执行顺序

1. 收尾B04：修复独立oracle的大文件全量缓存；压力必须测到完整runner/driver和核心，至少覆盖百万条匹配记录及高差异报告情形，并记录各层峰值及源码/数据SHA。核查流式输入、输出、expected、报告比较、hash检查及失败时无发布。重新运行课程总入口；把真实证据写进课程 evidence。
2. 收尾B05：逐项检查模块07的课程与接口一致性，确保SORT/MERGE、L1、L2、L3、L4及银行系统模型衔接，提供学生包与讲师参考、逐课命令和独立回归；不得只更新目录或写概述。
3. 实现剩余模块和毕业项目：模块01–06、08–12，完整满足12模块大纲、76小时左右课程规模、企业夜间银行Batch主线。重点完成SORT/MERGE以外的文件/数据基础、真实DB/GixSQL、CALL/LINKAGE、Shell/JOB/重跑、故障调查、Legacy影响调查和毕业项目；07/10/11不可缩水。
4. 分模块交付，每课满足作者规范：真实代码和数据、独立expected、starter及参考答案、构建/运行/验证/复位、故障练习、学生证据模板、讲师提示与评分、适用的失败不发布检查。所有命令从干净副本/任意cwd按文档可复现。
5. 更新总目录、覆盖矩阵、进度和证据。最后运行总入口与数据库验证；如环境缺失必须明确记录未验证，不得宣称通过。交付完整变更清单和证据给主代理，不自行提交或推送。

## 核心验收要求

- 冻结银行文件布局和全局契约：CUSTOMER v1 27B、ACCOUNT v1 47B、TRANSACTION v1 55B；不要静默改接口。
- 展示真实数据处理，不以文字展示或伪代码冒充实现。输入文件、损坏样本、预期输出和运行方式必须齐全。
- Expected须独立于被测程序生成/核算；说明人工算例、字段偏移和金额守恒依据。
- 固定格式COBOL保持Area A/B、无Tab、有效代码不超过72列；自由格式需明确说明。
- 验证正常、边界、非法数据、RC、精确字节/计数/金额、锁与目标保护、失败不发布及复位边界。
- 大文件资源证据必须覆盖真实完整链路；不可仅测COBOL核心而隐去Python runner或报告预期缓存。记录数据规模、输出规模、RSS口径、源码和夹具SHA、实际临时磁盘占用、失败注入和正式目标状态。
- 课程面向初学者，但目标是最终能维护真实Legacy Batch；含GNUCOBOL环境说明，并把插件操作和纯终端替代路线并列。

## 可直接发给接手 agent 的 Prompt

```text
请接手并完成 /home/tetsuya/development/cobol 中企业级 GNUCOBOL 课程的全部剩余工作，完成后交给主代理做统一独立验收。

先完整阅读 AGENTS.md、tasks/enterprise-cobol-remaining-course-handoff.md、tasks/enterprise-cobol-implementation-goal.md、tasks/enterprise-cobol-progress.md、tasks/enterprise-cobol-review.md、tasks/prd-enterprise-cobol-course.md、docs/curriculum/SYLLABUS.md、docs/curriculum/BANK-SYSTEM.md、docs/curriculum/AUTHORING-STANDARD.md、curriculum/README.md，以及数据库验证说明。

当前状态：B00–B03已由主代理验收；B04（07.6 L4）实现包存在但未验收，已知阻塞为 scripts/verify.py 全量读入输入并构造完整expected报告，而正式压力只覆盖COBOL核心；B05（模块07收口）未开始；模块01–06、08–12未完成。先收尾07.6并完成模块07整体回归，再实现全部其余模块和毕业项目。不要把B04作者RC0说成主代理验收。具体目录、已知问题、冻结契约和证据口径以交接文件及review记录为准。

课程要达到企业Legacy Batch实战标准：同一银行夜间批处理系统贯穿12模块，包含可运行COBOL、配套完整数据与expected、COPYBOOK/设计契约、学生starter、讲师参考、构建运行检查复位、修改任务、可复现故障、学生证据模板和评分提示。重点不能缩水模块07 SORT/MERGE与突合、模块10 Shell/JOB/重跑、模块11障害调查和维护；还需完成真实DB/GixSQL、CALL/LINKAGE、综合毕业项目及影响调查。每项要求以课程大纲/作者规范为准，不要以新增README或简化示例代替课程。

严格保护当前工作区：开始和结束均记录git status；保留旧 Makefile、course/ 和其他历史脏文件；禁止 reset、clean、覆盖性checkout/stash、git add .。不要提交或推送。只修改任务相关明确文件。

每模块先形成实施/验收清单，逐项实现和验证；失败时修复并重跑。独立expected不得照抄被测结果。大文件压力必须测实际完整runner/driver+COBOL核心，包括百万级与高差异报告，不能用只测核心的RSS掩盖oracle全量缓存；记录命令、原始RC、峰值内存、磁盘spill、输入输出规模、源码/数据SHA、正式发布状态。测试未实际运行、依赖缺失或无法验证的部分明确标记，绝不伪称通过。

完成后运行总课程检查及适用DB验证，更新进度/覆盖矩阵/证据，向主代理提交明确文件清单、验证结果、限制和未解决风险。主代理负责最终审查、验收和提交。
```
