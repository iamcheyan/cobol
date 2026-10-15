# 模块 04 设计：复杂结构与布局偏移

本设计只读复用模块 07 canonical Copybook，不修改 07/tasks/docs/Makefile 等既有文件，也不改动 CUSTOMER v1=27B、ACCOUNT v1=47B、TRANSACTION v1=55B。

## 结构语义（04.1）

- **REDEFINES**：别名视图与其被重定义项共享同一段存储，**不重复计长**。
  设计用 `01 WRAP` / `05 PAYLOAD`（8+7+3=18B）/ `05 PAYLOAD-RAW REDEFINES PAYLOAD PIC X(18)`，
  `LENGTH OF WRAP = 18`（不是 36）。实测见 04.1 报告。
- **66 RENAMES**：把连续若干字段重新命名成一组，长度 = 被 RENAMES 字段之和（示例 3+4=7）。
- **OCCURS ... INDEXED BY**：定长重复项 + 索引；用 `SET idx TO n` 按序号读取，
  避免硬编码下标算术。
- **OCCURS DEPENDING ON（ODO）**：重复项个数由计数域决定，且**必须是组内最后一项**。
  本配置下 `LENGTH OF` 组项目返回**运行时长度**：count=3 → 2+3×5=17；
  count=7 → 2+7×5=37。这与“编译期固定长度”的假设不同，是本模块的关键实测结论。

## COPY 与布局版本（04.2）

- 用 `COPY 'ENTERPRISE-CUSTOMER-V1.CPY'` 装入 V1；再以
  `COPY ... REPLACING ==CUSTOMER-CLASSIFICATION PIC X(1)== BY ==... PIC X(2)==`
  仅加宽该字段生成 V2。两个 01 组同名，引用一律加 `OF ENT-V1` / `OF ENT-V2` 限定。
- 结果：`CUSTOMER-CLASSIFICATION` 自身偏移不变（1 起算 460），其后**所有字段 +1**，
  总长 1,778 → 1,779。这是“改一个字段会移动哪些后续字段”的最小可复现实验。
- 引用修改（reference modification）：`WS-ID(1:4)`、`WS-ID(5:6)` 从定长字段切子串。
- 布局版本政策：V1 冻结；宽度变化必须新版本（`LAYOUT-VERSION=002`）、旧文件拒绝或转换、
  并行比对、切换与回滚，禁止原地改写既有文件。

## 175 字段记录与字段定位（04.3）

- 记录单位：1,778 字节，字段按 Copybook 顺序紧密排列、无对齐填充、无分隔符/LF。
- 外层边界：文件字节数必须为 1,778 的整数倍，否则 RC8 零发布（GnuCOBOL 定长读可能静默
  补空格返回 00，不能只靠 FILE STATUS）。程序内再校验 `LAYOUT-VERSION=001`、
  `BINARY-ABI-CODE=GCOB32BE`、`CUSTOMER-ID` 为 10 位数字。
- 目录：`FIELD-CATALOG.csv`（175 叶子，逐字段 offset/长度/单位/比较规则）为模块 07
  canonical 副本；**实测验证**由 `scripts/check.py` 用 `ADDRESS OF` 逐字段完成，
  不用 `LENGTH OF` 总长替代逐叶证据。
- 字段定位练习：04.3 打印 `CUSTOMER-ID`/`RECORD-STATUS`/`LEGAL-SURNAME`/
  `CUSTOMER-CLASSIFICATION`/`RISK-SCORE`/`SYNC-STATE`；学习者先按目录手算切片再核对。

## 输出契约

- 04.1：`LESSON,04.1` + `REDEFINES,<key>,<val>` / `RENAMES,...` / `OCCURS,...` / `ODO,...`。
- 04.2：`LESSON,04.2` + `LEN,V1/V2,<n>` / `SHIFT,V2-V1,<n>` / `CLASSIFICATION,...` /
  `REFMOD,...`。
- 04.3：`LESSON,04.3` + `LAYOUT,...` + 每记录 `REC,<n>,ID,<id>` 与
  `  STATUS/`SURNAME/`CLASS/RISK/`SYNC` 行 + `RECORDS,<n>`。

行序固定，检查器逐字比对。

## RC 与发布

| 情形 | RC | 发布 |
|---|---:|---|
| 04.1 / 04.2 正常 | 0 | 发布 |
| 04.3 正常/边界（含空文件、单记录） | 0 | 发布 |
| 04.3 长度错位/版本/ABI/非数字 key | 8 | 不发布 |
| 构建/锁/输出/校验失败 | 12 | 不发布 |

## 实测依据与环境

- 编译器：GnuCOBOL 3.2.0，Linux x86-64，默认方言。
- `ADDRESS OF` 逐字段：175 叶子偏移与目录完全一致；记录总长 1,778。
- V1/V2 探针：`S2-S1`（`SYNC-STATE` 偏移差）= 1；`LENGTH OF` 差 = 1；
  `CUSTOMER-CLASSIFICATION` 偏移两版相同 = 460。
- 运行期 `Warning: program compiled against libxml ...` 为环境噪声，记入 `stderr.txt`。

## 限制

- 仅 Linux x86-64 / GnuCOBOL 3.2 实测；其它编译器/字节序需另立 ABI 版本。
- 04.3 只做结构与长度/版本/键校验，不做模块 07 的全字段业务域比较（那是 07.6 的范围）。
- ODO 的 `LENGTH OF` 行为是本编译器实测；换编译器必须重测，不能照抄。
