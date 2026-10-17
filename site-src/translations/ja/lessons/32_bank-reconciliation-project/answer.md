---
_translated_from: lessons/32_bank-reconciliation-project/answer.md
_translated_by: site-src/translation agent
---

# 第 32 課修正演習：参考解答

このファイルでは `exercise.md` の番号付き修正演習 2 問だけに回答します。発展課題には回答しません。

## 1. A000000003 に 1.00 を入金する

`fixtures/transactions.txt` に次の行を追加します。

```text
A000000003D000000100
```

フィールドの内訳は、口座 `A000000003`、種別 `D`、金額 `000000100` セント、つまり 1.00 です。この口座の初期残高は 2.00 なので、記帳後の残高は 3.00 です。`./build.sh run` を実行すると、次の出力を確認できます。

```text
POSTED TX=006 ACCOUNT=A000000003 TYPE=D BALANCE=0000003.00
SYNC UPDATED ACCOUNT=A000000003 BALANCE=0000003.00
集計 口座=03 取引=006 記帳=003 拒否=003 更新=002 変更なし=001 挿入=000
```

`build/run/accepted.txt` に TX=006 が追加され、`build/run/account-report.txt` では A000000003 が `UPDATED` に分類されます。SQLite でこの口座の残高を確認すると 3.00 です。

## 2. 初期データベースから A000000005 を削除する

`schema.sql` の `INSERT INTO ACCOUNT_SNAPSHOT VALUES` リストから、次の行を削除します。

```sql
('A000000005', 'C0001005', 250.75)
```

`./build.sh run` を実行します。入力マスターには A000000005 が残っています。検索結果が 0 件なので、プログラムは顧客番号とマスター残高を挿入します。

```text
SYNC INSERTED ACCOUNT=A000000005 BALANCE=0000250.75
集計 口座=03 取引=005 記帳=002 拒否=003 更新=001 変更なし=001 挿入=001
```

続けて `./build.sh run-existing` を実行します。データベースに同じフィールドの口座が存在するため、結果は次のように変わります。

```text
SYNC UNCHANGED ACCOUNT=A000000005 BALANCE=0000250.75
集計 口座=03 取引=005 記帳=002 拒否=003 更新=001 変更なし=002 挿入=000
```

`run-existing` はデータベースの状態を保持し、`run` はデータベースを再作成します。この 2 つのコマンドで、初回の挿入と再実行時の冪等な分類を確認できます。
