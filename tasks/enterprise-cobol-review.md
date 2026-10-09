# 企业课程主代理审查记录

本文件由主代理记录独立审查结论。执行代理的进度与自测见 `enterprise-cobol-progress.md`；自测通过不自动视为主代理验收。

## 执行合同审查 — 2026-10-09

- 执行合同：`enterprise-cobol-implementation-goal.md`，提交 `c6a9ad6`。
- 逐批顺序：B00基线→B01 L2→B02 SORT/MERGE→B03 L3→B04 L4→B05模块07收口→B06–09基础链→B10 DB→B11 JOB→B12事故/维护→B13毕业→B14发行。
- 最终完成条件仍为全部12模块与设计硬门禁，不能以完成首个批次替代整项Goal。
- 执行模型：GPT-6 Luna。主代理负责独立测试、审查、反馈修正及验收后的提交推送。
- 历史Makefile/course未提交素材保持原状，不以清理工作区为由删除或纳入新提交。

## B00 独立回归 — 2026-10-09

- 主代理运行 `bash curriculum/check.sh`，原始RC0：23字节布局、24个微型突合案例、L1十个测试方法、夹具SHA256及固定72列检查通过。
- 主代理运行 `bash curriculum/validation/database/check.sh`，原始RC0；NULL/空结果/游标/23505/ROLLBACK100/COMMIT101/独立持久化/REOPEN/连接失败均通过，临时数据库与网络已清理。
- 基线源码提交：`8df4f91`；当前交接文档提交：`c6a9ad6`。
- 本机 `cobc -info` 报告 indexed file handler 为BDB；这仅是能力发现，B01仍须实际OPEN/WRITE/READ/REWRITE/CLOSE探针和失败检查。

## B01 契约预审 — 2026-10-09

状态：实现中，尚未验收。

发现：执行代理最初提出冲正仅引用序号紧邻原交易。该约束虽便于常量状态实现，但缩窄了要求，不能作为最终交付范围。

要求修正：

1. 保留TRANSACTION v1的55字节及含义，采用独立版本化REVERSAL-LINK关联接口。
2. 支持同账户、本业务日、此前成功接收的任意原交易；中间允许其他交易。
3. 校验不存在原交易、跨账户、原交易被拒绝、重复冲正、金额不等、方向不反及处理顺序。
4. 可用COBOL INDEXED临时账本保存原交易属性及accepted/reversed状态；核心账户/交易突合仍为顺序Key Break，内存有界。
5. 不采用全内存ID表、不用Python/SQL替代业务，也不用逐笔重扫全文件的平方复杂度变通。
6. 跨日历史冲正在后续DB模块明确拓展，此批不能声称已经实现跨日。

执行代理已确认调整方案；等待实际代码、独立预期、正常/异常测试和压力证据。仅确认方案不等于验证实现。

### 草稿代码预审 — 2026-10-10

以下均为进行中的草稿发现，尚未复验修复，不构成批次验收：

- 输出顺序须为交易明细后账户汇总，不能为提前打印期末余额缓存整组交易。
- RC合同统一为0正常、4业务拒绝但发布核对结果、8致命数据错误不发布、12系统错误不发布；Shell必须保留程序RC4，不能被最后的echo覆盖。
- 草稿无交易账户计数重复ADD，须修复并用无交易及空输入案例验证。
- 全局累计及单账户累计均可能超过单笔13位上限；贷借交替也会使累计超限而余额合法。须使用足够宽的精确字段并检查累计溢出。
- 索引WRITE失败不能全部算数据RC8：重复键与真实后端/IO故障需要分别映射，后者RC12。

执行代理已接受输出顺序、RC政策与全局累计修正；其余发现已发回实现代理。修复完成后由主代理重跑独立用例。

### 草稿独立执行与后续门禁 — 2026-10-10

- 主代理运行当前 `03-one-to-many/scripts/check.py`，原始RC0；当时包含normal RC4、跨账户重复ID/短交易/逆序 RC8、无效冲正原交易RC4五类检查。此结果只证明这五类，不能支持完整B01验收。
- 主代理用临时目录复制normal输入，将首条关联的账户改为0000000002后运行Shell，实际RC8且没有发布目录。执行时工作树仍由Luna修改；该结果不代替定位分支及稳定版本复验。
- 后续要求：关联账户/序号不一致立即作为契约错误RC8；两类ID字符集与交易一致；合法关联指向业务不合格原交易可逐笔拒绝RC4。
- 当前草稿CONTROL尚未包含期初/期末累计和运行时守恒断言，须补两级守恒检查，并由测试从输入快照独立计算预期。执行代理已接受。

### 守恒检查加入后的开发快照探针 — 2026-10-10

主代理从normal夹具复制并独立变异六种输入，运行真实Shell（所有临时目录由Python上下文清理）：

| 变异 | 原始RC | 正式目录 | 结论 |
|---|---|---|---|
| 三输入均空 | 12 | 无 | 未通过；应正常生成零控制数，已反馈 |
| 账户非空、交易和关联均空 | 12 | 无 | 未通过；应输出原余额及无交易账户，已反馈 |
| 交易缺末尾LF | 8 | 无 | 拒绝符合布局合同 |
| 账户CRLF | 8 | 无 | 拒绝符合ASCII LF合同 |
| 关联序号不匹配 | 8 | 无 | 拒绝符合接口完整性合同 |
| 关联原交易ID包含感叹号 | 8 | 无 | 拒绝符合ID字符合同 |

执行代理确认其守恒实现仍在定位RC12，故本轮结果是开发反馈，不是完成报告。B00压力测试由Luna报告session75568已RC0结束；主代理仍需检查保存的JSON证据，禁止把每侧1万/10万/100万记录误写成十倍交易量。

同日修复复验：Luna移除索引预扫描重开后的重复首条READ。主代理重新执行上述两个失败探针，空输入实际RC0并发布全部零值CONTROL；无交易场景实际RC0并发布3个账户原余额、NO-TX=3、OPENING=CLOSING=1050。这两项缺陷在该开发快照中已消除，已要求纳入永久验收；完整批次仍待审。

### INDEXED探针独立验收 — 2026-10-10

主代理运行 `python3 curriculum/modules/07-matching/labs/03-one-to-many/scripts/check-indexed.py`，原始RC0。随后逐行核对探针与驱动：真实建立索引、WRITE后重复WRITE返回22，CLOSE/OPEN I-O后READ返回ACCEPTED，REWRITE再READ返回REVERSED，不存在键返回23；不存在父目录的路径使OPEN失败并实际返回12。测试使用临时目录且不触碰课程原始夹具。此证据证明该环境具备所用BDB操作能力，不代表L2整批课程已完成。

### 预期报告独立守恒核算 — 2026-10-10

主代理使用独立临时Python脚本读取当前15组expected及原始47B/55B夹具，逐组核对：全部交易恰有一次分类；按接收ID从原交易金额/方向重新累计收付；从原账户符号和金额计算期初，从ACCOUNT输出计算期末；期初+贷−借=期末；CONTROL中的账户、交易、接收、拒绝、期初、期末、贷借均与独立计算一致。15组全部通过，包括累计超13位及跨账户冲正案例。该验证不运行参考实现、不调用实现代理oracle，但只证明给定分类后的数值和完整性，分类规则本身仍需代码与业务审核。

### L2压力门禁失败与测量审查 — 2026-10-10

Luna报告17144已终止且内存门禁失败（未逐档保存完整JSON），随后5167再次原始RC1，四档报告校验正确但RSS门禁失败：micro17468KiB、10k账户/100k交易28860KiB、100k账户/1m交易125632KiB、单账户100k同键组125632KiB，增长108164KiB超过固定65536KiB。不得隐去失败或调宽阈值。

主代理核读pressure.py发现：在Popen前用capture_output和splitlines将全部ID装入Python主进程；末档与前档RSS完全相同也提示进程统计污染可能。已要求先改为真实管道/临时文件，在全新驱动进程复验，并用独立time监测交叉核对；未排除驱动高水位继承前，不能据此断言BDB实际缓存增长。后端是否有界仍待有效测量证明。另已派独立只读审查，不抢占压力资源。

### 独立代码审查反馈 — 2026-10-10

只读审查与主代理复验确认，批次暂不放行：

- 主代理实际构造空ACCOUNT、同账户两笔C100/D100及合法第二笔冲正第一笔关联，得到RC8、无发布，stderr为LINK-CONSERVATION。孤立拒绝路径未消费关联；应逐笔NO-ACCOUNT业务拒绝RC4发布，而非关联缺失。已发Luna修复。
- 单户六位计数不检查溢出，也没有逐户笔数守恒；合法同序号不同ID可超过999999笔。静态发现，未声称已跑百万同户探针；要求扩宽并测试。
- build不存在源码实际返回1，应映射系统RC12。此前上溯路径问题已在开发中修复；主代理构建临时目标实际RC0，撤销旧路径问题。
- B01合同要求期末Master，当前ACCOUNT摘要丢失其他47B字段，不能作实际下游输入；已要求完整47B期末文件、55B接收交易、可关联拒绝原记录/原因，以及字节级预期。
- 教材段落名与实际源码不一致、总检查入口未接L2，待修正和接线。
- 独立审查员执行三类接口各short/long/no-final-LF/CRLF共12个短探针，均RC8无发布；本记录区分审查员证据与主代理实际复跑。

同日孤立LINK修复独立复验：主代理重新生成完全相同的空ACCOUNT、两笔C100/D100及第二笔冲正第一笔关联，实际RC4且发布正式目录；master.dat与accepted.dat为0字节，rejected.dat包含两笔原始55字节交易加NO-ACCOUNT原因。这证明该最小复现已修复；关联结构损坏、完整回归及更新输出后的压力仍需验收。

### 新输出版本总入口独立回归 — 2026-10-10

主代理执行 `bash curriculum/check.sh > /tmp/cobol-primary-l2-fullcheck.log 2>&1`，session59226原始RC0。入口已接L2；布局、微型突合、L1回归与哈希、L2合同/索引、全部新COBOL/Copybook72列检查均通过。该运行发生在新增master/accepted/rejected输出及build/reset检查之后。

Luna随后报告旧源码压力session83064原始RC0，流式外部唯一性预检后四档RSS为17324/17752/19796/19812KiB，增长2488KiB；这是执行代理的旧源码证据，尚不等价于主代理对最终新增输出版本的压力验收。17144/5167失败需在正式证据保留，不能抹去。

### 主代理最终输出版压力及I/O复审 — 2026-10-10

- 主代理独立运行最终输出版pressure.py，session50004原始RC0，源码SHA256 `8ec0c14c74bba3b51fc527526041d584323de6f486a293b0124d0ea31766b171`。四档RSS17452/17752/19768/19772KiB，增长2320KiB；百万交易52.379秒，十万同户交易5.109秒。完整JSON保存为 `curriculum/validation/evidence/B01-primary-pressure-2026-10-10.json`；范围仅该源码与给定档位，非生产容量承诺。
- 独立审查指出新增输出写满未传播。主代理自己构建当前COBOL，对normal分别设置MASTER_OUTPUT_FILE、ACCEPT_OUTPUT_FILE、REJECT_OUTPUT_FILE为/dev/full，其余正常临时文件，三次实际均RC4而非12。该真实I/O缺陷阻塞验收，已发回Luna；压力通过不能抵消失败写入仍成功的问题。
- 新输出测试使用read_text/splitlines会掩盖末尾LF与CRLF；已要求精确bytes预期，不把逻辑行相等声称完整字节验收。README错误段落名经Luna改正，待最终复核。

### 输出缓冲故障修复方向验证 — 2026-10-10

主代理读取实际runtime配置确认存在COB_SYNC（默认no），随后实际比较COB_SYNC=N/Y、master输出=/dev/full的同一COBOL探针，两次均原始RC4且无IO错误。因此同步开关不是已证明的修复方案。

Luna提出发布前独立字节核验器。主代理要求其流式读取输入/候选输出和报告，核对完整47B Master、55B接收、原交易加原因拒绝、计数和金额；失败必须使runner实际RC12且无发布，并以真实/dev/full和截断/CRLF/缺LF实验验证。此方向针对完整JOB发布安全；文档必须披露直接运行COBOL的运行时限制，不得虚称核心FILE STATUS已能捕获此故障。修复仍在实现，不算验收完成。

### 发布核验修复独立回归 — 2026-10-10

主代理运行新版L2 check.py，session38206原始RC0。核读测试确认其使用真实BATCHL2派生源，仅替换三路之一输出地址为/dev/full，其余算法、输入及输出正常；三路分别经真实runner验证RC12、正式目录不存在且核验错误对应缺失的输出文件。原始核心的RC4限制另有独立探针保留，未虚称核心运行时已修。

测试已改为原始bytes精确比较47B/55B及LF；核验器采用有长度上限的流式读取，以接收原交易方向/金额独立核算逐户及全局守恒。README明确直接核心无发布保证、必须通过runner。已请独立审查员最后复核新核验器，尚未作最终批次放行。

### B00/B01最终放行 — 2026-10-10

主代理最终总入口session77158原始RC0，独立复审最后无新实质阻塞；正常/业务拒绝/致命数据/环境错误、原始输出字节、两级守恒、锁保护、真实三路写满runner RC12无发布、固定格式及基线回归通过。主代理最终源码四档压力证据已保存，增长2320KiB。教材starter、分步操作、讲师提示/评分、版本布局、夹具与哈希、失败历史均已核读。B00/B01放行，后续B02按原合同执行。

明确边界：发布核验器负责完整性及守恒，非全业务独立重算器；逐笔政策与中间余额由COBOL及独立expected验证。GNU运行时核心直接写满可返回业务RC4，必须走runner核验后发布。压力只验证本机指定规模且无密集冲正的输入；未验证其他平台或生产容量。整个12模块与毕业系统仍未完成，本次放行不代表全Goal完成。

## B02 接手与合同预审 — 2026-10-10

B00/B01提交d4ca202并推送；生成Python缓存随后在8895ce5删除并加入ignore。Luna已接B02任务，主代理确认两课目录02-sort-merge/01-sort与02-merge方案：真实SD SORT INPUT/OUTPUT PROCEDURE和RELEASE/RETURN、至少两路真实MERGE，保留ASCII/LF交易v1全部55字节；完整账户/序号/ID键确定次序，全球交易ID重复RC8。正常RC0，数据RC8，系统RC12；不设没有业务意义的RC4。

额外预审要求：显式固定排序内存池预算，并以足够大输入产生磁盘spill后测试真实临时目录失败，不能以小文件全内存排序冒充临时盘验证。禁止用concat+外部sort代替MERGE。须以含冲正的未排序交易实际接L2验证，不改变ID/seq及关联语义。执行代理已接受，开始TDD/语法实验。B02尚未实现验收，后续12模块目标保持不变。

### B02正常夹具独立核算

主代理独立读取新设计的SORT normal与MERGE两源，均共6条55B+LF；分别验证MERGE每源按账户/序号/ID有序，独立完整键排序结果为Z1、A2、M3、A4、A6、B5。原金额按方向累计：账户1净+50、账户2净0，与期初1000/100下期末1050/100一致。该证据仅核对夹具和人工合同，SORT/MERGE源码尚未实现，不能声称程序通过。

另主代理自建 `curriculum/validation/fixtures/b02-key-order/` 四份独立55B夹具及哈希：输入B(seq2)、Z(seq1)、A(seq2)，正确Z/A/B，两个MERGE源为Z/B与A，净变化95。待实现后用它独立执行，验证不会把整行ASCII排序误当业务键。

### B02 SORT纵切独立运行与源码预审

主代理首次运行独立夹具遇到开发中runner在mktemp后清空work，实际RC1且/ids权限失败，无发布；反馈后再次执行同一独立输入，实际RC0、3条输出与expected.dat原始bytes完全一致，顺序Z/A/B。此结果证明当前SORT完整键选择正确，不代表整批通过。

源码预审确认已使用真实SD SORT/RELEASE/RETURN及MERGE USING。发现当前SORT仍LINE SEQUENTIAL PIC X(55)后直接RELEASE，验证全在Python；MERGE也缺承诺的COBOL预先有序性检查。这与已批准DESIGN的COBOL原始长度/字段/有序性校验不符，已要求补齐。Python可做独立oracle与全局ID唯一性外部JOB，不代替被教校验。当前完整实现位于starter也须在最终交付分离到instructor，starter保留可构建TODO。

主代理随后实际运行独立双流MERGE夹具：merge-left Z(seq1)/B(seq2)，merge-right A(seq2)，runner原始RC0，输出与expected.dat原始bytes完全一致（Z/A/B，3条）。仅证明该正常合并及完整键次序，不覆盖其他异常。Luna报告已增加COBOL variable-length字段/日期/各源顺序校验；主代理要求直接绕开Python预检验证无末LF/CRLF/Tab/NUL/短长行，确认LINE SEQUENTIAL转换不会掩盖原字节，未取得证据前不算契约闭环。

### B02核心原字节独立探针

主代理从instructor直接编译两个核心，绕过Python，以同一合法单记录分别构造有效、无LF、CRLF、ID含Tab、ID含NUL、长行、短行，MERGE使用变异源A和空源B。实测SORT依次RC0/8/8/8/8/8/8，原字节契约符合；MERGE依次RC0/0/0/12/12/0/0，仍受LINE SEQUENTIAL转换影响。已要求Luna补真实原字节MERGE预扫，使数据错误RC8；此为开发中具体缺陷，不以外层Python预检通过代替。

同日逐字节MERGE修复后，Luna提供核心稳定信号。主代理再次直接编译并运行相同七项探针：有效RC0有输出；无LF、CRLF、Tab、NUL、长、短均原始RC8且输出文件不存在。该原字节缺陷已在稳定核心复验消除，已要求执行代理纳入永久直接核心检查，不仅依赖Python预检。

### B02运行脚本系统故障注入

主代理在临时PATH加入只返回1的mktemp替身，分别执行SORT/MERGE runner正常夹具。两者实际RC1、未发布、锁均已清理。系统失败应映射RC12，已要求修复并永久测试。此证据仅证明工具失败传播与清理，不等价于真实SORT工作文件spill或磁盘故障；后者仍须独立实验。runner也应固定LC_ALL=C，不能依赖调用者locale。

同日修复复验：主代理重跑完全相同的mktemp失败注入，SORT与MERGE均原始RC12、无正式输出、无遗留锁。当前runner已固定LC_ALL=C。该工具失败问题已闭环，仍不能代替真实SORT临时工作文件故障验证。

### B02永久核心检查及资源实验进度

主代理独立运行两课check-core-raw.py均原始RC0，并运行MERGE check.py（session59477）原始RC0。原字节/字段/日期/每源顺序检查已进入可重复验收入口。

Luna报告250k交易/2M排序池时，实际/proc FD观察到TMPDIR下cobsort_0..3 deleted文件，最大14MB；资源大小限制后核心SIGXFSZ、runnerRC12且无发布/无遗留锁，L2桥接余额1050/100。这些尚为执行代理报告，主代理要求保存完整脚本/JSON、区分原始信号与shell状态、补真实临时目录权限故障及多档压力，再独立验收。不能以报告代替主代理已复跑证明。

### B02 永久 runner 保护测试独立复跑

主代理执行 `python3 curriculum/modules/07-matching/labs/02-sort-merge/scripts/check-runner-failures.py`，原始 RC0。两课 mktemp RC1 故障均映射 RC12、不发布且清理自身锁；已有目标内容保持；已有锁及 owner 文件保持。此为 runner 保护证据，不代替真实 SORT spill/磁盘资源故障证据。B02 仍在实施，尚未放行。

### B02 独立代码审查：字段政策漂移（待修复）

course_review 只读审查复现：小写交易ID及status R经SORT RC0发布而L2 RC8；零金额经SORT RC8而L2结构合法后业务拒绝RC4。主代理静读确认Python isalnum、金额>0、N/R政策，且COBOL IS ALPHABETIC包含空格，小写与空格ID门禁不足。要求B02保持既有TRANSACTION v1：ID明确A-Z0-9、状态N、非负金额包含零；零金额供下游业务判断。已要求Luna同步修复两课核心/runner/夹具/设计说明，并增加直接核心与runner反例以及零金额桥接L2 RC4测试。审查确认真实SORT/MERGE、复合键、每流顺序、全局ID外部去重和硬链接发布；这些不能抵消字段契约阻塞。

### B02 真实 TMPDIR 权限核心故障独立复现

主代理uid1000使用150,000条/8.4MB输入与2M排序池，先正常构建，再将核心运行TMPDIR指向现存0500目录。原始核心RC1，libcob报TX-WORK permanent file error status30，候选文件0B。独立JSON：`curriculum/validation/evidence/B02-primary-permission-2026-10-10.json`。对照直接runner继承0500 TMPDIR虽RC12无发布，但实际失败在cobc临时源创建，不能作为SORT运行时故障证据。已要求Luna永久脚本明确构建/运行临时目录边界，补真实核心失败经runner映射与发布保护测试。

### B02 字段核心修复独立复测通过

主代理绕过Python门禁直接编译运行两课核心，valid及zero金额均RC0且原始bytes精确保留；小写ID、16空格ID、status R均RC8。共10个独立探针，证据`curriculum/validation/evidence/B02-primary-field-policy-2026-10-10.json`，含当前两份核心SHA。两份永久check-core-raw.py另独立RC0。核心字段阻塞已修复；runner永久反例、zero金额接L2 RC4业务拒绝和完整交付仍待最终验证，B02尚未放行。

### B02 最新 runner 契约回归（实施中）

主代理MERGE check.py session86599原始RC0；SORT check.py session11645原始RC1，新增zero→L2桥接在引用未定义REPO时NameError。已反馈Luna补变量并整包复跑。这是验收脚本问题，不应将该次SORT测试称通过。pressure已新增wait4核心计量、源码/hash与真实只读TMPDIR和文件大小限制runner证据；当前已见JSON仅1000条smoke，不能作为百万档最终压力通过证据。等待Luna稳定整包后独立执行最终档位。

### B02 教材与重置脚本审查（待修复）

独立course_review发现两课check.sh引用不存在的课内check-runner-failures.py（实际为共享脚本）；SORT教程引用不存在CHECK-KEY段落；starter命令重用reference输出先被no-clobber挡住，不能证明执行starter；reset会删除empty output lock，而runner活锁本身为空目录。独立marked workspace+empty lock探针两课均reset RC0并删锁，需改为任意锁存在即拒绝，保持文件并加回归。已全部反馈Luna整包修复。字段政策静读复核一致。

### B02 reset 活锁保护修复独立通过

主代理两课marked workspace内同时放预存binary/output和empty lock，reset均拒绝且保留三者；独立断言通过。此项不再阻塞。教材命令与最终全套仍待稳定包复验。

### B02 教材命令实际复验

course_review 实际执行两课scripts/check.sh均RC0；临时workspace init/build/reference run均RC0，starter独立输出RC12无发布，reset有锁RC12保持三者、无锁RC0。MERGE README实际代码已改独立starter目标，旧问题撤销。剩余教学问题：修改starter后运行硬编码instructor的check-core-raw.py无法检测学生更改，已要求两课支持COURSE_SOURCE并补workspace副本命令。发布保护无新阻塞，正式pressure尚待最终结果。

### B02 最终主代理验收 — 放行

最终总入口session78535原始RC0，独立pressure session7620原始RC0。独立JSON `curriculum/validation/evidence/B02-primary-pressure-2026-10-10.json` 的两份核心SHA与当前源码一致。10k/100k/1m两算法全部通过；百万SORT22.029s/6656KiB，MERGE23.857s/6604KiB；全档RSS增长1480KiB。百万SORT实际观察四个cobsort FD，最大单文件35,232,196B，非以输入规模推断spill。真实0500运行TMPDIR原始核心RC1/status30及文件大小限制shell153都经runner归一RC12，无发布/无锁遗留。FD证据是抽样路径/大小聚合，无时间戳，不声称逐时序磁盘轨迹。

最后独立full-key反例SORT/MERGE均Z,A,B精确bytes；COURSE_SOURCE指定starter两课core测试都实际失败，证明不会暗测讲师源码；参考源码默认测试已在总入口通过。教材命令实际验证、reset活锁保护及字段政策漂移均闭环。学习包参考实现独立放instructor，正式学员无答案打包在B05/B14按原计划完成。B02交付与要求匹配，放行提交；B03及其余模块仍须逐批实施，不宣称整体完成。
