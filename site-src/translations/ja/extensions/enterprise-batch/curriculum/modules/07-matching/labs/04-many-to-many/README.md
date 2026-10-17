# Boss L3：顧客日次集計と4ストリーム統合

本課では、検証済みL2会計結果を顧客日次snapshotおよび前日controlと突合します。顧客は複数の口座と取引を持てます。口座と取引はそれぞれ1顧客にだけ属し、顧客単位で口座残高/件数、accepted貸方/借方金額/件数を集計します。N:Nは複数口座と複数取引が同じ顧客集計キーを共有する意味です。口座×取引を組み合わせたり直積を作ったりせず、顧客残高を各口座に複製しません。

会計上の事実源は引き続きL2です。公式runnerはまず生のACCOUNT、TRANSACTION、REVERSAL-LINKをB01 L2へ渡し、accepted/rejected、完全な期末Master、reportを保持してから、本課coreを実行します。L3は再計上せず、DBも更新しません。Snapshotはオフラインseedデータです。実際のDB抽出/更新はモジュール08の範囲です。

口座をaccount_id順に並べてもcustomer_idは逆行する場合があります：口座1→顧客2、口座2→顧客1、口座3→顧客2。したがってCOBOLでcustomer_idを付加したディスクソート済みストリームを先に作り、ACCOUNT、accepted TX、Snapshot、Previousの4ストリームを統合します。4つのcursor、現在レコード、固定精度の累計値だけを保持します。顧客グループはディスクspoolへ一時保存し、グループ終端でeligible/隔離を決めます。

## フィールドと方針

[DESIGN](DESIGN.md)と[FIELD-CATALOG](FIELD-CATALOG.md)を開き、`:CobolGotoCopybook`で本課の実ファイル`CUSTOMER-SNAPSHOT-V1.CPY`と`PREVIOUS-DAY-V1.CPY`を確認します。ACCOUNT v1はcanonical 47B、TRANSACTION v1はcanonical 55Bでレイアウト版フィールドはありません。Snapshot v1は36B、Previous-Day v1は39Bです。すべて固定幅ASCII、LF終端です。日付は実際のGregorian暦で検証し、Previousは銀行営業日カレンダーではなく直前の暦日です。

完全な顧客グループごとに次を確認します：顧客口座数と前日口座数が一致、当日期首合計と前日closingが一致、`expected closing = previous closing + L2 accepted credit - L2 accepted debit`、再計算closingがL2 closing master集計と一致、口座数とclosingがsnapshot control以内。口座数/残高はA/F/Cすべてのstatusを含みます。L2 rejectedは別途保持し、accepted金額には含めません。

Snapshot/Previous欠落、顧客status D、口座数/残高の業務差異はRC4となり、関連口座/accepted取引を元の47B/55Bバイトと理由付きで隔離します。行が欠けた孤児Snapshot/Previousも元36B/39B sourceを保存します。構造エラー（LF欠落、CRLF、幅/日付/版不正、キー重複/降順）はRC8で公開しません。ツール、権限、sort用ディスク、検証、lock、公開障害はRC12で公開しません。RC4でも他の合格顧客は公開できますが、下流処理は隔離ファイルを除外する必要があります。

全体controlは次を満たします：元ACCOUNT数 = eligible master数 + 隔離口座数；L2 accepted数 = eligible accepted TX数 + 隔離accepted TX数；accepted貸方/借方の各合計 = eligible額 + 隔離額；opening + credit − debit = closing。L2 rejected件数は別計上です。

## 学習経路

1. `fixtures/normal`を手作業で追跡します。口座順に読むと顧客順は2、1、2です。顧客1の2,000−100=1,900、顧客2の4,000+120−20=4,100を計算します。`expected/normal-master.dat`と`expected/normal-customer-totals.csv`で確認し、repo rootから`(cd curriculum/modules/07-matching/labs/04-many-to-many && sha256sum -c SHA256SUMS)`を実行します。
2. 参考`instructor/modules/07/04-many-to-many/BATCHL3.COB`の`1300-SORT-ACCOUNTS`、`1400-SORT-TRANSACTIONS`、`1500-RUN-FOUR-WAY`、`1550-RESET-GROUP`、`1580-DECIDE-GROUP`、`1590-REPLAY-SPOOL`を読みます。この表は実プログラムの各段階でREAD後にあるcursorを記録します。グループ開始時に4ストリームの最小customer keyを選び、その顧客のACCOUNTをグループ終端まで読み、続いてaccepted TXを終端まで読み、対応SnapshotとPreviousを各1回読み、最後にspoolを判定/再生します。表の各cursorはその段階のREAD完了後の現在レコードで、変化しないstreamは位置を保ちます。元ACCOUNTの顧客順は2,1,2。customer/account順ソート後のaccount IDは2,1,3です。accepted TXの顧客順は`01:T003`、`02:T001,T002,T004`です。

| ordinal | この段階で消費するレコード | A現在 | T現在 | S現在 | P現在 | グループ内集計または判定 |
|---:|---|---|---|---|---|---|
| 0 | 初期READ | 01:A02 | 01:T003 | 01:S01 | 01:P01 | 最小グループキー01 |
| 1 | A02消費後のREAD | 02:A01 | 01:T003 | 01:S01 | 01:P01 | 顧客01：口座2 opening 2000 |
| 2 | T003消費後のREAD | 02:A01 | 02:T001 | 01:S01 | 01:P01 | 顧客01：T003借方100 |
| 3 | S01消費後のREAD | 02:A01 | 02:T001 | 02:S02 | 01:P01 | 顧客01 snapshotを1度消費 |
| 4 | P01消費後のREAD、01判定 | 02:A01 | 02:T001 | 02:S02 | 02:P02 | 2000−100=1900、顧客01完了 |
| 5 | A01消費後のREAD | 02:A03 | 02:T001 | 02:S02 | 02:P02 | 顧客02：口座1 opening 1000 |
| 6 | A03消費後のREAD | EOF | 02:T001 | 02:S02 | 02:P02 | 顧客02：口座3 opening 3000、口座stream EOF |
| 7 | T001消費後のREAD | EOF | 02:T002 | 02:S02 | 02:P02 | 顧客02：貸方50 |
| 8 | T002消費後のREAD | EOF | 02:T004 | 02:S02 | 02:P02 | 顧客02：借方20 |
| 9 | T004消費後のREAD | EOF | EOF | 02:S02 | 02:P02 | 顧客02：貸方70、取引stream EOF |
| 10 | S02消費後のREAD | EOF | EOF | EOF | 02:P02 | 顧客02 snapshotを1度消費 |
| 11 | P02消費後のREAD、02判定 | EOF | EOF | EOF | EOF | 4000+貸方120−借方20=4100、顧客02完了 |

ACCOUNTとTXの2つのループは現在顧客に属する全レコードを個別に消費します。A03とT001/T002/T004を1件ずつ対にするわけではありません。顧客02は最終的に口座2件、取引3件です。各取引はまずACCOUNTへ帰属し、その`account.customer_id`を通じて1度だけ顧客集計へ加算されます。金額を重複計上せず、直積も作りません。
3. 独立work copyを作ってstarterを実行し、TODOによりRC12となり公開しないことを確認します。まず4 cursor比較とEOF状態だけを実装しREADごとに手traceし、次に顧客spoolとグループ末再生を追加し、最後に金額式、顧客差異隔離、control保存を追加します。各段階でreferenceと照合し、学習者プログラムに期待結果を直書きしないでください。
4. 独立work copyで口座1のcustomer_idを02から01に変更し、取引は口座経由で帰属させたままにします。Snapshot/Previous行も更新して独立計算します。顧客01/02金額が各口座経由で1度だけ集計され、顧客残高が複製されていないことを確認します。次に顧客01 Snapshotを除くと、顧客01のaccount/TX sourceは元バイトのまま隔離され、顧客02は公開可能でJOBはRC4となります。
5. Snapshot日を古くする、末尾LFを削除する、snapshot keyを複製する、のいずれかを試します。構造RC8、target directoryなしが期待値です。`python3 scripts/check.py`で永続ケースを確認し、`bash scripts/check.sh`で全業務/生バイト/starter/reset/fixture検査を行います。

## ビルド、実行、検査、リセット

```bash
lab=curriculum/modules/07-matching/labs/04-many-to-many
bash "$lab/scripts/build.sh" /tmp/batchl3
python3 "$lab/scripts/check.py"
bash "$lab/scripts/check.sh"
```

正式実行はlockと隔離stageを作成し、入力snapshotを取り、B01を実行してから本課COBOLを実行します。外部`sort`は候補出力を下流指定のaccount/sequence/idバイト順に並べ直すだけです。独立したディスク上SQLite oracleが各streamを検証してから公開します。通常の学習コマンド：

```bash
lab=$(cd curriculum/modules/07-matching/labs/04-many-to-many && pwd)
work=$(mktemp -d)
cp "$lab/fixtures/normal/"*.dat "$work/"
cd "$work"
bash "$lab/scripts/run.sh" account.dat transaction.dat \
  reversal-link.dat customer-snapshot.dat previous-day.dat \
  output-20261009 20261009
cd - >/dev/null
(cd "$work/output-20261009" && sha256sum -c inputs.sha256 \
  && sha256sum -c manifest.sha256)
```

差異なしの通常batchはRC0。L2または顧客業務隔離はRC4でdirectoryを公開します。構造エラーRC8、システムエラーRC12は公開しません。正式出力はすべて新規directoryで、既存targetは拒否されます。学習者sourceは`COURSE_SOURCE=/絶対パス/BATCHL3.COB`で指定できます。このoverrideはB03のみで、L2は検証済み参考実装を使用します。

starterは独立sourceで実行します。

```bash
lab=$(cd curriculum/modules/07-matching/labs/04-many-to-many && pwd)
student=$(mktemp -d)
cp "$lab/fixtures/normal/"*.dat "$student/"
cp "$lab/starter/BATCHL3.COB" "$student/BATCHL3.COB"
if COURSE_SOURCE="$student/BATCHL3.COB" bash "$lab/scripts/run.sh" \
  "$student/account.dat" "$student/transaction.dat" \
  "$student/reversal-link.dat" "$student/customer-snapshot.dat" \
  "$student/previous-day.dat" "$student/result" 20261009; then
  starter_rc=0
else
  starter_rc=$?
fi
[[ $starter_rc == 12 && ! -e $student/result ]]
```

12を返し`result`を作成しない想定です。TODO完成後に再検査します。`scripts/init-workspace.sh DIR`は空directoryにだけworkspace markerを書きます。`scripts/reset.sh DIR`はmarker付きで実行lockのないworkspaceのみresetします。lockがあればRC12で全ファイルを保持します。

## 演習の検査

各演習についてコマンド、生RC、出力manifest、core stdout/stderr、fixture hashを残します。

| 演習 | 期待値 | 検証点 |
|---|---|---|
| Snapshot残高上限ちょうど4100 | RC0 | 上限と一致は許可 |
| 上限を4099へ | RC4 | 顧客02だけ隔離 |
| 顧客01 Snapshot欠落 | RC4 | 顧客02 eligible、顧客01 sourceを元バイトで隔離 |
| Previous closingを4001へ変更 | RC4 | opening不一致、分割金額は保存 |
| Snapshot日付を古くする | RC8 | 全batch非公開 |
| customer_idを重複/降順に | RC8 | 既存出力を上書きせず候補も公開しない |

## 故障調査順

最初にrunnerの生RCを確認し、次に候補stageを見ます。RC4なら`customer-status.txt`、`isolation.txt`、control分割を調べます。RC8なら生LF/幅、日付、版、customer key順序を確認します。RC12ならstderrのbuild、sort、一時ディレクトリ、lock、独立検証、公開失敗を確認します。`run.sh`は失敗時にprivate stageとlockを自動削除し、正式出力directoryは残らない想定です。成功公開後は`sha256sum -c inputs.sha256`で入力snapshotの整合性、`sha256sum -c manifest.sha256`で出力ファイルを確認します。hashは完全性の確認用で、業務正当性は独立oracleとcontrol式で検査します。

エディタプラグインのターミナル代替：`rg -n '1500-RUN-FOUR-WAY|1580-DECIDE-GROUP|1590-REPLAY-SPOOL' instructor/modules/07/04-many-to-many/BATCHL3.COB`、`od -An -tc`で実際の行末とバイトを確認します。プラグイン移動先は本課に実在する段落とCopybookだけです。
