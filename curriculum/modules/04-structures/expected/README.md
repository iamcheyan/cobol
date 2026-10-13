# 模块 04 预期结果与独立核算

expected 由结构语义与实测 ABI 独立确定，再与编译后的 COBOL 输出比对；不把程序输出
当答案。核心实测由 [../scripts/check.py](../scripts/check.py) 用 GnuCOBOL `ADDRESS OF`
逐字段完成（175 叶子 + V1/V2 偏移），并写入
[../evidence/M04-layout-author.json](../evidence/M04-layout-author.json)。
`run.sh` 发布前由 [../scripts/verify.py](../scripts/verify.py) 用同一语义重算报告并
逐项比对（04.3 直接按字段目录偏移从原始字节重算），不符即拒绝且不发布。

## 04.1 结构语义

| 项 | 预期 | 依据 |
|---|---|---|
| WRAP 长度 | 18 | PAYLOAD=8+7+3=18；REDEFINES 别名不另占字节 |
| PAYLOAD / PAYLOAD-RAW 长度 | 18 / 18 | 同一段存储的两种视图 |
| R-AB 长度 | 7 | RENAMES R-A(3) THRU R-B(4) |
| R-AB 值 | `AAABBBB` | R-A=`AAA`, R-B=`BBBB` |
| OCCURS 项数 / INDEX-3 | 5 / `CCC` | `SET IDX-POS TO 3` 取第 3 项 |
| ODO count=3 长度 | 17 | 2(计数) + 3×5 |
| ODO count=7 长度 | 37 | 2(计数) + 7×5 |

## 04.2 COPY REPLACING 与偏移移动

| 项 | 预期 | 依据 |
|---|---|---|
| LEN,V1 | 1778 | 企业客户 V1 canonical 长度 |
| LEN,V2 | 1779 | 仅 CUSTOMER-CLASSIFICATION 由 X(1) 改 X(2) |
| SHIFT | 1 | 加宽 1 字节 |
| 分类偏移 | 460（两版相同） | 分类自身在其后被加宽，偏移不变 |
| SYNC-STATE 偏移 | V1=1778 / V2=1779 | 其后所有字段 +1 |
| REFMOD FIRST4/LAST6 | `0000` / `000001` | `CUSTOMER-ID` = `0000000001` |

## 04.3 企业记录定位

- `normal/enterprise-2.dat`：2 条记录（key 0000000001=A/EXAMPLE/1234，
  0000000003=B/SAMPLE/-25）。见 [04.3-normal.txt](04.3-normal.txt)。
- `boundary/enterprise-1.dat`：1 条；`boundary/enterprise-empty.dat`：0 条（RC0）。
- `invalid/`：长度错位 / 版本 `009` / ABI 不符 / 非数字 key 均 RC8 零发布。

## 与模块 07 的关系

目录、Copybook、1,778 字节布局与模块 07 L4 同源；本模块只做结构与定位教学，
不做逐字段业务域比较。175 字段偏移与目录一致由本模块 `check.py` 独立复测。
