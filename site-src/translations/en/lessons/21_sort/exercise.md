---
_translated_from: lessons/21_sort/exercise.md
_translated_by: site-src/translation agent
---
# 第21課の練習：SORTと入力手続き

この練習では第15～21課の内容だけを使います。順次ファイルの `SELECT` / `OPEN` / `READ` / `CLOSE`、`FILE STATUS`、`AT END`、`SORT`、`RELEASE` / `RETURN`、`PERFORM`、`DISPLAY` が対象です。

## 変更練習（解答例は `answer.md`）

2つとも**一時ディレクトリにあるフィクスチャ複製**だけを変更します。リポジトリー内の `accounts-unsorted.txt` は変更しないでください。

```sh
scratch=$(mktemp -d)
cp lesson.cob accounts-unsorted.txt "$scratch/"
cd "$scratch"
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o lesson_21 lesson.cob
```

1. 複製の先頭2行を入れ替えます。`./lesson_21` を実行し、出力が口座番号の昇順のままか、入力件数と出力件数が一致するか確認します。
2. 元のフィクスチャから作った複製の末尾に、口座番号 `A000000006`、顧客番号 `C0001006`、残高数字 `000000001` の27文字レコードを追加します。実行後、新しいレコードが最後に並び、入出力件数がともに `005` であることを確認します。

制約：`lesson.cob` は変更しません。追加する行は27文字にします。

各実行の標準出力全文を保存し、`RELEASE` と `RETURN` がどの手続きにあるか、それぞれの `AT END` がどこにあるか説明します。解答例は `answer.md` にあります。

## 発展課題（解答なし）

ソートキーに第2項目を追加し、口座番号の昇順、同一口座内では残高の降順に並べます。口座番号が同じで残高が異なるレコードを2件以上用意してください。変更後の `SORT ... ON ASCENDING KEY ...` 宣言と出力全文を記録し、キーを1つしか宣言しない場合に同一キーの順序へ依存してよいか、数例の観察だけでは結論できない理由も説明します。

ソース、コンパイル・実行コマンド、実際の出力、終了コードを提出してください。全件を `OCCURS` に読み込まず、`USING` / `GIVING` で2つの手続きを避けないでください。
