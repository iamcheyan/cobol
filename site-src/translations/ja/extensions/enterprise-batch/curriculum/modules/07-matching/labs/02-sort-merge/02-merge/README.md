# 07.2：COBOL MERGEで2つの整列済み取引ストリームを統合

本課の2つの独立入力はそれぞれ複合キーで厳密昇順です。COBOL `MERGE ... USING FEED-A FEED-B`は繰り返し最小キーを選び、OUTPUT PROCEDUREは`RETURN`を使って元の55バイトを書き出します。プログラムはまず両sourceをバイト単位で走査し、LF、レコード幅、フィールド、有効日付、各ストリーム内の厳密順序を検証し、その後実際に`MERGE`します。連結後にSORTする代替はありません。

業務キー、バイト境界、status、RCについては[DESIGN.md](DESIGN.md)と[フィールドカタログ](../common/FIELD-CATALOG.md)を参照してください。source構造ではcanonicalな[TRANSACTION-V1.CPY](../../../../../bank/copybooks/TRANSACTION-V1.CPY)のみを使用します。同じ口座とsequenceでもIDが異なれば有効です。各source内の全キー重複/降順、いずれかのsourceの全体ID重複、不正な元バイトはRC8です。両sourceが空なら空出力でRC0です。

## 学習経路

1. [Feed-A](fixtures/normal/feed-a.dat)と[Feed-B](fixtures/normal/feed-b.dat)の3要素キーを手計算します。AストリームはZ(seq1)、M(seq2)、B(acct2/seq1)、BストリームはA(seq2)、A(seq3)、A(acct2/seq1)です。2つのcursorをそれぞれ進めて毎回最小キーを選び、[expected/normal.dat](expected/normal.dat)のZ,A,M,A,A,B順を独立に導きます。
2. 参考実装`instructor/modules/07/02-sort-merge/MERGETX.COB`から`VALIDATE-SOURCE`、`CHECK-FIELDS`、`CHECK-ORDER`、`MERGE ... USING`、`WRITE-MERGED`を探します。事前走査は各入力自体の順序のみを確認し、ストリーム間の順序をMERGEが決める理由を説明します。
3. `:CobolGotoDef`で`MAIN-PROCEDURE`から`VALIDATE-SOURCE`、次に`WRITE-MERGED`へ移動します。SD下の`COPY "TRANSACTION-V1.CPY"`行で`:CobolGotoCopybook`を使い、canonicalフィールドを確認します。ターミナル代替：`rg -n 'VALIDATE-SOURCE|CHECK-ORDER|MERGE|USING|RETURN|TRANSACTION-V1' instructor/modules/07/02-sort-merge/MERGETX.COB`、`nl -ba curriculum/bank/copybooks/TRANSACTION-V1.CPY`。
4. 実験：Feed-A先頭2行を入れ替えると、MERGEはRC8で公開しないはずです。IDだけを小文字に変更してもRC8です。2入力内で同じ`transaction_id`を離れた位置に置くと、全体検査がRC8にします。次に金額0境界ストリームを使います。MERGEはRC0で元バイトをそのまま出力し、下流L2はZERO-AMOUNTをRC4で分類します。
5. SORTとMERGEの役割を比較します。前者は未整列入力から`RELEASE`で順序を作り、後者は整列済みsourceのみを読み、ストリームしながら最小キーを選びます。テキスト連結後のSORTがMERGEの代わりにならない理由を説明します。

外部比較ではバイト位置1–10、35–40、11–26を明示してソートします。

```bash
LC_ALL=C sort -k1.1,1.10 -k1.35,1.40 -k1.11,1.26 \
  fixtures/normal/feed-a.dat fixtures/normal/feed-b.dat
```

これは外部比較であり、コースの中核アルゴリズムではありません。本番出力はCOBOL MERGEで生成します。受入スクリプト内の外部sortは全体ID一意性とバイト多重集合の確認に限ります。

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

starterはビルドできますがRC12を返すため、誤った実装は公開されません。

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

starterの`MAIN-PROCEDURE`には単一のTODO入口があります。まず2ストリームcursorの擬似コードを書き、参考実装からバイト単位のsource検証、sourceごとの厳密キー順確認、`MERGE ... USING`/`RETURN`を移植します。段階的にビルドし、新しい出力パスでstarter実行を確認してください。workspaceのソースコピーをfield probeに指定することもできます：`COURSE_SOURCE="$work/MERGETX.COB" python3 "$lab/scripts/check-core-raw.py"`。デフォルトは講師参考実装を検査します。`B02_DATE`既定値は`20261009`、`COB_SORT_MEMORY=2M`はGnuCOBOL SORT/MERGE poolを明示的に制限、`TMPDIR`はcore一時資源を指定します。runnerは両入力をsnapshotし、原streamを変更しません。候補を独立検証してから上書きなしで公開します。`reset.sh "$work"`は本課marker付きで出力ロックのないworkspaceだけを受け付け、`mergetx`と`merged.dat`のみ削除し他ファイルを保持します。ロックを見つけた場合RC12で拒否し、何も削除しません。

## 下流ブリッジと証跡

`check.py`は実際にMERGE結果をBATCHL2へ渡し、L2レポート、完全な47B master、55B accepted/rejectedをバイト単位で確認します。通常のSORT→L2ブリッジも確認します。金額0の特例ではB02がMERGEのRC0を期待し、L2の業務分類はRC4でZERO-AMOUNT拒否行を公開します。[共通expected](../common/expected/)と[L2統合フィクスチャ](../common/fixtures/integration/)を参照してください。実測コマンド、生RC、hashは[evidence/TEMPLATE.md](evidence/TEMPLATE.md)に記録します。完全な負荷/work fileデータは[B02 pressure JSON](../evidence/B02-pressure-2026-10-10.json)にあります。

プラグイン操作は任意です。COPY行で`:CobolGotoCopybook`、`CHECK-ORDER`のPERFORMで`:CobolGotoDef`を使います。ターミナル代替は`rg`、`nl -ba`、`od -An -tc`です。プラグインは受入確認に関与しません。
