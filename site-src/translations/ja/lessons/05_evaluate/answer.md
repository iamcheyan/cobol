---
_translated_from: lessons/05_evaluate/answer.md
_translated_by: site-src/translation agent
---

# 第 05 課 修正演習 参考解答

`exercise.md` の修正演習にのみ回答し、発展演習（支払方法の分類）には答えません。ベースラインはこの課の元の `lesson.cob` です。

## 変更箇所

`EVALUATE WS-TRANSACTION-CODE` の `WHEN "T"` 分岐の `DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"` のあと、`WHEN OTHER` の前に次を挿入します。

```cobol
               WHEN "F"
                   DISPLAY "分類=FEE"
                   DISPLAY "処理=CHARGE_FEE"
```

データ項目の初期値も `F` に変更します。

```cobol
       01 WS-TRANSACTION-CODE PIC X VALUE "F".
```

他の分岐、`WHEN OTHER` の出力、固定書式はいずれも変更しません。変更後の `EVALUATE` 段落は次のようになります。

```cobol
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   DISPLAY "分類=DEPOSIT"
                   DISPLAY "処理=ADD_TO_ACCOUNT"
               WHEN "W"
                   DISPLAY "分類=WITHDRAWAL"
                   DISPLAY "処理=SUBTRACT_FROM_ACCOUNT"
               WHEN "T"
                   DISPLAY "分類=TRANSFER"
                   DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"
               WHEN "F"
                   DISPLAY "分類=FEE"
                   DISPLAY "処理=CHARGE_FEE"
               WHEN OTHER
                   DISPLAY "分類=UNKNOWN"
                   DISPLAY "処理=REJECT_FOR_REVIEW"
           END-EVALUATE
```

## 実行

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_05 lesson.cob
./build/lesson_05
echo $?
```

## 期待される出力

```text
取引参照番号=TXN-00000001
取引コード=F
分類=FEE
処理=CHARGE_FEE
```

`cobc -fsyntax-only` とコンパイルの終了コードは `0` で診断なし、プロセスの終了コードも `0` です。第 1 行の参照番号が変わらないのは、このフィールドを変更していないためです。

## 境界チェック（`WHEN OTHER` を変更していないことの確認）

追加した `WHEN "F"` 分岐を残したまま、初期値を `X` に戻して再コンパイル・実行します。

```text
取引参照番号=TXN-00000001
取引コード=X
分類=UNKNOWN
処理=REJECT_FOR_REVIEW
```

`X` は `D` / `W` / `T` / `F` のいずれの値とも一致しないため、やはり `WHEN OTHER` がフォールバックを担当します。これにより、追加した分岐は `F` にしか効かず、未知コード経路を壊していないことが分かります。`REJECT_FOR_REVIEW` はプログラムが出力する処理ラベルにすぎず、この課では実際の拒否フローを実装していない点に注意してください。
