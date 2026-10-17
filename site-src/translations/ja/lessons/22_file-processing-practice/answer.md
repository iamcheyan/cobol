---
_translated_from: lessons/22_file-processing-practice/answer.md
_translated_by: site-src/translation agent
---
# 第22課の変更練習解答

`exercise.md` の2つの変更練習だけを扱います。発展課題の解答はありません。各実行でフィクスチャ複製から始めます。

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_22 lesson.cob
cp accounts.txt transactions-unsorted.txt build/
cp build/transactions-unsorted.txt build/orig-transactions.txt
```

## 1. 未照合取引を口座 A000000009 に変更する

`build/transactions-unsorted.txt` の次の行を

```text
A000000004D000007500
```

次の内容に置き換えます。

```text
A000000009D000007500
```

`(cd build && ./lesson_22)` を実行します。この取引はマスターの `A000000009` と一致し、フィールドも正しいため、受け入れになります。マスターレコードが照合され、マスターのみの件数は0になります。標準出力：

```text
ACCEPTED 账号=A000000001
ACCEPTED 账号=A000000003
ACCEPTED 账号=A000000005
被拒绝 账号=A000000006 REASON=NO_ACCOUNT
被拒绝 账号=A000000007 REASON=BAD_AMOUNT
ACCEPTED 账号=A000000009
输入记录数=006 排序记录数=006
接受记录数=004
拒绝记录数=002 MASTER_ONLY账户记录数=000
```

`build/accepted.txt` は4行になり、次の行が含まれます。

```text
A000000009C0001009D000007500
```

`build/rejected.txt` は2件です。`A000000006...NO_ACCOUNT` と `A000000007...BAD_AMOUNT` が残ります。

不変条件を確認します。`受け入れ 4 + 拒否 2 = 入力 6`、`照合済みマスター 4 + マスターのみ 0 = マスター 5`。マスターなしの拒否は1件なので、`6 − 1 = 5` 件のマスターが照合されています。終了コード：`0`。

## 2. 口座 A000000007 の金額を修正する

まず `build/orig-transactions.txt` から取引フィクスチャを復元します。最後の取引を

```text
A000000007D00000X001
```

から

```text
A000000007D000000001
```

へ変更します。

9文字の金額が数字だけになりました。取引はマスターの `A000000007` に一致し、受け入れファイルへ入ります。金額は `0.01` です。このプログラムは形式を検証して出力しますが、**マスター残高は更新しません**。標準出力：

```text
ACCEPTED 账号=A000000001
ACCEPTED 账号=A000000003
被拒绝 账号=A000000004 REASON=NO_ACCOUNT
ACCEPTED 账号=A000000005
被拒绝 账号=A000000006 REASON=NO_ACCOUNT
ACCEPTED 账号=A000000007
MASTER_ONLY账户 账号=A000000009
输入记录数=006 排序记录数=006
接受记录数=004
拒绝记录数=002 MASTER_ONLY账户记录数=001
```

`build/accepted.txt` には次の行が追加されます。

```text
A000000007C0001007D000000001
```

`build/rejected.txt` には `A000000004` と `A000000006` の `NO_ACCOUNT` 2件が残ります。

不変条件は `受け入れ 4 + 拒否 2 = 入力 6`、`照合済みマスター 4 + マスターのみ 1 = マスター 5` です。終了コード：`0`。

どちらの練習でも、入力ファイルの物理的な行順は照合結果に影響しません。`SORT` が先に口座番号順へ並べ、現在のキーを比較するためです。変わるのはレコード内容で、処理順ではありません。入力手続きの `RELEASE` がレコードをソートへ渡し、出力手続きの `RETURN` が整列済みレコードを取得します。
