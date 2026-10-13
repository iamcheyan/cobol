# R12 修复证据：模块 06.4 两进程争锁与 JOB 锁（2026-10-10）

对应审查条目 R12：“模块06.4同进程重复OPEN得到41，不能代替两个进程争锁实验；
若后端不支持互斥，以实测证明限制并验证 JOB 锁方案”。
平台：Linux x86-64，GnuCOBOL 3.2.0，`cobc -info` → indexed file handler: BDB。

## 两进程争锁实测（不是同进程重开）

新增 `curriculum/modules/06-files/scripts/indexed-hold-probe.COB`：`OPEN I-O` 后停在
stdin 上持有文件；`check.py::check_cross_process_lock` 并发启动两个副本。

原始输出（本机实测）：

```text
process A: HOLD-OPEN=00
process B: HOLD-OPEN=00      <- 第二个进程在第一个仍持有时也成功打开
close: HOLD-CLOSE=00 rc 0
close: HOLD-CLOSE=00 rc 0
```

结论：默认 GnuCOBOL/BDB 句柄层**不提供跨进程互斥**；同一进程内重复 `OPEN` 返回 `41`
（`indexed-probe.COB`）不能推断两进程行为。

## JOB 锁方案验证

`run.sh` 用 `output.lock` 目录做单实例保护。`check.py::check_protection` 同时启动两个
`run.sh` 指向同一输出目录，实测断言：

- 两个进程 RC 排序为 `[0, 12]`；
- 失败者的 stderr 含 `Run locked`；
- 成功输出与 `expected/normal-valid.txt` 一致；
- 结束后 `output.lock` 目录已被清理，无残留。

## 对应表

完整的大纲要求 ↔ 源码/输入/学员修改/故障/expected/check/证据对应表见
`curriculum/modules/06-files/README.md` 第 9 节；适合性边界见 `DESIGN.md` 第 5.5 节。

## 附加：06.1 的 SD（排序描述项）实操

`curriculum/modules/06-files/scripts/sort-sd-probe.COB` 用 `SD SORT-WORK` 声明排序工作
文件，配 `SORT … ASCENDING KEY … USING SORT-INPUT GIVING SORT-OUTPUT`。原始输出实测：

```text
$ printf 'CAROL\nALICE\nBOB\n' > in.dat
$ SI_PATH=in.dat SO_PATH=out.dat ./sort-sd-probe
ALICE
BOB
CAROL
RC=0
```

由 `check.py::check_line_sequential_and_sd` 断言三行有序输出。

## 原始 RC 记录

| 命令 | RC |
|---|---:|
| 两个 `indexed-hold-probe` 并发 `OPEN I-O` 同一文件 | 各 0（`HOLD-OPEN=00`） |
| 两个 `run.sh` 并发同一输出目录 | 0 与 12（`Run locked`） |
| `bash curriculum/modules/06-files/scripts/check.sh` | 0 |
