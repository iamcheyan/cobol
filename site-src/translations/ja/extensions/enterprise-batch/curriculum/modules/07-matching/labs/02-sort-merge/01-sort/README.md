# 07.1：COBOL SD/SORTで取引ストリームをソート

この課では未整列のTRANSACTION v1入力を、L2が直接処理できる厳密順序のストリームにします。ソートはCOBOL `SORT`が実行します。INPUT PROCEDUREが生バイトを逐次読込・検証し、有効な55バイトレコードを`RELEASE`します。OUTPUT PROCEDUREは`RETURN`順に同じ内容を書きます。キーは`(account_id, sequence, transaction_id)`で、行全体、口座/IDだけ、入力順ではありません。

インターフェース、RC、フィールド方針、作業ファイル予算は[DESIGN.md](DESIGN.md)および共通[フィールドカタログ](../common/FIELD-CATALOG.md)を参照してください。レコード定義の唯一の情報源はcanonicalな[TRANSACTION-V1.CPY](../../../../../bank/copybooks/TRANSACTION-V1.CPY)です。口座キーと取引キーは書き換えません。金額0は構造上有効で、下流L2が分類します。IDは大文字A–Z/数字のみ、statusはNのみです。

## 手計算から実行へ

1. [normal入力](fixtures/normal/transaction.dat)でZ…001（seq1）、A…002/M…003（seq2）、A…004（seq3）に印を付け、続いて口座2のA…006/B…005を追います。まず6つの複合キー順を独立に書き、[expected/normal.dat](expected/normal.dat)と比較します。ZのIDは辞書順でAより後ですがsequenceが先なので先に出ます。同一sequence内ではAがMより先です。
2. `instructor/modules/07/02-sort-merge/SORTTX.COB`の`LOAD-INPUT`、`CHECK-FIELDS`、`WRITE-OUTPUT`を読みます。キーは`SORT ... ON ASCENDING KEY`に記述され、本課のソースに独立した`CHECK-KEY`段落はありません。`RELEASE`/`RETURN`を使い、1レコードの全ライフサイクルを追跡します。
3. `COPY "TRANSACTION-V1.CPY"`で`:CobolGotoCopybook`を使って実canonical Copybookを開きます。35–40および11–26バイトとカタログを照合します。ターミナル代替：`nl -ba instructor/modules/07/02-sort-merge/SORTTX.COB`、`rg -n 'SORT|RELEASE|RETURN|CHECK-FIELDS|TRANSACTION-V1' instructor/modules/07/02-sort-merge/SORTTX.COB`、`nl -ba curriculum/bank/copybooks/TRANSACTION-V1.CPY`。
4. 「生バイト読込→55B構成→フィールド/日付検証→RELEASE→SORT→RETURN→独立受入確認→公開」の状態図を描きます。不正行で候補が破棄される理由と、runnerが先に入力snapshotを作る理由を説明します。
5. starterの`MAIN-PROCEDURE`はビルド可能なTODO骨組みで、変更用`CHECK-KEY`段落はありません。まず紙に擬似コードを書き、referenceから`SD TX-WORK`、`SORT ... INPUT PROCEDURE`、`RELEASE`、`OUTPUT PROCEDURE`、`RETURN`をstarterへ移植します。各部分の後に独立したstarter目標をビルド/実行し、RC12で終了しなくなるまで進めます。自分のフィールド処理を検証するにはworkspaceへコピーし、対象ソースを明示します：`cp "$lab/starter/SORTTX.COB" "$work/SORTTX.COB"`。実装後に`COURSE_SOURCE="$work/SORTTX.COB" python3 "$lab/scripts/check-core-raw.py"`を実行します。コピー側でID検証を緩め小文字を許可すると、同じ検査が失敗するはずです。ASCII A–Z/0–9検証に戻します。最後に本課の`check.sh`を実行し、大入力でのwork file証跡を記録します。

外部ソートはキー規則の比較にのみ使えます。

```bash
LC_ALL=C sort -k1.1,1.10 -k1.35,1.40 -k1.11,1.26 fixtures/normal/transaction.dat
```

キーはバイト位置1–10、35–40、11–26に対応します。本課のCOBOL SD/SORTの代わりにはなりません。`check.py`内の外部sortも、ディスク上での全体ID一意性検査とバイト多重集合oracleに限って使用します。

## starter、build、run、check、reset

```bash
lab=$PWD/curriculum/modules/07-matching/labs/02-sort-merge/01-sort
work=$(mktemp -d)
bash "$lab/scripts/init-workspace.sh" "$work"
cd "$work"
# デフォルトでは講師参考実装をビルド
bash "$lab/scripts/build.sh" "$work/sorttx"
bash "$lab/scripts/run.sh" \
  "$lab/fixtures/normal/transaction.dat" "$work/sorted.dat"
cd "$lab/.."
sha256sum -c SHA256SUMS
bash "$lab/scripts/check.sh"
```

starterを演習するには、まずworkspace内のターゲットプログラムを削除してからstarterを明示指定します。

```bash
COURSE_SOURCE="$lab/starter/SORTTX.COB" \
  bash "$lab/scripts/build.sh" "$work/sorttx"
COURSE_SOURCE="$lab/starter/SORTTX.COB" \
  bash "$lab/scripts/run.sh" "$lab/fixtures/normal/transaction.dat" \
  "$work/starter-output.dat"  # 独立した新パスでstarter実行とRC12を確認
```

starterはビルド可能なTODO骨組みで、RC12を返し公開しません。別パス`starter-output.dat`を使い、referenceが残した出力によるno-clobber検出を避けます。デフォルトreferenceは独立した講師ディレクトリにあります。starterを段階的に完成してから受入確認してください。`check.sh`はreferenceに対し、normal、空ストリーム、1行、有効なうるう日、金額0、各構造異常、core単独の生バイト拒否、L2通常/金額0ブリッジ、fail-closedを検査します。`reset.sh "$work"`はmarker付きworkspaceかつ出力ロックなしの場合のみ`sorttx`と`sorted.dat`を削除します。ロックがあればresetはRC12を返して全ファイルを残し、実行中JOBを中断しません。

JOB設定：`B02_DATE`の既定は`20261009`、`COB_SORT_MEMORY`は`2M`（GnuCOBOLは1M超を要求）、`TMPDIR`はcore SORT work fileディレクトリを指定します。入力snapshotは元入力を保持し、候補出力はバイト/幅/順序/多重集合を検証した後、上書きしないlinkで公開します。RC0成功、RC8入力契約違反、RC12システム/ソート資源/build/検証/公開失敗。失敗候補は公開しません。業務上の金額0はL2がRC4で分類結果を公開します。

## プラグインとターミナル経路

Neovimは任意です。参考ソースの`COPY "TRANSACTION-V1.CPY"`で`:CobolGotoCopybook`、`SORTTX`内で`:CobolGotoDef`を使って`LOAD-INPUT`/`WRITE-OUTPUT`へ移動し、SD内`TRANSACTION-RECORD`で`:CobolCalcRecord`を使い55バイトを見積もれます。プラグインはソース読解の補助のみで、実行とバイト根拠はshell検査で確認します。ターミナル経路は`rg -n 'LOAD-INPUT|CHECK-FIELDS|SORT|RELEASE|RETURN'`、`nl -ba`、`od -An -tc`です。

## 証跡

実測結果を[evidence/TEMPLATE.md](evidence/TEMPLATE.md)に記録します。レッスン内expectedは手計算済みバイト列です。負荷、spill観察、資源エラーは共通の[B02 evidence](../evidence/B02-pressure-2026-10-10.json)にあります。
