# 事象 INC-2026-007：検証ノードが中止し、当日公開なし

> 学習者用パッケージ。**根本原因は含みません**。「症状と影響範囲 → タイムライン → 仮説と証拠 → 最小再現 → 根本原因 → 修正／ロールバック → 復旧と再実行 → 再発防止」の順で調査し、証拠を `evidence/` に提出してください。段階式ヒントは [hints.md](hints.md) を参照してください。

## 1. 症状と影響範囲

- 営業日 `20261009` の夜間バッチは **JOB002（検証）** で中止し、終了コードは **RC8** でした。
- JOB001（受信／Manifest 検証）は COMPLETE です。受信ファイルと Manifest の申告は**一致**しているため、問題は「未受信／途中切れ」ではなく、検証で内容が契約を満たさないと判明したことです。
- ネットフローは停止しました。JOB003 以降は**未実行**で、`publish/` に今回の公開ディレクトリはなく、CURRENT ポインターも更新されていません。
- 影響範囲：当日の下流ファイルはすべて欠落しています。下流には誤データが渡っていません（公開なし）。

## 2. タイムライン

| 時刻（UTC） | 事象 |
|---|---|
| 01:02:08 | スケジューラが `run_id=as-found` を開始、JOB001 受信 COMPLETE |
| 01:02:08 | JOB002 検証 start |
| 01:02:09 | JOB002 検証 ERROR `validator failed rc=8` |
| 01:02:09 | ネットフロー停止、JOB003 以降 NOT_RUN、ロック解放 |

元の現場は `scene/console.txt`、`scene/logs/nightly.log`、`scene/logs/JOB002.log`、`scene/scheduler-status.txt` を参照してください。

## 3. 提供資料一覧

| 資料 | 場所 |
|---|---|
| スケジューラ状態 | `scene/scheduler-status.txt` |
| 実行パラメータ（営業日/run_id/パス） | `scene/run.env` |
| 元の受信Manifest | `scene/MANIFEST`、`input/MANIFEST` |
| 元入力（未変更） | `input/transaction.dat`、`input/account_seed.dat`、`input/customer_seed.dat` |
| JOBログ | `scene/logs/nightly.log`、`scene/logs/JOB0*.log` |
| 関連ソース | `scene/source/M11VAL.COB`、`scene/source/job002-validate.sh` |
| Copybook（凍結インターフェース） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 再現スクリプト | `run.sh` |

## 4. 再現

```bash
# 任意のディレクトリから実行。本パッケージの input/ 複製を使い、共有fixtureは変更しない
bash INC-2026-007/student/run.sh /tmp/INC-2026-007-scene /tmp/INC-2026-007-db
echo "rc=$?"
cat /tmp/INC-2026-007-scene/logs/JOB002.log
```

現場と同じ元の RC が再現されるはずです（`scene/rc.txt` を参照）。

## 5. 調査課題（再現してから原因を特定）

1. 再現し、元の RC とエラー発生ノードを記録します。
2. `awk '{print NR": "length($0)}'` または `od -An -tc` で `input/transaction.dat` の**各レコードのバイト数**を調べ、`copybooks/TRANSACTION-V1.CPY` の凍結された 55 バイトレイアウトと照合します。
3. 長さの前提を満たさないレコードを特定します。この種の**長さ／位置ずれ**が、1件ごとの業務拒否（RC4）ではなく**構造エラー（RC8）**となる理由を説明してください。
4. JOB001 が通過し（Manifest と受信バイト列が一致）、JOB002 で初めて失敗する理由を説明してください。受信時検証と内容契約チェックの境界はどこですか？
5. `evidence/` に根本原因、最小修正（データ側かコード側か）、復旧／再実行の手順、再発防止策を記述します。長さ検証を緩めたり元入力を書き換えたりして問題を「隠す」修正は禁止です。

## 6. ヒント階層

[hints.md](hints.md) を参照してください。まず第1層だけを見てください。

## 7. プラグインとターミナルでの代替

- プラグイン：`source/M11VAL.COB` で `gd` を使い検証段落へ移動し、`K`／`:CobolPreview` で Copybook をプレビューします。保存時の診断で72列／Area A/Bを確認してください。
- ターミナルのみでの代替：
  ```bash
  awk '{print NR": "length($0)" cols"}' INC-2026-007/student/input/transaction.dat
  od -An -tc INC-2026-007/student/input/transaction.dat
  rg -n 'WS-LEN|record length|2000-PROCESS' \
     INC-2026-007/student/scene/source/M11VAL.COB
  ```
