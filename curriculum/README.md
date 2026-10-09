# 企业 Legacy Batch COBOL 课程（制作中）

本课程按[12模块/76小时设计](../docs/curriculum/README.md)制作，统一使用合成银行夜间处理案例。目前已实现技术验证和模块07的L1单元，**尚未完成全部课程，也尚未完成模块07**。旧 `course/` 是历史材料，不能当作新版课程验收结果。

## 已可运行

- [P1 字节布局](validation/layout/README.md)：DISPLAY、COMP-3正负数、COMP、COMP-5原始字节。
- [P1 双流原型](validation/matching/README.md)：24个状态/异常用例。
- [P1 DB 工具链](validation/database/README.md)：GixSQL候选、真实PostgreSQL游标/NULL/事务与独立持久化检查，包含明确的本地依赖补丁。
- [模块07 / L1](modules/07-matching/labs/01-one-to-one/README.md)：47/55字节银行接口、三类突合、学员起始代码、讲师答案、异常数据、运行发布与压力检查。

## 本地验收

```bash
bash curriculum/check.sh
bash curriculum/validation/database/check.sh
python3 curriculum/modules/07-matching/labs/01-one-to-one/scripts/pressure.py
```

第一条不需要Docker；第二条首次联网构建ESQL工具，使用一次性数据库/网络，退出清理，无宿主端口或持久化数据库卷；第三条生成最高每侧百万条数据并清理，Linux上测matcher进程RSS。课程编译产物不写入源码目录。

执行任务与主代理审查协议见[实施Goal交接文档](../tasks/enterprise-cobol-implementation-goal.md)。

## 制作进度

| 阶段 | 当前状态 |
|---|---|
| P0 设计 | 已完成并获准实施 |
| P1 技术验证 | 字节/双流/真实DB基线与证据见validation；平台仅Linux x86-64 |
| P2 模块07标杆 | L1已实现；SORT/MERGE、L2/L3/L4待制作 |
| P3 模块01–06、09 | 待制作；P1微实验不等于完整基础课程 |
| P4 模块08、10 | 待制作；DB探针不等于完整数据库/作业课程 |
| P5 模块11、12 | 待制作 |
| P6 发布/旧内容过渡 | 未放行 |

制作基线始终以设计文档为准。每课先定义输入/业务预期，再实现和运行测试；未验证的平台、恢复边界及模块明确保留未完成状态。
