# 独立した期待値（モジュール06）

`expected/*.txt`は`report.txt`全体の期待値です。DESIGNのフィールド契約と手計算例から定め、`check.py`がフィクスチャからaccepted/rejectedを独立に再構築してバイト単位で照合します。命名規則は`<group>-<case>.txt`です。

- `normal-valid.txt`：BALANCE = +1000 + 50 − 500 = **550**、READ=ACCEPT=3、REJECT=0。
- `boundary-empty.txt`：READ=ACCEPT=REJECT=0、BALANCE=0（空ファイルは有効）。
- `boundary-single.txt`：+1。
- `boundary-negative-balance.txt`：BALANCE = −9,999,999,999,999。
- `boundary-zero-balance.txt`：BALANCE = 0。
- `invalid-bad-account-id` / `bad-customer-id` / `unknown-currency` / `bad-sign` /
  `bad-balance` / `bad-date` / `date-mismatch` / `unknown-status`：各1件を拒否。理由はDESIGNの一覧を参照。BALANCE=0。
- `invalid-duplicate-id.txt`：受理1件 + 拒否1件、BALANCE=1000。
- `invalid-mixed.txt`：DESIGNの手計算例。READ=6、ACCEPT=2、REJECT=4、BALANCE=1100。

契約エラーフィクスチャ（`bad-layout`、`unsorted`、`short-record`、`long-record`、`no-trailing-lf`、`crlf`）には期待レポートが**ありません**。期待結果はRC8で公開なしです。ファイル欠落も同様に期待レポートはなく、RC12となります。

計算例（`invalid-mixed.dat`）：レコード1（+1000）とレコード6（+100）が受理され、残り4件はそれぞれ1つのフィールドエラーで拒否されます。BALANCE = 1000 + 100 = 1100、読込6件 = 受理2件 + 拒否4件。
