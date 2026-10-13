# 模块 03 预期结果与独立核算

所有 expected 由**独立参考模型**先算出，再与编译后的 COBOL 输出比对；不是把程序输出
保存成答案。参考模型在 [../scripts/verify.py](../scripts/verify.py) 中（Python，
`run.sh` 发布前调用），测试入口 [../scripts/check.py](../scripts/check.py) 复用同一模型；
COBOL 实现在 `instructor/modules/03-bytes/M03BYTES.COB`。

## 03.1 声明位数与 ABI

| 名称 | USAGE | 逻辑数字位 | 字节 | 依据 |
|---|---|---:|---:|---|
| AMT-DISPLAY | DISPLAY | 7 | 7 | 每数字 1 字节 |
| AMT-SIGN-SEP | SIGN LEADING SEPARATE | 7 | 8 | 数字 + 1 独立符号字节 |
| AMT-PACKED | COMP-3 | 7 | 4 | ceil((7+1)/2) |
| AMT-PACKED-BIG | COMP-3 | 13 | 7 | ceil((13+1)/2) |
| AMT-BINARY-4 | COMP | 4 | 2 | 值域 S9(4) |
| AMT-BINARY-9 | COMP | 9 | 4 | 值域 S9(9) |
| AMT-BINARY-18 | COMP | 18 | 8 | 值域 S9(18) |

字节序：把 `16909060 = 0x01020304` 放进 `S9(9) COMP` 得 `01 02 03 04`（大端）；
放进 `S9(9) COMP-5` 得 `04 03 02 01`（x86-64 本机小端）。

## 03.2 同一金额 12345.67 的原始字节

| 字段 | 值 | 原始字节 | 说明 |
|---|---|---|---|
| AMT-DISPLAY | +12345.67 | `31323334353637` | ASCII `1234567`，隐含小数，正符号=覆盖 `0x30` |
| AMT-SIGN-SEP | +12345.67 | `2b31323334353637` | 前导独立 `+` |
| AMT-DISPLAY-NEG | -12345.67 | `31323334353677` | 末字节 `0x77`=`0x70|7` 负覆盖 |
| AMT-SIGN-SEP-NEG | -12345.67 | `2d31323334353637` | 前导独立 `-` |
| AMT-PACKED-POS | +12345.67 | `1234567c` | 7 数字 + C 符号 |
| AMT-PACKED-NEG | -12345.67 | `1234567d` | 7 数字 + D 符号 |
| AMT-PACKED-BIG | +12345.67 | `0000001234567c` | 13 数字 + C，7 字节 |
| AMT-BINARY-4 | +1234 | `04d2` | 0x04D2=1234，大端 |
| AMT-COMP-MINOR | +1234567 | `0012d687` | 0x12D687=1234567，整数“分” |
| AMT-BINARY-18 | +123456789012345 | `00007048860ddf79` | 大端 8 字节 |

`amounts.bin` = 上述 10 个字段顺序拼接，共 59 字节。

## 03.3 Packed 解析

参考模型：每条 7 字节 → 14 半字节；前 13 为数字（须 0–9），末半字节为符号（C/D）；
解码为 `<sign><11 位整数>.<2 位小数>`。

| 夹具 | 原始字节 | 判定 |
|---|---|---|
| `normal/mixed-valid.dat` | 5 条正/负/±零/最大 | 全 OK，RC0 |
| `boundary/empty.dat` | 0 字节 | TOTAL=0，RC0 |
| `boundary/zero-positive.dat` | `0000000000000c` | `+00000000000.00` |
| `boundary/zero-negative.dat` | `0000000000000d` | `-00000000000.00`（负零数值 0） |
| `boundary/max-value.dat` | `9999999999999c` | `+99999999999.99` |
| `invalid/bad-digit-nibble.dat` | `00000a1234567c` | REJECT `DIGIT-NOT-0-9`，RC4 |
| `invalid/bad-sign-nibble.dat` | `0000001234567f` | REJECT `BAD-SIGN-NIBBLE`，RC4 |
| `invalid/truncated.dat` | 6 字节 | RC8，零发布（长度非 7 倍数） |
| `invalid/trailing-byte.dat` | 8 字节 | RC8，零发布 |
