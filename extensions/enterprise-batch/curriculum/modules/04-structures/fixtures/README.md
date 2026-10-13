# 企业客户记录夹具

所有 `.dat` 由 [../scripts/generate-fixtures.py](../scripts/generate-fixtures.py)
确定性生成，每条记录 1,778 字节（`ENTERPRISE-CUSTOMER-V1`），无 LF 或分隔符。
SHA256 见 [SHA256SUMS](SHA256SUMS)。

- `normal/enterprise-2.dat`：2 条有效记录。
- `boundary/enterprise-1.dat`：1 条；`boundary/enterprise-empty.dat`：0 字节。
- `invalid/`：长度错位（1783B）、版本 `009`、ABI 不符、非数字 key。

生成器只按已知目录偏移放置少量哨兵值，不编译/运行 COBOL，因此不会成为布局校验的
正确答案来源；布局由 `../scripts/check.py` 的 `ADDRESS OF` 探针独立测量。
