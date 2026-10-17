# モジュール05 合成フィクスチャ

すべてASCIIのCUSTOMER v1ファイルで、LF終端です。論理レコードは**LFを含まず**27バイトです。固定業務日は`20261009`です。`python3 scripts/generate-fixtures.py`で決定的に再生成できます（データのみを生成し、クレンジング処理は実装しません）。`SHA256SUMS`は全フィクスチャを対象とし、`check.sh`は実行前後にチェックサムを検証します。ランナーが原本を書き換えることはありません。

| ディレクトリ | フィクスチャ | 目的 |
|---|---|---|
| normal | `clean.dat` | 3件すべて有効。小文字ステータス`a`の正規化を含む |
| boundary | `empty.dat` | 0バイトファイル（有効、READ=0） |
| boundary | `single.dat` | 1件のレコード |
| boundary | `min-amount.dat` | 金額の下限0 |
| boundary | `max-amount.dat` | 金額の上限50,000,000（含む） |
| invalid | `missing-name.dat` | 必須の名前が空 → MISSING-NAME |
| invalid | `bad-id.dat` | IDが数値でない → MISSING-ID |
| invalid | `non-numeric-amount.dat` | 金額が数値でない → BAD-AMOUNT |
| invalid | `amount-over-cap.dat` | 金額が上限を超える → AMOUNT-RANGE |
| invalid | `unknown-status.dat` | ステータス`X` → UNKNOWN-STATUS |
| invalid | `duplicate-id.dat` | 隣接するID重複 → 2件目がDUPLICATE-ID |
| invalid | `mixed.dat` | 受理と拒否の混在。保存則と理由の優先順位を確認 |
| invalid | `unsorted.dat` | IDが順不同 → RC8、公開なし |
| invalid | `short-record.dat` | 論理レコードが27B未満 → RC8 |
| invalid | `long-record.dat` | 論理レコードが27B超 → RC8 |
| invalid | `no-trailing-lf.dat` | 最終レコードにLFがない → RC8 |
| invalid | `crlf.dat` | CRLF改行 → RC8 |

invalid内の業務拒否フィクスチャは設計上RC4となり、拒否明細を含めて公開されます。構造/契約エラーはRC8となり、公開されません。
