# 修正パッチ（企業顧客区分を 1 桁から 2 桁へ）

このディレクトリには実際に適用した修正を記録します。**修正は実行可能な参考実装としてすでに成果物に含まれている**ため、ここに長いコードを重複して掲載せず、変更点と再現方法を示します。

| 変更 | ファイル | 説明 |
|---|---|---|
| 新インターフェース | `system/copybooks/CAP-CUSTOMER-FEED-V2.CPY` | 32B 固定インターフェース（企業レイアウト v2） |
| 検証/正規化 | `system/cobol/CUSTV2.COB` | 31/32B を受理；v1→v2 アップグレード；BADSTATUS/BADCLASS/BADVERSION |
| 日次レポートの幅 guard | `system/cobol/NIGHTRPT.COB` | 宣言された layout と物理幅を照合 |
| 保存 | `system/lib/capdb.py` | customer.table に 32B を保存 |
| バイト guard | `system/lib/validate.py` | 企業レイアウトの幅 31/32 |

変更対象は**独立したバージョン管理対象の企業顧客レイアウト**（`CAP-CUSTOMER-FEED` v1/v2）であり、canonical CUSTOMER v1 の 27 バイトではありません。第 27 バイトの状態の意味は変わりません。

変更前の基準（RED）：`starter/CUSTV2.COB`（v1 のみ対応。v2 では RC12）。

RED→GREEN の再現方法：

```bash
bash curriculum/modules/12-capstone/maintenance/regression/red-green.sh /tmp/m12-rg
```

ロールバックは `maintenance/change-policy.md` 第 4 節を参照してください。
