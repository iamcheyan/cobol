# モジュール11：障害調査と保守（11.1–11.5）

目安9時間。前提：モジュール06（ファイル契約）、07（SORT／順次突合）、10（JOB運用）。本モジュールでは「実行できる」から「調査し、修正し、証明できる」へ進みます。**凍結された銀行夜間システムのスナップショット**（`system/`）を受け取り、**元の不正データを書き換えず、アサーションを緩めずに**、障害調査手順に沿って根本原因を特定し、最小限の修正と復旧再実行を行い、さらに**企業顧客区分**フィールドの保守変更を完了します（変更前に調査します。独立したバージョン管理対象の企業顧客レイアウトに適用し、27バイトCUSTOMER v1の第27バイトにあるレコード状態は変更しません）。

> プラットフォーム：**Linux x86-64**のみ実機検証済み（GnuCOBOL 3.2、Bash 5、GNU coreutils、Python 3.13）。macOS／WSL／その他のアーキテクチャは**未検証**です。
>
> **DB層について**：本モジュールは実PostgreSQLに**接続していません**。JOB004/JOB006は`system/lib/db.py`の**オフラインファイルチェックポイント**で、データベーストランザクションの意味と一意キー契約を模擬します。DB関連の証拠にはすべて「**DB未検証**」と明記してください。これを根拠に実DBのパイプラインが使えると主張してはいけません。

## 1. なぜ必要か／受け取る課題

銀行の夜間バッチで障害が起きたら、当番者は**まず現場を保存し、その後に原因を特定**しなければなりません。スケジューラ状態、JOB Log、RC、入力Manifestからタイムラインを作り、「未公開」と「誤った結果を公開済み」を区別し、根本原因を見つけ、最小限の修正を行い、復旧後のデータ整合性を証明します。本モジュールには、再現可能な7つの障害現場（11.1–11.4）と、フィールド拡張に関する保守調査（11.5）があります。

## 2. 入力、由来、形式、保証される前提

調査対象は`system/`（モジュール10の夜間フローに由来する凍結スナップショット。実際のCOBOL検証器／突合器とオフラインDBチェックポイントを含む）です。固定インターフェース（正規定義は`curriculum/bank/copybooks/`および`system/copybooks/`）：

- **CUSTOMER v1：27バイト** — id(8)/name(10)/balance_demo(8)/**status**(1、Aは有効／Dは停止)。
- **ACCOUNT v1：47バイト** — id(10)/customer(8)/currency(3)/sign(1)/balance(13)/status(1)/date(8)/version(3)。
- **TRANSACTION v1：55バイト** — account(10)/txid(16)/date(8)/sequence(6)/direction(1)/amount(13)/status(1)。

> **レコード状態 ≠ 顧客区分**：CUSTOMER v1の第27バイトは**レコード状態**（A/D）です。11.5の保守課題で拡張する「顧客区分」はこのバイトではなく、**独立してバージョン管理する企業顧客レイアウト**`maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY`にあります。この演習レイアウトは、モジュール07 L4の正規版大レコード`ENTERPRISE-CUSTOMER-V1`（1778バイト／175フィールド）と名称が重複してレイアウトが異なる状態（バージョンずれ）になるのを避けるため、**意図的に独立した名称**を使っています。両者は同じ`CUSTOMER-CLASSIFICATION`の意味を共有します。正規版の説明は`curriculum/bank/README.md`および`../../../docs/curriculum/BANK-SYSTEM.md` §2を参照してください。

保証事項：ASCII合成データ、LF改行、LFは論理レコード長に含めない、営業日にマシン日付を暗黙使用しない、各論理レコードの後ろにLFが1つ。短／長レコード、不正な数字、重複取引番号、順序逆転、0バイトファイル、リソース障害、制御合計の不一致はすべて**検出必須**の異常です。

## 3. クリーンなcheckoutからの構築、実行、リセット

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"

# 通常の夜間フロー（RC0、拒否なし）
bash curriculum/modules/11-incidents/scripts/run.sh \
  --input  curriculum/modules/11-incidents/fixtures/normal \
  --output /tmp/m11-night --db /tmp/m11-db \
  --business-date 20261009 --run-id demo
echo "rc=$?"     # 期待値 0

# 失敗現場を保持（障害調査用）
bash curriculum/modules/11-incidents/scripts/run.sh \
  --input  curriculum/modules/11-incidents/fixtures/INC-2026-004 \
  --output /tmp/m11-incident --db /tmp/m11-db2 \
  --business-date 20261009 --run-id demo --keep-scene
echo "rc=$?"     # 期待値 8

# 状態確認とリセット
bash curriculum/modules/11-incidents/scripts/run.sh \
  --input curriculum/modules/11-incidents/fixtures/normal \
  --output /tmp/m11-night --db /tmp/m11-db --business-date 20261009 \
  --command status
bash curriculum/modules/11-incidents/scripts/reset.sh /tmp/m11-night
```

派生ファイルが書き込まれるのは`--output`ディレクトリ内だけです。**入力fixture、`system/`ソース、共有`fixtures/`、既存の出力は上書きされません**。再利用ディレクトリやコース出力以外のディレクトリはRC12で拒否されます。

## 4. 期待出力、RC、件数、金額（独立検算）

`.authorツール`は`instructor/modules/11-incidents/tools/gen_course.py`にあります。これは凍結契約の業務ルールを**独立して再実装**して`expected/`を生成し、コースプログラムの出力は読みません。

`normal` fixture：口座3件（期首残高1000／50／0）、取引4件。

| 指標 | 値 | 出典 |
|---|---:|---|
| 受信 | 4 | fixtureの行数 |
| 検証の受理／拒否 | 4 / 0 | 業務ルール |
| 突合の受理／拒否 | 4 / 0 | `closing = opening + C − D` |
| 台帳計上 | 4 | 冪等キー |
| 期首／貸方／借方／期末合計 | 1050 / 625 / 200 / **1475** | 保存式 |
| 期末残高 | acc1 1300、acc2 150、acc3 25 | `closing = opening + C − D` |

完全な数値は`expected/normal.control.txt`と`expected/normal.closing.txt`、障害の期待動作は`expected/incidents.txt`、顧客の**状態**抽出は`expected/customer-v1.txt`、企業顧客の**区分**v1/v2抽出は`expected/enterprise-class-v1.txt`／`enterprise-class-v2.txt`にあります。

RC規約：`0`正常、`4`契約上許可されたWarning（個々の業務拒否）、`8`業務／契約異常、`12`システム異常。**どのステップが失敗しても公開しません**（`publish/<run_id>`は作成されません）。

## 5. どこを変更するか／壊してはいけないインターフェース

- 7件の障害は中立な事象ID（`INC-2026-001`…`INC-2026-007`）で命名され、各`INC-2026-00X/`にあります。まず`INC-2026-00X/student/README.md`に従って調査してください。根本原因、最小修正、「事象ID ↔ 講師番号」の対応は講師用パッケージ`instructor/modules/11-incidents/INSTRUCTOR.md`（講師用／必要に応じて提示）にあります。
- 保守変更は`maintenance/`で行います。まず**影響調査書**など5つの成果物を提出し、レビュー後に実装します（独立してバージョン管理された企業顧客レイアウトが対象。参考実装と証拠は`instructor/modules/11-incidents/maintenance/`、開始用の骨組みは`starter/M11CUST2.COB`）。
- **壊してはいけないもの**：3種類の凍結レコード幅とオフセット（CUSTOMER v1の第27バイトは常にレコード状態A/D）；`work/`、`publish/`ディレクトリ契約；`control.txt`のキー；RC 0/4/8/12の意味；冪等台帳キー`(business_date, transaction_id)`；下流行形式`STATUS|<id>|<status>`。

## 6. 再現可能な7種類の障害（中立な事象ID、症状のみ。根本原因は講師用パッケージを参照）

事象IDとディレクトリ名は中立な番号で、**根本原因を開示しません**。各パッケージには症状、タイムライン、ログ、既存システムのソースがあり、学習者自身で特定します。根本原因、段階式ヒント、講師番号との対応は`instructor/modules/11-incidents/INSTRUCTOR.md`を参照してください。

| 事象 | ディレクトリ | 症状（症状のみ。根本原因は含まない） | 元のRC |
|---|---|---|---:|
| 事象001 | `INC-2026-001/` | 検証ノードが中止し、当日の公開なし | 8 |
| 事象002 | `INC-2026-002/` | バッチ成功後、業務台帳と一致しない残高を公開 | 0（不具合） |
| 事象003 | `INC-2026-003/` | 受信ノードが中止し、公開なし | 12 |
| 事象004 | `INC-2026-004/` | 突合ノードが中止し、候補未生成 | 8 |
| 事象005 | `INC-2026-005/` | ソートノードが中止し、公開なし | 12 |
| 事象006 | `INC-2026-006/` | バッチ成功したが、制御合計が上流の宣言と不一致 | 0（不具合） |
| 事象007 | `INC-2026-007/` | 検証ノードが中止し、当日の公開なし | 8 |

各パッケージは`student/`ディレクトリだけで再現できます（`student/run.sh`）。スケジューラ状態、JOB Log、Shell／ソース、Copybook、元入力、パラメータ／Manifest、DB seedまたはSQL Logを含みます。障害調査の提出順序：**症状と影響範囲 → タイムライン → 仮説と証拠 → 最小再現 → 根本原因 → 修正／ロールバック → 復旧と再実行 → 再発防止**。

## 7. プラグイン操作とターミナルでの代替

- プラグイン：`gd`／`:CobolGotoDef`で段落へ移動、`K`／`:CobolPreview`でCopybookをプレビュー、Aerialのアウトラインで`system/`を参照。COBOL保存時の診断で72列／Area A/Bを確認します。
- ターミナルのみでの代替（プラグインがなくても完了できます）：
  ```bash
  rg -n 'WS-STRUCT|out of order|ledger_index|declared' \
     curriculum/modules/11-incidents/system
  od -An -tc curriculum/modules/11-incidents/fixtures/normal/transaction.dat
  sort -c -k1.1,1.10 curriculum/modules/11-incidents/fixtures/INC-2026-004/account_seed.dat
  ```

## 8. 提出する証拠と失敗条件

[evidence/README.md](evidence/README.md)に従って提出してください。各事象の再現コマンド、元のRC、タイムライン、根本原因、最小修正、復旧／再実行を記録します。保守変更では5つの成果物と回帰証拠を提出します。

次の場合は**失敗**です：RC0を業務上正しいとみなす、元入力の改ざんやアサーションの緩和で障害を「修正」する、失敗したのに正式公開する、システム障害を業務拒否として記録する、実DBを検証済みと主張する、PICを変更する前に保守調査を行わない、V1の元ファイルを上書き／書き換える。

受け入れ確認：

```bash
bash curriculum/modules/11-incidents/scripts/check.sh
```

（講師向け保守参考チェックは講師リポジトリにのみ存在し、学習者パッケージには含まれません：`instructor/modules/11-incidents/maintenance/check.sh`。）

講師向け根本原因、参考実装、RED→GREEN記録は`instructor/modules/11-incidents/INSTRUCTOR.md`を参照してください。
