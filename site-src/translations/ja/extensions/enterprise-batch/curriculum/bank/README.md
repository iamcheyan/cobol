# 銀行 canonical インターフェース（単一の定義元）

このディレクトリには、すべてのモジュールで共有する**凍結された銀行インターフェース**のcanonical定義があります。すべての実験、課程、JOBはここにある定義を再利用するか、バージョンを指定して参照してください。**同名インターフェースを個別に複製して差異を生じさせてはいけません。**フィールドの意味とバイトレイアウトは[BANK-SYSTEM.md](../../docs/curriculum/BANK-SYSTEM.md)に従います。

| ファイル | レコード | 幅 | 説明 |
|---|---|---:|---|
| [ACCOUNT-V1.CPY](copybooks/ACCOUNT-V1.CPY) | ACCOUNT v1 | 47 B | 口座マスター；account_id/customer/currency/sign/opening_balance/status/date/version |
| [TRANSACTION-V1.CPY](copybooks/TRANSACTION-V1.CPY) | TRANSACTION v1 | 55 B | 当日取引；account/txid/date/sequence/direction/amount/status |
| [CUSTOMER-V1.CPY](copybooks/CUSTOMER-V1.CPY) | CUSTOMER v1 | 27 B | 顧客の基礎学習オブジェクト；id/name/balance_demo/**status** |

テキストの固定長インターフェースはASCIIを使用し、各論理レコードの後にLFを付けます。LFはレコード長に含めません。金額は明示された最小通貨単位の整数です。日付は`YYYYMMDD`形式で、課程のカレンダーに基づいて検証します。

## 「顧客区分を1桁から2桁へ」保守について

CUSTOMER v1の27バイト目は**レコード状態status**（Aは有効 / Dは無効）であり、顧客区分（distinction/classification）**ではありません**。BANK-SYSTEMの第2節で、既存の27バイトCUSTOMERには顧客区分フィールドが**ない**ことを明示しています。保守課では、まず**独立したバージョン管理対象の企業顧客レイアウトと、その1桁の基準を定義**し、27バイトの学習用インターフェースを維持して両者の関係を説明してから、v2への移行を行ってください。**statusフィールドを顧客区分として扱ってはいけません。**

このリポジトリには、モジュール07 L4の`ENTERPRISE-CUSTOMER-V1`（1778バイト固定バイナリ）という正当な先例があります。v1の`CUSTOMER-CLASSIFICATION`は`PIC X(1)`（A/B/C/D）で、v2では`PIC X(2)`（A1/B1/C1/D1）に拡張され、レイアウトのバージョンは001→002となっています。モジュール11/12の顧客区分保守演習では、この例のような**独立してバージョン管理された企業レイアウト**を参照してください（同じ命名/バージョン規約を再利用または踏襲できます）。CUSTOMER v1の27バイト目を書き換えてはいけません。

## インタープリター実測の概要（Linux x86-64 / GnuCOBOL 3.2.0）

- `ACCOUNT-V1` = 47 B、`TRANSACTION-V1` = 55 B、`CUSTOMER-V1` = 27 B（`LENGTH OF`で実測）。
- PIC COMPはビッグエンディアン、COMP-5はネイティブのリトルエンディアンと実測されました。COMP-3は各半バイトを検証し、C/Dの符号のみ受け付けます。バイナリ/Packedの生バイトをテキストとして解析してはいけません。
