# エンタープライズ・バッチ課程拡張

この拡張には、合成銀行の夜間処理を題材とする12モジュールのエンタープライズ・バッチ課程が含まれます。レコードレイアウト、ファイル処理、ソート・マージ突合、Embedded SQL、モジュール化、JOBスケジューリング、障害調査、卒業プロジェクトを扱います。CPR #31 主課程の発展演習です。まず `lessons/` にある関連する言語、ファイル、モジュール化の課程を修了することをおすすめします。

## 32課の主課程との接続

| 先に修了することをおすすめする主課程 | エンタープライズ拡張モジュール | 続けて取り組む演習 |
|---|---|---|
| [15–22 ファイル処理](../../lessons/DIRECTORY.md) | [06 ファイル](curriculum/modules/06-files/README.md)、[07 ソート・マージ突合](curriculum/modules/07-matching/README.md) | マルチストリーム・ファイル、ソート・マージ、銀行照合 |
| [23–28 エンジニアリング](../../lessons/DIRECTORY.md) | [09 モジュール化](curriculum/modules/09-modular/README.md)、[10 JOB](curriculum/modules/10-jobs/README.md)、[11 障害調査](curriculum/modules/11-incidents/README.md) | ジョブ編成、再実行時の復旧、既存システムの保守 |
| [29–31 データベース](../../lessons/DIRECTORY.md) | [08 Embedded SQL](curriculum/modules/08-database/README.md) | GixSQL/PostgreSQLによるカーソル、トランザクション、冪等処理の実践 |
| [32 卒業プロジェクト](../../lessons/32_bank-reconciliation-project/README.md) | [12 エンタープライズ卒業プロジェクト](curriculum/modules/12-capstone/README.md) | 複数ジョブによる銀行夜間バッチ処理と障害復旧 |

## 資料

- [`curriculum/README.md`](curriculum/README.md)：モジュール一覧、状態、受け入れ確認の入口。
- [`docs/curriculum/README.md`](docs/curriculum/README.md)：設計、銀行データ契約、作成基準。
- [`instructor/`](instructor/)：講師用の参考実装、採点資料、レビュー記録。
- [`tasks/`](tasks/)：課程の作成、レビュー、引き継ぎ記録。

## チェック

リポジトリのルートから実行します。

```sh
bash extensions/enterprise-batch/curriculum/check.sh
```

または、この拡張のディレクトリに移動して実行します。

```sh
cd extensions/enterprise-batch
bash curriculum/check.sh
```

クイックチェックでは、全モジュール、課程パッケージ、固定形式ゲートを確認します。Dockerが必要なPostgreSQL/GixSQL経路は別スクリプトで検証します。Dockerを使用できない場合は、状態を`UNVERIFIED`のままにしてください。モジュール文書では、実データベースの結果とオフラインのファイルチェックポイントを区別しています。
