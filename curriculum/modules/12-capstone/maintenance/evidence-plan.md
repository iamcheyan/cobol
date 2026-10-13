# Evidence 计划

每个测试的期望与证据位置。证据由 `maintenance/regression/red-green.sh`
与 `scripts/check.py` 实际生成，不预填通过结果。

| 测试 | 期望 | 证据位置 |
|---|---|---|
| T1 正常 v1 | RC0；`A1` | `check.py check_day("normal","v1",0)` 输出 |
| T2 正常 v2 | RC0；含 `D1` | `check.py check_day("extension","v2",0)` |
| T3 异常日 | RC4，发布 | `check.py check_day("abnormal","v1",4)` |
| T5 宽度守卫 | RC8，无发布 | `check.py check_layout_guard()` |
| T7 跨版本 | GREEN | `maintenance/regression/red-green.sh` 的 `GREEN=0` |
| T8 四类日 | 各自 RC | `check.py` 四类日断言 |
| T9 恢复 | 账本 6 行、余额不变 | `check.py check_recovery()/check_rerun_idempotent()` |
| T10 安全修改 | 原输入未被改 | `check.py` 的 fixture SHA 不变断言 |
| 字节解释 | 27/31/32/47/55 字节 | `system/copybooks/*` + `validate.py length` |
| 事故 | 根因可复现 | `incidents/incident-01/reproduce/reproduce.sh` 的 `reproduce_rc=8` |

证据文件需包含：版本、编译器版本、营业日、run_id、命令、原始 RC、
输入/输出校验和、核对表、结论与限制。
