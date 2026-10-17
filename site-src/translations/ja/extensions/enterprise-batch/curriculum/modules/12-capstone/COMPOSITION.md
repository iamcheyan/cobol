# モジュール 12 システム構成一覧と依存関係の追跡（R15）

本書では、未知バージョンのシステム構成と、卒業課題の実行における各コンポーネントの役割を説明します。コンポーネントは一意のパスごとに数え、`system/lib/common.sh` と `system/jobs/*.sh` の実際の呼び出し関係に基づいて役割を示します。

分類基準（相互排他的、優先順）：

1. **実行時依存（run）**：capstone 夜間処理が実際に呼び出し、卒業課題の成果物を生成するコンポーネント。
2. **保守調査依存（maint）**：卒業課題の保守作業で、調査後に変更する必要がある既存コンポーネント（実行される場合と、影響調査のために読み取るだけの場合がある）。
3. **独立した教材用参考実装（ref）**：コースに含まれる canonical 実装。閲覧・比較用であり、capstone のオーケストレーションからは直接呼び出されない。
4. **starter**：学習者の出発点。意図的に未完成。
5. **生成ファイル（generated）**：スクリプトやツールが生成する派生ファイル。手書き成果物と分けて識別する。

## 1. 実行時依存（capstone 夜間処理から呼び出されるもの）

| コンポーネント | パス | 役割 |
|---|---|---|
| CUSTV2 | 学習者の `starter/CUSTV2.COB`（または `CAPSTONE_STUDENT_CUSTV2`）；参考実装 `system/cobol/CUSTV2.COB`（講師用リポジトリ） | JOB002d で顧客レコードを v1/v2 から正規化 |
| NIGHTRPT | `system/cobol/NIGHTRPT.COB` | JOB007d の顧客日次レポート |
| BANKVAL | 学習者のモジュール 10 `starter/BANKVAL.COB`（または `CAPSTONE_STUDENT_BANKVAL`）；参考実装 `instructor/modules/10-jobs/BANKVAL.COB` | JOB002c の業務検証 |
| SORTTX | `instructor/modules/07/02-sort-merge/SORTTX.COB` | JOB003b のソート（runner 経由） |
| BATCHL2 | `instructor/modules/07/03-one-to-many/BATCHL2.COB` | JOB005a の 1:N 突合（runner 経由） |

その他の実行時コンポーネント（COBOL 以外）：`system/lib/capdb.py`（12 論理テーブルのオフライン・チェックポイント）、`system/lib/report.py`（整合性・日次レポート照合）、`system/lib/validate.py`（生バイト構造）、`system/lib/ordercheck.py`、および再利用するモジュール 10 の `lib/db.py`/`lib/manifest.py`/`lib/verify_publish.py`（コピーはしません）。

| 分類 | 数 | 説明 |
|---|---:|---|
| capstone Copybook | 23 | `system/copybooks/` |
| capstone Shell | 17 | 9 個の job + nightly + common + build/run/check/reset + red-green + reproduce |
| JOB ノード | 32 | 9 個の JOB の展開 |
| 論理テーブル | 12 | `capdb.py` の先頭コメント |

## 2. JOB / プログラム / COPY / テーブルの利用関係

| JOB | ノードの処理 | プログラム/ツール | COPY | 論理テーブル |
|---|---|---|---|---|
| 001 | 受信+SHA256検証+凍結 | shell + MANIFEST-RECORD | MANIFEST-RECORD | batch_run |
| 002 | 幅/数字/業務/顧客 | validate.py + BANKVAL + CUSTV2 | TRANSACTION-V1, CUSTOMER-V1, CUSTV2-CONTROL | reject_log |
| 003 | ソート+順序/重複キー | SORTTX（07 runner）+ ordercheck.py | TRANSACTION-V1 | — |
| 004 | DB スナップショット | capdb.py | DB-CUSTOMER-SNAPSHOT-ROW, DB-ACCOUNT-SNAPSHOT-ROW | customer, account, customer_snapshot, account_snapshot |
| 005 | 1:N 突合+候補生成 | BATCHL2（07 runner） | TRANSACTION-V1, ACCOUNT-V1 | — |
| 006 | 冪等記帳+commit | capdb.py | DB-LEDGER-ROW, DB-IDEMPOTENCY-KEY-ROW, DB-BATCH-COMMIT-ROW | transaction_ledger, idempotency_key, batch_commit |
| 007 | 整合性/日次レポート照合 | report.py + NIGHTRPT | NIGHTRPT-CONTROL, CONTROL-TOTAL-ROW | control_total, reject_log |
| 008 | ステージング+Manifest+公開 | manifest.py + verify_publish.py | MANIFEST-RECORD | publish_registry |
| 009 | 確認+完了+翌日準備 | shell | — | batch_run, business_calendar |

## 3. 保守調査依存 / 独立した教材用参考実装 / starter

- **保守調査依存（maint）**：オーケストレーション対象の `system/` コンポーネントと、`maintenance/copybooks/` の対象インターフェース。学習者は依存を追跡するため、先に `maintenance/impact-investigation.md` を読む必要があります。
- **独立した教材用参考実装（ref）**：`instructor/` 配下の canonical `.COB` 23 個のうち、上表で capstone から呼び出す 3 個を除いたもの（モジュール 01–06、08–12 の参考実装、FILEVAL/MATCH/MERGETX/BATCHL3/BATCHL4、モジュール 08 ESQL など）は**本モジュールのオーケストレーションから呼び出されません**。閲覧用の参考実装です。
- **starter**：`starter/CUSTV2.COB`（未完成。v2 feed では RC12 を返し、公開しません）。
- **生成ファイル**：`fixtures/` の seed、`expected/*`（独立 oracle が生成）、`__pycache__/` など。手書き実装の規模には含めません。

## 4. コンポーネント依存の説明

卒業課題の構成は、実際の呼び出し関係に基づきます。上表は実行チェーンの依存関係を示します。読み取り専用で再利用する参考実装、starter、生成ファイルは前述の分類に従います。学習者は JOB / プログラム / COPY / テーブルの対応をたどって各コンポーネントの役割を把握できます。
