# 企業顧客レコードのフィクスチャ

すべての `.dat` ファイルは [../scripts/generate-fixtures.py](../scripts/generate-fixtures.py) によって決定的に生成されます。各レコードは 1,778 バイト（`ENTERPRISE-CUSTOMER-V1`）で、LF や区切り文字はありません。SHA256 ハッシュは [SHA256SUMS](SHA256SUMS) を参照してください。

- `normal/enterprise-2.dat`：有効なレコード 2 件。
- `boundary/enterprise-1.dat`：1 件；`boundary/enterprise-empty.dat`：0 バイト。
- `invalid/`：長さ不一致（1783B）、version `009`、ABI 不一致、数字以外の key。

生成器は既知のカタログオフセットに少数のセンチネル値を配置するだけで、COBOL のコンパイルや実行は行いません。そのため、レイアウト検証の正解データ源にはなりません。レイアウトは `../scripts/check.py` の `ADDRESS OF` プローブで独立して計測します。
