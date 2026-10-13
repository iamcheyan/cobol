# P1：金额的物理表示

目标：用实际文件字节确定后续课程的ABI基线。环境已验证 Linux x86-64、GnuCOBOL 3.2默认方言；其他架构/编译选项不能照抄本页预期。

```bash
python3 curriculum/validation/layout/check.py
```

检查器在临时目录编译并运行 LAYOUT.COB，逐字节比较23字节原始文件，退出时清理。想自己观察则在新的目录编译并执行：

```bash
mkdir /tmp/cobol-byte-lab
cobc -Wall -x -o /tmp/cobol-byte-lab/layout curriculum/validation/layout/LAYOUT.COB
(cd /tmp/cobol-byte-lab && ./layout && od -An -tx1 layout.bin)
```

该命令会覆盖实验目录中的layout.bin，不会覆盖仓库输入。

| 声明/值 | 实测字节 | 为什么 |
|---|---|---|
| 9(5)V99 DISPLAY /123.45 | `30 30 31 32 33 34 35` | 字符0012345，隐含小数没有字节；7个数字位 |
| S9(5)V99 COMP-3 /123.45 | `00 12 34 5c` | 7个数字半字节+符号；正C |
| 同声明/-123.45 | `00 12 34 5d` | 负D；不是ASCII减号 |
| S9(9) COMP /123456 | `00 01 e2 40` | 此配置4字节，高字节在前 |
| S9(9) COMP-5 /123456 | `40 e2 01 00` | 本机原生字节序，x86-64低字节在前 |

COMP/COMP-5是整数实验，与前三项的123.45不是同一逻辑数值，不要误以为二进制中保存了小数。若改成 `S9(11)V99 COMP-3`，13个数字位加符号通常是7字节；必须相应修改实验和独立预期，不能把现有23字节检查直接取消。

练习：①解释最大值99999.99及最小值；②将金额改为0/-0并查看符号；③增加SIGN SEPARATE并预测长度；④在复制的Packed字段中把一个数字半字节改成A，先判断IS NUMERIC再运算。④属于后续模块03任务，本P1检查尚未实现坏Packed解析器，不能把它计为通过。

插件：用 `:CobolCalcRecord` 预测 WS-LAYOUT；最终以 LENGTH OF 和原始文件比对为准。纯终端路径就是本页命令。提交源码、Hex、字段解释与环境版本，不仅提交“PASS”截图。
