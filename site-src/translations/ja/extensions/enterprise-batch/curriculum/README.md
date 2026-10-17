# エンタープライズ Legacy Batch COBOL 課程

この拡張は[12モジュール・76時間の設計](../docs/curriculum/README.md)に基づき、合成銀行の夜間処理を一貫した題材として使用します。モジュール01–12には、学習単元、実データ、実行可能な参考実装、starter、独立したexpected、障害演習、証跡テンプレートが含まれます。各モジュールの状態では、実行エージェントによる自己テストと、主エージェントによる独立した受け入れ確認を区別します。旧版の基礎課程については [`legacy-workshop/`](../../legacy-workshop/README.md) を参照してください。

## モジュールと受け入れ確認の入口

| モジュール | 内容 | クイックチェックの入口 | 状態 |
|---|---|---|---|
| [01-foundations](modules/01-foundations/README.md) | Legacy/業務日/JOB、コンパイルとリンク、固定/自由形式、列切り詰め | `bash modules/01-foundations/scripts/check.sh` | 実行エージェントの自己テスト完了、主エージェントのレビュー待ち |
| [02-data](modules/02-data/README.md) | PIC/階層/VALUE、MOVEの切り詰めと埋め合わせ、CUSTOMER v1の27Bフィールド一覧 | `bash modules/02-data/scripts/check.sh` | 実行エージェントの自己テスト完了、主エージェントのレビュー待ち |
| [03-bytes](modules/03-bytes/README.md) | DISPLAY/COMP/COMP-5/COMP-3の生バイト、不正Packedの解析 | `bash modules/03-bytes/scripts/check.sh` | 実行エージェントの自己テスト完了、主エージェントのレビュー待ち |
| [04-structures](modules/04-structures/README.md) | REDEFINES/OCCURS/ODO/COPY REPLACING、175フィールドの一覧とオフセット | `bash modules/04-structures/scripts/check.sh` | 実行エージェントの自己テスト完了、主エージェントのレビュー待ち |
| [05-control](modules/05-control/README.md) | IF/EVALUATE/PERFORM、SEARCH、STRING/UNSTRING、顧客データのクレンジング | `bash modules/05-control/scripts/check.sh` | 実行エージェントの自己テスト完了、主エージェントのレビュー待ち |
| [06-files](modules/06-files/README.md) | FD/FILE STATUS/EOF、固定長・LINEファイル、相対/索引ファイルとロック | `bash modules/06-files/scripts/check.sh` | 実行エージェントの自己テスト完了、主エージェントのレビュー待ち |
| [07-matching](modules/07-matching/README.md) | SORT/MERGE、L1/L2/L3/L4突合ベンチマーク（12時間、主要課程） | `bash modules/07-matching/check.sh` | L1/L2/SORT/MERGE/L3は主エージェントが受け入れ済み。L4は主エージェントの受け入れ待ち |
| [08-database](modules/08-database/README.md) | 実際のESQLカーソル/NULL/トランザクション/冪等性（6時間） | `bash modules/08-database/scripts/check-quick.sh`（オフライン）；`.../scripts/check.sh`（実DB、Dockerが必要） | 実DBのエンドツーエンド実行でRC0を確認済み、主エージェントのレビュー待ち |
| [09-modular](modules/09-modular/README.md) | CALL/LINKAGE/USING、RETURNING、共通モジュール、状態のライフサイクル | `bash modules/09-modular/scripts/check.sh` | 実行エージェントの自己テスト完了、主エージェントのレビュー待ち |
| [10-jobs](modules/10-jobs/README.md) | JOB001–009、RC/ロック/スナップショット/Manifest、4つのクラッシュ境界からの復旧（9時間、主要課程） | `bash modules/10-jobs/scripts/check.sh` | 実行エージェントの自己テスト完了、主エージェントのレビュー待ち |
| [11-incidents](modules/11-incidents/README.md) | 6種類の障害調査、顧客区分を1桁から2桁へ拡張する保守（9時間、主要課程） | `bash modules/11-incidents/scripts/check.sh` | 実行エージェントの自己テスト完了、主エージェントのレビュー待ち |
| [12-capstone](modules/12-capstone/README.md) | 未知のシステムを対象とした統合プロジェクト、4種類の日次締め処理、隠れた障害、採点（9時間） | `bash modules/12-capstone/scripts/check.sh` | 実行エージェントの自己テスト完了、主エージェントのレビュー待ち |

## ローカル受け入れ確認

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
bash curriculum/check.sh                                  # P1 + 全12モジュールのクイック受け入れ確認入口 + 固定形式ゲート
bash curriculum/modules/07-matching/check.sh              # モジュール07単独の入口
bash curriculum/modules/08-database/scripts/check.sh      # 実DBエンドツーエンド（Docker + PostgreSQL + GixSQL）
bash curriculum/validation/database/check.sh              # P1 ESQLツールチェーンの回帰確認（Docker）
python3 curriculum/modules/07-matching/labs/01-one-to-one/scripts/pressure.py    # L1メモリ負荷
python3 curriculum/modules/07-matching/labs/04-many-to-many/scripts/pressure.py # L3マルチストリーム負荷
python3 curriculum/modules/07-matching/labs/05-large-record/scripts/pressure.py # L4全体経路の負荷（oracleを含む）
bash curriculum/scripts/package-student.sh                # instructor/を除外した受講者用パッケージを生成
```

`curriculum/check.sh`にDockerは不要です。P1検証、全モジュールのクイック受け入れ確認入口、さらに3種類のゲートを実行します。ゲートは、凍結された銀行インターフェースの幅（すべての`copybooks/{ACCOUNT,TRANSACTION,CUSTOMER}-V1.CPY`を実測し47/55/27バイト）、課程資料の構成（12モジュールすべてのREADME/DESIGN/starter/fixtures/expected/scripts/evidenceと2つの経路）、72列/ASCII/タブなしです。`08-database`のクイック入口はオフライン契約のみを確認し、実DB実験には独立した任意の入口があります。`curriculum/validation/database/check.sh`は初回にネットワーク経由でESQLツールをビルドし、一時的なデータベースとネットワークを使って終了時に後片付けします。ホスト側のポートや永続データベースボリュームは作成しません。

ローカルにDocker、GixSQL、またはPostgreSQLがない場合、実DBおよび一部のインタープリター実験は「未検証」と記録してください。合格したと記述してはいけません。

## プラットフォーム、ABI、検証済み範囲

- 必須プラットフォームはLinux x86-64 + GnuCOBOL 3.2.0です。macOS/WSL/ARMは未テストで、文書でも「未検証」と明記しています。
- ローカル実測ではPIC COMPはビッグエンディアン、COMP-5はネイティブのリトルエンディアンでした。バイナリ表現は固定されたABIに基づいて解釈し、プラットフォームをまたいで推定しないでください。
- モジュール08は実際のEmbedded SQL（固定したGixSQL commit、ローカルパッチ2件、PostgreSQL）を使用します。モジュール10/11/12のDB層は明確に**オフラインのファイルチェックポイント**（`real_db_verified=false`）と記され、実際のPostgreSQLには接続していません。

## 制作の進捗

| フェーズ | 現在の状態 |
|---|---|
| P0 設計 | 完了、実装承認済み |
| P1 技術検証 | バイト/2ストリーム/実DBの基準値と証跡は`validation/`にあります。プラットフォームはLinux x86-64のみ |
| P2 モジュール07ベンチマーク | L1/SORT/MERGE/L2/L3は主エージェントが受け入れ済み。L4は実装済みで全体経路の負荷証跡を含み、主エージェントの受け入れ待ち |
| P3 モジュール01–06、09 | すべて実装され、実行エージェントの自己テストに合格。主エージェントによる独立レビュー待ち |
| P4 モジュール08、10 | 実装完了。08は実DBで実測済み、10はオフラインDBとして明記。主エージェントのレビュー待ち |
| P5 モジュール11、12 | 実装完了。11は6種類の障害と保守、12は未知のシステムと採点。主エージェントのレビュー待ち |
| P6 リリース/旧コンテンツ移行 | 受講者向けパッケージスクリプトと総合入口を用意済み。旧版課程資料は`extensions/legacy-workshop/`にアーカイブ済み |

課程の基準は設計文書に従います。各レッスンの入力と業務上の期待値は実装より先に決定します。未検証のプラットフォーム、復旧範囲、DBの状態は未完了のまま明示します。作業とレビューの手順は[実装Goal引き継ぎ文書](../tasks/enterprise-cobol-implementation-goal.md)を参照してください。
