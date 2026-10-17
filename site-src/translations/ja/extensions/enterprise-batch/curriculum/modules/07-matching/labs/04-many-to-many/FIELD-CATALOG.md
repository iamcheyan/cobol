# 07.5 ファイルフィールドカタログ

すべてのテキストファイルはASCII、LF終端で、幅にLFを含めません。CRLF、短/長行、最終LF欠落、制御文字は不可です。金額はJPY最小通貨単位の整数で、浮動小数点や小数円ではありません。既存の`ACCOUNT-V1.CPY` / `TRANSACTION-V1.CPY`は変更しません。新規layoutは独立して版管理し、BANK-SYSTEMの教材用27B CUSTOMER v1レコードを再定義しません。

## CUSTOMER-SNAPSHOT v1（36B）

一意キーはcustomer_idで、厳密昇順、顧客あたり最大1行です。このオフラインファイルはモジュール08の実DB抽出前に使う固定seed snapshotであり、DB接続や一貫読込が実装済みであることを意味しません。

| バイト | 幅 | フィールド | 規則/用途 |
|---:|---:|---|---|
| 1–8 | 8 | customer_id | ASCII数字、空でなく一意。ACCOUNT customer_idに対応 |
| 9–16 | 8 | snapshot_business_date | Gregorian有効YYYYMMDD、JOB日と一致 |
| 17–19 | 3 | layout_version | `001`のみ |
| 20 | 1 | customer_status | `A`有効、`D`停止で業務隔離 |
| 21–23 | 3 | max_account_count | ASCII数字、顧客関連口座数上限。A/F/CすべてのMasterを数える |
| 24–36 | 13 | max_customer_balance | ASCII数字、顧客期末残高合計上限、JPY整数 |

物理幅は36Bです。COBOL配置は`copybooks/CUSTOMER-SNAPSHOT-V1.CPY`で定義し、compile-time `LENGTH OF`とcheckerで合計幅を測定します。

## PREVIOUS-DAY v1（39B）

一意キーはcustomer_idで、厳密昇順、顧客あたり最大1行です。日付はJOB業務日の直前にあたる実在Gregorian暦日です。週末や日本の銀行休日を飛ばしません。前日summaryは関連口座すべて（status A/F/C全て）を集計し、口座ごとに重複適用してはいけません。

| バイト | 幅 | フィールド | 規則/用途 |
|---:|---:|---|---|
| 1–8 | 8 | customer_id | ASCII数字、空でなく一意 |
| 9–16 | 8 | previous_business_date | 有効Gregorian YYYYMMDD、JOB日の直前の暦日 |
| 17–19 | 3 | layout_version | `001`のみ |
| 20–25 | 6 | account_count | ASCII数字。A/F/C全statusを含む前日顧客関連口座数 |
| 26 | 1 | closing_sign | `+`または`-`。総残高が負の場合のみマイナス |
| 27–39 | 13 | closing_total | ASCII数字、前日顧客期末残高合計 |

物理幅は39Bです。COBOL配置は`copybooks/PREVIOUS-DAY-V1.CPY`で定義し、compile-time `LENGTH OF`とcheckerで合計幅を測定します。

## 4つの業務streamとsource

| Stream | 上流interface | 順序/件数 | 本段階での役割 |
|---|---|---|---|
| ACCOUNT | canonical v1 47B | account_id一意昇順。顧客ごとに複数口座可、customer_idはaccount_idと単調とは限らない | 現在期首と顧客関連付け。各口座をL2候補masterと照合 |
| TRANSACTION | canonical v1 55B + 独立REVERSAL-LINK v1 | account/sequence/id厳密順、id全体一意、口座ごと0..N件 | 生取引は先に実L2へ渡し、L3はL2 acceptedを消費してL2 rejects/controlを保持 |
| CUSTOMER-SNAPSHOT | 本課v1 36B | customer_id一意昇順 | status、口座数上限、期末合計上限。オフラインDB snapshot seed |
| PREVIOUS-DAY | 本課v1 39B | customer_id一意昇順 | 前日顧客口座数とclosing合計のcontrol |
