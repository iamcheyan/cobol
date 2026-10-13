# 模块 11 夹具说明

每个夹具是一个**接收目录**，含 `MANIFEST`（营业日、布局版本、文件校验和）
与声明文件本体。事件夹具是“交付到接收目录的原始输入”，**不得修改**；
`fixtures/SHA256SUMS` 由 `instructor/modules/11-incidents/tools/gen_course.py`
生成，`scripts/check.py` 会在运行前后比对。

夹具用**中性事件 ID**命名，本表只给症状与原始 RC，**不含根因**；每个
夹具的根因（教师用）见 `instructor/modules/11-incidents/INSTRUCTOR.md` 与
对应的 `ROOT-CAUSE.md`。

| 夹具 | 症状（不含根因） | as-found RC |
|---|---|---:|
| `normal/` | 3 账户、4 条合法交易，无拒绝 | 0 |
| `INC-2026-001/` | JOB002 结构失败，当日无发布 | 8 |
| `INC-2026-002/` | 现状以 RC0 发布，余额与业务台账不符 | 0（缺陷） |
| `INC-2026-003/` | JOB001 中止（文件与 Manifest 声明不符），无发布 | 12 |
| `INC-2026-004/` | JOB005 中止，候选未生成 | 8 |
| `INC-2026-005/` | JOB003 中止（运行环境注入），无发布 | 12 |
| `INC-2026-006/` | 现状以 RC0 发布，控制总数与上游声明不符 | 0（缺陷） |
| `INC-2026-007/` | JOB002 结构失败（记录长度/对齐不符），无发布 | 8 |

- `INC-2026-005` 的输入与 `normal` 相同，故障来自运行环境（见其 `student/run.sh`）。
- 固定确定性数据（FR-10），无随机、无 seed。
- 各事件的**原始输入副本**另存于 `INC-2026-00X/student/input/`；两者内容一致。
- `enterprise-customer/customer.v1` **不是**接收目录夹具：它是 11.5 维护课
  的独立、版本化企业客户布局 V1 基线（23 字节），无 MANIFEST，仅用于
  迁移/回滚/并行验证。

生成器：`python3 instructor/modules/11-incidents/tools/gen_course.py`
（会重建 `fixtures/`、`expected/` 与 `SHA256SUMS`）。
