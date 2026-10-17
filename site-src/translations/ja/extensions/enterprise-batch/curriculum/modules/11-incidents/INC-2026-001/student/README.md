# 事象 INC-2026-001：検証ノードが中止し、当日公開なし

> 学習者用パッケージ。**根本原因は含みません**。「症状と影響範囲 → タイムライン → 仮説と証拠 → 最小再現 → 根本原因 → 修正／ロールバック → 復旧と再実行 → 再発防止」の順で調査し、証拠を`evidence/`に提出してください。段階式ヒントは[hints.md](hints.md)を参照してください。

## 1. 症状と影響範囲

- 営業日`20261009`の夜間バッチが**JOB002（検証）**で中止し、終了コードは**RC8**でした。
- ネットフローは直ちに停止しました。JOB003以降のノードは**未実行**で、`publish/`に**今回の公開ディレクトリはありません**。CURRENTポインターも更新されていません。
- 影響範囲：当日の下流ファイルはすべて欠落しています。下流には誤データは渡っていません（公開なし）。

## 2. タイムライン

| 時刻（UTC） | 事象 |
|---|---|
| 01:02:08 | スケジューラが`run_id=as-found`を開始。JOB001受信COMPLETE |
| 01:02:08 | JOB002検証start |
| 01:02:09 | JOB002検証ERROR `validator failed rc=8` |
| 01:02:09 | ネットフロー停止、JOB003+ NOT_RUN、ロック解放 |

元の現場は`scene/console.txt`、`scene/logs/nightly.log`、`scene/logs/JOB002.log`、`scene/scheduler-status.txt`にあります。

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
# 任意のディレクトリから実行。本パッケージのinput/複製を使い、共有fixtureは変更しない
bash INC-2026-001/student/run.sh /tmp/INC-2026-001-scene /tmp/INC-2026-001-db
echo "rc=$?"
cat /tmp/INC-2026-001-scene/logs/JOB002.log
```

現場と同じ元RCが再現されるはずです（`scene/rc.txt`参照）。

## 5. 調査課題（再現してから原因を特定）

1. 再現し、元RCとエラー発生ノードを記録します。
2. `od -An -tc`／`cut`で`input/transaction.dat`をバイト単位に調べ、`copybooks/TRANSACTION-V1.CPY`の凍結レイアウトとフィールドごとに照合します。これは**構造エラー**か**業務拒否**かを判断し、コースのRC規約でその分類になる理由を説明してください。
3. ネットフローが下流ファイルを一切公開しなかったのが正しい動作である理由を説明してください。
4. 根本原因、最小修正（データ側かコード側か）、復旧と再実行の手順、再発防止策を`evidence/`に記述してください。検証を緩めたり元入力を書き換えたりして問題を「隠す」修正は禁止です。

## 6. ヒント階層

[hints.md](hints.md)を参照してください。まず第1層だけを見てください。

## 7. プラグインとターミナルでの代替

- プラグイン：`source/M11VAL.COB`で`gd`を使い検証段落へ移動し、`K`／`:CobolPreview`でCopybookをプレビューします。保存時の診断で72列／Area A/Bを確認します。
- ターミナルのみでの代替：
  ```bash
  awk '{print NR": "length($0)" cols"}' INC-2026-001/student/input/transaction.dat
  od -An -tc INC-2026-001/student/input/transaction.dat
  rg -n 'WS-STRUCT|2000-PROCESS' \
     INC-2026-001/student/scene/source/M11VAL.COB
  ```
