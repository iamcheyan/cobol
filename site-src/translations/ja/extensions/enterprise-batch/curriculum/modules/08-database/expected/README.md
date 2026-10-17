# 期待結果：独立した計算

ここにある期待値は、現行プログラムの出力をコピーしたもの**ではありません**。業務契約、seed SQL、フィクスチャから独立に導出し、プログラムで検証します（作成基準の第4節を参照）。`scripts/check.py`内の実行可能なoracleは`db/seed.sql`と`fixtures/`から以下の期待値を再計算し、不一致があれば検証を失敗させます。

## Snapshot（08.3）

業務日`20261009`の`db/seed.sql`内DB顧客はC1/C2/C3/C5です。`customer_id`昇順でCUSTOMER v1 27B（`id(8)+name(10)+balance(8)+status(1)`）を組み立て、`snapshot-20261009.dat`に出力します（4件 × 27B + LF = 112B）。C4は業務日`20261010`のため、カーソルで正しく除外されます。

## 突合（08.3）

上流の`fixtures/customer-upstream-20261009.dat`にはC1/C2/C3/C9があります。C2の残高は260（DBでは250）、C9はファイルのみです。C5はDBのみです。キーで比較すると次の結果です。

| キー | 結果 |
|---|---|
| 00000001 | MATCH |
| 00000002 | FIELD-DIFF `balance_demo` 位置19-26、DB=00000250、上流=00000260 |
| 00000003 | MATCH |
| 00000005 | DB-ONLY |
| 00000009 | FILE-ONLY |

`snapshot-control.txt`：`DATABASE-ROWS=4 FILE-ROWS=4 MATCH=2 FIELD-DIFF=1 DB-ONLY=1
FILE-ONLY=1 DIFFS=3` → RC4。差異なしの上流`…-nodiff.dat`はDB snapshotとバイト単位で一致し、すべてMATCH、`DIFFS=0` → RC0です。

## 適用と冪等性（08.4）

期首残高（`db/seed.sql`）：A1=100、A2=200、A3=300。`fixtures/transactions-20261009.dat`の取引はA1 +50、A1 −20、A2 +70です。

- 初回commit：A1=100+50−20=**130**、A2=200+70=**270**、A3=**300**。ledger 3行、commit 1行 → `db-after-first.txt`。
- retry（同一業務日、新しいrun_id）：すべての一意キーが既存のため全件SKIP。上記の値は変わりません → `db-after-retry.txt`。`apply-retry.out`には`ALREADY-APPLIED=`と`DAY-ALREADY-COMMITTED=YES`が含まれます。
- rollbackモード：commitしません → 残高`100,200,300`、ledger 0行 → `db-after-rollback.txt`。
- 実行内重複`fixtures/transactions-dup-in-run.dat`（T…001を複製）：`23505` → 同一実行内重複 → RC8で全体をrollback → `db-after-dup.txt`（残高`100,200,300`、ledger 0行、commit 0件）。

`db-after-*.txt`はCOBOLの出力ではなく、**独立したpsql接続**（`docker exec … psql`）で読み取ります。そのためプログラムがRC0を返しても金額が誤っていれば検出できます。

## メタデータキー

`snapshot-meta.keys.txt`には必須キーが列挙されています。`CUTOFF`はDB時計から取得するため、存在と形式のみを確認し、バイト単位の比較はしません。
