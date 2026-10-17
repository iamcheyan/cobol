# Test Case（企業顧客区分を 1 桁から 2 桁へ）

| # | 分類 | 入力 | 期待値 |
|---:|---|---|---|
| T1 | 正常 v1 | `fixtures/normal`（企業顧客 31B） | RC0、区分を `A1` にアップグレード |
| T2 | 正常 v2 | `fixtures/extension`（企業顧客 32B、`D1` を含む） | RC0、`customer-day.dat` に `D1` を含む |
| T3 | 正常（業務拒否あり） | `fixtures/abnormal` | RC4、公開する；制御総数が整合 |
| T4 | 境界 | 顧客 1 件 / 口座 0 件 | RC0、顧客日次レポートが空でも有効 |
| T5 | 異常 | v1 を宣言したがファイルは 32B（またはその逆） | JOB002a RC8、公開なし |
| T6 | 異常 | v2 区分が無効（例：`AX`） | JOB002d RC4、reject に記録（BADCLASS） |
| T7 | バージョン跨ぎ | 同じ v1 日を新旧両バージョンで並行実行 | `customer-day.dat` と制御総数が一致 |
| T8 | 全処理 | 4 種類の日（normal/abnormal/rerun/extension） | 各 RC と公開結果が契約に一致 |
| T9 | 復旧 | 5 種類のクラッシュ境界 + 同日再実行 | 台帳の重複なし、残高不変、CURRENT が正しい |
| T10 | 安全な変更 | 事故復旧で元入力を変更しない | 業務訂正を別途監査可能 |

RED→GREEN の証拠は `regression/red-green.sh` が生成します。RED では未完成の v1 専用 starter に v2 fixture を与え、GREEN では `system/cobol/CUSTV2.COB` を使います。
