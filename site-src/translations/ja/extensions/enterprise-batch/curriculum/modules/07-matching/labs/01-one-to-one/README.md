# 07.3 / Boss L1：2つの整列済みストリームを1:1突合

推奨2時間。前提：SELECT/FD/FILE STATUS、PERFORM、EVALUATEを読み、固定長ファイルのバイト幅を理解していること。必要なら先に[データ契約](../../../../../docs/curriculum/BANK-SYSTEM.md)を読み、[バイト配置の実験](../../../../validation/layout/README.md)を行います。

## 業務課題

夜間処理では口座Masterと取引ファイルを受け取ります。この演習の上流契約では1口座あたり最大1件の取引です。両方に存在、口座のみ、取引のみを分類してください。孤立取引は上流の口座がまだ到着していない可能性があるため、黙って破棄してはいけません。本課は分類のみで、**残高を更新したり引落を計上したりしません**。口座状態、貸方/借方、金額方針は後続のL2で定義します。

全ファイルを配列に入れたり、取引ごとにMasterを再走査したりしないでください。各ファイルを前方向に一度だけ読み、作業領域には現在のレコード、直前のキー、固定数のカウンターのみを保持します。

## clean checkoutから実行

検証済みLinux環境にはGnuCOBOL 3.2、Bash、GNU coreutils（realpath、sha256sumを含む）、Make/Gitが必要です。受入確認にはPython 3も必要です。プラグインとDBは不要です。macOS/WSLは未検証です。

リポジトリルートから参考プログラムを実行します。

```bash
lab=curriculum/modules/07-matching/labs/01-one-to-one
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/account.dat" \
  "$lab/fixtures/normal/transaction.dat" /tmp/bank-l1-first 20261009
cat /tmp/bank-l1-first/report.txt
diff -u "$lab/expected/normal.txt" /tmp/bank-l1-first/report.txt
(cd /tmp/bank-l1-first && sha256sum -c inputs.sha256)
python3 "$lab/scripts/check.py"
```

実行ごとに新しい出力ディレクトリを使用します。`/tmp/bank-l1-first`が既に存在する場合、スクリプトはRC12を返し、既存結果を保持します。リセット時は自分で作成した実行ディレクトリだけ削除してください。テストは専用一時ディレクトリを自動作成し、後で削除します。スクリプトは任意のディレクトリから実行でき、空白を含むパスにも対応します。

`run.sh`は業務結果を先に観察できるよう、デフォルトで独立した講師参考実装を使用します。演習ではstarterを自分のディレクトリへコピーし、`COURSE_SOURCE`を指定して同じrunner/検査を実行します。

```bash
cp "$lab/starter/MATCH.COB" /tmp/MY-MATCH.COB
export COURSE_SOURCE=/tmp/MY-MATCH.COB
python3 "$lab/scripts/check.py"  # starterは失敗し、実装完了後に成功する想定
```

starterはビルドできますが、未完成を偽らず意図的に12を返します。参考解答はすべて`instructor/`にあります。自己テスト前に読まないでください。

## 入力と出力

口座レコードは各47バイト、取引レコードは各55バイトで、レコードごとにLFが必要です。LFは幅に含みません。業務日は`20261009`です。Copybookの数値入力は最初PIC Xで受け、IS NUMERICを確認してから変換します。不正データを演算に参加させてはいけません。

フィールド詳細は[DESIGN.md](DESIGN.md)を参照してください。空ファイル、金額0、キー`0000000000`は許可されます。口座は厳密昇順、この1:1課では取引の口座キーも厳密昇順です。取引IDは大文字ASCII英数字16桁で全体一意です。空行、CRLF、NUL、短/長行、最終LF欠落、降順、重複キー、古い業務日、未知バージョンはすべて8を返します。

`report.txt`にはキー順に`MATCH|account_id`、`MASTER-ONLY|account_id`、`TX-ONLY|account_id`を出力します。最終行の5件数は順に口座読込、取引読込、MATCH、MASTER ONLY、TX ONLYで、各値を12桁ゼロ埋めします。

normalフィクスチャの手計算：口座キー1/3/5/8、取引キー1/2/5/7。共通キー1/5、口座のみ3/8、取引のみ2/7です。よって`4=2+2`と`4=2+2`になります。expectedファイルはこの集合関係から作成し、プログラム出力の写しではありません。金額は変更せず、追跡用に元入力snapshotを結果とともに保持します。

## 段階的に実装

1. 2本の読込ポインターを図示し、normalフィクスチャの比較を1回ずつ手で追います。
2. 独立したEOFフラグを2つ定義します。実在する全ゼロ/全9キーをEOFの代わりにしてはいけません。
3. read-master/read-transactionを個別に実装します。元の長さを保持し、フィールドと順序を検証してから比較ループへ渡します。
4. 比較ごとに消費するストリームだけを進め、同値なら両方進めます。片側EOF後は反対側を最後まで処理します。
5. 3種類の明細を出力し、件数式とCLOSE状態を確認し、成功時に0を返します。
6. 自動受入確認を実行し、比較分岐を意図的に逆にしてテストが検出することを確認します。

## 変更と故障の演習

- 口座キー`0000000000`と`9999999999`を先頭/末尾に追加し、EOFが番兵キーではないと示します。
- 最後の取引を存在しない口座に変更し、新しい手計算traceと期待結果を提出します。
- `fixtures/invalid/`のファイルを対応入力に置き換えます。RC8で新しい出力ディレクトリなしが期待値です。ファイル欠落はRC12です。
- 実行中に同名`.lock`を保持し、RC12を確認します。ロックは実行中の試行に属するため、他プロセスのロックを自動削除してはいけません。異常終了後はプロセスが残っていないと確認してから、残存ロックを手動削除します。
- なぜ1:Nをこの課で単純に繰り返せないのでしょうか。厳密昇順の制約とL2で必要なKey Break状態を説明します。

## プラグインとターミナルでの調査

`MATCH.COB`で`:CobolGotoDef`を使ってPERFORMを追い、`:CobolGotoCopybook`でCOPYを見て、`:CobolCalcRecord`で47/55バイトを見積もれます。見積りは実測の代わりになりません。同じ調査は`rg -n 'PERFORM|READ|EOF|COPY'`、`nl -ba`、`od -An -tx1`でも行えます。

## 提出物と合格条件

ソース、状態遷移表、正常/故障時のコマンドとRC、元入力SHA256、レポート、2つの件数保存式を提出し、[evidence/README.md](evidence/README.md)に記録します。自動受入確認に合格しても、「なぜこの段階では片側だけを進めるのか」を説明できる必要があります。メモリ増加検査は[pressure.py](scripts/pressure.py)を参照してください。runnerとデータ生成プロセスはCOBOL matcherのRSSに含めません。
