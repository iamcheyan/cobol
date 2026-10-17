# モジュール09：モジュール化プログラム（CALL / LINKAGE / 共通モジュール）

目安は4時間です。前提：モジュール06のファイル処理、モジュール07の金額と整合性。実行環境：Linux x86-64、GnuCOBOL 3.2.0、Bash、GNU coreutils、Python 3（受け入れテスト用ドライバーのみ）。macOS/WSLでは未検証です。

学習範囲は09.1–09.3：`CALL`/`LINKAGE`/`USING`、`BY REFERENCE`/`BY CONTENT`/`BY VALUE`、`RETURNING`、`GOBACK`、WORKING-STORAGEのライフサイクル、共通Copybook、引数長/バージョンとインターフェースの不一致です。金額計算（AMTCALC）、顧客検証（CUSTVAL）、ログ（LOGGER）の共通モジュールを切り出し、呼び出し側と被呼び出し側の両方が障害調査にどう影響するかを実演します。インターフェース配置、フィールドオフセット、RC伝播、手計算例は [DESIGN.md](DESIGN.md) を参照してください。

## 1. この処理が業務で必要な理由

夜間バッチでは「この金額を記帳できるか」「この顧客は有効か」「統一形式のログをどう書くか」を複数のJOBで繰り返し扱います。JOBごとに独自実装すると、ルール変更のたびに差異が生じ、障害調査でどの複製が正しいのか判断できなくなります。要件は、これらの処理を**バージョン付きの呼び出し可能なサブプログラム**に切り出し、メインプログラムから `CALL` で再利用することです。引数の長さ/バージョンが一致しない場合や、呼び出されたモジュールに未初期化状態が残る場合に、障害を再現して原因を特定し、その状態を正確に返せるようにします。

## 2. 入力元、形式、保証済みの前提条件

`fixtures/normal/`、`fixtures/boundary/<case>/`、`fixtures/invalid/<case>/` にある固定幅ファイル3種：`customer.dat`（27B）、`account.dat`（47B）、`transaction.dat`（55B）。ASCII、LF終端です。フィールドと規則は `../../../docs/curriculum/BANK-SYSTEM.md` を参照してください。業務日は引数で指定します（フィクスチャでは `20261010`）。前提条件：上流JOBがレコード長とLFを保証し、口座は昇順、取引は口座/連番/取引ID順であり、`transaction_id` は全体で一意です（重複時はRC8、DESIGN §6参照）。本モジュールではモジュール07の突合/取消処理を再実装せず、CALLと共通モジュールに集中します。

## 3. クリーンなcheckoutからのビルド、実行、リセット

```bash
lab=curriculum/modules/09-modular
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/customer.dat" \
  "$lab/fixtures/normal/account.dat" "$lab/fixtures/normal/transaction.dat" \
  /tmp/bank09-run 20261010
rc=$?
set -e
test "$rc" -eq 0            # normalケースは業務拒否なし
diff -u "$lab/expected/normal.txt" /tmp/bank09-run/report.txt
python3 "$lab/scripts/check.py"    # 正常/境界/エラーおよび障害経路をすべて検査
```

`run.sh` は任意の作業ディレクトリから実行でき、空白を含む新規出力パスに対応し、既存出力を即時拒否し、並行実行をロックします。失敗（RC8/12）の場合はディレクトリを公開しません。公開ディレクトリには `report.txt`、`ledger.dat`、`customers-valid.dat`、`customers-rejected.dat`、`batch09.log`、`inputs.sha256`、`outputs.sha256`、`run.txt`、`compiler.txt`、`source.sha256` が含まれます。リセット：

```bash
bash "$lab/scripts/build.sh" /tmp/batch09         # 演習をコンパイルするだけ
bash "$lab/scripts/reset.sh" /tmp/bank09-run      # マーカー付きのコース出力ディレクトリだけを削除
```

`reset.sh` はシンボリックリンク、マーカーのないディレクトリ、リポジトリ内のパスを拒否します。手作業の演習では先にフィクスチャをコピーし、元ファイルを編集しないでください。

## 4. 期待出力、RC、件数と金額、独立検算

`expected/normal.txt` は業務規則から独立して導出したものです（手計算例はDESIGN §8）。プログラム出力を転記したものではありません。normalケース：顧客2/2件を受理、取引3件=受理3+拒否0、口座2件=取引あり2+取引なし0、期首1500、貸方600、借方200、期末1900。口座ごとに `closing = opening + credit − debit` が成立します。各ケースのRCは `expected/cases.json` にあります（RC0は正常、RC4は明細ごとの業務拒否があり公開、RC8は契約エラーで非公開）。各フィクスチャの独立計算根拠は `expected/README.md` を参照してください。

`scripts/oracle.py` はCOBOLから独立した**Python参照モデル**で、`expected/` を生成します。公開前に `run.sh` は `scripts/verify-publish.py` を呼び、**生入力**から同じモデルでレポート、台帳、顧客出力2種、ログを再計算し、バイト単位で照合します。差異があればRC12となり、何も公開されません。また記帳前に外部ソートを使って `transaction_id` の**全体一意性**を検査します。重複があればRC8で非公開となり、`COURSE_SOURCE` の差し替えでもこの検査は回避できません（`fixtures/invalid/dup-global-txid`、`dup-cross-account`）。

## 5. 変更する箇所と維持すべきインターフェース

- `starter/BATCH09.COB` のTODOを埋め、顧客検証、口座キー境界での記帳、ログ出力を実装します。
- 共通モジュール3種（AMTCALC / CUSTVAL / LOGGER）は**既存依存であり、学習者向けパッケージに含まれます**。配置は `lib/{AMTCALC,CUSTVAL,LOGGER}.COB`、インターフェースCopybookは `copybooks/*-V1.CPY` です。リポジトリでは `instructor/modules/09-modular/` を参照実装とし、`build.sh`/`run.sh` が自動的にどちらかを選びます。
- **凍結契約**：CUSTOMER 27B / ACCOUNT 47B / TRANSACTION 55B とインターフェースヘッダー `VERSION='001'` を安易に変更してはいけません。進化させる場合は `-V2` を追加し、旧バージョンも解釈可能な状態に保ちます。
- 維持するもの：`RETURN-CODE`（0/4/8/12）の意味、公開前の整合性と独立検証、失敗時に公開しないこと。

## 6. 意図的な破壊、調査、復旧

順番に実施し、実行前に各結果を予測してください。

1. **インターフェースのバージョン不一致**：メインプログラムでAMTCALCに渡す `MOVE '001' TO AMT-IFACE-VERSION` を `002` に変更します。被呼び出し側は8を返し、メインプログラムは `INTERFACE-MISMATCH`、プロセスはRC8となり、公開物はありません。原因は**呼び出し側**にあります。被呼び出し側の動作は正しく、呼び出し側が古い/新しいバージョンヘッダーを送っています。`001` に戻して復旧します。
2. **引数長の不一致**：`MOVE LENGTH OF AMT-CALC-INTERFACE TO AMT-IFACE-LENGTH` を `MOVE 1` に変更します。AMTCALCは8 `IFACE-LENGTH` を返し、公開物はありません。
3. **状態の漏れ**：`ifaceprobe` を実行すると、`STATIC CALL1=0001 CALL2=0002`（2回目に前回状態が残る）と `INITIAL CALL1=0001 CALL2=0001` が確認できます。原因はサブプログラムの静的WORKING-STORAGEが呼び出し間で保持されることです。最小修正は `IS INITIAL` または毎回の明示的な初期化です。
4. **業務/契約境界**：`fixtures/` には、金額ゼロ、貸越、13桁オーバーフロー、不明な方向、口座なし、凍結口座（RC4で公開）と、短いレコード、レイアウトバージョン `002`、誤った業務日、逆順の取引、**全体重複取引ID**（RC8で非公開）のケースがあります。
5. **取引IDの全体重複**：normalの3件目について、口座と連番を保ったまま第11–26バイトを1件目の `transaction_id` に置き換えます。ファイルは `account/sequence/id` 順のままなので、従来の順序突合ではRC0で誤って公開し、二重記帳してしまいます。修正後のJOBは外部ソートによる全体検査でRC8となり、公開しません。`dup-global-txid`（同一口座、異なる連番）と `dup-cross-account`（口座間）のフィクスチャが両方をカバーします。

`check.py` の `check_starter_and_faults` は1、2の障害を参照ソースへ自動注入し、RC8かつ非公開を確認します。`check_probe` は3の決定的な出力を確認します。

## 7. プラグイン操作と端末での代替方法

端末操作も同等の代替手段です。プラグインがなくてもコースを進められます。

- `:CobolGotoDef` で呼び出しインターフェースを確認します。メインプログラムの `CALL 'AMTCALC' USING AMT-CALC-INTERFACE` にカーソルを置いて `lib/AMTCALC.COB` へ移動し、`USING` 項目を確認します。`COPY "AMTCALC-INTERFACE-V1.CPY"` 行で `:CobolGotoCopybook` を使い、インターフェースCopybookを開いて長さ/バージョンヘッダーを確認します。端末では `rg -n 'CALL .|USING|LINKAGE|RETURNING|GOBACK' lib/` を使います。
- Aerial/アウトラインでメインプログラムの段落階層 `1000-MAIN/2000-.../3000-.../6000-...` を確認し、呼び出し境界を把握します。端末では `rg -n '^       1|^       2|^       3|^       6|^       8' starter/BATCH09.COB`（完成後）または `instructor/modules/09-modular/BATCH09.COB` を使います。
- P1のPIC計算器でインターフェースフィールドのバイト数を確認します（`AMT-BALANCE` は `S9(13) COMP-3`=7B）。端末では `AMT-CALC-INTERFACE` の `LENGTH OF` を実測します（=45）。フィールドオフセットはDESIGN §3にあります。

プラグインの推定値をバイト配置の最終根拠にしないでください。`cobc` で実測した `LENGTH OF` と `check.py` を根拠にします。

## 8. 完了時の証拠と失敗条件

[evidence/README.md](evidence/README.md) に従って提出します：ソース変更、normalレポートと `ledger.dat`、RC4（公開）を少なくとも1件、RC8/RC12（非公開）を少なくとも1件、それぞれの実RCと「出力ディレクトリがない」証拠、`ifaceprobe` のバイト/RC出力、入出力SHA256、独立検算した件数と金額整合性、インターフェースの変更前後バージョンの説明。以下はいずれも失敗です：失敗後に公開する、8/12を業務拒否として扱う、契約の代わりにインターフェース長/バージョンをハードコードする、被呼び出し側が呼び出し側の私有領域を書き換える、状態漏れを再現または修正できない、**取引IDの全体重複を見逃して二重記帳する**。

## レッスン演習と再現可能な障害（09.1–09.3）

- **09.1 CALL/LINKAGE/USING、BY REFERENCE/CONTENT/VALUE、RETURNING、GOBACK**
  - 演習：`ifaceprobe.COB` の `BYREF-SUB` 呼び出しを `BY CONTENT` に変え、`AFTER=` が書き戻されなくなることを確認します（`BY REFERENCE` と比較）。次に `CALL ... USING ... RETURNING` から `RETURNING` を外し、メインプログラムが戻りコードを読めなくなることを確認します。
  - 再現可能な障害：メインプログラムの `CALL 'BYCTR-SUB' USING BY CONTENT WS-A` を `USING WS-A`（デフォルトの `BY REFERENCE`）に変えます。すると被呼び出し側が呼び出し側の `WS-A` を書き換えられ、`BY-CONTENT AFTER` は `BBBBB` から `CCCCC` に変わります。呼び出し箇所の引数渡し方式が結果を直接左右することを示します。
- **09.2 WORKING-STORAGEのライフサイクル、共通Copybook、引数長/バージョン/インターフェース不一致**
  - 演習：`INIT-ACC` から `IS INITIAL` を外すと `INITIAL CALL2` が `0001` から `0002` に変わります。再度追加すると元に戻ります。
  - 再現可能な障害：`check_starter_and_faults` はインターフェースバージョンを `002` に、または `LENGTH OF` を `1` に自動変更します。被呼び出し側とメインプログラムはRC8を返し、何も公開されません。手動で `sed` を使って変更し、`run.sh` を再実行しても再現できます。
- **09.3 金額計算/顧客検証/ログの切り出し、呼び出し側と被呼び出し側が共同で調査に影響するケース**
  - 演習：`AMTCALC` 内の `OVERDRAFT` 判定を一時的にメインプログラムへ移し、`fixtures/invalid/overdraft` のレポート/RCがどう変わるか確認してから戻します。責任境界の変更でRCと原因の帰属が変化することを確認します。
  - 再現可能な障害：バージョン不一致時、被呼び出し側は正しく動作していても、古い/新しいバージョンヘッダーを送った呼び出し側に原因があります。調査では `AMTCALC.COB` のインターフェース検証と、`BATCH09.COB` の `MOVE ... TO AMT-IFACE-VERSION` の両方を確認します。つまり、呼び出し側と被呼び出し側の両方が調査に関わります。

```bash
lab=curriculum/modules/09-modular
bash "$lab/scripts/check.sh"                 # 障害注入とプローブを含む全受け入れ検査
COURSE_SOURCE="$lab/starter/BATCH09.COB" bash "$lab/scripts/run.sh" \
  "$lab/fixtures/normal/customer.dat" "$lab/fixtures/normal/account.dat" \
  "$lab/fixtures/normal/transaction.dat" /tmp/bank09-starter 20261010   # RC12が期待値。ディレクトリなし
cobc -Wall -I "$lab/copybooks" -x -o /tmp/ifaceprobe \
  "$lab/scripts/ifaceprobe.COB" "$lab/lib/AMTCALC.COB" && /tmp/ifaceprobe
```

講師向け参照実装、根本原因一覧、採点基準は `instructor/modules/09-modular/` にあります。
