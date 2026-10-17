---
_translated_from: lessons/09_group-items/exercise.md
_translated_by: site-src/translation agent
---
# 第 09 課演習：グループ項目

## 変更演習（解答は `answer.md`）

元の `lesson.cob` から始め、`WS-ACCOUNT-NUMBER` の初期値を `0001234567` から `0007654321` に変更します。

```cobol
             10 WS-ACCOUNT-NUMBER PIC X(10)
                VALUE "0007654321".
```

変更するのはこの `VALUE` のみです。`PIC`、レベル番号、宣言順はそのままにします。

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_09 lesson.cob && ./build/lesson_09
```

期待される差分：次の3行だけが変わります（3行目と、グループ出力それぞれの21〜30バイト）。残り7行と終了コード `0` は変わりません。

```text
口座番号=0007654321
グループデータ=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
外部記録=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
```

## 学んだことを応用する（解答なし）

支払人、受取人、支払情報の3つの `05` サブグループを持つ支払指示 `01` レコードを設計します。各グループに `VALUE` 付きの `10` 基本項目を複数配置します。少なくとも2つの項目名を別々のグループで再利用し、`OF` で参照先を修飾してください。同じ幅の `PIC X(n)` 受取項目を宣言し、グループ全体を `MOVE` して表示します。レコード長と各項目の位置を計算し、出力と照合します。

この課の階層データ項目と固定 `VALUE` のみを使い、`REDEFINES`、`OCCURS`、ファイル入力、データベースは追加しません。
