# モジュール 02 合成入力

すべてのファイルは ASCII テキストで LF 終端、各論理レコードは27バイトです（[銀行システム設計](../../../../docs/curriculum/BANK-SYSTEM.md)の CUSTOMER v1 と同じ）。
LF はレコード長に含めません。文字数をバイト数と取り違えないよう、名前フィールドはまず ASCII に制限します。
`python3 scripts/generate-fixtures.py` で決定的に再生成できます。このスクリプトはバイト列のみを生成し、ロード／検証ロジックは実装しません。
`SHA256SUMS` はこのディレクトリ内の全ファイルを対象とします。

| パス | 用途 | 期待結果 |
|---|---|---|
| `normal/customer.dat` | 有効な顧客3件（A/D両方の状態） | RC0、すべて受理、残高合計10012394 |
| `boundary/empty.dat` | 0バイト（空ファイルを許容） | RC0、読み込みレコード数0 |
| `boundary/single.dat` | レコードが1件のみ（最後のレコード） | RC0 |
| `boundary/max-balance.dat` | `balance_demo` が8桁の最大値99999999 | RC0 |
| `boundary/name-full.dat` | 名前がちょうど10文字 | RC0 |
| `boundary/no-final-lf.dat` | 最終レコードの後に LF がない | RC8、公開なし |
| `invalid/short.dat` | 26バイトの短いレコード | RC8、公開なし |
| `invalid/long.dat` | 28バイトの長いレコード | RC8、公開なし |
| `invalid/crlf.dat` | レコード行が CRLF で終わる | RC8、公開なし |
| `invalid/bad-id.dat` | 顧客 ID に数字以外が含まれる | RC8、公開なし |
| `invalid/duplicate-id.dat` | 顧客 ID が2件同一 | RC8、公開なし |
| `invalid/unsorted.dat` | 顧客 ID が降順 | RC8、公開なし |
| `invalid/name-missing.dat` | 名前がすべて空白 | RC4、理由 `NAME-MISSING` |
| `invalid/bad-amount.dat` | `balance_demo` に数字以外が含まれる | RC4、理由 `BAD-AMOUNT` |
| `invalid/unknown-status.dat` | 状態が Z | RC4、理由 `UNKNOWN-STATUS` |
| `types/typeinput.dat` | 型実験の入力：5バイトのレコード3件、`ABCDE`/`AB123`/`AB CD` | `TYPESLAB` が `expected/typeslab.txt` とバイト単位で一致 |

RC8 フィクスチャには正式な期待レポートがありません。契約ではバッチ全体を失敗させ、出力ディレクトリを公開しないことを求めるためです。ランナー内で元フィクスチャを書き換えてはいけません。
`types/typeinput.dat` は `experiments/types/TYPESLAB.COB` 用の5バイト／レコードの行形式入力で、CUSTOMER v1 の27バイト契約には含まれません。
