# バージョン付きインターフェース（読み取り専用で再利用）

本モジュールでは企業顧客 Copybook を**複製しません**。異なる実装が二重に存在するのを防ぐためです。canonical 版は学習者向けパッケージに含まれ、次の場所にあります。

    curriculum/modules/07-matching/labs/05-large-record/copybooks/ENTERPRISE-CUSTOMER-V1.CPY

（リポジトリ内の講師用コピーは `instructor/modules/07/05-large-record/` にあり、両者の内容は一致します。）
モジュール04は `cobc -I <canonical copybook dir>`（`scripts/build.sh` を参照。講師用ツリーがあればそちらを優先し、なければ上記の配布可能なパスを使用）で、コンパイル時にこのファイルを `COPY` します。04.2ではさらに `COPY ... REPLACING` を使い、`CUSTOMER-CLASSIFICATION` を `X(1)` から `X(2)` に広げた V2 を**メモリ上で**派生させます。新しい Copybook ファイルは作成しません。

基本の銀行インターフェース（CUSTOMER v1=27B、ACCOUNT v1=47B、TRANSACTION v1=55B）は `curriculum/bank/copybooks/` を参照してください。本モジュールでは変更しません。
