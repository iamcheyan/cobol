# Copybook：バージョン管理されたインターフェース

| Copybook | 契約 | 説明 |
|---|---|---|
| `CUSTOMER-V1.CPY` | CUSTOMER v1 = **27B** | 本モジュール08.3のスナップショットと突合のインターフェース（`customer_id 8 + name 10 + balance_demo 8 + status 1`） |

`ACCOUNT v1 = 47B`と`TRANSACTION v1 = 55B`のcanonical sourceは引き続き[`curriculum/bank/copybooks/`](../../../bank/copybooks/)（`ACCOUNT-V1.CPY`、`TRANSACTION-V1.CPY`）にあります。同名インターフェースの分岐を避けるため、ここでは**重複して管理しません**。`scripts/build.sh`はこのディレクトリとcanonicalディレクトリの両方を`cobc -I`に追加するため、プログラムから`COPY ACCOUNT-V1` / `COPY TRANSACTION-V1`を使用できます。

`APPLY.COB`は55Bの取引を数値オフセットで直接読みます（`account 1-10`、`transaction_id 11-26`、`date 27-34`、`sequence 35-40`、`direction 41`、`amount 42-54`、`status 55`）。このバイトレイアウトは`scripts/check.py`の固定幅アサーションと[DESIGN.md](../DESIGN.md)で凍結されています。
