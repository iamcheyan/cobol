# モジュール08 フィクスチャ

すべて業務日`20261009`向けの合成データです。テキストインターフェースはASCII、LF終端で、固定レコード幅にLFは含めません。CUSTOMER v1レコードは27バイト、TRANSACTION v1レコードは55バイトです。`SHA256SUMS`はフィクスチャファイルを対象とし、検査では実行前後に入力を検証します。原本を編集せず、故障演習には一時コピーを作成してください。

| フィクスチャ | 目的 |
|---|---|
| `customer-upstream-20261009.dat` | 1フィールド差分、ファイルのみのキー1件、DBのみのキー1件を含む上流CUSTOMERファイル |
| `customer-upstream-20261009-nodiff.dat` | データベースsnapshotと同一の上流ファイル |
| `transactions-20261009.dat` | commitと残高更新の検証に使用する3取引 |
| `transactions-dup-in-run.dat` | 1回の実行内で取引を重複させ、RC8 rollbackを確認 |

DB seedは`db/seed.sql`にあります。フィクスチャは`expected/README.md`に記載した独立計算を支えるよう作られており、期待値の根拠にプログラム出力を使いません。
