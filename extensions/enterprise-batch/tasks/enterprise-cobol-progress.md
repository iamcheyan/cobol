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
| 07.1–07.2 | SD SORT 与双流 MERGE | 主代理已验收并提交 `2affe66` |
| 07.3 | Boss L1 1:1（47B/55B，三分类） | B00回归RC0，随B01提交验收 |
| 07.4 | Boss L2 1:N Key Break、余额、拒绝、冲正 | 主代理已验收并提交 `d4ca202` |
| 07.5 | Boss L3 多流/N:N | 主代理已验收并放行 |
| 07.6 | Boss L4 150+字段逐字段比较 | 实现与执行代理验证完成；等待主代理独立审查 |
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
- `bash curriculum/check.sh` 已接入B02并保留B01检查，最终原始RC=0；23B布局/24项matching/10项L1契约/BDB索引探针/L2、两课SORT-MERGE完整检查/全部SHA256/COBOL固定格式72列均通过。主代理已验收并提交B02 `2affe66`，后续压力与审查记录见本节尾部放行记录。
- 实现源SHA与测量工具/配置、全档输出和独立L2 expected见`curriculum/modules/07-matching/labs/02-sort-merge/evidence/B02-pressure-2026-10-10.json`；课程静态fixture/expected摘要由各课根`SHA256SUMS`覆盖。不得将L1/B01压力数字作为本课依据。
- B01状态澄清：主代理已验收并提交`d4ca202`，后续Python缓存ignore为`8895ce5`。历史IO review与修正作为已闭环证据，不再标待审；压力JSON的源码SHA `8ec0...171`早于reject可变行实现当前SHA `bc22549...621f2`，不同版本不混用。
- TDD技能已复读；当前先写RED用例再实现，无后台压力任务。主代理批准目录/接口与键策略，并要求含Z-ID较早sequence、A-ID较晚sequence和同sequence多ID的反例数据。

### B03 模块07.5 Boss L3 多流/N:N — 实施中

- B02已由主代理验收提交 `2affe66`；B03单批实施中，不进入B04，未提交/推送。
- 已复读 B03 Goal、PRD、SYLLABUS、BANK-SYSTEM、AUTHORING-STANDARD、B01/B02接口和TDD技能。工作区原Makefile/course脏文件保留。
- 主代理已批准客户日汇总：B01先按ACCOUNT/TRANSACTION/REVERSAL-LINK执行账务与冲正；B03用原ACCOUNT、L2 accepted、离线customer snapshot、previous-day按customer聚合。缺snapshot/previous及业务差异RC4定位隔离；结构日期/版本/重复/排序错误RC8整批不发布。该snapshot是离线种子，不冒称DB抽取；08再接真实数据库。
- 已建立DESIGN/FIELD-CATALOG、36B/39B独立Copybook、四流状态消费表和非单调account→customer人工trace；正常数据与独立expected已固定。RED用例在runner尚不存在时原始被测RC127失败，断言失败状态保留于脚本/证据待补。
- 主代理新增审查要求已纳入契约：L2 closing master除余额外必须与原ACCOUNT逐字段节一致；余额独立按opening+accepted credit-debit核验。账户、accepted交易、credit、debit分别按eligible/isolation守恒；L2 rejected单独统计不混入accepted金额。
- B03当前状态：COBOL四流核心、L2→L3 runner、磁盘流式独立oracle、客户级拆分守恒、候选校验/no-clobber发布、normal及业务差异case已实现。主代理独立的10案复核已通过，非单调客户账户顺序和独立expected一致。
- 本地永久测试已覆盖16种A/T/S/P EOF组合、2/3/4个客户同时隔离、L2 RC0/4分类、snapshot/previous Gregorian闰日/跨月/跨年及非法日期、课程starter编译与实际RC12、COURSE_SOURCE、编译失败映射、reset保留未知/学生文件和遇锁拒绝。直接核心坏原字节矩阵（snapshot/previous无LF、CRLF、Tab、NUL、短、长）RC8；三路真实BATCHL3 `/dev/full` runner注入RC12且无发布。最终复跑`bash curriculum/check.sh`为RC0，包含B01/B02回归、B03、本批Copybook/COBOL ASCII与72列门禁。
- 正式多档压力`python3 curriculum/modules/07-matching/labs/04-many-to-many/scripts/pressure.py`原始RC=0，证据为`curriculum/modules/07-matching/labs/04-many-to-many/evidence/B03-author-pressure-2026-10-10.json`。balanced 10k/100k/1m实际为1000账户、10000/100000/1000000 TX、max customer group 10/100/1000；集中单客户组10k/100k/1m实际为1/1/2账户、max group 10k/100k/1m，百万组两账户各50万笔。核心child VmHWM分别balanced 6100/6988/6944KiB、集中组5816/6812/6948KiB；峰值6988KiB、相对首档增长888KiB，均低于65,536KiB/8,192KiB阈值。10k档全内存；100k及以上档实际观察到`cobsort`工作FD，单文件最大56,343,772B；压力明确固定`COB_SORT_MEMORY=2M`。压力脚本记录每档准确账户/TX/snapshot/previous条数、输入/输出SHA256、核心PID、源码/runner/driver/tool版本。核心RSS含libcob，排除B01、外部sort、SQLite oracle和driver。
- 同一JSON记录真实运行时TMPDIR `0500`故障：100k集中TX、核心GNUCOBOL SORT-WORK status30/raw RC1，runner RC12、无发布；脚本在构建完成后才把runtime TMPDIR切到无权限目录。
- 发布后sha256校验的审查注入曾复现旧runner返回RC12但已发布目录。已将input/manifest校验移至stage内、原子rename前，并永久加入仅令`sha256sum -c`失败的PATH shim测试；修复后runner RC12、目标不存在、锁清理。`check-source.py`与总入口RC0。pressure JSON中的runner SHA准确指向修复前被测runner，JSON同时记录修后runner SHA和仅校验顺序的差异；主代理正在按修后稳定入口做独立pressure复核。
- 剩余工作是主代理整批独立审查并修复其指出的问题；本执行代理不提交/推送，也不进入B04，直到B03主代理放行。

B02主代理放行：总入口session78535 RC0；独立pressure session7620 RC0，10k/100k/1m SORT与MERGE逐档通过，核心RSS增长1480KiB，百万SORT/MERGE分别6656/6604KiB，真实spill四个临时文件、最大35,232,196B。真实TMPDIR权限及文件大小限制均runner12无发布无锁。独立full-key Z,A,B最终byte exact通过；COURSE_SOURCE确实测试学生源码，reset空锁保护通过。独立证据见validation/evidence/B02-primary-pressure-2026-10-10.json及enterprise-cobol-review.md。仅放行B02，12模块目标仍未完成。

B03主代理最终放行：独立pressure19425和总入口29350均原始RC0；六档含单客户百万组全部pass，core峰值7016KiB、相对首档增长1084KiB、实际spill最大56,343,772B，0500 TMPDIR runner12不发布；当前core/runner/driver SHA匹配主代理JSON。手算10案、source/reset/starter、输出篡改、发布前hash失败回归及最终真实READ教材trace均闭环。主代理review详见enterprise-cobol-review.md；B03放行提交，B04尚未实现，完整12模块目标仍未完成。

### B04 模块07.6 Boss L4 — 实现与执行代理验证完成，等待主代理独立审查

- 主代理已批准既有设计；本批保持目录 `curriculum/modules/07-matching/labs/05-large-record/`，讲师参考核心与canonical Copybook位于 `instructor/modules/07/05-large-record/`。学生starter独立，不共享讲师答案源码。
- 固定1778B无分隔二进制记录，175个具名字段。目录独立列PIC/USAGE、偏移/长度、domain、NULL、敏感级别及比较语义。V1分类维持1字节；两字节分类只作为未来V2迁移练习。
- Instructor COBOL核心使用固定顺序文件与双游标比较；匹配记录逐175字段执行RAW、TEXT-NORM、DISPLAY/COMP/COMP-3 numeric或IGNORE-AUDIT语义。结构/域校验覆盖版本、ABI、key及唯一递增顺序、DISPLAY ASCII、required/null关系、日期/时间、数字和packed有效半字节、字段范围；binary COMP高位不作ASCII扫描，packed只允许C/D符号，数学正负零相等。输出包含字段ID/物理位置、脱敏值与控制计数；OLD/NEW-only key也脱敏。
- `B04-layout-author.json`由GnuCOBOL 3.2运行时逐字段取`ADDRESS OF`与field length，实测175个offset/length均匹配目录，总长1778B；记录compiler及目录、canonical Copybook、COBOL源码SHA。course Copybook与canonical instructor Copybook逐bytes同步门禁通过；课程包SHA涵盖讲师核心/Copybook/README，拒绝漂移。
- 实际独立expected与Python byte-level verifier检查binary fixtures、报告、stage发布前候选。Python仅生成/独立验收，不做比较核心。starter由`COURSE_SOURCE`实编译并真实运行，TODO映射RC12且不发布。
- 当前永久变更/故障矩阵涵盖规范化相等、正负packed零表示相等、audit-only、DISPLAY/COMP/COMP-3实值改变与缩放边界、忽略字段、敏感字段遮蔽、域/required-null/optional-null、日期/时间、packed digit/sign、COMP高位、key/version/ABI/order、空/单边/截断记录、starter、reset保护和发布/hash失败。通过RC0，证明上游B00–B03未被本课回归破坏。
- 压力证据`B04-pressure-author.json`：直接COBOL core依次比对10k/100k/1m OLD记录（每条1778B；最大输入1,778,000,000B）与空NEW流，OLD-only控制全核验，核心返回预期RC4；VmHWM为5052/5076/5068KiB，首末增长16KiB，耗时1.139/11.354/111.127秒。证据记录core/二进制/runner/driver及输入报告hash。测量不包含runner与Python verifier RSS，未将其扩大声称为全JOB内存界限。
- 2026-10-10执行验证：`python3 .../scripts/check.py` RC0；压力脚本RC0；`bash .../scripts/check.sh` RC0（课程与fixture所有SHA通过）；`bash curriculum/check.sh` RC0（B00–B04及格式检查通过）。详细可复现记录见课程包`evidence/B04-author-run-2026-10-10.md`。该记录是执行证据，不是独立验收声明。
- 主代理独立审查尚未完成；课程目标仍不能标“已验收”。不得据此提交/推送或开始B05。工作区既有Makefile/course脏材料保留，未暂存/提交/推送；禁止修改review与独立验收材料。
- 执行边界遵循主代理最新指示：当前仅实施B04，完成后等主代理审查反馈；没有明确放行不得推进后续批次。

## 接手执行代理批次（2026-10-10，接手交接文档后）

本批次由接手执行代理完成 B04 收尾、B05 收口与模块 01–06、08–12 实现。执行代理不提交/推送、不宣布验收；以下均为执行证据，待主代理独立审查。

### B04 收尾 — 已完成（执行证据，待主代理验收）

- 根因修复：`scripts/verify.py` 原将整个输入读入内存并构造整份 expected 报告。已改为流式：逐 1778B 记录生成 expected 到临时文件，再以 1MiB 分块与 COBOL 报告比较；峰值内存为单条记录 + 目录，与记录数、报告大小无关。
- 永久回归：`scripts/check.py` 新增 oracle 有界内存守卫——120,000 条（213MB）输入必须在 `ulimit -v 140000`（140MB）下通过；整份缓存会 >213MB 而失败。`verify.py` 另在 200,000 条（355MB）下经 160MB 上限实测通过。
- 完整链路压力：`scripts/pressure.py` 改为驱动真实 `scripts/run.sh`（COBOL core + 流式 verifier + manifest/发布门禁），记录 standalone verifier 的精确 `wait4` `ru_maxrss` 与 10ms `/proc` 采样各进程 VmHWM、运行时树聚合 RSS。大文件 scratch 选非 /tmp 文件系统并在退出时清理；夹具只读。
- 结果（`evidence/B04-pressure-author.json`，core SHA `831eef1f…`）：百万匹配高差异（1,000,000×2，输入 3.556GB，每条一个字段变化）runner RC4 发布、core VmHWM 5,220KiB、in-run python3 VmHWM 21,136KiB、verifier standalone `ru_maxrss` 20,908KiB、报告 49,000,308B、wall 577.5s；十万匹配无差异 runner RC0、core 5,216KiB、verifier 19,760KiB。完整链路失败注入（仅令 verifier 失败）runner RC12、无发布、无锁遗留。
- 更新 `evidence/B04-author-run-2026-10-10.md` 与 lab `SHA256SUMS`；`bash curriculum/modules/07-matching/labs/05-large-record/scripts/check.sh` 与 `bash curriculum/modules/07-matching/check.sh` 均 RC0。仍属执行证据，非主代理验收。

### B05 模块07收口 — 已完成（执行证据，待主代理验收）

- 新增 `curriculum/modules/07-matching/README.md`（07.1–07.6 课次到实验单元映射、SORT→L2→L3→L4 关联图、冻结契约、命令、验收要点）与 `curriculum/modules/07-matching/check.sh`（SORT/MERGE + L1 + L2 + L3 + L4 全入口）——实跑 RC0。
- 新增 `curriculum/scripts/package-student.sh`：可重复学生打包，排除 `instructor/` 与位于 `curriculum/` 内的 `INSTRUCTOR.md` 讲师说明、`__pycache__`；生成 `MANIFEST.txt`/`MANIFEST.sha256` 并断言无答案路径。实测无 instructor 泄漏。`.gitignore` 增加 `/dist/`。

### 模块 01–06、08–12 实现 — 已完成（执行代理自测，待主代理验收）

- 每个模块交付中文 README、DESIGN、可构建 starter（未完成 RC12 不发布）、讲师参考实现（`instructor/modules/NN-*/`）、normal/boundary/invalid 真实夹具 + SHA256SUMS、独立核算 expected、`scripts/{build,run,check,reset}`（任意 cwd、空格路径、no-clobber、锁保护、失败不发布）、学员证据模板。
- 各模块 `check.sh` 执行代理实跑 RC0：01–06、07、09、10、11、12（`scripts/check.sh`）；08 离线 `check-quick.sh` RC0 + 真实 DB `scripts/check.sh` RC0（Docker + PostgreSQL 17 + GixSQL 固定 commit + 两个 P1 补丁，一次性容器）。
- 模块08 独立复跑：`bash curriculum/modules/08-database/scripts/check.sh` 原始 RC0（离线契约 + 真实 DB 端到端 + 独立 psql 核对 + starter）。遵守固定格式，已修正 copybook 的 CJK 注释与 >72 列问题。
- 总入口 `curriculum/check.sh` 重写：P1 校验 + 遍历全部 12 模块快速入口（模块可提供 `scripts/check-quick.sh` 以声明无 Docker 的快速入口）+ 固定格式门禁（`.COB/.CPY/.CBL` 全 ASCII、≤72 列、无 Tab，含 instructor `.COB`）。

### 本批次限制（如实标注，未验证不写通过）

- 平台仅 Linux x86-64 + GnuCOBOL 3.2.0；macOS/WSL/ARM 未验证。
- 真实 DB 仅模块08（及 P1 工具链）；模块10/11/12 的 DB 为标注 `real_db_verified=false` 的离线文件检查点。
- 模块11 维护 T9/T10、模块12 结业现场未知事故、各模块非 PostgreSQL 平台错误码等未在本机执行。
- 工作区既有 `Makefile`、`course/`、`tasks/`、`docs/` 等历史改动保留；本批次只新增课程模块目录、模块07收口文件、`curriculum/check.sh`、`curriculum/README.md`、`curriculum/scripts/package-student.sh`、`.gitignore` 与 B04 相关文件。未 commit/push。

### 待主代理独立验收

- 全部模块的独立复跑、expected 人工核算抽查、失败夹具无发布、DB 独立连接与重跑、事故包可复现性、学生包打包。
- 尤其：模块08 真实 DB 复跑；模块10/11/12 离线 DB 声明是否满足“真实 DB 不可用则标注”的政策；模块12 规模解读。

### 冻结契约违规纠错（2026-10-10，执行证据，待主代理验收）

独立审计发现两处违反 BANK-SYSTEM §2 的硬约束：CUSTOMER v1 第 27 字节按契约必须是**记录状态 status**（A 有效 / D 停用），而模块 11 将其标为 `CUSTOMER-CLASSIFICATION`（A/B/C/D）并把客户区分维护寄生在该字节；模块 12 将其标为 `distinction`（A active/D dormant）并扩为 2 位。BANK-SYSTEM 明确“不要把状态字段擅自当客户区分”，维护课须“先定义独立、版本化的企业客户布局”。

- 已新增 canonical [curriculum/bank/README.md](../curriculum/bank/README.md) 与 [curriculum/bank/copybooks/CUSTOMER-V1.CPY](../curriculum/bank/copybooks/CUSTOMER-V1.CPY)（第 27 字节 `CUSTOMER-STATUS`，编译器实测 27B），与既有 ACCOUNT-V1(47B)/TRANSACTION-V1(55B) 一并作为单一 canonical 来源。
- 模块 11：system 与 6 个事故场景的 CUSTOMER-V1 副本恢复 status 语义；客户区分维护改为作用于独立版本化 `ENTERPRISE-CUSTOMER-V1/V2`（对齐模块 07 L4 命名/版本约定）；`M11CUST.COB`、JOB007/008、fixtures/expected/SHA/讲师材料/证据全部更新；`check.py` 新增契约守卫（若再出现“第 27 字节=区分”则 FAIL）。`bash curriculum/modules/11-incidents/scripts/check.sh` 与维护 `check.sh` 均 RC0；6 事故与 RED→GREEN 仍成立。
- 模块 12：byte 27 恢复 status；区分维护改为作用于 `ENTERPRISE-CUSTOMER-V1/V2`（v1=31B → v2=32B，嵌入未变的 27B 前缀），删除旧 `CUSTOMER-V2.CPY`；COBOL/lib/JOB/schema/fixtures/expected/SHA/grading/讲师/证据全部更新。`bash curriculum/modules/12-capstone/scripts/check.sh` RC0，`grading/grade.py` 100/100 全硬门禁通过。
- 重跑 `bash curriculum/check.sh` 原始 RC0（P1 + 12 模块 + 142 源固定格式门禁）。
- 一致性守卫：新增 [curriculum/validation/interfaces/check.py](../curriculum/validation/interfaces/check.py) 并接入总入口——所有 `copybooks/{ACCOUNT,TRANSACTION,CUSTOMER}-V1.CPY`（32 份，含 instructor）经真实 GnuCOBOL 编译实测为 47/55/27 字节，冻结布局一旦漂移即 FAIL。各模块因多个接口在同一程序内 COPY 会产生重名冲突，COBOL 字段名允许本地前缀（如 `CUST-ID`/`ACCOUNT-V1-RECORD`），但字节宽度由该守卫强制一致；因此不要求逐字节同一文件。
- 残余：企业客户布局与模块 07 L4 的 `ENTERPRISE-CUSTOMER-V1` 仅对齐命名/版本约定，不是同一 1778B 二进制编码；真实 DB 仅在模块 08 接入，模块 10/11/12 仍为标注的离线检查点。

## R01–R15 最终验收返工（2026-10-10，执行证据，待主代理独立复验）

按 `tasks/enterprise-cobol-final-review-2026-10-10.md` 逐项复现反例→修实现/文档→补回归。逐项状态、命令、原始 RC、证据与未完成项见 `tasks/enterprise-cobol-r01r15-fix-report.md`。要点：

- P1：R01 真实 DB 贯通 JOB004/JOB006（模块10/12，Docker+PostgreSQL17+GixSQL，离线路线保留并标注）；R02 账本先行、余额派生自愈（ledger 失败余额不变）；R03 发布后失败保留已发布产物与 DB 提交（`has_committed_or_published`）；R04 模块09 全局重复交易ID 外排拦截 RC8；R05 模块03/04 独立语义验证（改标志不再能发布）；R06 模块08 COURSE_SOURCE 正确源 RC0；R07 学生包按角色+内容排除答案且全模块隔离包可 build/run/check；R09 B04 差异报告含 run_id/版本/序号/脱敏键/字段名；R10 B04 reset 统一锁协议 RC12 保留；R11 压力须断言且记录磁盘高水位/临时空间耗尽；R12 模块02/05/06/11 补齐实操；R13 评分不认空文件、G6 永不自动 PASS。
- P2：R14 事故目录改中性 `INC-2026-00x`；
- 修复后 `bash curriculum/check.sh` 原始 RC0（156 源）；模块08/10/12 真实 DB RC0；P1 RC0；`pressure.py` RC0 status=pass；隔离学生包回归 PASS。
- 未决：R07 模块10 BANKVAL 练习答案被模块11 既存系统逐字节 vendored（隔离包回归仅允许既定路径，其余失败）；R09 字段名采用 catalog `cobol_name`。均交主代理裁定。未提交/推送，工作树保留。
