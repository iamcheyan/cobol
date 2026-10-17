# モジュール06 合成フィクスチャ

すべてASCIIのACCOUNT v1ファイルでLF終端です。論理レコードは**LFを含まず**47バイトです。固定業務日は`20261009`です。`python3 scripts/generate-fixtures.py`で決定的に再生成できます（データのみを生成し、検証処理は実装しません）。`SHA256SUMS`はすべてのフィクスチャを対象とし、`check.sh`は実行前後にチェックサムを検証します。ランナーは原本を書き換えません。

| ディレクトリ | フィクスチャ | 目的 |
|---|---|---|
| normal | `valid.dat` | 3件有効（+1000 A / +50 F / -500 C）、BALANCE=550 |
| boundary | `empty.dat` | 0バイトファイル（有効、READ=0） |
| boundary | `single.dat` | 1件のレコード |
| boundary | `negative-balance.dat` | 負の期首残高`-9999999999999` |
| boundary | `zero-balance.dat` | 期首残高0 |
| invalid | `bad-account-id.dat` | 口座IDが数値でない → BAD-ACCOUNT-ID |
| invalid | `bad-customer-id.dat` | 顧客IDが数値でない → BAD-CUSTOMER-ID |
| invalid | `unknown-currency.dat` | 通貨`USD` → UNKNOWN-CURRENCY |
| invalid | `bad-sign.dat` | 符号`*` → BAD-SIGN |
| invalid | `bad-balance.dat` | 残高が数値でない → BAD-BALANCE |
| invalid | `bad-date.dat` | `20260230`は実在する日付でない → BAD-DATE |
| invalid | `date-mismatch.dat` | `20261008` ≠ 業務日 → DATE-MISMATCH |
| invalid | `unknown-status.dat` | ステータス`Z` → UNKNOWN-STATUS |
| invalid | `duplicate-id.dat` | 隣接する口座ID重複 → 2件目がDUPLICATE-ID |
| invalid | `mixed.dat` | 受理/拒否の混在。保存則と優先順位を確認 |
| invalid | `bad-layout.dat` | レイアウト`002` → RC8、公開なし |
| invalid | `unsorted.dat` | 口座IDが順不同 → RC8 |
| invalid | `short-record.dat` | 論理レコードが47B未満 → RC8 |
| invalid | `long-record.dat` | 論理レコードが47B超 → RC8 |
| invalid | `no-trailing-lf.dat` | 最終レコードにLFがない → RC8 |
| invalid | `crlf.dat` | CRLF改行 → RC8 |

業務拒否フィクスチャは設計上RC4となり、拒否明細を公開します。構造/契約エラーはRC8となり、公開されません。ファイル欠落フィクスチャはありません。`run.sh`に存在しないパスを渡してRC12を発生させます。
