---
_translated_from: lessons/07_paragraphs/exercise.md
_translated_by: site-src/translation agent
---
# 第 07 課演習：段落

この演習では第 07 課で学んだ `PROCEDURE DIVISION` 内の名前付き段落、`PERFORM 段落名`、`MOVE`、`COMPUTE`、`DISPLAY`、`STOP RUN` のみを使います。入力データはすべてプログラム内に固定されています。

## 変更演習（解答例は `answer.md`）

2つの変更は重ねず、それぞれ元の `lesson.cob` から始めます。

1. 金額変更：`WS-OPENING-BALANCE` の初期値を `2000.00`、`WS-DEPOSIT` を `250.00` にし、`WS-WITHDRAWAL` は `40.10` のままにします。再コンパイルして実行し、新しい期末残高と最終残高を確認します。
2. 呼び出し順の変更：`0000-MAIN` で `PERFORM 2000-PROCESS` を `PERFORM 1000-INITIALIZE` より前に移し、ほかの文は変更しません。段階表示と最終残高を記録し、処理段落が設定した値が後の初期化で上書きされる理由を説明します。

各変更後に実行します。

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_07 lesson.cob
./build/lesson_07
```

解答例は、この2つの変更演習のみを扱う `answer.md` を参照してください。

## 学んだことを応用する（解答なし）

サンプル読込、取引コード検査、残高計算、集計出力の4つの名前付き段落を設計し、メイン段落から呼び出します。固定の `VALUE` データのみを使い、ファイル、表、ループ、`CALL` は使いません。

データ依存のある2つの段落（たとえば読込前に検査する、計算前に集計する）の順番を入れ替えます。出力の差と、どのような場合に依存関係が問題になるかを説明してください。固定形式の全ソース、コンパイルコマンド、順序変更前後の実出力と終了コードを提出します。解答はありません。
