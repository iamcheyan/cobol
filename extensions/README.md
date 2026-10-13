# 可选课程与配套资料

32 课主课程从仓库根目录的 [`lessons/`](../lessons/README.md) 开始。本页索引可选拓展，避免把不同目标和先修路径混入主课程顺序。

## 旧版基础课程

[`legacy-workshop/`](legacy-workshop/README.md) 保留原有 00–29 课、编译脚本、练习数据和插件工作流。可按主题补充练习；课程顺序与 CPR #31 主课程相互独立。

## 企业批处理扩展

[`enterprise-batch/`](enterprise-batch/README.md) 是 12 模块企业课程，以合成银行夜间处理为案例，包含文件布局、排序突合、模块化、数据库、作业调度、事故调查和毕业项目。

课程设计、讲师参考实现、评分与审查材料均已归入该扩展目录，并由其 README 提供验收入口。数据库模块会区分真实 Embedded SQL 验证和离线文件检查点；按各模块标注的环境条件报告结果。

## Neovim 插件教程

[`docs/`](../docs/01-punchcard-and-ruler.md) 保留七篇 `cobol.nvim` 教程，覆盖固定格式标尺、结构导航、PIC 计算、诊断、编译工作流、实战示例和插件回归练习。它们是编辑器辅助资料，不是主课程的先修要求。

## 独立 COBOL 示例

仓库根目录保留 `INPUTCSV.COB`、`FIXEDREC.COB`、`TBLSRCH.COB` 和 `BATCHRPT.COB` 及其 Copybook/输入数据。通过根目录 Makefile 的 `make check`、`make run` 和 `make clean` 进行语法检查、运行和清理。
