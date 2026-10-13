# B04 / 07.6 Boss L4：企业客户扩展记录逐字段比较

状态：设计基线已由主代理批准进入实现；批准不代表Copybook布局或课程包验收通过。本文件不批准实现擅自改变字段/布局。

## 业务边界

B04比较同一CUSTOMER-ID在两个批次中的企业客户扩展快照，定位每个业务字段变化。它不替代已有接口：CUSTOMER27是基础教学对象，ACCOUNT v1仍是47B账户主档，TRANSACTION v1仍是55B交易；本课新增独立的`ENTERPRISE-CUSTOMER-V1`固定二进制记录，不把175+业务属性塞进ACCOUNT，也不声称它是B03的离线Customer Snapshot。

V1保留独立的一位`CUSTOMER_CLASSIFICATION`基线（A retail、B business、C private、D public-sector）；`RECORD_STATUS`是另一业务语义（A active/I inactive），不能被误用成客户区分。**V1不并列塞入V2字段，也不伪称一位与两位是两个不同分类语义。**维护练习先对V1做影响调查，再设计新的`ENTERPRISE-CUSTOMER-V2`：同一分类字段从PIC X扩为PIC X(2)，布局版本由001改002，V2分类码映射/offset变化/上下游迁移另行评审。练习示例映射A→A1、B→B1、C→C1、D→D1；V1文件不得被原地覆盖。

本草案有175个具名业务叶子字段，覆盖Header/Identity/Classification/Address/Contact/Bank relationship/Risk compliance/Limits/Channel/Audit。字段ID、物理偏移和比较规则见同目录`FIELD-CATALOG.csv`。没有FILLER；组项目身不占字节；V1不使用REDEFINES或可变OCCURS，所以不会将别名重复计入字段数，也没有运行时变长记录。

## Proposed 物理记录布局

- 编码：固定单字节ASCII字节；所有DISPLAY文本/代码/数字均占一个ASCII字节/字符。非ASCII输入拒绝RC8。本练习用罗马字母合成客户数据，不覆盖生产Unicode/EBCDIC转换。
- Framing：旧、新文件均为连续的固定宽度二进制记录，**每条1,778字节，不含分隔符和LF**；字段按Copybook声明顺序紧密排列，无对齐填充。不得用LINE SEQUENTIAL、`splitlines()`或文本转换读取它。空文件是零记录；完整额外记录是一个额外业务键，不是“超长行”。
- 布局字段：开头`LAYOUT_VERSION=X(3)`固定`001`；之后`BINARY_ABI_CODE=X(8)`固定`GCOB32BE`，表明本版本的GnuCOBOL 3.2/Linux x86-64 PIC COMP big-endian ABI；之后偏移12处是十位ASCII数字`CUSTOMER_ID`键。
- 表示：普通文本/代码/日期为DISPLAY `PIC X`；无符号计数/修订号为DISPLAY `PIC 9(n)` ASCII；18个limit金额为非负`PIC S9(9)V99 COMP-3`，6字节、两位小数、单位为PRIMARY_CURRENCY major units；`RISK_SCORE_ADJUSTMENT`也是6字节COMP-3但单位为risk points，范围−9999.99..9999.99；二者不共用单位。`RISK_SCORE`为`PIC S9(9) COMP`，4字节，按GnuCOBOL实测big-endian（例如0x01020304输出01 02 03 04）；不能从CPU native endian推断。`COMP-5`在本机实测为native little-endian，但V1不使用COMP-5。V1避免隐含对齐。
- Packed合法字节：每个数字半字节必须为0–9；本课程合同仅接受正C、负D sign nibble。主代理的真实GnuCOBOL原语探针发现当前编译器对PIC S的F sign nibble `IS NUMERIC`返回false，故不把F当合法值。解析前逐半字节校验，不允许非法Packed参与算术。正负零C/D表示都是数学0，作为不同原始编码但数值相等案例；执行代理本机探针已实测二者均`IS NUMERIC`且比较相等（这是原语证据，不代表最终字段/布局验收）。
- 文件/平台限制：课程只验收GnuCOBOL 3.2运行于Linux x86-64 host、且PIC COMP实测为big-endian的构建，Copybook、编译参数和ABI tag须匹配；不同编译器、字节序、PIC/优化选项均需新的ABI版本和独立实测。COMP值先通过二进制范围校验再参与比较。
- 版本与原始长度门禁：runner在锁内快照输入并按bytes检查总文件长度是否为1,778整倍数，拒绝部分尾记录RC8；随后COBOL固定记录读取逐记录确认版本、ABI、key、必填/代码、DISPLAY数值、COMP范围、Packed各nibble和严格递增键。GNUCOBOL固定顺序文件读不足一条可能静默补足PIC X且返回00；因此**字节数取模检查是必要的外层原字节边界**，不宣称仅靠FILE STATUS可检出短record。插入/删除一个字节会令取模失败；额外完整记录按键/基数语义分类。

字段起始偏移为1-based字节位置。CSV偏移是设计推导，只有生成Copybook后由GnuCOBOL实际布局writer逐字段输出具名哨兵，再由独立byte checker核对所有175个字段切片、总长与目录一致，才可升级为已验证布局。编译器`LENGTH OF`检查只证明总长，不能替代逐叶偏移证据。主代理独立验收还会逐字段交叉验证，请勿改其验收契约。

## 比较语义

旧/新文件分别按CUSTOMER-ID严格升序且每个键最多一条。COBOL以有界双游标顺序合并：键相等时逐字段比较；旧键小输出OLD-ONLY；新键小输出NEW-ONLY。两边EOF合法；两边空RC0；单边有记录产生对应记录级差异RC4。重复、逆序key、版本或ABI冲突、宽度错误、非法编码/数值为结构错误RC8，整批不发布。工具/磁盘/锁/输出/核验失败RC12且无发布。存在合法业务差异RC4，报告/统计经独立验收后发布。

字段规则明确分为：

- `RAW`：在字段字节上逐字节相等；用于键、版本、状态/代码、日期及需要保留表示的标识。
- `TEXT-NORM`：先验证ASCII可打印范围，将a–z按ASCII规则映射为A–Z，再仅移除右侧ASCII空格；不trim左侧、不折叠中间空格、不做locale/Unicode转换。归一化后相同不产生业务差异，但以summary计数记录“字节不同、语义相同”。
- `NUMERIC`：先校验原始DISPLAY/COMP/COMP-3表示及字段范围，再按PIC符号/小数缩放解码，比较精确十进制语义，不用浮点。数值相等但合法编码字节不同时不产生业务差异，另计representation-equal。
- `IGNORE-AUDIT`：允许审计维护字段变化，计为audit-only并在报告中定位field_id；不增加业务差异RC，不进入“字段差异”统计。

可执行域规则：必填DISPLAY文本/代码的全空格值非法；nullable文本/日期只允许整字段空格表示NULL，不允许部分空格冒充NULL。所有X字段先拒绝控制字节/高位非ASCII；代码字段另依CSV逐字段精确码集验证。flag字段为Y/N/U，MFA/voiceprint为Y/N；记录状态仅A/I；classification仅A/B/C/D；客户类型IND/ORG/TRU；产品族DEP/CRD/LON/INV；币种JPY/USD；本课国家码JP/US。审查状态各字段码值按CSV区分（例如KYC为N/P/C/R、AML为C/P/H/R）。日期范围19000101..20991231并用Gregorian校验；审计时间戳为真实YYYYMMDDHHMMSS，时间限制HH00..23、MM/SS00..59；CONTACT_TIME_FROM/TO为有效HHMM。每个count字段各自PIC宽度和上界见CSV。所有limit仅0.00..999999999.99，不接受负限额；风险调整允许正负并按risk points解释。主电话号码的country/area/number三字段必须全有或全NULL；nullable=N字段的空格不是缺省值而是结构错误。

差异行包含run ID、输入版本、旧/新记录序号、遮蔽客户键、field_id/name、1-based offset、length、rule、差异类型、old/new显示值。具体每行格式（逗号分隔，COBOL实际输出，oracle独立复算同一格式）：

```text
FIELD,<run_id>,<layout_version>,<old_seq>,<new_seq>,<redacted_key>,<field_id>,<cobol_name>,<offset>,<length>,<rule>[,REDACTED]
AUDIT,<run_id>,<layout_version>,<old_seq>,<new_seq>,<redacted_key>,<field_id>,<cobol_name>,<offset>,<length>,IGNORE-AUDIT
OLD|<old value>
NEW|<new value>
```

`<redacted_key>`固定为`******`加客户ID后4位；`<old_seq>`/`<new_seq>`是该文件内条带的1-based记录序号（`OLD-COUNT`/`NEW-COUNT`）；`<name>`取FIELD-CATALOG.csv的canonical `cobol_name`（人工业务名`business_name`可由catalog按field_id解析）。同一匹配记录内，IGNORE-AUDIT块先输出、业务字段块后输出。敏感字段旧新值固定输出`[REDACTED]`，不得把明文写入stdout/stderr/差异报告；raw二进制在报告中只输出安全十六进制表示（敏感时仍遮蔽）。日期格式固定YYYYMMDD并执行Gregorian校验。Summary至少有old/new/matched/old-only/new-only records、business-different fields、audit-only fields、normalized-equal、numeric-representation-equal、结构拒绝数；所有统计由COBOL实际计数，独立verifier从原始记录和变更清单另算。

## 独立验收及发布

核心算法是COBOL：固定记录逐条读取，双键游标比较，按目录逐项比较全部175叶字段并输出候选。Python可生成夹具与用独立字段元数据/人工变更清单验收结果，不替代字段比较。输入快照、锁、私有stage、RC映射、候选字节/计数校验、no-clobber atomic publish沿用已验收课程runner模式；所有hash及候选检查必须在rename前完成，rename后不得再执行可失败验收。

独立变更集至少含完全相同、首/中/尾单字段、多组多字段、文本大小写/尾空格等价、Packed不同合法零表示数值等价、数值实际变化/正负/缩放/上下界、ignore audit、敏感字段脱敏、无效Packed数字/符号、DISPLAY非法数字/范围、key/版本/ABI、空/单边EOF/短/长/重复/逆序等。expected须先人工给出原始十六进制位置与语义值，再运行实现。

## 影响调查练习：客户区分1位→2位

迁移对象不是`RECORD_STATUS`。调查V1 `CUSTOMER_CLASSIFICATION PIC X`的读取/比较/排序/输出位置，再为同一语义提出V2 `PIC X(2)`、布局版本002、明确值映射及unknown策略；追踪客户主数据、B03 customer key/snapshot、B04新旧比较、下游通知/渠道/限额消费、批作业参数和恢复点。V1冻结不改；V2必须说明分类宽度改变使其后所有物理偏移变化、旧文件拒绝/转换策略、双写/并行比对、切换、回滚及版本冲突测试。未经调查不直接在V1中间插PIC并覆盖文件。
