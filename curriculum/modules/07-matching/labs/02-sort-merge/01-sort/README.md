# 07.1：用 COBOL SD/SORT 排序交易流

这课把乱序的 TRANSACTION v1 输入变成 L2 可直接消费的严格有序流。排序由 COBOL `SORT` 执行：INPUT PROCEDURE 逐原始字节读取并核验，`RELEASE` 有效的55字节记录；OUTPUT PROCEDURE `RETURN` 并原样写出。键为(account_id, sequence, transaction_id)，不是整行、账户/ID或输入顺序。

接口、RC、字段政策和工作文件预算见 [DESIGN.md](DESIGN.md) 与共通 [字段目录](../common/FIELD-CATALOG.md)。记录定义唯一来源是 [TRANSACTION-V1.CPY](../../../../../bank/copybooks/TRANSACTION-V1.CPY)。账户及交易键不改写；零金额是结构合法数据，给下游L2分类；ID仅大写A–Z/数字，状态仅N。

## 从手算到运行

1. 在 [normal输入](fixtures/normal/transaction.dat) 圈出Z…001(seq1)、A…002/M…003(seq2)、A…004(seq3)，再追踪账户2的A…006/B…005。先独立写下六个复合键顺序，再用 [expected/normal.dat](expected/normal.dat) 对照。Z的ID字典序比A大，却因sequence较早排在A之前；同sequence下A先于M。
2. 阅读 `instructor/modules/07/02-sort-merge/SORTTX.COB` 的 `LOAD-INPUT`、`CHECK-FIELDS`、`WRITE-OUTPUT`。排序键写在 `SORT ... ON ASCENDING KEY` 中；本课源码没有独立 `CHECK-KEY` 段。在 `RELEASE`/`RETURN` 跟一行记录走完整条生命周期。
3. 在 `COPY "TRANSACTION-V1.CPY"` 处使用 `:CobolGotoCopybook` 打开真实canonical copybook。对着第35–40及11–26字节核对字段目录。终端替代：`nl -ba instructor/modules/07/02-sort-merge/SORTTX.COB`、`rg -n 'SORT|RELEASE|RETURN|CHECK-FIELDS|TRANSACTION-V1' instructor/modules/07/02-sort-merge/SORTTX.COB` 和 `nl -ba curriculum/bank/copybooks/TRANSACTION-V1.CPY`。
4. 按“读原始字节→构造55B→字段/日期验证→RELEASE→SORT→RETURN→独立验收→发布”画出状态图。解释为什么坏行会让候选文件被丢弃，为什么runner先快照输入。
5. starter 的 `MAIN-PROCEDURE` 是可编译的 TODO 框架，不包含可修改的 `CHECK-KEY` 段。先在纸上写伪代码，再把reference中的 `SD TX-WORK`、`SORT ... INPUT PROCEDURE`、`RELEASE`、`OUTPUT PROCEDURE` 与 `RETURN` 移植到starter；每完成一段，构建并运行单独的starter目标，直到starter不再以RC12退出。要验证自己写的字段逻辑，可复制到workspace并显式指定被测源码：`cp "$lab/starter/SORTTX.COB" "$work/SORTTX.COB"`，完成可运行实现后执行 `COURSE_SOURCE="$work/SORTTX.COB" python3 "$lab/scripts/check-core-raw.py"`。把该副本的ID校验故意放宽为小写后，同一命令应失败；恢复ASCII A–Z/0–9校验。最终运行本课 `check.sh` 并记录大输入工作文件证据。

外部排序只用于对照键规则，可用：

```bash
LC_ALL=C sort -k1.1,1.10 -k1.35,1.40 -k1.11,1.26 fixtures/normal/transaction.dat
```

命令键对应字节1–10、35–40、11–26。它不能代替本课 COBOL SD/SORT；`check.py` 内的外部sort仅用于磁盘化global ID唯一检查及字节多重集oracle。

## starter、build、run、check、reset

```bash
lab=$PWD/curriculum/modules/07-matching/labs/02-sort-merge/01-sort
work=$(mktemp -d)
bash "$lab/scripts/init-workspace.sh" "$work"
cd "$work"
# default builds the instructor reference
bash "$lab/scripts/build.sh" "$work/sorttx"
bash "$lab/scripts/run.sh" \
  "$lab/fixtures/normal/transaction.dat" "$work/sorted.dat"
cd "$lab/.."
sha256sum -c SHA256SUMS
bash "$lab/scripts/check.sh"
```

为了练习 starter，先删掉工作目录中的目标程序，然后显式选 starter：

```bash
COURSE_SOURCE="$lab/starter/SORTTX.COB" \
  bash "$lab/scripts/build.sh" "$work/sorttx"
COURSE_SOURCE="$lab/starter/SORTTX.COB" \
  bash "$lab/scripts/run.sh" "$lab/fixtures/normal/transaction.dat" \
  "$work/starter-output.dat"  # 独立新路径，确认实际执行starter并返回12
```

starter 是可构建的 TODO 框架，会以 RC12 拒绝发布。独立的 `starter-output.dat` 确保不是被reference遗留文件触发no-clobber检查。默认reference路径是独立讲师目录；将starter逐步补齐后验收。`check.sh` 检查reference的normal、空流、单行、有效闰日、零金额、所有结构异常、直接核心原字节拒绝、L2普通/零金额桥接，以及失败关闭。`reset.sh "$work"` 仅在带marker且不存在输出锁时清理 `sorttx` 和 `sorted.dat`；任何锁都使reset以RC12拒绝并保留全部文件，以免打断仍在运行的任务。

JOB设置：`B02_DATE` 默认为 `20261009`；`COB_SORT_MEMORY` 默认为 `2M`（GnuCOBOL要求大于1M）；`TMPDIR` 控制核心SORT工作文件目录。输入快照只读原始输入，候选输出经字节/长度/顺序/多重集核对后以no-clobber链接发布。RC0成功、RC8输入契约错误、RC12系统/排序资源/构建/核验/发布失败；失败候选不发布。业务零金额由L2返回RC4并发布分类结果。

## 插件与终端路径

可选Neovim：在参考源码的 `COPY "TRANSACTION-V1.CPY"` 行执行 `:CobolGotoCopybook`，在 `SORTTX` 上用 `:CobolGotoDef` 跳转 `LOAD-INPUT`、`WRITE-OUTPUT`，在SD的 `TRANSACTION-RECORD` 查看 `:CobolCalcRecord` 估算55字节。插件导航仅帮助读源码，运行和字节结论由以上shell检查给出。纯终端完成同样任务：`rg -n 'LOAD-INPUT|CHECK-FIELDS|SORT|RELEASE|RETURN'`、`nl -ba`、`od -An -tc`。

## 证据

真实结果填写 [evidence/TEMPLATE.md](evidence/TEMPLATE.md)。课内expected是静态手算字节文件；压力、spill观察和资源错误保存在共同 [B02 evidence](../evidence/B02-pressure-2026-10-10.json)。
