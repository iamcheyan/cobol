---
_translated_from: lessons/23_copybooks/answer.md
_translated_by: site-src/translation agent
---
# 第23課の変更練習解答

[`exercise.md`](./exercise.md) の2つの変更練習を扱います。発展課題の解答は [`exercise.md`](./exercise.md) には含まれません。各練習はクリーンな作業用複製から開始します。コマンドは `build/work` で実行し（`-I copybooks` が必要）、最後に課のディレクトリへ戻って `build/` を削除します。

## 1. 共有口座番号を `PIC X(8)` にする

変更はCopybookの1行だけです。

```cobol
          05 WS-ACCOUNT-NUMBER PIC X(8).
```

両方の利用側を再コンパイルして実行します。

```sh
cd build/work
cobc -fsyntax-only -I copybooks lesson.cob                 # -Wallなし：出力なし、終了コード0
cobc -fsyntax-only -Wall -I copybooks lesson.cob           # -Wallあり：-Wtruncate警告
cobc -x -Wall -I copybooks -o lesson_23 lesson.cob         # 終了コード0、警告あり
cobc -x -Wall -I copybooks -o account_report_23 account_report_23.cob
./lesson_23
./account_report_23
```

両プログラムで変更したCopybook行を指す `-Wtruncate` 警告が出ます。終了コードは `0` です。

```text
lesson.cob:31: warning: value size exceeds data size [-Wtruncate]
lesson.cob:31: note: value size is 10 [-Wtruncate]
copybooks/ACCOUNT-REC.CPY:5: note: 'WS-ACCOUNT-NUMBER' defined here as PIC X(8) [-Wtruncate]
account_report_23.cob:16: warning: value size exceeds data size [-Wtruncate]
```

確認環境では `-Wall` / `-Wtruncate` なしだと `cobc -fsyntax-only` も `cobc -x` も警告を出しません。

`lesson_23` の出力では口座番号のサマリー行だけが変わります。

```text
入账成功 类型=D 金额=0000125.50
入账成功 类型=C 金额=0000025.25
入账拒绝 原因=INSUFFICIENT
入账拒绝 原因=BAD_TYPE
入账拒绝 原因=NO_ACCOUNT
账户号码=A0000000 客户号码=C0001001 余额=0001100.25
成功笔数=002 拒绝笔数=003
```

レポート出力は `口座レポート 口座番号=A0000000 顧客番号=C0001009 残高=0000020.00` です。

`WS-ACCOUNT-RECORD` は `8 + 8 + 9 = 25` バイトになります（`FUNCTION LENGTH` で25を測定）。第17、20、22課の27バイト口座インターフェースと一致せず、27バイトで分割する側では項目位置がずれます。

`MOVE "A000000001" TO WS-ACCOUNT-NUMBER` は8文字の宛先で右側が切り詰められ、`A0000000` になります。10文字の取引口座へ移すと後ろに空白2文字が付きます。`IF WS-TRANSACTION-ACCOUNT NOT = WS-ACCOUNT-NUMBER` では、COBOLが短い英数字項目を空白で補うため、`A0000000  ` と `A0000000` は等しく、記帳経路が変わりません。5件目の `A000000099` は異なるため引き続き `NO_ACCOUNT` です。残高と件数は変わりません。**件数が変わらなくてもデータは切り詰められ、27バイト契約は壊れます。**

## 2. 最後の取引を既知口座へ変更する

演習1とは別の新しい複製を作ります。`lesson.cob` の1行を変更します。

```cobol
           MOVE "A000000001" TO WS-TRANSACTION-ACCOUNT
```

メインだけを再コンパイルします。レポートプログラムとCopybookは変わらないため、既存のレポート実行ファイルを使えます。

```sh
cd build/work
cobc -x -Wall -I copybooks -o lesson_23 lesson.cob
./lesson_23
```

コンパイルに警告・エラーはなく、終了コードは `0` です。

```text
入账成功 类型=D 金额=0000125.50
入账成功 类型=C 金额=0000025.25
入账拒绝 原因=INSUFFICIENT
入账拒绝 原因=BAD_TYPE
入账成功 类型=D 金额=0000001.00
账户号码=A000000001 客户号码=C0001001 余额=0001101.25
成功笔数=003 拒绝笔数=002
```

5件目は共有口座と一致し、`NO_ACCOUNT` ではなくタイプ `D` の1.00を記帳します。残高は `1100.25 + 1.00 = 1101.25`。受け入れ3件、拒否2件で計5件です。レポート出力は `口座レポート 口座番号=A000000009 顧客番号=C0001009 残高=0000020.00` のままです。

今回はレイアウトを変えずメインの定数だけを変えたので `lesson.cob` だけ再コンパイルします。演習1は共有宣言の幅を変更したため、両利用側を再コンパイルし、外部固定長契約も影響を受けました。
