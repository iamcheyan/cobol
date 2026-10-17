---
_translated_from: lessons/30_sql-cursors/exercise.md
_translated_by: site-src/translation agent
---

# 第30課 演習：カーソルと結果セットの境界

前提： [第29課](../29_embedded-sql/README.md)の GixSQL/SQLite ツールチェーンがインストール済みであること。本課のソースは [`lesson.cob`](./lesson.cob)、実行方法と観察内容は [`README.md`](./README.md) の「ビルドと実行」「空、単一行、複数行、EOF のケース」を参照してください。

## 変更演習（解答は[`answer.md`](./answer.md)）

二つの演習はどちらも**本課の元のソース** `lesson.cob` から始め、別々に取り組んでください。前の演習で変更したソースから続けてはいけません。変更するたびに `./build.sh run` を再実行します。スクリプトは本課の `build/cursor.db` を削除し、[`schema.sql`](./schema.sql) から二行のフィクスチャを再作成するため、結果を再現できます。

1. **結果の順序を逆にする。** `ACCOUNT-CURSOR` 宣言の並び順を `ORDER BY ACCOUNT_NO DESC` に変更します。再コンパイルして実行し、出力順、`行数=`、EOF の処理を比較してください。変更はカーソルの `SELECT` 文にある `ORDER BY` 句だけに限定し、`FETCH` ループや `CLOSE` は変更しないでください。

2. **一つの口座に限定する。** 元のソースから始め、`FROM ACCOUNT_SNAPSHOT` の後に `WHERE ACCOUNT_NO = 'A000000002'` の行を追加します。口座が一件だけ出力され、次の `FETCH` で EOF が処理されることを確認してください。変更はカーソルの `SELECT` 文にある `WHERE` 句だけに限定してください。

## 学んだことを応用する演習（解答なし）

`ACCOUNT_SNAPSHOT` に `ACCOUNT_STATUS`（例：`ACTIVE` / `CLOSED`）を追加し、カーソルが有効な口座だけを返すようにします。[`schema.sql`](./schema.sql) と [`schema-empty.sql`](./schema-empty.sql) を変更して、引き続き実行できる状態にしてください。そのうえで：

- `./build.sh run-empty` を実行して**0 行**の結果を観察し、[`expected-empty-output.txt`](./expected-empty-output.txt) と比較して本ツールチェーンの空結果の挙動を説明します。
- **一行**と**複数行**のフィクスチャを設計してそれぞれ実行し、`行数=` と EOF を確認します。
- 「`FETCH` のエラー」と「`SQLCODE 100`」の違いを説明し、正常にオープンしたカーソルがすべて `CLOSE` されることを確認します。

解答はありません。各コマンド、実際の出力、終了コード、および選んだフィールドやルールで 0 行、一行、複数行のケースをどう検証できるかを記録してください。
