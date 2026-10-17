# 02 データ定義と顧客 Record（4時間）

推奨学習時間は4時間。前提：モジュール01（環境、コンパイル、固定形式の列規則）。Linux x86-64 のみ実機で検証済みです。macOS/WSL/ARM は未検証です。

## 1. 業務背景：顧客マスターデータを独立してモデル化する理由

銀行の夜間処理では口座と取引を処理しますが、その前に信頼できる**顧客マスターデータ**が必要です。誰がシステムに登録され、名前は何か、現在有効か停止中かを管理します。口座と取引はいずれも顧客 ID を参照します。学習者の課題：CUSTOMER v1 の**フィールドカタログと契約**を作り、顧客ファイルを検証し、業務ルールに従って不正レコードを拒否し、合計額を照合する最小のローダープログラムを作成します。また小さな実験で、`PIC` の論理桁数と実際の格納バイト数、暗黙の小数、`MOVE` のカテゴリ変換、切り捨てと空白埋めを説明します。これは後続の口座モデル（ACCOUNT v1）と JOB の上流基盤になります。

## 2. 入力元、形式、前提条件

入力は `CUSTOMER v1`（**凍結済み契約、1レコード27バイト**）です。出典は[銀行システム設計](../../../docs/curriculum/BANK-SYSTEM.md) 第2節と一致し、本モジュールには実物の Copybook [copybooks/CUSTOMER-V1.CPY](copybooks/CUSTOMER-V1.CPY) があります。ファイルは ASCII、LF 終端です。`LF` はレコード長に含めません。文字数をバイト数と誤認しないよう、名前は ASCII に限定します。前提として上流は当日の顧客スナップショットだけを配置しますが、長さ、文字種、ソート順、必須項目はこの JOB が独自に検証する必要があります。

> 「区分」を混同しないでください。CUSTOMER v1 の27バイト目は `customer_status`（`A`/`D`）だけで、**状態であり、顧客区分ではありません**。v1 レイアウトには顧客区分フィールドが**ありません**。BANK-SYSTEM にある「顧客区分」は顧客 DB の属性です。モジュール11の「1桁から2桁への拡張」保守でこの27バイト目を書き換えてはいけません。まず独立してバージョン管理する企業顧客レイアウトを定義してください（モジュール07 L4 の `ENTERPRISE-CUSTOMER-V1` を再利用または整合させます。[curriculum/bank/README.md](../../bank/README.md) 参照）。27バイトの教材用インターフェースを維持し、両者の関係を説明したうえで v2 移行を行います。`balance_demo` は本モジュールの実験用金額（単位はセント、符号なし）であり、最終的な台帳ではありません。口座モデルでは残高を ACCOUNT v1（47バイト）に移します。移行理由と手順は [DESIGN](DESIGN.md) を参照してください。

## 3. クリーンな checkout からのビルド、実行、リセット

必要環境：Linux x86-64、GnuCOBOL 3.2、Bash、coreutils、Python 3（検収ドライバーのみ）。参照実装は `instructor/modules/02-data/` にあります。`starter/` はコンパイルできますが未実装で、RC12 を返します。すべての出力は**新しい**出力ディレクトリに書き込みます。

```bash
lab=curriculum/modules/02-data
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/customer.dat" /tmp/bank-m02-run
rc=$?
set -e
test "$rc" -eq 0
diff -u "$lab/expected/normal.control.txt" /tmp/bank-m02-run/control.txt
bash "$lab/scripts/check.sh"     # MOVE/型/レイアウト実験を含む、契約のエンドツーエンド検収
```

```bash
bash "$lab/scripts/build.sh" /tmp/custload     # 練習コードだけをコンパイル
bash "$lab/scripts/reset.sh" /tmp/bank-m02-run # リセット（マーカー付き出力ディレクトリのみ許可）
```

実行で上書きされる**派生ファイル**：新しい出力ディレクトリ内の `control.txt`、`accepted.dat`、`rejected.dat`、`inputs.sha256`、`outputs.sha256`、`run.txt`、`compiler.txt`、`source.sha256`。ソースfixtureと `expected/` は変更されません。

## 4. 期待される出力、RC、件数、金額、独立検算

`control.txt`（件数は12桁固定幅、残高合計は18桁固定幅）：

```text
JOB|CUSTLOAD|V1
CONTROL|READ=000000000003|ACCEPTED=000000000003|REJECTED=000000000000|BALANCE-TOTAL=000000000010012394
```

| fixture | RC | READ | ACCEPTED | REJECTED | 残高合計 | 意味 |
|---:|---:|---:|---:|---:|---:|---|
| normal | 0 | 3 | 3 | 0 | 10012394 | すべて有効 |
| empty | 0 | 0 | 0 | 0 | 0 | 契約上、空ファイルを許可 |
| single | 0 | 1 | 1 | 0 | 500 | 最終レコード |
| max-balance | 0 | 1 | 1 | 0 | 99999999 | 8桁の上限 |
| name-full | 0 | 1 | 1 | 0 | 1000 | 名前がちょうど10文字 |
| name-missing | 4 | 1 | 0 | 1 | 0 | 名前がすべて空白 |
| bad-amount | 4 | 1 | 0 | 1 | 0 | 残高に数字以外を含む |
| unknown-status | 4 | 1 | 0 | 1 | 0 | 状態が A/D 以外 |
| 構造fixture 7件 | 8 | — | — | — | — | 長さ/LF/CR/ID/ソート。公開しない |

独立検算は [expected/README.md](expected/README.md) を参照してください。`check.py` は制御レポートをバイト単位で比較し、元のfixtureから `accepted.dat`/`rejected.dat` を独立導出します。ランナー内の `verify-publish.py` も別途独立再計算します。

## 5. どこを変更するか、壊してはいけないインターフェース

入口は `starter/CUSTLOAD.COB`（TODO はファイル内コメント参照）です。参照実装は `instructor/modules/02-data/CUSTLOAD.COB` にあります。**壊してはいけない**もの：CUSTOMER v1 の27バイトレイアウトとフィールドオフセット、`control.txt` の行形式と12/18桁固定幅、ランナー契約 `run.sh INPUT NEW_OUTPUT` と RC 規約。

## 6. 意図的に条件を壊す方法、調査、復旧

- **02.1 ビット/バイトの誤解**：`customer_id` を数値 `PIC 9(8)` として扱って `COMPUTE` を試す、または10文字の名前を10バイト以外として扱います。`LENGTH OF` を出力して実際のバイト数を確認します。`CUSTOMER-V1.CPY` をコピーして `PIC` を1か所変更し、再コンパイルして長さの変化を確認しても構いません。
- **02.2 MOVE の切り捨て/空白埋め/カテゴリ変換**：第7節の `experiments/move/MOVELAB.COB` を実行します。`MOVE 12345 TO WS-T1 (PIC 9(3))` の結果 `345` を予測と照合します。`12345.67` を `9(3)V99` に移すと `345.67` になります。上位桁の切り捨てと暗黙の小数を説明してください。
- **02.3 オフセットの誤り**：`experiments/layout/LENGTH-PROBE.COB` をコンパイルします。まず `copybooks/` で `CUSTOMER-RECORD=27` を確認し、次に `experiments/layout/` に切り替えると、名前が**意図的に誤記**された `X(11)` により `CUSTOMER-RECORD=28`、`NAME-LENGTH=11` となります。これは**誤ったレイアウトのデモで、契約ではありません**。`PIC` を1つ変更すると後続フィールドのオフセットがすべて移動することを示します。実際のレイアウト変更では影響を調査してバージョン管理し、旧インターフェースを維持する必要があります。復旧するには `X(10)` に戻します。

調査の原則：元のfixtureと元のRCを保持し、まず `FILE-STATUS`/長さ診断を確認してからフィールドオフセットを特定します。アサーションを緩めて「修復」してはいけません。

## 7. プラグインの使い方とターミナルでの代替

- **プラグイン**：`:CobolGotoCopybook` で `COPY "CUSTOMER-V1.CPY"` の正規インターフェースを開きます。Aerial/アウトラインで01/05レベルの階層を確認し、PIC バイト表示で `PIC X(10)`=10B、`PIC 9(8)`=8B を照合します。
- **ターミナルでの代替**：`awk '{print length($0)}'` でレコード幅を確認し、`od -An -tc` で LF を確認します。`cobc` で `MOVELAB.COB` をコンパイルし、MOVE 実験表を出力します。`rg -n 'PIC|COPY|VALUE|88|77' ファイル` でデータ宣言を確認します。プラグインの推定値をバイトレイアウトの最終判断に使ってはいけません。

## 8. 提出する証拠と失敗条件

[evidence/README.md](evidence/README.md) のテンプレートに従い、フィールドカタログ、normal/境界/異常の実行コマンドと元のRC、control レポート、MOVE 実験表と型実験（`TYPESLAB`）の結果および規則の説明、RC8で公開されない証拠、入力 SHA256 を提出します。**失敗条件**：`check.py` がアサーションと一致しない、RC8のfixtureで出力ディレクトリが作られる、ソースfixtureの SHA256 が変わる、プログラムの現在出力を expected として使う、CUSTOMER v1 の27バイトを別の長さに変更する。

## レッスン課題とプラグイン/ターミナルの対応

### レッスン 02.1 PIC X/A/9、01/05/77/78/88、VALUE、集団項目と基本項目

- [copybooks/CUSTOMER-V1.CPY](copybooks/CUSTOMER-V1.CPY) と `experiments/layout/LENGTH-PROBE.COB` で、`01` 集団項目と `05` 基本項目を見つけます。
- **実行可能な実験**：`experiments/types/TYPESLAB.COB` は `fixtures/types/typeinput.dat` を読み込み、`78 WS-LIMIT` 定数、`77 WS-COUNT` 独立項目、`88 CLS-ALPHA/CLS-MIXED` 条件名、`01/05` 集団を使って `PIC X(5)` と `PIC A(5)` を並べて比較します。`check.py` が `expected/typeslab.txt` とバイト単位で照合します。重要な結論：数字を含む X データを `PIC A` に `MOVE` しても自動拒否されません（レコード2は `M`）。自分で `IS ALPHABETIC` を使って検証する必要があります。一方、数値項目を `PIC A` に `MOVE` するとコンパイルできません（再現可能な障害）。
- **変更演習**：`starter/CUSTLOAD.COB` に `77 WS-FLAG PIC X VALUE 'N'.` と `88 FLAG-IS-N VALUE 'N'.` を追加し、`SET FLAG-IS-N TO TRUE` を実行します。`VALUE` は初期値にすぎないことを説明してください。
- **再現可能な障害**：`customer_id` を誤って `PIC 9(8)` として扱うと、数値比較で先頭ゼロが失われます。`LENGTH OF` と16進表示で、実際の格納は8バイト ASCII であることを示します。
- **プラグイン/ターミナル**：プラグインで階層と PIC 表示を確認し、ターミナルでは `rg -n 'PIC|VALUE|88|77'` を使います。

### レッスン 02.2 S/V、金額範囲、暗黙の小数、MOVE のカテゴリ変換、切り捨てと空白埋め

- `experiments/move/MOVELAB.COB` を実行します（check.py が `expected/movelab.txt` とバイト単位で照合）。A〜I の9例は、暗黙小数 `9(3)V99` の表示、整数 `9(5)` への `MOVE` による小数破棄、数値から英数字への変換、英数字の空白埋め、符号を先頭に分離した表示、英数字の切り捨て、整数上位桁の切り捨て、`9(3)V99` の暗黙小数を示します。
- **変更演習**：`PIC S9(5)V99` に `-1234.56` を格納する例を追加し、出力を予測します。
- **再現可能な障害**：`MOVE 12345 TO PIC 9(3)` → `345`（上位桁が切り捨てられ、丸めは行われません）。
- **プラグイン/ターミナル**：プラグインの PIC バイト表示を使い、ターミナルでは MOVELAB を実行して `od` で確認します。

### レッスン 02.3 顧客 Record v1：ID、名前、状態、フィールドカタログ

- フィールドカタログ（[DESIGN](DESIGN.md) 参照）を作り、`customer_id` の先頭ゼロ、`customer_name` の右側空白埋め、`balance_demo` の単位がセントであること、`customer_status` の `A`/`D` の意味を説明します。CUSTOMER v1 に顧客区分フィールドは**なく**、27バイト目は状態だけです。
- **変更演習**：`starter/CUSTLOAD.COB` の TODO を完成させ、件数整合を維持したまま normal を成功させます。
- **再現可能な障害（契約外のデモ）**：`experiments/layout/` の誤った Copybook は名前を意図的に `X(11)` とし、レコード長を28バイトにします。`LENGTH-PROBE` で再現し、1つのフィールドの PIC を変えると後続オフセットがどう動くか説明します。これは v1 契約ではなく、27→28移行でもありません。
- **プラグイン/ターミナル**：プラグインの `:CobolGotoCopybook`、ターミナルの `od -An -tc` と `LENGTH-PROBE` を使います。

参照実装、根本原因、段階的なヒント、採点説明は `instructor/modules/02-data/` を参照してください。
