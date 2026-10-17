---
_translated_from: lessons/15_sequential-file-read/answer.md
_translated_by: site-src/translation agent
---
# 第 15 課変更演習：参考解答

この解答は [`exercise.md`](./exercise.md) の2つの変更演習だけを扱います。「学んだことを応用する」の解答はありません。2問は同じ一時実行ディレクトリーを共用し、繰り返しリセットできます。

```sh
cd lessons/15_sequential-file-read
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -x -Wall -o "$scratch_dir/lesson_15" lesson.cob
cp transactions.txt "$scratch_dir/"
```

## 1. 5件目のレコードを追加

```sh
printf 'DAY-20261013|TXN-000005|D|0001234567|10.00\n' >> "$scratch_dir/transactions.txt"
wc -lc "$scratch_dir/transactions.txt"        # 5行、238バイト = 195 + 42 + 1
( cd "$scratch_dir" && ./lesson_15 ); echo $? # 終了コード 0
```

想定される標準出力（追加行が1つ、件数変更が1つ）：

```text
オープン=OK
レコード=DAY-20261013|TXN-000001|D|0001234567|125.50
レコード=DAY-20261013|TXN-000002|T|0001234567|0007654321|40.00
レコード=DAY-20261013|TXN-000003|D|0002468101|75.00
レコード=DAY-20261013|TXN-000004|T|0007654321|0009999999|20.00
レコード=DAY-20261013|TXN-000005|D|0001234567|10.00
EOF=はい レコード数=05
クローズ=OK
```

追加した行が5件目の正常読み込みレコードとなり、次の `READ` で EOF に到達するため、件数は `04` から `05` に変わります。

リセットするには、`transactions.txt` を一時コピーに再度コピーして上書きするか、新しい `mktemp -d` ディレクトリーを作ります。このプログラムはテキストを読むだけです。行に `D` や金額が書かれていても残高や口座データは変更しません。

## 2. 空ファイルを読み込む

```sh
: > "$scratch_dir/transactions.txt"
( cd "$scratch_dir" && ./lesson_15 ); echo $? # 終了コード 0
```

想定される標準出力：

```text
オープン=OK
EOF=はい レコード数=00
クローズ=OK
```

空ファイルも正常に開けるため、`オープン=FAILED` は表示されません。最初の `READ` が直ちに `AT END` に進み、`レコード=` 行は出ず、件数は `00`、クローズも成功します。別の結果も確認する場合は、追加で `rm -f "$scratch_dir/transactions.txt"` を実行できます。その場合は `オープン=FAILED STATUS=35` が表示され、終了コードは `1` です。このケースは本課 README の「実行して確認」で説明されており、今回の演習解答には含みません。
