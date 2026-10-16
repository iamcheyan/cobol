---
_translated_from: lessons/01_hello-cobol/answer.md
_translated_by: site-src/translation agent
---

# 第 01 課 修正演習 参考解答

この解答は `exercise.md` の修正演習のみに対応し、発展演習の解答は含みません。

元の `lesson.cob` から、ソース中の次の行を変更します。

```cobol
           DISPLAY "こんにちは、COBOL！".
```

を、次のように変更します。

```cobol
           DISPLAY "こんにちは、バッチチーム！".
```

変更するのはこの文字列リテラルだけで、プログラム構造と固定書式はそのままにします。実行してください。

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_01 lesson.cob
./build/lesson_01
```

期待される出力：

```text
こんにちは、バッチチーム！
```

プロセスの終了コードは引き続き `0`、`cobc -fsyntax-only` は `0` を返し、診断メッセージは出ません。
