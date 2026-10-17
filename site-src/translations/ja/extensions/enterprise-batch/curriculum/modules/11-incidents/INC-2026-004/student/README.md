# 事象 INC-2026-004：突合ノードが中止し、候補未生成

> 学習者用パッケージ。**根本原因は含みません**。調査の順序：症状と影響範囲 → タイムライン → 仮説と証拠 → 最小再現 → 根本原因 → 修正／ロールバック → 復旧と再実行 → 再発防止。段階式ヒントは[hints.md](hints.md)を参照してください。

## 1. 症状と影響範囲

- 営業日`20261009`の夜間バッチが**JOB005（順次突合と残高計算）**で中止し、終了コードは**RC8**でした。
- JOB003/JOB004はCOMPLETEでした。JOB005失敗後、JOB006以降は実行されず、公開もありません。
- 影響範囲：候補の期末Masterは生成されておらず、下流にデータはありません（誤結果の公開なし）。

## 2. タイムライン

| 時刻（UTC） | 事象 |
|---|---|
| 01:02:xx | JOB001–JOB004 COMPLETE rc=0 |
| 01:02:xx | JOB005 match start |
| 01:02:xx | JOB005 ERROR `match failed rc=8`、ログに順序逆転のメッセージ |
| 01:02:xx | ネットフロー停止、JOB006+ NOT_RUN、ロック解放 |

元の現場は`scene/console.txt`、`scene/logs/nightly.log`、`scene/logs/JOB005.log`、`scene/scheduler-status.txt`にあります。

## 3. 提供資料一覧

| 資料 | 場所 |
|---|---|
| スケジューラ状態 | `scene/scheduler-status.txt` |
| 実行パラメータ | `scene/run.env` |
| 元の受信Manifest | `scene/MANIFEST`、`input/MANIFEST` |
| 元入力（未変更） | `input/transaction.dat`、`input/account_seed.dat`、`input/customer_seed.dat` |
| JOBログ | `scene/logs/nightly.log`、`scene/logs/JOB0*.log` |
| 関連ソース | `scene/source/M11MATCH.COB`、`scene/source/job005-match.sh`、`scene/source/db.py` |
| Copybook（凍結インターフェース） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 再現スクリプト | `run.sh` |

## 4. 再現

```bash
bash INC-2026-004/student/run.sh /tmp/INC-2026-004-scene /tmp/INC-2026-004-db
echo "rc=$?"
cat /tmp/INC-2026-004-scene/logs/JOB005.log
cat -A /tmp/INC-2026-004-scene/work/db/account_master.dat   # 突合が実際に読み込んだMaster
```

## 5. 調査課題

1. 再現し、元RCと失敗ノードを記録します。
2. 突合は**順序依存**アルゴリズムで、2つの入力ストリームそれぞれにソート前提があります（Masterはaccount_id順、取引はaccount_id, sequence, transaction_id順）。`M11MATCH.COB`の読み取り部分を確認し、どちらのストリームの順序を検証して中止したか調べます。
3. `input/account_seed.dat`から各入力ストリームがそれぞれのソート前提を満たしているか独立検証します。違反があれば、最初の違反位置（口座値と前後のレコード）を示してください。
4. 根本原因をたどります：Seed → JOB004スナップショット → JOB005読み取りのどの段階で順序が失われた／壊れたのでしょうか？誤った候補を生成するのではなく、候補未生成で失敗したことが正しい理由も説明してください。
5. 復旧（どの境界で再ソート／再抽出するか）と再発防止策（上流抽出でのソート、境界での順序事前検証、スナップショットと元データの整合性確認）を提示します。

## 6. ヒント階層

[hints.md](hints.md)を参照してください。

## 7. プラグインとターミナルでの代替

```bash
cut -b1-10 INC-2026-004/student/input/account_seed.dat
sort -c -k1.1,1.10 INC-2026-004/student/input/account_seed.dat \
  && echo "sorted" || echo "NOT sorted"
rg -n 'out of order|PREV-ACCT|1000-READ-ACCOUNT' \
   INC-2026-004/student/scene/source/M11MATCH.COB
```
