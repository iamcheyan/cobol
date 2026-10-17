---
_translated_from: lessons/07_paragraphs/answer.md
_translated_by: site-src/translation agent
---
# 第 07 課変更演習：解答例

この解答は `exercise.md` の2つの変更演習のみを扱います。それぞれ元の `lesson.cob` から始め、次のコマンドでコンパイル・実行します。

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_07 lesson.cob
./build/lesson_07
```

## 金額を変更する

初期値を次のようにします。

```cobol
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 2000.00.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 250.00.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
```

処理段落では `2000.00 + 250.00 - 40.10 = 2209.90` と計算されます。主な出力：

```text
期末残高=0002209.90
最終残高=0002209.90
```

段階の順序は、初期化、処理、最終集計のままです。

## 初期化と処理の順序を入れ替える

メイン段落で最初に `2000-PROCESS`、続いて `1000-INITIALIZE`、最後に `9000-FINALIZE` を実行します。主な出力順は次のように変わります。

```text
段階=PROCESS
期末残高=0001085.40
段階=INITIALIZE
段階=FINALIZE
最終残高=0000000.00
バッチ=COMPLETE
```

`WORKING-STORAGE` の項目は各段落で共有されます。処理段落が先に `1085.40` を設定し、その後初期化段落が同じ項目をゼロにするため、集計段落は `0000000.00` を読みます。この結果は段落間の呼び出し順への依存を示しています。
