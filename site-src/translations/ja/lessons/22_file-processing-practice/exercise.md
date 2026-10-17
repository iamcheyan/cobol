---
_translated_from: lessons/22_file-processing-practice/exercise.md
_translated_by: site-src/translation agent
---
# 第22課の練習：統合バッチの入力変更

第15～22課で学んだ内容だけを使います。順次ファイル入出力、固定幅レコード、`SORT` / `RELEASE` / `RETURN`、キー順照合、`EVALUATE` / `IF`、`FILE STATUS`、`RETURN-CODE` が対象です。

## 変更練習（参考解答は `answer.md`）

**フィクスチャの複製**を使い、リポジトリー内のファイルは変更しないでください。`OPEN OUTPUT` が結果ファイルを上書きするため、毎回新しい複製から実行します。`build/` 作業ディレクトリを準備します。

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_22 lesson.cob
cp accounts.txt transactions-unsorted.txt build/
cp build/transactions-unsorted.txt build/orig-transactions.txt   # 復元用の元データを保存
```

1. `build/transactions-unsorted.txt` で、口座番号 `A000000004` の取引を `A000000009` に変更します。他のフィールドは変えません。`(cd build && ./lesson_22)` を実行し、受け入れ、拒否、マスターのみの件数を確認して、両方の出力ファイルを1行ずつ照合します。
2. `build/orig-transactions.txt` から取引フィクスチャを復元します。`A000000007` の取引金額を9桁の `000000001` に変更します。実行後、金額による拒否が受け入れに変わることを確認し、件数と2つの出力ファイルを調べます。

制約：`lesson.cob` は変更しません。各入力レコード幅（取引20文字、マスター27文字）を保ってください。

各実行の標準出力全文と2つの結果ファイルを保存します。`SORT` によって入力行の順序が照合結果に影響しない理由と、`RELEASE` / `RETURN` を実行する手続きを説明します。件数の不変条件で両方の結果を確認してください。参考解答は `answer.md` にあります。

## 発展課題（解答なし）

マスターに存在する口座へ2件目の取引を追加し、一つのマスターレコードで同一口座の複数取引を照合するルールを設計します。出力順、残高更新、エラー処理を決め、同一口座の連続取引、口座欠落、マスターEOF、不正な金額をテストします。

ソース、コンパイル・実行コマンド、実際の標準出力、両方の結果ファイル内容を提出します。マスターを読む位置がこの課のプログラムとどう変わるか説明してください。全レコードを `OCCURS` テーブルに読み込まず、受け入れ／拒否ファイルの内容を省略しないでください。
