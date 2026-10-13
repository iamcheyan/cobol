# 模块 12 毕业评分表

自动评分：`instructor/modules/12-capstone/grading/grade.py`。总分 ≥80/100
**且通过全部硬门禁**才算毕业；硬门禁失败不能由其他得分抵消。

## 评分维度

| 维度 | 分值 | 自动判据 |
|---|---:|---|
| 数据结构与字节解释 | 15 | 冻结 copybook 宽度 27/31/32/47/55（CUSTOMER v1 27 与 CAP-CUSTOMER-FEED v1/v2 31/32）与 `validate.py length` 字节探针 |
| 文件/排序/突合正确性 | 25 | `scripts/check.py` 四类日对独立 expected 的核对 |
| DB、JOB、恢复与幂等 | 20 | `scripts/check.py` 的 rerun/5 崩溃边界/锁/控制门禁 |
| 影响调查及安全修改 | 20 | 变更包文件齐全 + RED→GREEN 通过 |
| 事故调查与证据 | 20 | 事故材料齐全（8）+ 可用发布材料复现（12） |

## 硬门禁

| 门禁 | 判据 | 为什么不可抵消 |
|---|---|---|
| G1 无重复扣款 | 同日重跑账本不变、余额不变 | 资金正确性 |
| G2 金额/笔数核对正确 | 独立 expected 与运行控制总数一致 | 业务正确性 |
| G3 失败不发布 | broken/layout-guard/系统失败均无 `publish/` | 防错误外泄 |
| G4 上下游版本兼容有证据 | `red-green.sh` RED!=0 且 GREEN=0 | 布局升级安全性 |
| G5 事故根因可复现 | `reproduce.sh` 输出 `reproduce_rc=8` 且 `published=none` | 事故调查真实性 |
| G6 先调查后修改 | 变更包顺序与 `impact-investigation.md` 存在 | 工程纪律 |

## 结业现场

结业现场包含一个**未在课堂演示过的未知事故**（讲师可从模块 11 素材或
本模块的 `incidents/` 变体另行发放）。学员须在限定时间内完成
现象→时间线→假设→最小复现→根因→修复→恢复→防再发。
