# 企业 COBOL 课程实施进度

更新时间：2026-10-10。执行代理 GPT-6 Luna；主代理按批审查。状态未经主代理确认不标“已验收”。

## 大纲覆盖矩阵

| 模块/课次 | 教学单元与预定交付 | 状态 |
|---|---|---|
| 01.1–01.3 | 业务日/JOB图、构建入口、固定/自由格式实验 | 未开始 |
| 02.1–02.3 | PIC/层级/MOVE、CUSTOMER v1 27B字段目录 | 未开始 |
| 03.1–03.3 | DISPLAY/COMP/COMP-5/COMP-3字节实验、坏数据解析 | P1微原型已存在；课程未开始 |
| 04.1–04.3 | 复杂结构与150+字段目录/差异练习 | 未开始 |
| 05.1–05.3 | 控制/字符串/客户清洗 | 未开始 |
| 06.1–06.4 | 文件契约、长度/状态/拒绝转换 | 未开始 |
| 07.1–07.2 | SD SORT 与双流 MERGE | 未开始 |
| 07.3 | Boss L1 1:1（47B/55B，三分类） | 基线已实现；B00回归RC0，待批次审查 |
| 07.4 | Boss L2 1:N Key Break、余额、拒绝、冲正 | 运行时IO复核修正完成；功能矩阵RC0，等待主代理复审 |
| 07.5 | Boss L3 多流/N:N | 未开始 |
| 07.6 | Boss L4 150+字段逐字段比较 | 未开始 |
| 08.1–08.4 | GixSQL游标/NULL/事务到完整DB课程 | P1真实DB基线已存在；课程未开始 |
| 09.1–09.3 | CALL/LINKAGE/版本参数与共通模块 | 未开始 |
| 10.1–10.5 | 参数/RC/锁/快照/发布/恢复JOB | 未开始 |
| 11.1–11.5 | 六类事故与客户区分1→2位维护 | 未开始 |
| 12.1–12.4 | 陌生系统综合项目/毕业验收 | 未开始 |

## 批次记录

### B00 接手与基线回归 — 执行完成，主代理验证通过

- 起点：交接提交 `c6a9ad6`；P1/L1基线 `8df4f91`。
- 接手时已有未提交旧 `Makefile`、`course/`素材；逐项保留，不清理、不暂存。
- 读取：`AGENTS.md`、Goal、PRD、SYLLABUS、BANK-SYSTEM、AUTHORING-STANDARD、课程入口、P1证据、DB说明及TDD技能。
- 覆盖矩阵：见本文上表。
- `bash curriculum/check.sh`：RAW_RC=0；23B逐字节布局、24个微型突合用例、L1十项契约测试、全部夹具SHA256、72列检查通过。主代理独立复跑总入口RC0。
- `bash curriculum/validation/database/check.sh`：RC=0；真实PostgreSQL/GixSQL隔离容器测试NULL/Indicator、02000、游标EOF、23505、回滚、独立连接提交核对、重开游标及连接失败映射。Docker缓存命中；仅留工具镜像。
- `python3 curriculum/modules/07-matching/labs/01-one-to-one/scripts/pressure.py`：RC=0，10k/100k/1m 每侧规模、逐行报告和控制总数全部核验；实测/源码及数据/报告hash见[独立证据](../curriculum/validation/evidence/B00-L1-pressure-2026-10-10.md)。
- B00各项回归/压力证据见上，当前可进入课程批次审查。

### B01 模块07.4 Boss L2 — 主代理审查修正中

- 政策和接口：ACCOUNT v1 47B、TRANSACTION v1 55B保留；新增48B REVERSAL-LINK v1；支持同账户本业务日任意较早已成功接受的普通交易、中间可有其他交易。GnuCOBOL BDB索引实测通过，磁盘INDEXED账本存全量transaction状态，内存不保留ID表；顺序账户/交易算法仍逐笔Key Break。
- 独立人工算例：normal中的1000+500−200−500=800，第四笔透支拒绝；全局期初1050+贷500−借700=期末850。aggregate-over-13测试逐户收/付各18万亿且每户closing合法，total credit 27万亿、debit 18万亿、closing 9万亿。
- RED记录：先添加`check.py`后运行时因run.sh尚不存在按预期失败，原始RC=1，断言显示缺少run.sh导致被测命令127。后续发现测试实现性问题：预扫描重开交易文件后首行被多读一次；TX守恒诊断显示总读5、接收1、拒绝3，报告确认首笔丢失。删掉重复READ后全套通过。
- 已跑：`python3 .../03-one-to-many/scripts/check.py` RC=0，覆盖RC0/4/8/12、23个normal/boundary/business/invalid输入、原始输入hash不变、输入快照与输出清单校验、非Gregorian日期、闰日、starter拒绝发布、空间路径、已有目标/锁保护、并发同目标、编译失败映射RC12、build/reset保护。独立 expected 验证报告分类、完整47B master、55B accepted与带原因rejected原交易。`check-indexed.py` RC=0，BDB WRITE/重复键22/READ/缺键23/REWRITE/readback/失败OPEN通过。总入口`bash curriculum/check.sh`会跑B01；执行RC0，主代理session 59226也RC0。
- 压力探针结果与失败历史在[evidence](../curriculum/modules/07-matching/labs/03-one-to-many/evidence/B01-pressure-2026-10-10.md)：17144旧脚本RC1但无逐档输出；5167 RC1并保留各档高水位及driver全量捕获污染问题；修正后83064 RC0旧功能源码文件排序的结果，增长2488 KiB。
- 后续IO审查发现GnuCOBOL LINE SEQUENTIAL对`/dev/full` WRITE/CLOSE仍可能报00；独立复现当前核心对master/accepted/rejected分别RC4。增加流式`verify-publish.py`发布闸门，独立按raw输入+report分类检查输出逐字节完整、逐户/全局金额等式与CONTROL；不实现匹配业务，内存仅当前记录/累计器。
- 真实BATCHL2衍生的三路`/dev/full` runner故障注入均返回RC12、无发布，错误指向对应缺失输出；核心裸程序RC4作为运行时限制保留记录。输出验收改为byte exact LF/width，覆盖截断、CRLF、无末尾LF和金额伪造。
- 压力探针结果与失败历史在[evidence](../curriculum/modules/07-matching/labs/03-one-to-many/evidence/B01-pressure-2026-10-10.md)：17144旧脚本RC1但无逐档输出；5167 RC1并保留各档高水位及driver全量捕获污染问题；修正后83064 RC0旧源码，增长2488 KiB；23804 RC0输出扩展前源码，增长2396 KiB。主代理另在`curriculum/validation/evidence/B01-primary-pressure-2026-10-10.json`记录源码SHA 8ec0...171及全档成功。后续更改只涉及reject输出可变行、发布验证器和故障测试，不影响账户/交易匹配/账本算法内存；故未重复压力。
- 本批除IO修复外已完成；`python3 .../03-one-to-many/scripts/check.py`最新RC=0，等待主代理复核IO门禁并审查；按约束不进入B02。
- 主代理审查：待审查；审查问题与修复：无。

B01教学补充build/reset入口、starter课程源示范、人工trace→Key Break→ledger→守恒→故障调查路径、讲师评分与修复提示已写入；本地总入口原RC0，IO门禁增补后L2 check.py RC0；等待主代理复核。

## 主代理放行记录 — 2026-10-10

B00/B01已由主代理放行：最终总入口session77158原始RC0；主代理独立压力session50004原始RC0，源码SHA8ec0c14c74bba3b51fc527526041d584323de6f486a293b0124d0ea31766b171，增长2320KiB；三路真实核心写满经runner RC12无发布；独立审查最终无新阻塞。仅限B00/B01，全部12模块Goal仍未完成。详细证据和局限见enterprise-cobol-review.md。下一批B02由主代理提交成功后交Luna。
