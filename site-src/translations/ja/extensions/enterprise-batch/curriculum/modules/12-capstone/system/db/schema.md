# Capstone DB スキーマ：論理テーブル 12 個

物理実装は `system/lib/capdb.py` を参照してください。DB 層は**オフラインのファイルチェックポイント**であり、実際のデータベースではありません（PostgreSQL／Embedded-SQL は未接続・未検証）。

| # | 論理テーブル | 物理ストレージ | 主キー／一意キー | 説明 |
|---:|---|---|---|---|
| 1 | customer | `customer.table` | customer_id | CAP-CUSTOMER-FEED v2、32B（31B の v1 は自動アップグレード） |
| 2 | account | `account.table` | account_id | ACCOUNT v1、47B |
| 3 | transaction_ledger | `ledger.dat`（値列） | (business_date, transaction_id) | 記帳済み取引 |
| 4 | batch_run | `run/<date>.table` | (date, run_id, phase) | JOB 実行記録 |
| 5 | batch_commit | `commit/<date>.json` | business_date | コミット識別子と台帳ハッシュ |
| 6 | customer_snapshot | `snapshots/<date>/customer_snapshot.dat` | customer_id | 当日の凍結ビュー |
| 7 | account_snapshot | `snapshots/<date>/account_master.dat` | account_id | 当日の凍結ビュー |
| 8 | reject_log | `reject_log.dat` | (date, stage, key) | 検証／突合での拒否記録 |
| 9 | control_total | `control_total.dat` | (date, run_id) | 整合性の証跡 |
| 10 | publish_registry | `publish_registry.dat` | (date, run_id) | 公開登録 |
| 11 | idempotency_key | `ledger.dat`（キー列） | (business_date, transaction_id) | 冪等性キー |
| 12 | business_calendar | `business_calendar.dat` | date | 営業日カレンダー |

トランザクション境界：`capdb.py apply` は単一プロセス内で、まず残高と台帳を書き込み（`fsync` + `rename`）、次にコミットマーカーを書き込みます。クラッシュ後は「台帳／コミット識別子を先に読む」ことで判定し、ログの最終行から状態を推定することはありません。
