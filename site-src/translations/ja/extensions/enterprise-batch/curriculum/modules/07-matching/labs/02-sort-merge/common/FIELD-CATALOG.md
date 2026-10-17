# TRANSACTION v1 固定フィールドカタログ

正規source：[TRANSACTION-V1.CPY](../../../../../bank/copybooks/TRANSACTION-V1.CPY)。SORT/MERGEのSDレコードはこの版を直接`COPY`します。コース内に別コピーや独自フィールド定義を作ってはいけません。入出力はASCII 55バイトで、行末LFは幅に含みません。

| バイト（1始まり） | フィールド | PIC | 契約 |
|---|---|---|---|
| 1–10 | TX-ACCOUNT-ID | X(10) | ASCII数字 |
| 11–26 | TRANSACTION-ID | X(16) | ASCII `A-Z` / `0-9`、全体で一意 |
| 27–34 | TRANSACTION-DATE | X(8) | JOB業務日と一致するGregorian有効日付 |
| 35–40 | TRANSACTION-SEQUENCE | X(6) | ASCII数字、ソートキー第2要素 |
| 41 | TRANSACTION-DIRECTION | X | `C`または`D` |
| 42–54 | TRANSACTION-AMOUNT | X(13) | ASCII数字、0は有効。下流業務規則で分類 |
| 55 | TRANSACTION-STATUS | X | `N`のみ。取消関係は独立REVERSAL-LINK v1で表現 |

全ソートキーは(account 1–10, sequence 35–40, ID 11–26)で、各要素を昇順にします。MERGE sourceは厳密昇順です。同じ口座/sequenceでもIDが異なれば有効です。
