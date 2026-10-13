# 模块 09 作者运行证据（2026-10-10）

平台：Linux x86-64 ・ GnuCOBOL 3.2.0 ・ Bash 5.2 ・ Python 3.13。营业日 `20261010`。
以下是本模块实现时真实执行过的命令与原始返回码；学员请按 `evidence/README.md` 交自己的证据，
不要覆盖本文件。

## 1. 全量验收

```console
$ bash curriculum/modules/09-modular/scripts/check.sh
PASS: module 09 CALL/LINKAGE contracts and failure paths
$ echo $?
0
```

## 2. RED → GREEN：调用者送错接口版本

RED：把主程序送 AMTCALC 的版本改成 `002`（被调用者行为正确，根因在调用者）。

```console
$ rogue=/tmp/red-amt-version.COB
$ sed "s/MOVE '001' TO AMT-IFACE-VERSION/MOVE '002' TO AMT-IFACE-VERSION/" \
    instructor/modules/09-modular/BATCH09.COB > "$rogue"
$ rm -rf /tmp/b09-red
$ COURSE_SOURCE="$rogue" bash curriculum/modules/09-modular/scripts/run.sh \
    curriculum/modules/09-modular/fixtures/normal/customer.dat \
    curriculum/modules/09-modular/fixtures/normal/account.dat \
    curriculum/modules/09-modular/fixtures/normal/transaction.dat /tmp/b09-red 20261010
INTERFACE-MISMATCH
$ echo $?
8
$ test -e /tmp/b09-red && echo exists || echo "no publish"   # → no publish
```

GREEN：改回 `001`。

```console
$ bash curriculum/modules/09-modular/scripts/run.sh \
    curriculum/modules/09-modular/fixtures/normal/customer.dat \
    curriculum/modules/09-modular/fixtures/normal/account.dat \
    curriculum/modules/09-modular/fixtures/normal/transaction.dat /tmp/b09-green 20261010
PASS: business and control totals verified
$ echo $?
0
$ diff -q curriculum/modules/09-modular/expected/normal.txt /tmp/b09-green/report.txt && echo match
match
```

## 3. 接口/生命周期探针（RED→GREEN 之二：状态泄露与修复）

```console
$ cobc -Wall -I curriculum/modules/09-modular/copybooks -x -o /tmp/ifaceprobe \
    curriculum/modules/09-modular/scripts/ifaceprobe.COB \
    instructor/modules/09-modular/AMTCALC.COB
$ /tmp/ifaceprobe
BY-REF     AFTER=BBBBB
BY-CONTENT AFTER=BBBBB
BY-VALUE   N-BEFORE=+0000000042
BY-VALUE   N-AFTER=+0000000042
STATIC     CALL1=0001
STATIC     CALL2=0002
INITIAL    CALL1=0001
INITIAL    CALL2=0001
AMT-OK     RC=000 BAL=+0000000001500 REASON=OK
AMT-VER    RC=008 REASON=IFACE-VERSION
AMT-LEN    RC=008 REASON=IFACE-LENGTH
AMT-ZERO   RC=004 REASON=ZERO-AMOUNT
AMT-OVERD  RC=004 REASON=OVERDRAFT
AMT-OVFL   RC=004 REASON=OVERFLOW
AMT-DIR    RC=004 REASON=BAD-DIRECTION
AMT-NUM    RC=004 REASON=AMT-NOT-NUMERIC
$ echo $?
0
```

`STATIC CALL2=0002` 是第二次调用的残留（RED）；`INITIAL CALL2=0001` 是 `IS INITIAL` 修复（GREEN）。
`AMT-VER`/`AMT-LEN` 证明长度与版本不匹配在进入业务前即返回 RC8。

## 4. 各夹具原始 RC（节选）

| 夹具 | 原始 RC | 发布 |
|---|---:|---|
| normal | 0 | 是 |
| empty-customers / no-transactions / max-amount / all-empty | 0 | 是 |
| customer-bad-status / customer-bad-id / customer-no-name | 4 | 是 |
| zero-amount / overdraft / overflow / unknown-direction | 4 | 是 |
| no-account / frozen-account | 4 | 是 |
| bad-layout-version / short-account / bad-account-date | 8 | 否 |
| unsorted-transactions | 8 | 否 |
| starter（未实现） | 12 | 否 |

## 5. 内部模块长度实测

```console
CUSTOMER=00027  AMTCALC=00045  CUSTVAL=00040  LOGGER=00054   # LENGTH OF, GnuCOBOL 3.2
```

## 6. 限制

- 仅 Linux x86-64 实际验证；macOS/WSL 未验证。
- `BY VALUE` 与子程序 `RETURNING` 在 GnuCOBOL 3.2 有已知未完成告警，已在 DESIGN 第 4 节说明，
  生产模块改用 `RETURN-CODE` 回传。
- `LINE SEQUENTIAL` 输出会裁剪行尾空格，日志行因此不定宽；独立模型同样裁剪。
