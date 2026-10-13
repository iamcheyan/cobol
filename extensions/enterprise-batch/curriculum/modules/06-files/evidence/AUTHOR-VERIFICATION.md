# 作者验证记录 — 模块 06（非学员证据）

日期：2026-10-10。环境：Linux x86-64，GnuCOBOL 3.2.0（`cobc -info` → indexed handler BDB），
Bash，GNU coreutils，Python 3。代表性命令与**原始返回码**：

```text
$ cobc --version | head -1
cobc (GnuCOBOL) 3.2.0
$ cobc -info | grep handler
indexed file handler     : BDB
$ bash curriculum/modules/06-files/scripts/check.sh
PASS: module 06 file contract, boundary and invalid cases           # RC=0
$ bash .../run.sh .../fixtures/normal/valid.dat /tmp/green6 20261009
PASS: file contract and control totals verified                     # RC=0
```

RED→GREEN：

```text
COURSE_SOURCE=starter/FILEVAL.COB run.sh .../normal/valid.dat /tmp/red6 ...
  -> RC=12，未发布输出目录（RED）
run.sh .../normal/valid.dat /tmp/green6 ...
  -> RC=0，发布并核对通过（GREEN）
```

逐夹具实测 RC：

| 夹具 | RC |
|---|---:|
| normal/valid, boundary/{empty,single,negative-balance,zero-balance} | 0 |
| invalid/{bad-account-id,bad-customer-id,unknown-currency,bad-sign,bad-balance,bad-date,date-mismatch,unknown-status,duplicate-id,mixed} | 4 |
| invalid/{bad-layout,unsorted,short-record,long-record,no-trailing-lf,crlf} | 8 |
| 输入缺失 | 12（stderr `Input missing/unreadable`；未发布） |

FILE STATUS：发布目录 `filestatus.log` = `OPEN|ACCOUNT|00` / `EOF|ACCOUNT|10`。

## 06.2 LINE SEQUENTIAL 实测（line-seq-probe，RC=0）

```text
LINE-LOGICAL=HELLO
LINE-NEXT=10
LINE-RAW-BYTES=06      # HELLO + LF
LINE-RAW-LF=Y
FIXED-RAW-BYTES=05     # 定长无 LF
```

## 06.4 索引文件实测（indexed-probe，RC=0）

```text
CREATE=00 WRITE1=00 DUPLICATE=22 CLOSE=00 IO=00
READ=V1 REWRITE=00 MISSING=23 DELETE=00 DELETED-READ=23
REOPEN=41        # 同一进程再次 OPEN 已打开文件
MISS-OPEN=35     # OPEN 缺失文件 → 映射 RC12
```

## 06.4 相对文件实测（relative-probe，RC=0）

```text
CREATE=00 WRITE1=00 WRITE2=00 DUPLICATE=22 CLOSE=00 IO=00
READ1=00 AAAA REWRITE=00 READ9=23 DELETE=00 DELETED-READ=23
```

## 06.4 跨进程锁实测（单次实验）

进程 A `OPEN I-O` 后 sleep 10，进程 B 在 A 持有期间 `OPEN I-O`：

```text
A: HOLD=00
B: SECOND=00        # 未被拒绝
```

结论：**默认 GnuCOBOL/BDB 索引文件不提供跨进程互斥**。单实例保护必须由 JOB 层外部锁
（本课 `run.sh` 的 `.lock` 目录）保证；`REOPEN=41` 只反映同一进程内重复打开。此边界写入
DESIGN 第 5.5 节与 README 第 8 节。

限制：仅 Linux x86-64 实测；索引/相对文件仅作阅读实验与模块 07 临时账本用途；`libcob:
warning`（libxml）为环境噪声。未解决项：无（模块 06 范围内）。
