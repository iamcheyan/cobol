# モジュール 01 の合成入力

すべてのファイルは ASCII テキストで、LF で終端します。各論理レコードは 47 バイトです（[銀行システム設計](../../../../docs/curriculum/BANK-SYSTEM.md)の ACCOUNT v1 と同じ）。
LF はレコード長に含めません。固定営業日は 20261009 です。`python3 scripts/generate-fixtures.py` で決定的に再生成できます。
このスクリプトはバイト列を生成するだけで、バッチ処理ロジックは実装しません。`SHA256SUMS` はこのディレクトリ内の全ファイルを対象とします。

| パス | 目的 | 期待結果 |
|---|---|---|
| `normal/account.dat` | 有効な口座 3 件（状態 A/F/C の 3 種） | RC0、すべて受理 |
| `boundary/empty.dat` | 0 バイトの入力（契約で許可された空ファイル） | RC0、0 件を読み込み |
| `boundary/single.dat` | レコードが 1 件のみ（最後のレコード） | RC0、1 件を読み込み |
| `boundary/no-final-lf.dat` | 最終レコードの後に LF がない | RC8、公開なし |
| `invalid/short.dat` | 46 バイトの短いレコード | RC8、公開なし |
| `invalid/long.dat` | 48 バイトの長いレコード | RC8、公開なし |
| `invalid/crlf.dat` | レコード行が CRLF で終わる | RC8、公開なし |
| `invalid/bad-id.dat` | 口座番号に数字以外の文字を含む | RC8、公開なし |
| `invalid/bad-layout.dat` | レイアウトバージョンが 002 | RC8、公開なし |
| `invalid/bad-date.dat` | レコードの日付が営業日と一致しない | RC8、公開なし |
| `invalid/duplicate-id.dat` | 同じ口座番号のレコードが 2 件（重複キー） | RC8、公開なし |
| `invalid/unsorted.dat` | 口座番号が降順 | RC8、公開なし |
| `invalid/unknown-status.dat` | 状態が未知の値 Z | RC4、拒否明細を公開 |

RC8 フィクスチャには `expected/` の正式レポートがありません。契約上、バッチ全体が失敗し、出力ディレクトリを公開しないためです。
業務拒否フィクスチャの expected は `expected/unknown-status.control.txt` を参照してください。実行側で元のフィクスチャを書き換えてはいけません。
