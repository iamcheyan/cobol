# 作者验证记录 — 模块 05（非学员证据）

日期：2026-10-10。环境：Linux x86-64，GnuCOBOL 3.2.0（`cobc -info` → indexed handler BDB），
Bash，GNU coreutils，Python 3。代表性命令与**原始返回码**：

```text
$ cobc --version | head -1
cobc (GnuCOBOL) 3.2.0
$ bash curriculum/modules/05-control/scripts/check.sh
PASS: module 05 cleanse normal, boundary and invalid contracts      # RC=0
$ bash .../run.sh .../fixtures/normal/clean.dat /tmp/ev5 20261009
PASS: business and control totals verified                          # RC=0
```

RED→GREEN：

```text
COURSE_SOURCE=starter/CLEANSE.COB run.sh .../normal/clean.dat /tmp/red5 ...
  -> RC=12，未发布任何输出目录（RED）
run.sh .../normal/clean.dat /tmp/green5 ...
  -> RC=0，发布并核对通过（GREEN）
```

逐夹具实测 RC（`run.sh` 原始退出码）：

| 夹具 | RC | 说明 |
|---|---:|---|
| normal/clean | 0 | 3 条接收，AMOUNT=60 |
| boundary/empty | 0 | 0 字节合法 |
| boundary/min-amount, max-amount, single | 0 | 边界合法 |
| invalid/{missing-name,bad-id,non-numeric-amount,amount-over-cap,unknown-status,duplicate-id,mixed} | 4 | 字段级业务拒绝，发布 |
| invalid/{unsorted,short-record,long-record,no-trailing-lf,crlf} | 8 | 契约错误，不发布 |
| 输入缺失 | 12 | 不发布 |

语言微实验（实际输出）：

```text
$ ./language-probe   # RC=0
NORM|00000001|Alice|ACTIVE
NORM|00000002|Bob|DISABLED
NORM|00000003|Carol|UNMAPPED
$ ./search-all-probe # RC=0
SORTED=FOUND
UNSORTED=MISS
```

失败注入：`/dev/full` 作为 accepted/rejected 输出时 `verify-publish.py` 拦截，RC12 且不发布
（由 `check.py::check_full_device_fail_closed` 覆盖）。

限制：仅 Linux x86-64 实测；金额上限 50,000,000 为合成政策；`libcob: warning`（libxml）为
环境噪声。未解决项：无（模块 05 范围内）。
