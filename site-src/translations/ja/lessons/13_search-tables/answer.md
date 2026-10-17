---
_translated_from: lessons/13_search-tables/answer.md
_translated_by: site-src/translation agent
---
# 第 13 課変更演習：参考解答

この解答は `exercise.md` の2つの変更演習だけを扱い、「学んだことを応用する」の解答はありません。各変更は元の `lesson.cob` から独立して行います。コンパイルと実行のコマンド：

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_13 lesson.cob
./build/lesson_13
```

## 既存口座の残高を変更

`1000-LOAD-ACCOUNTS` を次のように変更します。

```cobol
           MOVE 600.00 TO WS-ACCOUNT-BALANCE(3)
```

2種類の検索は同じ口座に一致し、変更後の残高を返します。

```text
逐次検索=検出 口座=0002468101  残高=0000600.00
二分検索=検出 口座=0002468101  残高=0000600.00
```

## 最大の口座番号を追加

OCCURS の上限を5に変更します。

```cobol
          05 WS-ACCOUNT-ENTRY OCCURS 5 TIMES
             ASCENDING KEY IS WS-ACCOUNT-NUMBER
             INDEXED BY WS-ACCOUNT-IDX.
```

4件目の後に、重複せず既存のどのキーよりも大きいレコードを追加します。

```cobol
           MOVE "0009999999" TO WS-ACCOUNT-NUMBER(5)
           MOVE 75.00 TO WS-ACCOUNT-BALANCE(5).
```

2つ目の検索対象を `0009999999` に変更します。5件目を追加しても昇順とキーの一意性は保たれます。2種類の検索はどちらも次を出力します。

```text
逐次検索=検出 口座=0009999999  残高=0000075.00
二分検索=検出 口座=0009999999  残高=0000075.00
```

`ASCENDING KEY` 宣言だけを変更し、実際のデータ順を一致させなければ、`SEARCH ALL` の結果は信頼できません。宣言はテーブルを自動的に並べ替えるものではありません。
