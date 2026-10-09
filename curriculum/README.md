# 企业 Legacy Batch COBOL 课程（制作中）

本课程按[12模块/76小时设计](../docs/curriculum/README.md)制作，统一使用合成银行夜间处理案例。目前已有技术验证，以及模块07的L1/L2、SORT/MERGE和L3课程；**全部12模块尚未完成，模块07的L4也未制作，L3已通过主代理整批审查**。旧 `course/` 是历史材料，不能当作新版课程验收结果。

## 已可运行

- [P1 字节布局](validation/layout/README.md)：DISPLAY、COMP-3正负数、COMP、COMP-5原始字节。
- [P1 双流原型](validation/matching/README.md)：24个状态/异常用例。
- [P1 DB 工具链](validation/database/README.md)：GixSQL候选、真实PostgreSQL游标/NULL/事务与独立持久化检查，包含明确的本地依赖补丁。
- [模块07 / L1](modules/07-matching/labs/01-one-to-one/README.md)：47/55字节银行接口、三类突合、学员起始代码、讲师答案、异常数据、运行发布与压力检查。
- [模块07 / SORT与MERGE](modules/07-matching/labs/02-sort-merge/README.md)：两课入口含真实COBOL SD SORT/双流MERGE、学员/讲师源码、异常矩阵和压力检查；主代理已验收。
- [模块07 / L2 1:N](modules/07-matching/labs/03-one-to-many/README.md)：真实Key Break、余额、拒绝与带原交易引用的冲正；主代理已验收。
- [模块07 / L3 多流N:N](modules/07-matching/labs/04-many-to-many/README.md)：账户、L2 accepted、客户快照、前日控制四流客户日汇总；主代理独立总入口、六档压力与故障验收已通过。

## 本地验收

```bash
bash curriculum/check.sh
bash curriculum/validation/database/check.sh
python3 curriculum/modules/07-matching/labs/01-one-to-one/scripts/pressure.py
python3 curriculum/modules/07-matching/labs/04-many-to-many/scripts/pressure.py
```

第一条不需要Docker并运行L1至L3课程入口；第二条首次联网构建ESQL工具，使用一次性数据库/网络，退出清理，无宿主端口或持久化数据库卷；第三条生成最高每侧百万条数据并清理，Linux上测L1 matcher进程RSS；第四条运行L3 balanced及单客户组10k/100k/1m压力并测COBOL child RSS/实际SORT spill。L3 pressure证据固定于该课`evidence/`，课程编译产物不写入源码目录。

执行任务与主代理审查协议见[实施Goal交接文档](../tasks/enterprise-cobol-implementation-goal.md)。

## 制作进度

| 阶段 | 当前状态 |
|---|---|
| P0 设计 | 已完成并获准实施 |
| P1 技术验证 | 字节/双流/真实DB基线与证据见validation；平台仅Linux x86-64 |
| P2 模块07标杆 | L1、SORT/MERGE、L2已验收；L3已验收；L4待制作 |
| P3 模块01–06、09 | 待制作；P1微实验不等于完整基础课程 |
| P4 模块08、10 | 待制作；DB探针不等于完整数据库/作业课程 |
| P5 模块11、12 | 待制作 |
| P6 发布/旧内容过渡 | 未放行 |

制作基线始终以设计文档为准。每课先定义输入/业务预期，再实现和运行测试；未验证的平台、恢复边界及模块明确保留未完成状态。
