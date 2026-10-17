# 保守変更パッケージ：企業顧客区分を 1 桁から 2 桁へ

このディレクトリは `AUTHORING-STANDARD` 第 6 節が求める Legacy Maintenance 変更パッケージです。変更は**調査してから実施**します。以下の順序が作業順です。レビュー承認後にコードを変更してください。

| 順序 | ファイル | 成果物 |
|---:|---|---|
| 1 | [impact-investigation.md](impact-investigation.md) | 影響調査書 |
| 2 | [change-list.md](change-list.md) | 修正対象一覧 |
| 3 | [change-policy.md](change-policy.md) | 修正方針（レイアウト v1/v2、互換性、移行、ロールバック） |
| 4 | [test-cases.md](test-cases.md) | Test Case |
| 5 | [evidence-plan.md](evidence-plan.md) | Evidence 計画 |
| 6 | [copybooks/CAP-CUSTOMER-FEED-V2.CPY](copybooks/CAP-CUSTOMER-FEED-V2.CPY) | 固定インターフェース v2（32 バイト） |
| 7 | [regression/red-green.sh](regression/red-green.sh) | 変更前後の回帰（RED→GREEN） |

要件（原文）：**顧客区分を 1 桁から 2 桁に拡張する。**

## 変更対象：独立したバージョン管理対象の企業顧客レイアウト

変更対象は canonical CUSTOMER v1 の 27 バイトではありません。この固定インターフェースの第 27 バイトは**レコード状態 status**（A は有効 / D は停止）であり、顧客区分とは無関係です。本リポジトリでは**変更しません**（[curriculum/bank/README.md](../../../bank/README.md) と [BANK-SYSTEM.md 第 2 節](../../../../docs/curriculum/BANK-SYSTEM.md)を参照）。

顧客区分は**独立したバージョン管理対象の capstone 顧客 feed** `CAP-CUSTOMER-FEED` にあります。モジュール 04/07 の canonical 1778 バイト・175 フィールドの `ENTERPRISE-CUSTOMER` 大型レコードとは**意図的に別名**です。物理長とフィールドは互換性がなく、同名を共用するとバージョン名でレイアウトのずれが隠れます（モジュール 11 の実験用レイアウトも同様に別名です）。

| レイアウト | バージョン | 幅 | `CUSTOMER-CLASSIFICATION` | 値 |
|---|---|---:|---|---|
| CAP-CUSTOMER-FEED v1 | `001` | 31 B | `PIC X(1)` | `A`/`B`/`C`/`D` |
| CAP-CUSTOMER-FEED v2 | `002` | 32 B | `PIC X(2)` | `A1`/`B1`/`C1`/`D1` |

企業レイアウトは canonical CUSTOMER v1 の 27 バイト（第 1–27 バイト）を**内包**するため、第 27 バイトは引き続きレコード状態です。区分は後ろに追加される独立フィールドです。

参照インターフェース：`system/copybooks/CAP-CUSTOMER-FEED-V1.CPY`（31 バイト）と `system/copybooks/CAP-CUSTOMER-FEED-V2.CPY`（32 バイト）。canonical `system/copybooks/CUSTOMER-V1.CPY`（27 バイト、第 27 バイト = status）は変更しません。
