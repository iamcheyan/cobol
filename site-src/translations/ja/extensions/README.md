# 任意コースと関連資料

32 レッスンのメインコースは、リポジトリのルートにある [`lessons/`](../lessons/README.md) から始まります。このページでは、メインコースの順序に別の目標や前提条件を混在させないよう、任意の拡張資料を紹介します。

## メインコースのレッスン別に選ぶ

以下の資料は 32 レッスンの流れに対応しています。追加練習、別の実装との比較、発展学習に利用できます。メインコースの順序は変わらず、修了条件にも含まれません。

| メインコースのレッスン | 任意の関連資料 | テーマ |
|---|---|---|
| 01–08 | [`legacy-workshop/lessons/00-environment/`](legacy-workshop/lessons/00-environment/)、[`01-program-anatomy/`](legacy-workshop/lessons/01-program-anatomy/)、[`07-conditions-88/`](legacy-workshop/lessons/07-conditions-88/)–[`09-loops-perform/`](legacy-workshop/lessons/09-loops-perform/) | 環境、固定形式、レベル 88 の条件名、制御フロー |
| 09–14 | [`legacy-workshop/lessons/10-tables-occurs-search/`](legacy-workshop/lessons/10-tables-occurs-search/)、[`11-strings-unstring-inspect/`](legacy-workshop/lessons/11-strings-unstring-inspect/)、[`14-copybooks-redefines/`](legacy-workshop/lessons/14-copybooks-redefines/); [`TBLSRCH.COB`](standalone-examples/TBLSRCH.COB) | テーブル、文字列処理、Copybook、再定義 |
| 15–22 | [`legacy-workshop/lessons/12-sequential-files/`](legacy-workshop/lessons/12-sequential-files/)、[`13-file-status-errors/`](legacy-workshop/lessons/13-file-status-errors/)、[`17-reports-control-break/`](legacy-workshop/lessons/17-reports-control-break/)、[`18-sort-merge/`](legacy-workshop/lessons/18-sort-merge/)、[`25-project-csv-pipeline/`](legacy-workshop/lessons/25-project-csv-pipeline/)、[`26-project-fixed-records/`](legacy-workshop/lessons/26-project-fixed-records/) | ファイル状態、レポート、ソート、CSV／固定長レコードの一連のプロジェクト |
| 23–28 | [`legacy-workshop/lessons/15-subprograms-linkage/`](legacy-workshop/lessons/15-subprograms-linkage/)、[`19-modules-environment/`](legacy-workshop/lessons/19-modules-environment/)、[`20-debugging-diagnostics/`](legacy-workshop/lessons/20-debugging-diagnostics/)、[`21-compiler-options/`](legacy-workshop/lessons/21-compiler-options/)、[`22-bash-build-run/`](legacy-workshop/lessons/22-bash-build-run/)–[`24-bash-pipelines-scheduling/`](legacy-workshop/lessons/24-bash-pipelines-scheduling/) | サブプログラム、プロジェクトのデバッグ、ビルド、自動化、スケジューリング |
| 29–31 | [`legacy-workshop/lessons/16-intrinsic-functions-dates/`](legacy-workshop/lessons/16-intrinsic-functions-dates/)、[`enterprise-batch/curriculum/modules/08-database/`](enterprise-batch/curriculum/modules/08-database/) | 日付関数と実際の Embedded SQL の応用 |
| 32 | [`legacy-workshop/lessons/28-capstone-night-batch/`](legacy-workshop/lessons/28-capstone-night-batch/)、[`29-reference-topic-map/`](legacy-workshop/lessons/29-reference-topic-map/)、[`enterprise-batch/curriculum/modules/11-incidents/`](enterprise-batch/curriculum/modules/11-incidents/)、[`12-capstone/`](enterprise-batch/curriculum/modules/12-capstone/) | 夜間バッチ処理、知識の振り返り、インシデント調査、企業向け総合課題 |

エディターのツール練習は [Neovim エディター補助チュートリアル](neovim-tooling/README.md)（36 本。COBOL 専用に加え、検索、一括編集、コード理解、Git、セッション管理を扱う汎用編を含む）、4 つの独立したサンプルは [`standalone-examples/`](standalone-examples/README.md) を参照してください。

## 旧版入門コース

[`legacy-workshop/`](legacy-workshop/README.md) には、旧来の 00–29 レッスン、コンパイル用スクリプト、練習データ、プラグインのワークフローが保存されています。テーマ別の追加演習に利用できます。レッスンの順序は CPR #31 メインコースとは独立しています。

## エンタープライズバッチ拡張

[`enterprise-batch/`](enterprise-batch/README.md) は、架空の銀行の夜間処理を題材にした 12 モジュールの企業向けコースです。ファイルレイアウト、ソートとマージ、モジュール化、データベース、ジョブスケジューリング、インシデント調査、総合課題を扱います。

コース設計、講師向け参照実装、採点、レビュー資料はこの拡張ディレクトリにまとめられており、検証方法は README に記載されています。データベースモジュールでは、実際の Embedded SQL 検証とオフラインのファイル確認項目を区別しています。各モジュールに記載された環境条件に沿って結果を報告してください。

## Neovim プラグインのチュートリアル

[Neovim エディター補助チュートリアル](neovim-tooling/README.md) は全 **36 本**で、7 分類に整理されています。COBOL 専用の `cobol.nvim`（01–07）、検索とジャンプ（09–11、23）、一括編集（08、12–14）、コード理解（15–18）、Git（19–20）、画面と外観（22、24–30）、補助とその他（21、31–36）。各ページに本機の実際のキー、実測記録、演習と合格条件があります。メインコースの前提条件ではありません。

**どこから入るか**：まず [チュートリアル目次](neovim-tooling/README.md) を開いてください。分類索引と、3 通りの推奨順序（時間がない／COBOL を扱う／コース文書を編集する）があります。

## 独立した COBOL サンプル

[`standalone-examples/`](standalone-examples/README.md) には、独立して実行できる COBOL プログラム 4 本と、その Copybook、入力データが保存されています。このディレクトリで `make check`、`make run`、または `make clean` を実行してください。
