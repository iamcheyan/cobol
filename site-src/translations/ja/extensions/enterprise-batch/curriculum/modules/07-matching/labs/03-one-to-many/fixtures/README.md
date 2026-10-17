# L2 合成入力

すべてASCIIテキストでLF終端です。ACCOUNT 47B、TRANSACTION 55B、REVERSAL-LINK 48B（いずれも幅にLFを含みません）。業務日は`20261009`固定です。`python3 scripts/generate-fixtures.py`で決定的に再生成できます。このscriptはデータを生成するのみで、口座突合や計上処理を実装しません。`SHA256SUMS`はすべての入力ファイルを対象とします。

| フィクスチャグループ | 目的 |
|---|---|
| normal | 同一口座の4取引、離れた位置の取消、当座貸越拒否、凍結口座、取引なし口座 |
| boundary-* | 空/取引なしファイル、単一金額上限、overflow、金額0、全体/口座累計13桁超 |
| business-* | 孤立口座、閉鎖口座、別口座取消、将来/未受理/重複原取引、取消金額不一致 |
| duplicate-id-cross-account | 遠く離れた別口座間の全体ID重複 |
| short-transaction / unsorted-transactions | 生長さと口座/sequence順序の誤り |
| invalid-link-* | 口座違い、sequence違い、ID文字不正、取引のない孤立関連 |

業務拒否フィクスチャは設計どおりRC4となり、拒否明細を公開します。インターフェース/順序/全体一意性のエラーはRC8となり、公開しません。runnerはこれらのsourceフィクスチャを書き換えてはいけません。
