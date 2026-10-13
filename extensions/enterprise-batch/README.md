# 企业批处理扩展课程

本扩展包含 12 个模块的企业批处理课程，以合成银行夜间流程为案例，覆盖记录布局、文件处理、排序突合、Embedded SQL、模块化、JOB 调度、事故调查和毕业项目。它是 CPR #31 主课程的进阶练习，建议先完成 `lessons/` 中对应的语言、文件和模块化课程。

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
