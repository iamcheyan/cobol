# 固定二进制夹具

所有 `.dat` 均由 [../scripts/generate-fixtures.py](../scripts/generate-fixtures.py)
确定性生成（无外部随机、无 seed 依赖），记录单位为 7 字节 `PIC S9(11)V99 COMP-3`，
文件中无 LF 或其它分隔符。SHA256 见 [SHA256SUMS](SHA256SUMS)。

- `normal/mixed-valid.dat`：正、负、正零、负零、最大金额各一条。
- `boundary/`：空文件、正零、负零、最大金额。
- `invalid/`：坏数字半字节 `0xA`、坏符号半字节 `0xF`、截断 6 字节、8 字节（错位）。

更新夹具后必须先审查十六进制差异，再单独核对 `../expected/` 的人工核算，不能从程序
输出反向生成答案。坏字节以真实字节提交，不是只在 README 里写“这里是坏数据”。
