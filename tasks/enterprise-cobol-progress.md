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
| 07.1–07.2 | SD SORT 与双流 MERGE | B02实现完成，待主代理审查 |
| 07.3 | Boss L1 1:1（47B/55B，三分类） | B00回归RC0，随B01提交验收 |
| 07.4 | Boss L2 1:N Key Break、余额、拒绝、冲正 | 主代理已验收并提交 `d4ca202` |
| 07.5 | Boss L3 多流/N:N | 未开始（等待B02放行） |
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

### B01 模块07.4 Boss L2 — 主代理已验收

- 政策和接口：ACCOUNT v1 47B、TRANSACTION v1 55B保留；新增48B REVERSAL-LINK v1；支持同账户本业务日任意较早已成功接受的普通交易、中间可有其他交易。GnuCOBOL BDB索引实测通过，磁盘INDEXED账本存全量transaction状态，内存不保留ID表；顺序账户/交易算法仍逐笔Key Break。
- 独立人工算例：normal中的1000+500−200−500=800，第四笔透支拒绝；全局期初1050+贷500−借700=期末850。aggregate-over-13测试逐户收/付各18万亿且每户closing合法，total credit 27万亿、debit 18万亿、closing 9万亿。
- RED记录：先添加`check.py`后运行时因run.sh尚不存在按预期失败，原始RC=1，断言显示缺少run.sh导致被测命令127。后续发现测试实现性问题：预扫描重开交易文件后首行被多读一次；TX守恒诊断显示总读5、接收1、拒绝3，报告确认首笔丢失。删掉重复READ后全套通过。
- 已跑：`python3 .../03-one-to-many/scripts/check.py` RC=0，覆盖RC0/4/8/12、23个normal/boundary/business/invalid输入、原始输入hash不变、输入快照与输出清单校验、非Gregorian日期、闰日、starter拒绝发布、空间路径、已有目标/锁保护、并发同目标、编译失败映射RC12、build/reset保护。独立 expected 验证报告分类、完整47B master、55B accepted与带原因rejected原交易。`check-indexed.py` RC=0，BDB WRITE/重复键22/READ/缺键23/REWRITE/readback/失败OPEN通过。总入口`bash curriculum/check.sh`会跑B01；执行RC0，主代理session 59226也RC0。
- 压力探针结果与失败历史在[evidence](../curriculum/modules/07-matching/labs/03-one-to-many/evidence/B01-pressure-2026-10-10.md)：17144旧脚本RC1但无逐档输出；5167 RC1并保留各档高水位及driver全量捕获污染问题；修正后83064 RC0旧功能源码文件排序的结果，增长2488 KiB。
- 后续IO审查发现GnuCOBOL LINE SEQUENTIAL对`/dev/full` WRITE/CLOSE仍可能报00；独立复现当前核心对master/accepted/rejected分别RC4。增加流式`verify-publish.py`发布闸门，独立按raw输入+report分类检查输出逐字节完整、逐户/全局金额等式与CONTROL；不实现匹配业务，内存仅当前记录/累计器。
- 真实BATCHL2衍生的三路`/dev/full` runner故障注入均返回RC12、无发布，错误指向对应缺失输出；核心裸程序RC4作为运行时限制保留记录。输出验收改为byte exact LF/width，覆盖截断、CRLF、无末尾LF和金额伪造。
- 压力探针结果与失败历史在[evidence](../curriculum/modules/07-matching/labs/03-one-to-many/evidence/B01-pressure-2026-10-10.md)：17144旧脚本RC1但无逐档输出；5167 RC1并保留各档高水位及driver全量捕获污染问题；修正后83064 RC0旧源码，增长2488 KiB；23804 RC0输出扩展前源码，增长2396 KiB。主代理另在`curriculum/validation/evidence/B01-primary-pressure-2026-10-10.json`记录源码SHA 8ec0...171及全档成功。后续更改只涉及reject输出可变行、发布验证器和故障测试，不影响账户/交易匹配/账本算法内存；故未重复压力。
- 后续独立审查指出GnuCOBOL缓冲写边界，执行代理按review修复并复验RC0；该问题已闭环，不是当前B02阻塞项。
- 主代理验收并提交：`d4ca202`（B00/B01），随后Python缓存忽略修正提交`8895ce5`。B01压力源码版本差异见两份独立证据，不混称同一SHA。

B01教学补充build/reset入口、starter课程源示范、人工trace→Key Break→ledger→守恒→故障调查路径、讲师评分与修复提示已写入并随B01验收。

## 主代理放行记录 — 2026-10-10

B00/B01已由主代理放行：最终总入口session77158原始RC0；主代理独立压力session50004原始RC0，源码SHA8ec0c14c74bba3b51fc527526041d584323de6f486a293b0124d0ea31766b171，增长2320KiB；三路真实核心写满经runner RC12无发布；独立审查最终无新阻塞。仅限B00/B01，全部12模块Goal仍未完成。详细证据和局限见enterprise-cobol-review.md。

### B02 模块07.1/07.2 SORT与MERGE — 主代理已验收

- 目录与接口提案已获主代理认可：`curriculum/modules/07-matching/labs/02-sort-merge/{01-sort,02-merge}`；ACCOUNT v1/TRANSACTION v1不变，排序全键(account_id, sequence, transaction_id)，55B原始字段逐字保留、输出LF。
- 算法要求：COBOL SD/SORT INPUT/OUTPUT PROCEDURE与真实RELEASE/RETURN；MERGE至少两份预排序独立源流，不能concat后SORT替代。各源先独立验证顺序；全局transaction_id重复RC8；同账户同sequence不同ID按ID确定顺序。空流允许，缺末尾LF/短长/CRLF/非法字段/逆序源拒绝RC8。
- RED→GREEN：先有01-sort独立验收脚本，缺少runner时normal用例实际RC127而失败；后实现再转绿。当前SORT/MERGE两课完整runner检查各RC0，直接核心原始字节检查也各RC0。
- 实际COBOL：SORT用SD与COBOL COPY TRANSACTION-V1.CPY、INPUT/OUTPUT PROCEDURE、逐字节SEQUENTIAL PIC X输入、RELEASE/RETURN；MERGE用真实`MERGE ... USING FEED-A FEED-B`，逐字节预扫两个源的55B+LF、字段、真实日期与严格键序。Python validator仅作JOB门禁/全局ID外部排序及候选输出独立oracle。输出不覆盖目标；runner创建锁、对输入做快照、先生成候选再独立byte/count/order/multiset验证后no-clobber发布。
- 真实SORT溢写观测：对直接COBOL核心输入250,000条、每条56字节、14,000,000B，显式`COB_SORT_MEMORY=2M`。通过`/proc/<core-pid>/fd`观察到`TMPDIR`内`cobsort..._0`至`_3 (deleted)`临时工作文件，观察到最大14,000,000B；程序RC0、输出14,000,000B。文件在程序关闭后删除。该证据证明实际spill，而非以大输入推断。
- 资源失败探针：150,000条(8,400,000B)、2M池，在core阶段继承`RLIMIT_FSIZE=5120 blocks`；运行实际RC153(SIGXFSZ)，runner映射RC12、无正式输出、锁清理。`PATH`首位注入只会RC1的`mktemp` shim后，两runner已改为RC12、无发布、无遗留锁。不得将TMPDIR无效回退告警说成失败；GnuCOBOL对无效TMPDIR会退回系统临时目录。
- SORT/MERGE课程runner及直接核心探针已本地通过：正常键反例6条精确bytes、空流/单行、短/长/无LF/CRLF/Tab/NUL/非法Gregorian日期/方向、MERGE逆序每流、重复global ID及跨源重复。父代理独立key adversarial fixture也已分别验证SORT与MERGE输出`Z,A,B`精确bytes。L2桥接永久测试与独立expected已固定：SORT与MERGE普通流进入BATCHL2均RC0，六笔accepted、完整master与report逐bytes匹配；SORT零金额桥接BATCHL2 RC4，ZERO-AMOUNT拒绝行与zero master/report逐bytes匹配。账户1期末1050，账户2期末100。
- 教材、starter/build/run/check/reset、讲师评分和学生证据模板已齐备；starter以独立输出路径实跑并返回RC12。reset遇到任何锁均RC12且保留workspace全部文件，永久测试覆盖空目录锁。
- 两课永久检查各自验证reference排序/归并、空/单流、字段及物理原字节错误、global ID重复、桥接L2 RC0、SORT零金额桥接L2 RC4、starter实际TODO RC12、失败关闭、reset锁保护。共享故障检查覆盖编译失败、mktemp失败、既有目标和既有锁保护。两课check.sh改为调用实际共享脚本路径。
- 正式压力`python3 curriculum/modules/07-matching/labs/02-sort-merge/scripts/pressure.py`原始RC=0，10k/100k/1m分别测试SORT与MERGE；最大单账户组500k。2M池下百万SORT观察到四个`cobsort`临时文件，最大单文件35,232,196B；百万SORT/MERGE分别约22.754/22.035秒，core RSS分别6760/6472KiB；全档最高6760KiB、最低5140KiB，RSS增长1620KiB，低于65,536KiB绝对及8,192KiB增长阈值。JSON保存wait4各核心RSS、PID及`/proc`抽样所得临时FD路径/最大文件大小；FD抽样未记录时间戳。退出后路径显示`(deleted)`。压力JSON含输入/输出hash及工具版本。
- 真实临时目录权限故障（构建目录可写，核心TMPDIR为0500）runner RC12、无发布/无锁遗留；原生核心报永久文件错误status30/RC1。文件大小限制导致核心外层shell RC153(SIGXFSZ)，runner RC12、无发布/无锁遗留。早期实际spill观察和资源失败的原始记录均保留在pressure JSON。
- `bash curriculum/check.sh` 已接入B02并保留B01检查，最终原始RC=0；23B布局/24项matching/10项L1契约/BDB索引探针/L2、两课SORT-MERGE完整检查/全部SHA256/COBOL固定格式72列均通过。执行代理报告该稳定快照待主代理审查；B02尚未主代理验收，不进入B03。
- 实现源SHA与测量工具/配置、全档输出和独立L2 expected见`curriculum/modules/07-matching/labs/02-sort-merge/evidence/B02-pressure-2026-10-10.json`；课程静态fixture/expected摘要由各课根`SHA256SUMS`覆盖。不得将L1/B01压力数字作为本课依据。
- B01状态澄清：主代理已验收并提交`d4ca202`，后续Python缓存ignore为`8895ce5`。历史IO review与修正作为已闭环证据，不再标待审；压力JSON的源码SHA `8ec0...171`早于reject可变行实现当前SHA `bc22549...621f2`，不同版本不混用。
- TDD技能已复读；当前先写RED用例再实现，无后台压力任务。主代理批准目录/接口与键策略，并要求含Z-ID较早sequence、A-ID较晚sequence和同sequence多ID的反例数据。

B02主代理放行：总入口session78535 RC0；独立pressure session7620 RC0，10k/100k/1m SORT与MERGE逐档通过，核心RSS增长1480KiB，百万SORT/MERGE分别6656/6604KiB，真实spill四个临时文件、最大35,232,196B。真实TMPDIR权限及文件大小限制均runner12无发布无锁。独立full-key Z,A,B最终byte exact通过；COURSE_SOURCE确实测试学生源码，reset空锁保护通过。独立证据见validation/evidence/B02-primary-pressure-2026-10-10.json及enterprise-cobol-review.md。仅放行B02，12模块目标仍未完成。
