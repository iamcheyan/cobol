# 企业批处理扩展课程

本扩展包含 12 个模块的企业批处理课程，以合成银行夜间流程为案例，覆盖记录布局、文件处理、排序突合、Embedded SQL、模块化、JOB 调度、事故调查和毕业项目。它是 CPR #31 主课程的进阶练习，建议先完成 `lessons/` 中对应的语言、文件和模块化课程。

## 与 32 课主线衔接

| 建议先完成的主课 | 企业扩展模块 | 适合继续练习 |
|---|---|---|
| [15–22 文件处理](../../lessons/DIRECTORY.md) | [06 文件](curriculum/modules/06-files/README.md)、[07 排序突合](curriculum/modules/07-matching/README.md) | 多流文件、排序合并和银行对账 |
| [23–28 工程化](../../lessons/DIRECTORY.md) | [09 模块化](curriculum/modules/09-modular/README.md)、[10 JOB](curriculum/modules/10-jobs/README.md)、[11 事故调查](curriculum/modules/11-incidents/README.md) | 作业编排、重跑恢复和既存系统维护 |
| [29–31 数据库](../../lessons/DIRECTORY.md) | [08 Embedded SQL](curriculum/modules/08-database/README.md) | GixSQL/PostgreSQL 实测游标、事务和幂等处理 |
| [32 毕业项目](../../lessons/32_bank-reconciliation-project/README.md) | [12 企业毕业项目](curriculum/modules/12-capstone/README.md) | 多作业银行夜间批次和故障恢复 |

## 资料

- [`curriculum/README.md`](curriculum/README.md)：模块地图、状态和验收入口。
- [`docs/curriculum/README.md`](docs/curriculum/README.md)：设计、银行数据契约和编写标准。
- [`instructor/`](instructor/)：讲师参考实现、评分材料和审查记录。
- [`tasks/`](tasks/)：课程制作、审查和交接记录。

## 检查

从仓库根目录运行：

```sh
bash extensions/enterprise-batch/curriculum/check.sh
```

或进入本扩展目录后运行：

```sh
cd extensions/enterprise-batch
bash curriculum/check.sh
```

快速检查覆盖各模块、课程打包和固定格式门禁。需要 Docker 的 PostgreSQL/GixSQL 路线由独立脚本验证；Docker 不可用时必须保留 `UNVERIFIED` 状态。模块文档会区分真实数据库结果和离线文件检查点。
