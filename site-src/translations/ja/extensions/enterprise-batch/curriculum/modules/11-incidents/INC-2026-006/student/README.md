# 事象 INC-2026-006：夜間バッチは全体成功したが、制御合計が上流の申告値と不一致

> 学習者用パッケージ。**根本原因は含みません**。調査順序：症状と影響範囲 → タイムライン → 仮説と証拠 → 最小再現 → 根本原因 → 修正／ロールバック → 復旧と再実行 → 再発防止。
> 段階式ヒントは [hints.md](hints.md) を参照してください。

## 1. 症状と影響範囲

- 営業日 `20261009` の夜間バッチは**全ノード COMPLETE、全体 RC0**で、`publish/as-found/` に正式公開済みです。
- 業務側で当日の**貸方合計**と**期末合計**を独立して再計算したところ、上流がファイルに添付した制御合計（Manifest の `control_*` 宣言）と**一致しません**でした。
- 影響範囲：**誤った制御合計と期末残高がすでに公開済み**です。この結果で下流が照合すると、上流と一致しない日次締め結果になります。
- 注意：今回の誤りは**内部では完全に整合**しています。JOB007 の内部照合はすべて通過しました。

## 2. タイムライン

| 時刻（UTC） | 事象 |
|---|---|
| 01:02:xx | JOB001–JOB009 がすべて COMPLETE rc=0 |
| — | JOB006 がコミット済み。JOB007 内部照合 PASS。JOB008 公開済み |
| 事後 | 業務側が上流の申告値と照合し、制御合計の不一致を発見 |

元の現場は `scene/console.txt`、`scene/logs/nightly.log`、`scene/logs/JOB007.log`、`scene/logs/JOB002.log`、`scene/published-control-report.txt`、`scene/MANIFEST`、`scene/scheduler-status.txt` を参照してください。

## 3. 提供資料一覧

| 資料 | 場所 |
|---|---|
| スケジューラ状態 | `scene/scheduler-status.txt` |
| 実行パラメータ | `scene/run.env` |
| 上流申告の control_* を含む元の受信Manifest | `scene/MANIFEST`、`input/MANIFEST` |
| 元入力（未変更） | `input/transaction.dat`、`input/account_seed.dat`、`input/customer_seed.dat` |
| JOBログ | `scene/logs/nightly.log`、`scene/logs/JOB0*.log` |
| DB台帳の現場 | `scene/ledger-victim.dat`、`scene/db-account.table` |
| 公開済み結果 | `scene/published-control-report.txt`、`scene/published-closing-master.dat` |
| 関連ソース | `scene/source/control.py`、`scene/source/M11MATCH.COB`、`scene/source/M11VAL.COB` |
| Copybook（凍結インターフェース） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 再現スクリプト | `run.sh` |

## 4. 再現

```bash
bash INC-2026-006/student/run.sh /tmp/INC-2026-006-scene /tmp/INC-2026-006-db
echo "rc=$?"                          # 元の RC
cat /tmp/INC-2026-006-scene/work/control/control.txt
grep '^control_' INC-2026-006/student/input/MANIFEST
```

## 5. 調査課題

1. 再現し、元の RC と「公開済み」という事実を確認します。
2. `input/transaction.dat` から貸方／借方合計と期末合計を独立して再計算し、`scene/published-control-report.txt` および上流申告値（Manifest の `control_*`）と三者を照合します。どの値が一致しませんか？
3. `scene/source/control.py` を読んでください。JOB007 は具体的にどの数値同士を比較していますか？入力 Manifest の制御合計を使っていますか？使っていない場合、「内部で整合」していることが「上流と照合済み」の代わりにならない理由は何ですか？
4. 差額の原因を判断します（あるレコードの金額自体が誤入力されたのか、プログラムの計算が誤っているのか）。該当レコードとオフセットの特定方法を示してください。
5. 最小修正（JOB007 に「上流が申告した制御合計との照合」を加え、不一致なら RC8 として公開しない）、復旧／再実行（データを訂正した実行、新しい業務バージョン）、再発防止を提示してください。

## 6. ヒント階層

[hints.md](hints.md) を参照してください。

## 7. プラグインとターミナルでの代替

```bash
cut -b41-54 INC-2026-006/student/input/transaction.dat
awk '{s+=substr($0,42,13)} END{print "sum amount="s}' \
  INC-2026-006/student/input/transaction.dat
rg -n 'control_|declared|MANIFEST|closing_total' \
   INC-2026-006/student/scene/source/control.py \
   INC-2026-006/student/input/MANIFEST
```
