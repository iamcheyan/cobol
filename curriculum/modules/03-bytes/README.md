# 模块 03 数据底层表示（03.1–03.3）

建议 5 小时。先修：模块 02（PIC、`V`、隐含小数、`S`）。本模块只解释“同一个金额在
内存/文件里到底是什么字节”，不改变任何银行接口。冻结契约不变：CUSTOMER v1=27B、
ACCOUNT v1=47B、TRANSACTION v1=55B（见 [BANK-SYSTEM](../../../docs/curriculum/BANK-SYSTEM.md)）。

本模块把 P1 字节实验（[validation/layout](../../validation/layout/README.md)）扩成完整课程：
声明位数与物理字节的区别、ABI/字节序/运行时 Data Exception、非法 Packed 与错位解析。

## 1. 业务为什么需要（需求）

银行夜间批处理要和大型机遗留文件对接：这些文件里的金额不是文本，而是 `DISPLAY`、
`COMP`（二进制）或 `COMP-3`（Packed Decimal）字节。值班开发者必须能在不看源码的情况
下回答：一段原始字节代表多少钱、有没有隐含小数、符号存哪、多少字节、换台机器会不会变。
你做错的代价是把 Packed 的 `0x0C` 当成字符串扫描、或把二进制大端当小端，导致金额错位
而 **RC 仍是 0**。本模块的任务就是建立可验证的字节观，并写出“非法金额先拒绝、绝不参加
算术”的解析器。

## 2. 输入从哪来、格式与前提

- `M03BYTES` 的参考实现由本仓库提供（`instructor/modules/03-bytes/M03BYTES.COB`），
  学员起始代码在 `starter/M03BYTES.COB`。
- 03.1/03.2 不读输入：程序自己把金额写成原始字节，用于 Hex Dump 对照。
- 03.3 读一个**原始二进制**文件：每条记录固定 7 字节，是 `PIC S9(11)V99 COMP-3`
  （13 个数字半字节 + 1 个符号半字节 = 14 半字节 = 7 字节，无 LF、无对齐填充）。
- 前提：只验收 GnuCOBOL 3.2、Linux x86-64、默认方言（`COMP-3`、`FUNCTION TRIM`
  属 GNU 扩展，**禁止** `-std=cobol85`，见 §6)。ASCII 合成数据。
- 夹具：`fixtures/normal/`、`fixtures/boundary/`、`fixtures/invalid/`，SHA256 见
  [fixtures/SHA256SUMS](fixtures/SHA256SUMS)，由
  [scripts/generate-fixtures.py](scripts/generate-fixtures.py) 确定性生成。

## 3. 构建 / 运行 / 复位（任意启动目录）

`scripts/*` 可在任意 cwd 运行，支持带空格的路径。输出目录必须**不存在**（no-clobber）。

```bash
cd /home/tetsuya/development/cobol
bash curriculum/modules/03-bytes/scripts/run.sh 03.1 /tmp/m03-l1
bash curriculum/modules/03-bytes/scripts/run.sh 03.2 /tmp/m03-l2
bash curriculum/modules/03-bytes/scripts/run.sh 03.3 /tmp/m03-l3 \
     curriculum/modules/03-bytes/fixtures/normal/mixed-valid.dat
cat /tmp/m03-l3/report.txt
```

- 03.3 的输入字节数必须是 7 的整数倍，否则运行器先判 RC8 且**不发布**任何输出。
- 运行器在私有 stage 目录生成产物，全部校验通过后才原子重命名为输出目录；失败或
  已有同名目录一律拒绝（RC12）。这**不会**覆盖仓库夹具或其它实验。
- 复位：`bash curriculum/modules/03-bytes/scripts/reset.sh /tmp/m03-l3`
  只在文件集合完整且 `manifest.sha256` 校验通过时删除该输出目录。

派生产物（输出目录内）：`report.txt`（stdout）、`stderr.txt`、`compiler.txt`、
`source.sha256`、`manifest.sha256`；03.1 另有 `abi.bin`，03.2 另有 `amounts.bin`，
03.3 另有输入快照 `input.dat` 与 `inputs.sha256`。

## 4. 预期输出、RC 与独立核算

- **03.1 RC0**：声明逻辑位数 vs `LENGTH OF` 物理字节；COMP 大端、COMP-5 本机小端。
  预期见 [expected/03.1-declare.txt](expected/03.1-declare.txt)。`abi.bin` 前 8 字节
  必须是 `01 02 03 04 04 03 02 01`（大端 COMP / 小端 COMP-5）。
- **03.2 RC0**：同一金额 `12345.67` 与 `-12345.67` 的 DISPLAY / SIGN SEPARATE /
  COMP-3 / 整数分 COMP 原始字节，预期见
  [expected/03.2-hexdump.txt](expected/03.2-hexdump.txt)。`amounts.bin` 共 59 字节。
- **03.3**：每条记录给出 `OK` 解码值或 `REJECT` 原因；`REJECTED=0` 时 RC0，
  有拒绝时 RC4（报告仍发布，因为解析结论本身就是要交付的产物）。
- 独立核算：`scripts/check.py` 内含独立的 Python 参考模型（逐半字节校验、符号 C/D、
  插入隐含小数点、大端整数），重算全部 hex 与 03.3 每条记录，再与 `expected/` 和
  编译后的 COBOL 输出双向比对。核算说明见 [expected/README.md](expected/README.md)。
- **发布前语义核验**：`scripts/run.sh` 在发布前调用 `scripts/verify.py`（与 `check.py`
  共用同一独立模型），由输入原始字节重算期望的 `report.txt` 与 `abi.bin`/`amounts.bin`，
  逐项比对。仅把完成标志改成 `'Y'`、占位 `TODO` 报告、跳过记录、错误金额/符号或记录数
  不符都会失败且**不发布**（对照 §6 的失败注入）。`check.py` 已加入对应回归。

## 5. 需要修改哪里、哪些不能破坏

修改 `starter/M03BYTES.COB` 里 03.1/03.2/03.3 的 TODO 段落，做完把
`WS-EXERCISES-DONE` 设为 `'Y'`。**不能破坏**：

- CUSTOMER v1=27B / ACCOUNT v1=47B / TRANSACTION v1=55B 的既有接口；
- 本模块输出报告的字段顺序（检查器按行逐字比对）；
- 固定格式 80 列规则（Area A/B、无 Tab、有效代码 ≤72 列）。

## 6. 故意破坏与恢复（可复现故障）

1. **非法 Packed 数字半字节**：`fixtures/invalid/bad-digit-nibble.dat` 含 `0xA`，
   程序必须在算术之前逐半字节拒绝，输出 `DIGIT-NOT-0-9`，RC4。
2. **非法符号半字节**：`bad-sign-nibble.dat` 末半字节 `0xF` → `BAD-SIGN-NIBBLE`，RC4。
3. **错位/错误长度**：`truncated.dat`（6B）、`trailing-byte.dat`（8B）不是 7 的倍数
   → 运行器 RC8、零发布。这是外层原字节边界，不能只靠 `FILE STATUS`（GnuCOBOL 定长读
   可能静默补足 `PIC X` 并返回 `00`）。
4. **严格 85 方言**：`cobc -std=cobol85 -fsyntax-only M03BYTES.COB` 会因 `COMP-3`
   报错——这就是为什么 AGENTS/§6 禁止该参数。`check.py` 断言这一步确实失败。
5. **负零陷阱**：`-0.00`（符号 D）与 `+0.00`（符号 C）字节不同、数值都是 0；
   解析器按 C/D 分别接受，不要因为“值是 0”就判非法。
6. **主机 Data Exception vs GnuCOBOL 实际行为**（本环境实测）：把非数字字节塞进
   `PIC 9` 再参与算术，IBM 主机通常抛 data exception（ABEND `S0C7`）；而本机
   GnuCOBOL 3.2 **不报错**，直接算出垃圾值（实测 `ABC`→124、`XYZ`→901，RC0）。
   因此本模块坚持“先逐半字节校验、后算术”，不能依赖运行时替我们拦非法数字。

**恢复**：03.3 的非法记录是“解析成功但拒绝”，报告照发；只有长度错位才 RC8 无发布。
恢复步骤就是修好输入或修好解析器后重跑，运行器从不覆盖既有输出目录。

## 7. 插件路线与纯终端替代

- 插件（cobol.nvim）：用细线标尺确认 Area A/B 与 72 列；`:CobolCalcRecord` 只是估算，
  **不得**当作字节布局的最终依据；`gd` 跳字段、`K` 预览。
- 纯终端等价：`xxd -g1 amounts.bin`、`od -An -tx1`、`sed -n`/`awk` 按列核对；
  最终以 `LENGTH OF`、`ADDRESS OF` 和原始字节为准。两者都要能独立完成本模块。

## 8. 交付证据与失败判定

需交：源文件与 SHA256、编译器/ABI 版本、每个 lesson 的原始命令与 RC、Hex Dump 与解释表、
非法 Packed 的逐半字节判定、错位长度为何 RC8 无发布、`check.sh` 输出。
模板见 [evidence/README.md](evidence/README.md)。

**失败判定**：只交 DISPLAY 文本截图不给原始字节；把 Packed/二进制当字符串扫描；
让非法数据先参与算术；或用严格 `-std=cobol85` 掩盖 GNU 扩展；或只把
`WS-EXERCISES-DONE` 改为 `'Y'` 就提交占位/错误报告（`run.sh` 的独立语义核验会拒绝且
不发布）。任一即失败。
