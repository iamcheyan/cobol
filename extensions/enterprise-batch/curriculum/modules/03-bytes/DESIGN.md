# 模块 03 设计：金额的物理表示与非法数据解析

状态：设计基线，仅覆盖模块 03；不改动 CUSTOMER v1=27B、ACCOUNT v1=47B、
TRANSACTION v1=55B 契约，也不改动模块 07 与既有 P1 实验。

## 环境与 ABI 基线

- GnuCOBOL 3.2、Linux x86-64、**默认方言**；`COMP-3` / `FUNCTION TRIM` 是 GNU 扩展，
  禁止 `-std=cobol85`。其它编译器/架构/字节序需重新实测并另立 ABI 版本。
- 实测 ABI（本仓库 `instructor/modules/03-bytes/M03BYTES.COB` 运行时探针 + P1）：
  - `PIC S9(n)` DISPLAY 每数字 1 字节；`SIGN LEADING SEPARATE` 另加 1 符号字节。
  - DISPLAY 无 `SIGN SEPARATE` 时为**符号覆盖（overpunch）**：正 `0x30|digit`，
    负 `0x70|digit`（如 `-12345.67` 末字节 `0x77`）。
  - `COMP-3`：每字节两个数字半字节，末半字节为符号（C 正 / D 负），
    字节数 = `ceil((N+1)/2)`（N=数字位数）。`S9(11)V99`→13 位+符号→7 字节。
  - `COMP`：此配置**大端**，长度按值域（`S9(4)`=2B、`S9(9)`=4B、`S9(18)`=8B）。
  - `COMP-5`：本机原生**小端**。
- 只有先校验原字节，才能解释数值；`COMP`/`COMP-3` 的高位字节**不得**当 ASCII 扫描。
- **主机 Data Exception 与 GnuCOBOL 实际行为**：COBOL 标准规定对含非法数字的数值项做
  算术会触发 data exception；IBM 主机表现为 ABEND `S0C7`。但本机 GnuCOBOL 3.2 实测
  **不报错**：把 `ABC`/`XYZ` 放入 `PIC X` 后用 `REDEFINES` 当 `PIC 9` 参与 `COMPUTE`，
  分别得到 124/901 且 RC0（静默垃圾值）。因此课程要求显式校验 nibble，绝不依赖运行时。
- 运行时提示 `Warning: program compiled against libxml 212 using older 209` 是本机
  GnuCOBOL 链接库版本噪声，与业务无关，记录在 `stderr.txt`，不参与断言。

## 统一记录单位（03.3）

- 原始文件：连续的 7 字节记录，无 LF、无对齐；`PIC S9(11)V99 COMP-3`，13 数字位 + 符号。
- 外层边界：文件字节数必须为 7 的整数倍，否则 RC8 且零发布。原因：GnuCOBOL 定长顺序
  文件读到不足一条时可能静默补 `PIC X` 空格并返回 `FILE STATUS 00`，不能只靠读循环。
- 逐半字节校验：13 个数字半字节必须 0–9；符号半字节必须 C 或 D（本课程不接受 F）。
  **校验通过之前不做任何十进制算术**，只做整数取半字节比较。
- 解码：数字串前 11 位为整数部分、后 2 位为小数部分（隐含小数点不占字节）。
  正负零（C/D）都是数值 0，字节不同、语义相等。

## 输出契约

报告为 CSV 风格纯文本，逐行类型：

- 03.1：`LESSON`、`ABI`（endianness）、`DECL,<name>,<usage>,<digits>,<bytes>,<formula>`。
- 03.2：`LESSON`、`AMOUNT`、`HEX,<name>,<lower-hex>`、`TOTAL,<bytes>`。
- 03.3：`LESSON`、`REC,<seq>,<hex>,OK,<value>,` 或
  `REC,<seq>,<hex>,REJECT,[INVALID],<reason>`、三行 `SUMMARY`。

行序固定，检查器逐字比对；任何多余/缺失行即失败。

## RC 与发布

| 情形 | RC | 发布 |
|---|---:|---|
| 03.1 / 03.2 正常 | 0 | 发布 |
| 03.3 全部合法 | 0 | 发布 |
| 03.3 有拒绝（合法输入，解析结论） | 4 | 发布 |
| 03.3 文件长度不是 7 倍数（结构错位） | 8 | 不发布 |
| 构建/锁/输出/校验失败 | 12 | 不发布 |

## 运行器与失败不发布

`run.sh`：参数校验 → 加目录锁 `OUT.lock` → 私有 `mktemp` stage → 快照输入并校验和
→ 编译参考/学员源码 → 在 stage 内运行（stdout→report.txt，stderr→stderr.txt）
→ RC 归一化（0/4 通过，其它失败）→ 校验和与 manifest → 全部通过后 `mv -T -n` 原子发布。
任何一步失败清理 stage 并保留锁说明，绝不产生正式输出。`reset.sh` 仅在文件集合完整且
manifest 校验通过时删除输出目录（拒绝未知文件、软链、篡改）。

## 与银行系统的关系

03.1/03.2 用基础实验金额 `12345.67`，并额外演示 ACCOUNT v1 的“整数最小单位”思想
（`S9(9) COMP` 存 1234567 分）。03.3 的 7 字节 Packed 记录与模块 07 L4 的
`S9(9)V99 COMP-3` 限额字段同族（都是 Packed、先校验半字节再比较），为模块 07 的
Packed 处理与模块 11 事故调查（非法数字/错位）打底。本模块不新增银行文件契约。

## 限制

- 仅 Linux x86-64 / GnuCOBOL 3.2 实测；EBCDIC、大机 overpunch 码表、其它 endian 未验证。
- 仅演示单字节 ASCII；多字节/Unicode 字符数与字节数差异不在本模块结论内。
