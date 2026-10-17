# 修正対象一覧

担当者の役割：上流インターフェース（外部）、バッチ開発（本リポジトリ）、DB 運用、下流コンシューマー。

| # | 分類 | 対象 | 修正内容 | 担当 | 回帰証拠 |
|---:|---|---|---|---|---|
| 1 | Copybook | `system/copybooks/CAP-CUSTOMER-FEED-V2.CPY` | 32B 固定インターフェースを追加 | バッチ開発 | フォーマット検査 |
| 2 | プログラム | `system/cobol/CUSTV2.COB` | 31/32B を受理；v1 を v2 にアップグレード；BADSTATUS/BADCLASS/BADVERSION を検証 | バッチ開発 | RED→GREEN |
| 3 | プログラム | `system/cobol/NIGHTRPT.COB` | 宣言された layout と物理幅の一致を検証 | バッチ開発 | layout guard |
| 4 | DB | `system/lib/capdb.py` | `customer.table` に 32B を保存；`read_customer_records` が 31/32B を受理 | DB 運用 | スナップショット/apply |
| 5 | File | `fixtures/extension/` | v2 の合成日を追加 | バッチ開発 | 4 種類の日 |
| 6 | Shell | `system/jobs/job002-validate.sh` | CUSTV2 の出力を使って v2 に正規化 | バッチ開発 | JOB002d |
| 7 | JOB | `JOB002/JOB004/JOB007` | レイアウトに応じた説明を追加；トポロジーは変更なし | バッチ開発 | 夜間処理全体 |
| 8 | 設計書 | `DESIGN.md`、本変更パッケージ | レイアウト版と移行履歴 | バッチ開発 | 文書レビュー |
| 9 | 下流インターフェース | `customer-day.dat` | 区分列を 2 桁に固定（v1 日は `A→A1` に変換） | 下流コンシューマー | 互換性テスト |
| 10 | 上流インターフェース | `customer.extract` | レイアウト版（001/002）を宣言 | 上流 | MANIFEST |

変更禁止：モジュール 01–11、canonical runner（SORT/L2/BANKVAL）、固定済み ACCOUNT v1（47B）/TRANSACTION v1（55B）/CUSTOMER v1（27B、第 27 バイト = レコード状態）。
