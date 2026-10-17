# モジュール 12：卒業総合プロジェクト — 未知バージョンの銀行システム

目安：9 時間。前提：モジュール 06（ファイル契約）、07（ソートと順次突合）、10（JOB 運用）。本モジュールでは 06/07/08/10 の canonical コンポーネントを**オーケストレーション**して「未知バージョン」の夜間バッチシステムを構成します。アーキテクチャを自分で復元し、顧客区分拡張を完成させ、4 種類の営業日を実行し、**隠れた根本原因**の事故を調査します。

> プラットフォーム：Linux x86-64 のみ実動確認済み（GnuCOBOL 3.2.0、Bash、GNU coreutils、Python 3）。macOS/WSL/他のアーキテクチャは**未検証**です。
>
> **DB 層について（2 つのルートを混在させないこと）**：
> 1. **標準の教材ルート（オフライン）**：`system/lib/capdb.py` はオフライン・ファイル・チェックポイントを使い、12 論理テーブルの DB 契約を模擬します。このルートの証拠には「DB 層 = オフライン・ファイル・チェックポイント、実 DB 未検証」と明記してください。オフラインの RC0 を実 DB のエンドツーエンド検証として示してはいけません。
> 2. **実 DB ルート（R01）**：`scripts/real-db.sh` は canonical モジュール 10 harness（Docker + PostgreSQL17 + GixSQL + モジュール 08 ESQL）を再利用し、実カーソル抽出と**単一トランザクション**での冪等記帳（残高 + 台帳 + `batch_commit` を同一トランザクションで処理）を実施し、独立した psql で照合します。恒久回帰テストは `scripts/check-real-db.sh` です。実 DB が利用できない場合は `UNVERIFIED` と報告し、成功したように見せません。

## 1. なぜ必要か / どんな要件を受け取ったか

銀行は毎晩、上流取引を受信し、検証・ソート・口座期首との突合・冪等記帳・制御総数照合を行い、下流向け顧客日次レポートを生成して公開する必要があります。ファイル、DB、下流公開の間に**原子的コミットはありません**。そのため「失敗時は公開しない、再実行で二重引落ししない、クラッシュから復旧できる」ことが必須です。

渡されたのは**未知バージョン**です。文書が不完全で、コンポーネントは異なる章に分かれています。課題は 4 段階です：12.1 アーキテクチャと依存関係の復元、12.2 顧客区分の 1 桁から 2 桁への拡張を完成させ正常/異常/再実行日を処理、12.3 夜間処理全体を完走、12.4 隠れた根本原因の事故を調査して復旧策を示します。

## 2. 入力、出所、形式、保証済みの前提

受信ディレクトリには `transaction.dat`（TRANSACTION v1、1 件 55B+LF）、`customer.dat`（企業顧客レイアウト CAP-CUSTOMER-FEED v1 31B または v2 32B）、`account_seed.dat`（ACCOUNT v1 47B）、`MANIFEST`（営業日、レイアウト版、各ファイルの SHA256）が含まれます。

固定インターフェース（`system/copybooks/`）：CUSTOMER **v1 27B（第 27 バイト = レコード状態 status、A/D のみ）** / ACCOUNT **v1 47B** / TRANSACTION **v1 55B**。顧客区分は**独立したバージョン管理対象の** CAP-CUSTOMER-FEED レイアウトにあります：v1 **31B**（区分は第 28 バイト、A/B/C/D）、v2 **32B**（区分は第 28–29 バイト、A1..D1）。canonical CUSTOMER v1 の 27 バイトは変更しません。企業レイアウトは canonical CUSTOMER v1 の 27 バイトを先頭に内包します。

**名称について**：capstone の小さな顧客 feed は `CAP-CUSTOMER-FEED` と呼び、モジュール 04/07 の canonical 1778 バイト・175 フィールドの大きな `ENTERPRISE-CUSTOMER` レコードや、モジュール 11 の事故実験用レイアウトとは区別します。3 者は物理長とフィールドが互換ではありません。同じ `ENTERPRISE-CUSTOMER-Vx` 名を共用すると、バージョン名でレイアウトのずれが隠れるため、共用してはいけません。本レイアウトと canonical 大型レコードは「同じ業務概念の異なる粒度のビュー」にすぎません。本レイアウトの第 1–27 バイトは canonical CUSTOMER v1 とバイト単位で同一で、その後に capstone 独自の区分とバージョンフィールドを追加します。実際の大企業レコードの保守（150 以上のフィールド差分）はモジュール 07 L4 で扱います。

LF は論理長に含めません。ASCII を使い、営業日はマシンの日付ではなく明示的な引数で指定します。

保証済み：上流はファイル全体を同一レイアウトで送信します（混在レイアウトは構造エラー）。重複 `transaction_id`、短い/長いレコード、無効な数値は検出対象の異常です。

## 3. クリーンな checkout からのビルド、実行、リセット

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
mod=curriculum/modules/12-capstone

# 任意：capstone COBOL のみを個別にビルド
bash "$mod/scripts/build.sh" /tmp/capstone-bin

# 正常日（v1）
bash "$mod/scripts/run.sh" --input "$mod/fixtures/normal" \
  --output /tmp/c12-normal --db /tmp/c12-db \
  --business-date 20261010 --layout v1 --run-id n1
echo "rc=$?"            # 期待値 0

# 異常日（業務拒否あり、公開は行う）
bash "$mod/scripts/run.sh" --input "$mod/fixtures/abnormal" \
  --output /tmp/c12-abn --db /tmp/c12-db-abn \
  --business-date 20261010 --layout v1 --run-id a1
echo "rc=$?"            # 期待値 4

# フィールド拡張日（区分 v2、D1 顧客を含む）
bash "$mod/scripts/run.sh" --input "$mod/fixtures/extension" \
  --output /tmp/c12-ext --db /tmp/c12-db-ext \
  --business-date 20261010 --layout v2 --run-id e1
echo "rc=$?"            # 期待値 0

# 再実行日：同じ DB に normal と同じ feed を再度実行（新しい出力ディレクトリ）
bash "$mod/scripts/run.sh" --input "$mod/fixtures/rerun" \
  --output /tmp/c12-rerun --db /tmp/c12-db \
  --business-date 20261010 --layout v1 --run-id r1
echo "rc=$?"            # 期待値 0；apply は new_transactions=0、残高は不変

# 状態確認とリセット
bash "$mod/scripts/run.sh" --input "$mod/fixtures/normal" \
  --output /tmp/c12-normal --db /tmp/c12-db --business-date 20261010 \
  --layout v1 --command status
bash "$mod/scripts/reset.sh" /tmp/c12-normal
```

派生ファイルが上書きされるのは `--output` ディレクトリ内のみです。入力ディレクトリ、fixtures、DB seed は**上書きしません**。既存の出力ディレクトリは RC12 で拒否します。

## 4. 期待出力、RC、件数、金額（独立照合）

`normal`：3 口座（期首 1000/50/0）、6 件すべて記帳。

| 指標 | normal | abnormal | extension |
|---|---:|---:|---:|
| received | 6 | 9 | 7 |
| validate 受理/拒否 | 6/0 | 5/4 | 7/0 |
| match 受理/拒否 | 6/0 | 4/1 | 7/0 |
| 期首 / 貸記 / 借記 / 期末 | 1050/1050/250/**1850** | 1050/900/200/**1750** | 1250/1150/250/**2150** |
| 期待 RC | 0 | 4 | 0 |

詳細値は `expected/*.control.txt`（件数と金額）、`expected/*.closing.txt`（期末残高）、`expected/*.customerday.txt`（顧客日次レポート）を参照してください。これらは `instructor/modules/12-capstone/tools/gen_course.py` の**独立 oracle**が計算したもので、コース実装の出力はコピーしていません（`expected/README.md` を参照）。

RC：normal/rerun/extension=0；abnormal=4；`broken`（transaction_id 重複）=8 で**正式公開なし**；システム障害=12 で**正式公開なし**。

## 5. 変更する場所と、壊してはいけないインターフェース

- 学習者の出発点：`starter/CUSTV2.COB`（コンパイル可能。v2 feed では RC12 を返し、公開しません）。32 バイトの企業 v2 と 31→32 のアップグレードに対応させます。
- **学習者が総合システムに接続する方法**：夜間処理は標準で**学習者自身の** `starter/CUSTV2.COB` をコンパイルして実行します（starter 内で直接完成させられます。外部ファイルを使う場合は `CAPSTONE_STUDENT_CUSTV2=<あなたのソース>` で上書き）。JOB002c の取引検証器も同様に、完成済みモジュール 10 `starter/BANKVAL.COB` を使います（または `CAPSTONE_STUDENT_BANKVAL` で上書き）。参考実装 `system/cobol/CUSTV2.COB` は問題集/講師用リポジトリにのみあり、**学習者向け配布物には含まれません**。
- 変更禁止：CUSTOMER v1 27B（第 27 バイト = 状態）/ ACCOUNT v1 47B / TRANSACTION v1 55B の幅とオフセット、`work/`・`publish/`・`state/` のディレクトリ契約、RC の意味、冪等キー `(business_date, transaction_id)`、`customer-day.dat` の 30B レイアウト。
- JOB003/JOB005 はモジュール 07 の参考実装を再利用（コピーしません）。学習者はモジュール 07 の SORT/MERGE 実験を先に完成させる必要があり、そうすれば総合処理でソート/突合できます。
- 変更パッケージと順序は `maintenance/` を参照（先に影響調査、その後に変更）。

## 6. 意図的な障害と復旧（各実験で再現可能な障害を 1 つ以上）

| 実験 | 障害の起こし方 | 現象 | 復旧 |
|---|---|---|---|
| 12.1 依存関係 | `work/` の成果物を上書き | 後続ノードの意味が不正 | スナップショットから派生ファイルを再構築 |
| 12.2 レイアウト | 宣言レイアウトと物理幅が不一致 | JOB002a RC8、公開なし | layout/上流ファイルを修正 |
| 12.3 クラッシュ | `--crash-at {before,mid,after}-db-commit / during-publish / after-publish` | 元の RC は 97、現場を保持 | 同じ run-id で再実行すれば自動復旧 |
| 12.3 再実行 | 同じ DB、同じ営業日、新しい出力ディレクトリ | RC0、残高/台帳は不変 | — |
| 12.4 事故 | `incidents/incident-01/` を参照 | JOB003 RC8、公開なし | 業務上の訂正後に再実行 |

## 7. プラグイン操作とターミナルのみでの代替

- プラグイン：`gd`/`:CobolGotoDef` で JOB スクリプトと COBOL 間を移動し依存を追跡します。`COPY "CAP-CUSTOMER-FEED-V2.CPY"` には `:CobolGotoCopybook` を使ってインターフェースを確認します。COBOL 保存時に診断で 72 列/Area A/B を確認し、Aerial のアウトラインで NIGHTRPT/CUSTV2 の構造を確認します。
- ターミナルのみで確認する場合：

```bash
rg -n 'CUSTV2_|NIGHTRPT_|c12_step|duplicate transaction' \
  curriculum/modules/12-capstone
od -An -tc curriculum/modules/12-capstone/fixtures/extension/customer.dat | head
cut -b 11-26 curriculum/modules/12-capstone/fixtures/broken/transaction.dat \
  | sort | uniq -d
```

## 8. 提出する証拠と失敗の判定

[evidence/README.md](evidence/README.md) に従い、4 種類の日、5 種類のクラッシュ境界、事故調査について、実行コマンドと元の RC を提出します。次は**失敗**です：JOB が失敗したのに正式公開された、同日再実行で二重引落しした、クラッシュ復旧後に DB/台帳/ファイル/状態が一致しない、過去の `publish/<run_id>` を今回の結果として扱った、システム障害を業務拒否に分類した、実 DB を検証済みと主張した。

## 受け入れ確認

```bash
bash curriculum/modules/12-capstone/scripts/check.sh
```

（講師採点器は講師用リポジトリにのみあり、学習者向け配布物には含まれません：`instructor/modules/12-capstone/grading/grade.py`。）

`check.sh` は 4 種類の日、layout guard、冪等な再実行、5 種類のクラッシュ復旧、ロック/no-clobber、システム障害、制御ゲート、starter、RED→GREEN を確認します。

## システム構成

卒業課題の実行コンポーネントと依存関係は[システム構成一覧](COMPOSITION.md)を参照してください。実際の呼び出し関係に基づき、実行時依存、保守調査依存、教材用参考実装、starter、生成ファイルを区別しています。
