# R12 修复证据：模块 05 PERFORM VARYING / 作用域 / 跌落实操（2026-10-10）

对应审查条目 R12：“模块05缺实际 PERFORM VARYING、作用域/顺序跌落实验”。
平台：Linux x86-64，GnuCOBOL 3.2.0。

## 新增可运行实操

`curriculum/modules/05-control/scripts/control-flow-probe.COB`（固定格式，≤72 列），
由 `check.py::check_control_flow` 实际编译运行并逐行断言。

原始输出（本机实测，RC0）：

```text
$ cobc -Wall -x -o /tmp/cfprobe curriculum/modules/05-control/scripts/control-flow-probe.COB
$ /tmp/cfprobe
VARYING=15     # PERFORM VARYING I FROM 1 BY 1 UNTIL I > 5
INLINE=20      # PERFORM 2 TIMES ... END-PERFORM（内联）
FIRST          # PERFORM 2000-FIRST：作用域止于段落边界
SCOPE-DONE
FIRST          # PERFORM 2000-FIRST THRU 3000-SECOND：落入后续段落
SECOND
THRU-DONE
PROBE_RC=0
```

## 覆盖的 syllabus 05.1 条目

| 条目 | 位置 | 学员修改 | 断言 |
|---|---|---|---|
| PERFORM VARYING | probe `UNTIL I > 5` | 改 `> 3` → `VARYING=6` | `VARYING=15` |
| 内联 PERFORM | probe `PERFORM 2 TIMES` | 改 `3 TIMES` → `INLINE=30` | `INLINE=20` |
| 段落作用域 | `PERFORM 2000-FIRST` | 去掉 `THRU` | 只有一次 `FIRST`，`SECOND` 消失 |
| 落入后续段落 | `PERFORM ... THRU 3000-SECOND` | — | `FIRST`→`SECOND` 顺序出现 |

## 对应表

完整的大纲要求 ↔ 源码/输入/学员修改/故障/expected/check/证据对应表见
`curriculum/modules/05-control/README.md` 第 10 节；控制流语义说明见 `DESIGN.md` 第 8 节。

## 原始 RC 记录

| 命令 | RC |
|---|---:|
| `cobc -Wall -x -o cfprobe control-flow-probe.COB` | 0 |
| `/tmp/cfprobe` | 0 |
| `bash curriculum/modules/05-control/scripts/check.sh` | 0 |
