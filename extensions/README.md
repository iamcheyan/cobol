# 可选课程与配套资料

32 课主课程从仓库根目录的 [`lessons/`](../lessons/README.md) 开始。本页索引可选拓展，避免把不同目标和先修路径混入主课程顺序。

## 按主课选用拓展

以下材料按 32 课主线定位；它们用于重复练习、比较另一种实现或继续研究，不改变主课顺序，也不作为主课完成条件。

| 主课课号 | 可选补充材料 | 补充主题 |
|---|---|---|
| 01–08 | [`legacy-workshop/lessons/00-environment/`](legacy-workshop/lessons/00-environment/)、[`01-program-anatomy/`](legacy-workshop/lessons/01-program-anatomy/)、[`07-conditions-88/`](legacy-workshop/lessons/07-conditions-88/)–[`09-loops-perform/`](legacy-workshop/lessons/09-loops-perform/) | 环境、固定格式、88 级条件名、控制流 |
| 09–14 | [`legacy-workshop/lessons/10-tables-occurs-search/`](legacy-workshop/lessons/10-tables-occurs-search/)、[`11-strings-unstring-inspect/`](legacy-workshop/lessons/11-strings-unstring-inspect/)、[`14-copybooks-redefines/`](legacy-workshop/lessons/14-copybooks-redefines/)；[`TBLSRCH.COB`](standalone-examples/TBLSRCH.COB) | 表格、字符串处理、Copybook 与重定义 |
| 15–22 | [`legacy-workshop/lessons/12-sequential-files/`](legacy-workshop/lessons/12-sequential-files/)、[`13-file-status-errors/`](legacy-workshop/lessons/13-file-status-errors/)、[`17-reports-control-break/`](legacy-workshop/lessons/17-reports-control-break/)、[`18-sort-merge/`](legacy-workshop/lessons/18-sort-merge/)、[`25-project-csv-pipeline/`](legacy-workshop/lessons/25-project-csv-pipeline/)、[`26-project-fixed-records/`](legacy-workshop/lessons/26-project-fixed-records/) | 文件状态、报表、排序，以及端到端 CSV/定长项目 |
| 23–28 | [`legacy-workshop/lessons/15-subprograms-linkage/`](legacy-workshop/lessons/15-subprograms-linkage/)、[`19-modules-environment/`](legacy-workshop/lessons/19-modules-environment/)、[`20-debugging-diagnostics/`](legacy-workshop/lessons/20-debugging-diagnostics/)、[`21-compiler-options/`](legacy-workshop/lessons/21-compiler-options/)、[`22-bash-build-run/`](legacy-workshop/lessons/22-bash-build-run/)–[`24-bash-pipelines-scheduling/`](legacy-workshop/lessons/24-bash-pipelines-scheduling/) | 子程序、工程调试、构建、自动化和调度 |
| 29–31 | [`legacy-workshop/lessons/16-intrinsic-functions-dates/`](legacy-workshop/lessons/16-intrinsic-functions-dates/)、[`enterprise-batch/curriculum/modules/08-database/`](enterprise-batch/curriculum/modules/08-database/) | 日期函数与真实 Embedded SQL 进阶 |
| 32 | [`legacy-workshop/lessons/28-capstone-night-batch/`](legacy-workshop/lessons/28-capstone-night-batch/)、[`29-reference-topic-map/`](legacy-workshop/lessons/29-reference-topic-map/)、[`enterprise-batch/curriculum/modules/11-incidents/`](enterprise-batch/curriculum/modules/11-incidents/)、[`12-capstone/`](enterprise-batch/curriculum/modules/12-capstone/) | 夜间批处理、知识回顾、事故调查和企业级毕业项目 |

Neovim 辅助练习见 [`neovim-tooling/tutorials/`](neovim-tooling/tutorials/01-punchcard-and-ruler.md)；四个独立示例见 [`standalone-examples/`](standalone-examples/README.md)。

## 旧版基础课程

[`legacy-workshop/`](legacy-workshop/README.md) 保留原有 00–29 课、编译脚本、练习数据和插件工作流。可按主题补充练习；课程顺序与 CPR #31 主课程相互独立。

## 企业批处理扩展

[`enterprise-batch/`](enterprise-batch/README.md) 是 12 模块企业课程，以合成银行夜间处理为案例，包含文件布局、排序突合、模块化、数据库、作业调度、事故调查和毕业项目。

课程设计、讲师参考实现、评分与审查材料均已归入该扩展目录，并由其 README 提供验收入口。数据库模块会区分真实 Embedded SQL 验证和离线文件检查点；按各模块标注的环境条件报告结果。

## Neovim 插件教程

[`neovim-tooling/tutorials/`](neovim-tooling/tutorials/01-punchcard-and-ruler.md) 保留七篇 `cobol.nvim` 教程，覆盖固定格式标尺、结构导航、PIC 计算、诊断、编译工作流、实战示例和插件回归练习。它们是编辑器辅助资料，不是主课程的先修要求。

## 独立 COBOL 示例

[`standalone-examples/`](standalone-examples/README.md) 保留四个独立 COBOL 程序及其 Copybook 和输入数据。进入该目录后运行 `make check`、`make run` 或 `make clean`。
