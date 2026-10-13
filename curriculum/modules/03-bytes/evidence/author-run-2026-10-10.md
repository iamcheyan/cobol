# 模块 03 作者执行记录（2026-10-10）

环境：Linux x86_64；`cobc (GnuCOBOL) 3.2.0`，默认方言（无 `-std=cobol85`）。
所有命令在仓库根 `/home/tetsuya/development/cobol` 执行。

## 1. ABI 探针（独立于模块程序）

    mkdir /tmp/m03probe && cobc -x -o /tmp/m03probe/probe /tmp/m03probe/PROBE.COB
    (cd /tmp/m03probe && ./probe && xxd probe.bin)

实测：`+12345.67` DISPLAY = `31323334353637`；负号覆盖末字节 `0x77`；
`S9(5)V99 COMP-3` 正/负 = `1234567c` / `1234567d`；`S9(11)V99 COMP-3` = 7 字节；
`S9(9) COMP` = 大端 `0012d687`，`COMP-5` = 小端 `87d61200`。
这些事实用于独立撰写 `expected/`。

## 2. RED（学员 starter 必须失败且不发布）

    COURSE_SOURCE=curriculum/modules/03-bytes/starter/M03BYTES.COB \
      bash curriculum/modules/03-bytes/scripts/run.sh 03.3 /tmp/ev-m03-starter \
      curriculum/modules/03-bytes/fixtures/normal/mixed-valid.dat

原始 RC = **12**；`/tmp/ev-m03-starter` 不存在（零发布）；`/tmp/ev-m03-starter.lock`
不存在（无锁泄漏）。

## 3. GREEN（讲师参考实现）

    bash curriculum/modules/03-bytes/scripts/check.sh

RC = **0**，输出 `PASS: module 03 declarations, raw bytes, packed parse and fail-closed`，
随后 `sha256sum -c SHA256SUMS` 全部 `完了`。

单条非法 Packed（坏数字 nibble）：

    bash curriculum/modules/03-bytes/scripts/run.sh 03.3 /tmp/ev-m03-green \
      curriculum/modules/03-bytes/fixtures/invalid/bad-digit-nibble.dat

原始 RC = **4**（业务拒绝，报告仍发布）。`report.txt`：

    REC,0001,00000a1234567c,REJECT,[INVALID],DIGIT-NOT-0-9
    SUMMARY,TOTAL,0001
    SUMMARY,ACCEPTED,0000
    SUMMARY,REJECTED,0001

## 4. 结构错位（长度非 7 倍数）→ RC8 零发布

    bash .../run.sh 03.3 /tmp/out curriculum/modules/03-bytes/fixtures/invalid/truncated.dat
    # 原始 RC = 8；/tmp/out 不存在

## 5. 严格 85 方言的可复现故障

    cobc -std=cobol85 -fsyntax-only instructor/modules/03-bytes/M03BYTES.COB
    # error: syntax error（COMP-3 属 GNU 扩展），非 0 RC

## 6. 原始字节证据

    xxd curriculum/modules/03-bytes/fixtures/normal/mixed-valid.dat
    # 0000001234567c 0000001234567d 0000000000000c 0000000000000d 9999999999999c
    # run.sh 03.1/03.2 产物：abi.bin = 0102030404030201，amounts.bin = 59 字节

## 7. 主机 Data Exception vs GnuCOBOL 实测

    # PROBE: REDEFINES 非数字 X 当 PIC 9 参与 COMPUTE
    # ABC -> Y=124 ; XYZ -> Y=901 ; 均为 RC0（无运行时错误）

主机上这类非法数字运算通常触发 data exception（ABEND S0C7）；本机 GnuCOBOL 3.2
却静默产生垃圾值。故解析器必须先逐半字节校验，绝不先算术。

## 限制

- 仅 Linux x86-64 / GnuCOBOL 3.2 实测；EBCDIC、其它字节序、其它编译器未验证。
- 运行期 `Warning: program compiled against libxml ...` 为环境噪声，不参与断言。
- `-std=cobol85` 拒绝是本环境事实，不代表所有厂商方言。
