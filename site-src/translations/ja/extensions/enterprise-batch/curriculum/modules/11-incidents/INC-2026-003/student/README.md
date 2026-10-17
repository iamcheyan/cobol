# 事象 INC-2026-003：受信ノードが中止し、当日公開なし

> 学習者用パッケージ。**根本原因は含みません**。調査の順序：症状と影響範囲 → タイムライン → 仮説と証拠 → 最小再現 → 根本原因 → 修正／ロールバック → 復旧と再実行 → 再発防止。段階式ヒントは[hints.md](hints.md)を参照してください。

## 1. 症状と影響範囲

- 営業日`20261009`の夜間バッチが**JOB001（受信／Manifest検証）**で中止し、終了コードは**RC12（システム異常）**でした。
- ネットフローは直ちに停止し、JOB002以降は実行されませんでした。`publish/`に今回の公開はありません。
- 上流転送側は「送信成功」と報告していますが、受信ディレクトリにある当日取引ファイルは**0バイト**です。

## 2. タイムライン

| 時刻（UTC） | 事象 |
|---|---|
| 01:02:09 | スケジューラが`run_id=as-found`を開始；JOB001 start |
| 01:02:09 | JOB001 ERROR `checksum mismatch for 'transaction.dat'` |
| 01:02:09 | ネットフロー停止、JOB002+ NOT_RUN、ロック解放 |

元の現場は`scene/console.txt`、`scene/logs/nightly.log`、`scene/logs/JOB001.log`、`scene/scheduler-status.txt`にあります。

## 3. 提供資料一覧

| 資料 | 場所 |
|---|---|
| スケジューラ状態 | `scene/scheduler-status.txt` |
| 実行パラメータ | `scene/run.env` |
| 元の受信Manifest | `scene/MANIFEST`、`input/MANIFEST` |
| 元入力（未変更、0バイト） | `input/transaction.dat` |
| DB seed | `input/account_seed.dat`、`input/customer_seed.dat` |
| JOBログ | `scene/logs/nightly.log`、`scene/logs/JOB001.log` |
| 関連ソース | `scene/source/M11VAL.COB`、`scene/source/job002-validate.sh` |
| Copybook（凍結インターフェース） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 再現スクリプト | `run.sh` |

## 4. 再現

```bash
bash INC-2026-003/student/run.sh /tmp/INC-2026-003-scene /tmp/INC-2026-003-db
echo "rc=$?"
wc -c INC-2026-003/student/input/transaction.dat   # 実際のバイト数を確認
cat /tmp/INC-2026-003-scene/logs/JOB001.log
```

## 5. 調査課題

1. 再現し、元RCと失敗ノードを記録します。
2. JOB001がJOB002に進む前に実行するすべての検証を列挙します（Manifestの宣言、チェックサム、スナップショットを参照）。**最初に異常を検出した項目**はどれですか？
3. これはRC8（業務）とRC12（システム）のどちらに分類されますか？理由を説明してください。
4. 重要な区別：0バイトファイルは「正当な空ファイル」でしょうか、それとも「壊れた転送」でしょうか？コース契約の「空ファイルを許可する」方針はどう定義されていますか？感覚で判断せず、Manifestの期待内容を引用してください。
5. 復旧手順（再受信／送信元の検証、新しいrun_idで再実行）と再発防止策（転送チェック、受信後のサイズ検知、アラート）を提示します。

## 6. ヒント階層

[hints.md](hints.md)を参照してください。

## 7. プラグインとターミナルでの代替

```bash
od -An -tc INC-2026-003/student/input/transaction.dat
sha256sum INC-2026-003/student/input/transaction.dat
cat INC-2026-003/student/scene/MANIFEST
rg -n 'checksum|MANIFEST|snapshot' \
   INC-2026-003/student/scene/source/M11VAL.COB \
   INC-2026-003/student/scene/logs/JOB001.log
```
