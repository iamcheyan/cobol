# 事象 INC-2026-002：夜間バッチは全体成功したが、口座期末残高が業務台帳と一致しない

> 学習者用パッケージ。**根本原因は含みません**。調査の提出順序：症状と影響範囲 → タイムライン → 仮説と証拠 → 最小再現 → 根本原因 → 修正／ロールバック → 復旧と再実行 → 再発防止。段階式ヒントは[hints.md](hints.md)を参照してください。

## 1. 症状と影響範囲

- 営業日`20261009`の夜間バッチは**すべてのノードがCOMPLETE、全体RC0**で、`publish/as-found/`に正式公開済みです。
- 業務側の照合で、口座`0000000001`の期末残高が**2000**と判明しました。業務台帳の期待値は**1500**です。口座`0000000002`の期末150、`0000000003`の期末25は期待値と一致しています。
- 影響範囲：**誤った結果が下流へすでに公開されています**。「公開されていない」場合より危険です。この結果を使って下流で計上すると、実際の差額が生じます。

## 2. タイムライン

| 時刻（UTC） | 事象 |
|---|---|
| 01:02:xx | JOB001–JOB009すべてCOMPLETE rc=0 |
| — | JOB006がDB台帳とcommitを書き込み、JOB008が`publish/as-found/`を公開済み |
| 事後 | 業務側が独立再計算し、口座0000000001の期末に500の差を発見 |

元の現場は`scene/console.txt`、`scene/logs/nightly.log`、`scene/logs/JOB006.log`、`scene/ledger-victim.dat`、`scene/published-control-report.txt`、`scene/scheduler-status.txt`にあります。

## 3. 提供資料一覧

| 資料 | 場所 |
|---|---|
| スケジューラ状態 | `scene/scheduler-status.txt` |
| 実行パラメータ | `scene/run.env` |
| 元の受信Manifest | `scene/MANIFEST`、`input/MANIFEST` |
| 元入力（未変更） | `input/transaction.dat`、`input/account_seed.dat`、`input/customer_seed.dat` |
| JOBログ | `scene/logs/nightly.log`、`scene/logs/JOB0*.log` |
| DB台帳の現場（オフラインチェックポイント） | `scene/ledger-victim.dat`、`scene/db-account.table` |
| DB契約（DDL／SQL Log） | `scene/db-schema.sql`、`scene/sql-log.txt` |
| 公開済み結果 | `scene/published-control-report.txt`、`scene/published-closing-master.dat` |
| 関連ソース | `scene/source/db.py`、`scene/source/control.py`、`scene/source/M11MATCH.COB` |
| Copybook（凍結インターフェース） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 再現スクリプト | `run.sh` |

> DBについて：このコースのスナップショットは**実際のPostgreSQLに接続していません**。`lib/db.py`はオフラインファイルチェックポイントで、`db-schema.sql`には上流で宣言された契約（UNIQUE制約を含む）が記録されています。「実DBを検証済み」という結論はすべて未検証です。

## 4. 再現

```bash
bash INC-2026-002/student/run.sh /tmp/INC-2026-002-scene /tmp/INC-2026-002-db
echo "rc=$?"                 # 再現された元RC
cat /tmp/INC-2026-002-db/ledger.dat
cat /tmp/INC-2026-002-scene/work/control/control.txt
```

## 5. 調査課題

1. 再現し、元RCと「公開済み」という事実を確認します。
2. `input/transaction.dat`から口座`0000000001`の期末残高を独立計算し、`scene/published-closing-master.dat`と照合して差額の原因を示します。
3. `scene/db-schema.sql`に宣言された一意キーと`scene/ledger-victim.dat`の実データを照合します。契約の要件は何ですか？実際に何が起きましたか？プログラムはこの契約をコードに反映していますか？
4. 内部の保存確認（JOB007の自己照合）で、この差額を**検出できない**理由を説明します。
5. 最小修正、復旧／再実行（公開およびcommit済みの場合、どう訂正するか。業務訂正の実行と新しい業務版が必要か）、再発防止を提示します。

## 6. ヒント階層

[hints.md](hints.md)を参照してください。

## 7. プラグインとターミナルでの代替

```bash
cut -b1-26 INC-2026-002/student/input/transaction.dat | sort | uniq -d
sort INC-2026-002/student/scene/ledger-victim.dat | cut -d'|' -f1,2 | uniq -d
rg -n 'ledger_index|new_rows|in index|UNIQUE' \
   INC-2026-002/student/scene/source/db.py \
   INC-2026-002/student/scene/db-schema.sql
```
