# 模块 12 人工审核签署（参考答案专用）

MANUAL-REVIEW-SIGNOFF

本签署**只覆盖课程仓库中的参考答案材料**，用于 `grade.py` 自检时把“人工学习成果”
从 PENDING 转为 PASS。它**不可转移**给任何学员提交：学员提交没有讲师签署，
`grade.py` 会正确报告 `PENDING manual review` —— **参考答案自测通过不等于学生毕业**。

审核方式：逐项阅读下列交付物，确认其为**已填写实质内容**（非空文件、非未填模板），
且顺序满足“先调查、后修改”。

| 审核项 | 文件 | 结论 |
|---|---|---|
| 影響調査書（先于修改） | `maintenance/impact-investigation.md` | 通过：含字段定义、使用位置、依赖与未知项 |
| 修正対象一覧 | `maintenance/change-list.md` | 通过：列出 Copybook/程序/JOB/接口 |
| 修正方針 | `maintenance/change-policy.md` | 通过：v1/v2 兼容、迁移、回滚 |
| Test Case | `maintenance/test-cases.md` | 通过：正常/边界/异常/跨版本/恢复 |
| Evidence 计划 | `maintenance/evidence-plan.md` | 通过：每项测试的期望与证据位置 |
| 学员证据模板 | `evidence/README.md` | 通过：模板未预填通过结果 |
| 组成与依赖追踪 | `COMPOSITION.md` | 通过：去重组成、使用关系、规模差距如实记录 |

硬门禁 G6（先调查后修改）：`maintenance/impact-investigation.md` 记录调查日期早于
任何代码修改，且 `evidence/README.md` 为可审查的过程记录模板；本项为**人工判断**，
脚本只能确认其存在且有实质内容，不能自动证明顺序。

审核人：课程维护者（参考答案）。日期：2026-10-10。
