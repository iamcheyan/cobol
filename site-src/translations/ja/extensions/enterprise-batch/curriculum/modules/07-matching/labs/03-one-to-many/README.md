# 07.4 / Boss L2：有界状態による1:N口座計上

推奨4時間。前提：07.3 L1、ファイル状態、10進金額。業務課題：1口座に1日0件以上の整列済み取引がある場合、1件ずつ残高を更新し、拒否理由を説明し、原取引を参照する取消を実装します。修了時にはKey Breakの確定処理、取引IDを全体で重複排除する必要性、55バイトv1レコードでは取消の原取引を表現できない理由を説明します。

## 実行

Linux x86-64、GnuCOBOL 3.2（BDB索引ファイル対応）、Bash、GNU coreutils、Python 3（受入ドライバーのみ）、`sort`が必要です。macOS/WSLは未検証です。すべてのファイルは新しい出力ディレクトリで実行し、入力や既存出力を上書きしません。講師参考は`instructor/`にあり、starterはビルド可能ですが12を返します。

```bash
lab=curriculum/modules/07-matching/labs/03-one-to-many
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/account.dat" \
  "$lab/fixtures/normal/transaction.dat" \
  "$lab/fixtures/normal/reversal-link.dat" /tmp/bank-l2-run 20261009
rc=$?
set -e
test "$rc" -eq 4   # このケースには業務拒否があり、RC4でも照合済み結果を公開
diff -u "$lab/expected/normal.txt" /tmp/bank-l2-run/report.txt
python3 "$lab/scripts/check.py"
python3 "$lab/scripts/check-indexed.py"
```

金額出力は固定幅の符号付き整数です。RC4は取引単位の業務拒否で、照合済み出力を公開します。RC8はインターフェース/順序/全体一意性違反、RC12はシステム障害で、どちらも出力ディレクトリを作りません。別口座の原取引を参照する取消対象は業務拒否RC4となり理由も公開します。関連ファイルの口座/sequenceが参照先と一致しない場合は構造エラーRC8で、バッチ全体を公開しません。

公開ディレクトリには`report.txt`、完全な47バイト期末`master.dat`、受理した元取引`accepted.dat`、理由付き拒否元取引`rejected.dat`、入出力SHA256 manifest、ソース版概要があります。stdoutを見るだけでは正式な公開ディレクトリの代わりになりません。

この環境のGnuCOBOL BDBでは、LINE SEQUENTIALのbuffer出力を`/dev/full`へ書いた場合、WRITE/CLOSE statusが00のままプログラムが業務RC4を返すことがあります。そのため参考coreはJOB入口の`run.sh`経由でのみ実行してください。runnerがreport、元入力行、3種類の出力、口座別/全体金額controlをストリーム検査します。行欠落、切詰め、CRLF、保存則不一致はRC12に対応し、公開しません。コンパイル済coreの直接実行には公開保証がありません。

## 学習経路と実行可能な課題

各段階で先に予測し、その後コマンドで検証します。

1. **手動trace**：`DESIGN.md`の例を読み、normalの各取引後残高を手計算します。T03がT01を参照する箇所を印し、T02が検索に影響しない理由を説明します。`awk '{print NR, length($0)}'`で行幅、`od -An -tc`でLFを確認します。
2. **EOFとKey Break**：`1000-MAIN`の2ポインター`EVALUATE`と`4000-CLOSE-ACCOUNT`を探します。取引が先に終了、口座に取引なし、最後の口座終了時のpointer状態を図示します。その口座の取引グループを消費した後にのみclosingを出せる理由を説明し、`boundary-no-transactions`と`boundary-empty-all`のexpectedと照合します。
3. **台帳状態**：`1700-INDEX-TRANSACTIONS`での事前ロードと、`6000-POST-TX`のランダム`READ`/`REWRITE`を確認します。`check-indexed.py`を実行し、書込/読込、重複キー22、欠落キー23、open失敗を観察します。台帳に原取引の受理/取消状態を保存し、口座グループ残高を保存しない理由を説明します。
4. **保存則**：normalの各口座について`opening + credits - debits = closing`と全体controlを独立計算します。`boundary-aggregate-over-13`では口座単位金額が有効でも全体累計が13桁を超えることを確認します。期待値はフィクスチャから独立計算し、プログラム出力を写しません。
5. **故障調査**：まずフィクスチャを一時ディレクトリへコピーします。金額0へ変更するとRC4と拒否理由出力が期待されます。REVERSAL-LINK口座を改変するとRC8で公開なしです。`run.txt`、`inputs.sha256`、`source.sha256`を比較し、JOB snapshotとソース証跡を確認します。

ビルド可能なstarterを同じrunnerに接続するには`COURSE_SOURCE`を使います。starterはRC12を返し、出力を公開しない想定です。

```bash
starter=$(realpath "$lab/starter/BATCHL2.COB")
set +e
COURSE_SOURCE="$starter" bash "$lab/scripts/run.sh" \
  "$lab/fixtures/normal/account.dat" "$lab/fixtures/normal/transaction.dat" \
  "$lab/fixtures/normal/reversal-link.dat" /tmp/bank-l2-starter 20261009
rc=$?
set -e
test "$rc" -eq 12 && test ! -e /tmp/bank-l2-starter
```

## ビルド、検査、リセット

```bash
bash "$lab/scripts/build.sh" /tmp/batchl2  # 演習用をコンパイル。正式実行はrun.shで公開
bash "$lab/scripts/check.sh"
bash "$lab/scripts/reset.sh" /tmp/bank-l2-run
```

`reset.sh`は本課の`run.txt`、`inputs.sha256`、`outputs.sha256`、`report.txt`標識がある非symlinkディレクトリのみ受け付け、リポジトリ内パスと未標識ディレクトリを拒否します。手動演習ではフィクスチャをコピーし、`fixtures/`原本を変更しません。テストの中間ファイルは自動削除されます。

## 業務インターフェースと演習

ACCOUNTは47バイト、TRANSACTIONは55バイトを維持します。方針と手計算は[DESIGN](DESIGN.md)を参照します。取消には口座、sequence、取消ID、原取引IDを持つ48バイトREVERSAL-LINK v1を独立して使い、公開取引v1を変更しません。ソース読解ではまず2本の順次pointerと口座Key Breakを追い、次に一時INDEXED台帳のREAD KEY/REWRITEを調べます。台帳は取引IDをまたぐ参照に使い、残高中核は1取引ずつ順次処理します。

プラグインでは`:CobolGotoDef`で読込段落を確認し、参考ソースの`COPY "ACCOUNT-V1.CPY"`または`COPY "TRANSACTION-V1.CPY"`行で`:CobolGotoCopybook`を実行してcanonical interfaceを確認できます。ターミナル代替は`rg -n 'KEY BREAK|READ|REWRITE|OVERDRAFT|PERFORM'`と`od -An -tc`です。演習：金額0拒否assertionを追加します。次に、取消参照を既存の別口座原取引IDに変更し、RC4で`CROSS-ACCOUNT`を公開することを確認します。別に関連行の口座を変更しRC8、公開なしを確認します。拒否取引が期末残高と保存式を維持する理由を説明します。

提出物はソース、normalの取引別残高表、少なくとも1件の失敗RC/公開なし証跡、入力SHA256、件数/金額保存の証拠です。講師用根因、ヒント、参考ソースは`instructor/modules/07/03-one-to-many/`にあります。
