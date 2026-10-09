# 07.2：把两个有序交易流用 COBOL MERGE 合成一条

本课的两个独立源各自已按复合键严格升序。COBOL `MERGE ... USING FEED-A FEED-B`逐次挑选最小键，OUTPUT PROCEDURE 用 `RETURN` 写出原55字节。程序先逐原始字节预扫两条源，确认LF、记录宽度、字段、真实日期及每条流严格升序；随后执行真正的 `MERGE`。没有拼接后再SORT的替代实现。

业务键、字节边界、状态和RC见 [DESIGN.md](DESIGN.md) 与 [字段目录](../common/FIELD-CATALOG.md)。源结构只使用canonical [TRANSACTION-V1.CPY](../../../../../bank/copybooks/TRANSACTION-V1.CPY)。同账户同sequence不同ID合法；各源内相同全键/逆序、任何来源的重复global ID、错误原字节均RC8。两源都为空时输出空文件且RC0。

## 学习路径

1. 先手算 [Feed-A](fixtures/normal/feed-a.dat) 和 [Feed-B](fixtures/normal/feed-b.dat) 的三元键。A流是Z(seq1)、M(seq2)、B(acct2/seq1)，B流是A(seq2)、A(seq3)、A(acct2/seq1)。将两个游标各推进一次，逐轮选最小键，独立得到 [expected/normal.dat](expected/normal.dat) 的Z,A,M,A,A,B顺序。
2. 在参考 `instructor/modules/07/02-sort-merge/MERGETX.COB` 查 `VALIDATE-SOURCE`、`CHECK-FIELDS`、`CHECK-ORDER`、`MERGE ... USING` 和 `WRITE-MERGED`。说明为什么预扫只验证每个输入自身顺序，而 MERGE 才决定跨流次序。
3. 用 `:CobolGotoDef` 从 `MAIN-PROCEDURE` 跳到 `VALIDATE-SOURCE`、再跳到 `WRITE-MERGED`；光标放在SD下的 `COPY "TRANSACTION-V1.CPY"` 行使用 `:CobolGotoCopybook`，核对canonical字段。终端等价操作：`rg -n 'VALIDATE-SOURCE|CHECK-ORDER|MERGE|USING|RETURN|TRANSACTION-V1' instructor/modules/07/02-sort-merge/MERGETX.COB`、`nl -ba curriculum/bank/copybooks/TRANSACTION-V1.CPY`。
4. 做实验：把Feed-A的首两行交换，MERGE必须RC8且无发布；只把ID改为小写，仍RC8；把两个输入中同一transaction_id放得很远，必须跨源RC8。再用zero-amount边界流，MERGE仍RC0原样输出，交给L2则按ZERO-AMOUNT分类为RC4。
5. 对比SORT和MERGE职责：前者从乱序输入通过 `RELEASE` 建立顺序；后者只读已排序源并流式选最小键。说明为何不能先合并文本再SORT来冒充MERGE。

外部比较命令明确按字节1–10、35–40、11–26排序：

```bash
LC_ALL=C sort -k1.1,1.10 -k1.35,1.40 -k1.11,1.26 \
  fixtures/normal/feed-a.dat fixtures/normal/feed-b.dat
```

这是外部对照，不是课程核心。生产结果由 COBOL MERGE 生成；验收脚本的外部sort只执行global ID唯一性与字节多重集检查。

## starter、build、run、check、reset

```bash
lab=$PWD/curriculum/modules/07-matching/labs/02-sort-merge/02-merge
work=$(mktemp -d)
bash "$lab/scripts/init-workspace.sh" "$work"
cd "$work"
bash "$lab/scripts/build.sh" "$work/mergetx"
bash "$lab/scripts/run.sh" \
  "$lab/fixtures/normal/feed-a.dat" "$lab/fixtures/normal/feed-b.dat" \
  "$work/merged.dat"
cd "$lab/.."
sha256sum -c SHA256SUMS
bash "$lab/scripts/check.sh"
```

starter可构建但返回RC12，确保错误实现不发布：

```bash
set +e
COURSE_SOURCE="$lab/starter/MERGETX.COB" \
  bash "$lab/scripts/run.sh" "$lab/fixtures/normal/feed-a.dat" \
  "$lab/fixtures/normal/feed-b.dat" "$work/starter-output.dat"
rc=$?
set -e
test "$rc" -eq 12
test ! -e "$work/starter-output.dat"
```

starter的 `MAIN-PROCEDURE` 是单一TODO入口。练习时先写双流比较游标的伪代码，再从reference移植逐字节源校验、每源严格键序检查及 `MERGE ... USING`/`RETURN`；逐阶段构建，使用新输出路径确认自己的starter实际运行。字段探针也可指定workspace源码副本：`COURSE_SOURCE="$work/MERGETX.COB" python3 "$lab/scripts/check-core-raw.py"`，默认则检查instructor reference。`B02_DATE` 默认 `20261009`；`COB_SORT_MEMORY=2M` 显式限制GnuCOBOL SORT/MERGE运行池；`TMPDIR`控制核心临时资源。runner快照两个输入，不改原始流；独立校验候选结果后才no-clobber发布。`reset.sh "$work"`仅接受带本课marker且没有任何输出锁的目录，只清理`mergetx`、`merged.dat`，保留其他文件；发现锁时以RC12拒绝且不删除任何内容。

## 下游桥接和证据

`check.py`实际把MERGE结果传给BATCHL2，逐字节检查L2报告、完整47B master、55B accepted及rejected；另有SORT→L2常规桥接。零金额专例的B02预期RC0、L2业务分类RC4并发布ZERO-AMOUNT拒绝行。查看 [共同expected](../common/expected/) 与 [L2接口夹具](../common/fixtures/integration/)。记录本人实测命令、原始RC与SHA见 [evidence/TEMPLATE.md](evidence/TEMPLATE.md)；完整压力/工作文件数据见 [B02 pressure JSON](../evidence/B02-pressure-2026-10-10.json)。

可选插件导航：在COPY行运行`:CobolGotoCopybook`，再在`CHECK-ORDER`的PERFORM上运行`:CobolGotoDef`；终端替代为`rg`、`nl -ba`和`od -An -tc`。插件不参与验收。
