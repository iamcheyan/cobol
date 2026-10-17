---
_translated_from: lessons/29_embedded-sql/answer.md
_translated_by: site-src/translation agent
---

# 第 29 課の変更演習：参考解答

このファイルでは `exercise.md` の2つの変更演習だけに回答します。発展演習の回答はありません。どちらも元の `lesson.cob` から始め、変更のたびに次を実行します。

```sh
./build.sh run
echo $?
```

## 1. 2つ目の口座を検索する

`MAIN-PROCEDURE` 内の最初の代入を次のように変更します。

```cobol
               MOVE "A000000002" TO WS-LOOKUP-ACCOUNT
```

最初の出力行は次のようになります。

```text
検索=A000000002 状態=FOUND 顧客=C0001002 BALANCE=00875.00
```

`SELECT ... INTO` は `ACCOUNT_NO`、`CUSTOMER_ID`、`BALANCE` の各列を、それぞれ `WS-ACCOUNT`、`WS-CUSTOMER`、`WS-BALANCE` に書き込みます。`BALANCE` は `PIC 9(7)V99` なので、`875.00` はゼロ埋めされて `00875.00` と表示されます。2回目の `A99999999X` の検索は引き続き `NOT_FOUND` です。`接続=成功` / `切断=成功` は変わらず、終了コードは `0` です。

## 2. 2回目の検索を存在する口座に変更する

元のソースから始め、2つ目の代入を次のように変更します。

```cobol
               MOVE "A000000002" TO WS-LOOKUP-ACCOUNT
```

2回とも該当行が見つかります。標準出力は次のとおりです。

```text
接続=成功
検索=A000000001 状態=FOUND 顧客=C0001001 BALANCE=01250.75
検索=A000000002 状態=FOUND 顧客=C0001002 BALANCE=00875.00
切断=成功
```

2回目の検索の `SQLCODE` は `100`（該当行なし）から `0`（成功）に変わり、`WHEN 100` 分岐は実行されなくなります。終了コードは引き続き `0` です。

どちらの演習も同じ点を示しています。`SQLCODE = 100` は**業務上の結果**です。SQL自体に問題がなければ、バッチは正常に終了し `0` を返すべきです。`0` と `100` 以外の値だけが `WHEN OTHER` に進み、`状態=エラー SQLSTATE=` を表示して終了コード `1` で終わります。
