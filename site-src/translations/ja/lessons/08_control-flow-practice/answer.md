---
_translated_from: lessons/08_control-flow-practice/answer.md
_translated_by: site-src/translation agent
---
# 第 08 課変更演習：解答例

この解答は `exercise.md` の2つの変更演習のみを扱います。それぞれ元の `lesson.cob` から始め、次のコマンドでコンパイル・実行します。

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_08 lesson.cob
./build/lesson_08
```

## 期首残高を変更する

`lesson.cob` の初期値を次のようにします。

```cobol
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 2000.00.
```

最初の2取引の処理後、残高は `2085.40` です。そのため、残高不足で拒否されていた第003取引の出金が受理されます。新しい残高は `2000.00 + 125.50 - 40.10 - 1500.00 = 585.40` です。負数の入金と未知のコードだけが拒否されます。

```text
処理件数=005
承認件数=003
拒否件数=002
最終残高=0000585.40
```

## 利用可能残高と同額の出金

`2100-LOAD-SAMPLE` の `WHEN 3` 分岐を次のように変更します。

```cobol
                   MOVE 1085.40 TO WS-TRANSACTION-AMOUNT
```

最初の2取引の後の残高は `1085.40` です。出金条件には `<= WS-CURRENT-BALANCE` を使っているため、同額でも受理され、残高はゼロになります。負数の入金と未知のコードは引き続き拒否されます。

```text
レコード=003 符号=W 金額=+01085.40
結果=ACCEPTED 理由=WITHDRAWAL
処理件数=005
承認件数=003
拒否件数=002
最終残高=0000000.00
```

この2つの演習では、期首状態が最終計算に与える影響と、出金額が現在残高と等しい場合の `<=` の境界動作を確認できます。
