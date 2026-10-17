---
_translated_from: lessons/21_sort/exercise.md
_translated_by: site-src/translation agent
---
# 第21課の練習：SORTと入力手続き

この練習は第15～21課の範囲だけを使います。順次ファイルの `SELECT` / `OPEN` / `READ` / `CLOSE`、`FILE STATUS`、`AT END`、`SORT` と `RELEASE` / `RETURN`、`PERFORM`、`DISPLAY` です。

## 変更練習（回答例は answer.md に掲載）

2つとも**一時ディレクトリに置いたフィクスチャ複製**だけを変更します。リポジトリーの `accounts-unsorted.txt` は変更しないでください。まず作業ディレクトリを用意します。

```sh
scratch=$(mktemp -d)
cp lesson.cob accounts-unsorted.txt "$scratch/"
cd "$scratch"
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o lesson_21 lesson.cob
```

1. 複製の先頭2行を入れ替えます。`./lesson_21` を実行し、出力が口座番号の昇順のままか、入力件数と出力件数が一致するかを確認します。
2. 元のフィクスチャから始め、複製の末尾に27文字のレコードを追加します。口座番号 `A000000006`、顧客番号 `C0001006`、残高数字 `000000001` です。実行後、新しいレコードが最後に並び、入出力件数がともに `005` になることを確認します。

制約：`lesson.cob` は変更しません。追加する行は27文字でなければなりません。

各実行の標準出力全文を保存し、`RELEASE` と `RETURN` がそれぞれどの手続きで実行され、`AT END` がどこにあるかを示してください。回答例は answer.md にあります。

## 発展課題（回答なし）

ソートキーに第2項目を追加し、口座番号の昇順、同じ口座では残高の降順に並べます。口座番号が同じで残高が異なるレコードを2件以上用意し、変更後の `SORT ... ON ASCENDING KEY ...` 宣言と出力全文を記録してください。キーを1つしか宣言しない場合、同じキーのレコード順序に依存してよいか、数例を見ただけでは結論できない理由も説明します。

ソース、コンパイル・実行コマンド、実際の出力、終了コードを提出してください。全件を `OCCURS` に読み込まず、`USING` / `GIVING` でこの課の2つの手続きを避けないこと。
