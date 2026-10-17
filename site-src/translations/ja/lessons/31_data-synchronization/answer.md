---
_translated_from: lessons/31_data-synchronization/answer.md
_translated_by: site-src/translation agent
---

# 第 31 課修正演習：参考解答

このファイルでは [`exercise.md`](./exercise.md) の 2 つの修正演習だけに回答し、「発展演習」の解答は扱いません。どちらも元の `snapshot.txt` と `schema.sql` から始め、`lesson.cob` は変更しません。変更後、次を実行します。

```sh
./build.sh run
echo $?
cat differences.txt
sqlite3 -header build/lesson31.db "SELECT ACCOUNT_NO, FILE_STATUS, FILE_CUSTOMER, FILE_BALANCE FROM RECON_RESULT;"
```

以下の出力はすべて、本ワークスペースで実際に実行した結果です。

## 1. 2 行目の金額を `000087500` に変更する

変更箇所：`snapshot.txt` 2 行目の第 19～27 列。

```text
A000000001C0001001000125075
A000000002C0001002000087500
A000000003C0001003000002500
```

標準出力の期待値（6 行、終了コード `0`）：

```text
接続=成功
MATCH ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=01250.75
MATCH ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00875.00
FILE_ONLY ACCOUNT=A000000003 CUSTOMER=C0001003 BALANCE=00025.00
集計 行数=003 一致=002 変更=000 ファイルのみ=001
切断=成功
```

`differences.txt` の期待値（1 行のみ。ベースラインの `CHANGED` 行がなくなる）：

```text
FILE_ONLY ACCOUNT=A000000003 CUSTOMER=C0001003 BALANCE=00025.00
```

`RECON_RESULT` は引き続き 3 行です。`A000000001|MATCH`、`A000000002|MATCH`、`A000000003|FILE_ONLY` です。

理由：ファイル側の `000087500` 分は `87,500 / 100 = 875.00` 元で、`ACCOUNT_SNAPSHOT` の `A000000002` の金額と一致します。顧客番号も一致するため、`3100-LOOKUP-ACCOUNT` にある `IF WS-CUSTOMER = WS-DB-CUSTOMER AND WS-BALANCE = WS-DB-BALANCE` が成立し、分類が `CHANGED` から `MATCH` に変わります。件数不変条件も変わります。`一致 2 + 変更 0 + ファイルのみ 1 = ファイル行数 3` で、`differences.txt` の行数は `1 = 変更 + ファイルのみ` となります。

## 2. `ACCOUNT_SNAPSHOT` に口座を 2 件追加する

変更箇所：`schema.sql` の `INSERT INTO ACCOUNT_SNAPSHOT VALUES` に続く値リスト（直前の行にカンマを追加し、最後の行をセミコロンで終えます）。

```sql
INSERT INTO ACCOUNT_SNAPSHOT VALUES
    ('A000000001', 'C0001001', 1250.75),
    ('A000000002', 'C0001002', 875.00),
    ('A000000003', 'C0001003', 25.00),
    ('A000000099', 'C0001099', 500.00);
```

標準出力の期待値（6 行、終了コード `0`）：

```text
接続=成功
MATCH ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=01250.75
CHANGED ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00100.00
MATCH ACCOUNT=A000000003 CUSTOMER=C0001003 BALANCE=00025.00
集計 行数=003 一致=002 変更=001 ファイルのみ=000
切断=成功
```

`differences.txt` の期待値（1 行のみ、改行を含め 62 バイト）：

```text
CHANGED ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00100.00
```

データベースの状態：`RECON_RESULT` は 3 行（`MATCH`、`CHANGED`、`MATCH`）、`ACCOUNT_SNAPSHOT` は 4 行です。`A000000099` はスナップショットテーブルに存在しますが、標準出力、差異ファイル、`RECON_RESULT` のどこにも**現れません**。

理由：`A000000003` をスナップショットテーブルに追加すると、3 回目の検索結果が `SQLCODE = 100` から `0` に変わります。顧客番号 `C0001003` と金額 `25.00` はファイル側と一致するため、このキーの分類は `FILE_ONLY` から `MATCH` に変わり、`ファイルのみ` の件数は 0 になります。`A000000099` はファイルに対応する行がありません。プログラムはファイル側だけを走査し、ファイルのキーごとにデータベースを検索するため、データベースのみの口座の結果は作りません。これが本課に `DB_ONLY` 分類がない理由であり、4 つ目の件数不変条件の説明でもあります。データベースのみの口座数は `4 − (一致 2 + 変更 1) = 1` ですが、この口座はどの出力にも現れません。

## 2 つの演習を確認する方法

各演習で、次の 4 点をすべて確認します。標準出力にある 3 分類と件数、`differences.txt` の行数と内容、`RECON_RESULT` の行数と分類、プロセスの終了コード（どちらの演習も `0` が期待値）。集計数字だけでは「あるレコードがどこへ行ったか」は分かりません。差異ファイルだけでは、結果テーブルの行が欠けていることを見つけられません。
