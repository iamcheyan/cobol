# 模块 03 学员证据模板

- 姓名 / 日期：
- 源文件 SHA256（参考实现或你的 starter）：
- 编译器与 ABI 版本（`cobc -V`，Linux x86-64）：
- 逐 lesson 命令与**原始 RC**：
- 03.1：声明位数 vs `LENGTH OF` 表，COMP 大端 / COMP-5 小端证据（`abi.bin` hex）：
- 03.2：`12345.67`/`-12345.67` 各类表示的 Hex Dump 与解释（符号、隐含小数、字节序、长度）：
- 03.3：合法记录的逐半字节判定与解码值：
- 03.3：非法 Packed 记录（坏数字 nibble / 坏符号 nibble）的拒绝原因，说明为何未参与算术：
- 03.3：错位/错误长度输入为何 RC8 且零发布：
- `bash scripts/check.sh` 的输出：
- 插件 `:CobolCalcRecord` 估算与 `LENGTH OF` 实测是否一致（不一致说明原因）：
