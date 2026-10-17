# 事象 INC-2026-005：ソートノードが中止し、公開なし

> 学習者用パッケージ。**根本原因は含みません**。調査順序：症状と影響範囲 → タイムライン → 仮説と証拠 → 最小再現 → 根本原因 → 修正／ロールバック → 復旧と再実行 → 再発防止。
> 段階式ヒントは [hints.md](hints.md) を参照してください。

## 1. 症状と影響範囲

- 営業日 `20261009` の夜間バッチは **JOB003（ソートと順序検証）** で中止し、終了コードは **RC12（システム異常）** でした。
- JOB001/JOB002 は COMPLETE。JOB003 の失敗後、JOB004 以降は未実行で、公開もありません。
- 運用側のメモ：この時間帯にホストの一時領域で異常が発生していました。
- 影響範囲：ソートファイルは生成されず、下流にデータはありません。**正式な公開はなく**、ロックは解放されています。

## 2. タイムライン

| 時刻（UTC） | 事象 |
|---|---|
| 01:02:xx | JOB001/JOB002 COMPLETE rc=0 |
| 01:02:xx | JOB003 sort start |
| 01:02:xx | JOB003 ERROR（システム異常）rc=12 |
| 01:02:xx | ネットフロー停止、JOB004 以降 NOT_RUN、ロック解放 |

元の現場は `scene/console.txt`、`scene/logs/nightly.log`、`scene/scheduler-status.txt` を参照してください。

## 3. 提供資料一覧

| 資料 | 場所 |
|---|---|
| スケジューラ状態 | `scene/scheduler-status.txt` |
| 実行パラメータ | `scene/run.env` |
| 元の受信Manifest | `scene/MANIFEST`、`input/MANIFEST` |
| 元入力（未変更） | `input/transaction.dat`、`input/account_seed.dat`、`input/customer_seed.dat` |
| JOBログ | `scene/logs/nightly.log`、`scene/logs/JOB0*.log` |
| 関連ソース | `scene/source/job003-sort.sh`（ソートノード）、`scene/logs/JOB003.log`、`scene/source/nightly.sh` |
| Copybook（凍結インターフェース） | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| 再現スクリプト | `run.sh`（この実行に限り、失敗する `mktemp` を PATH に注入） |

## 4. 再現

```bash
bash INC-2026-005/student/run.sh /tmp/INC-2026-005-scene /tmp/INC-2026-005-db
echo "rc=$?"
cat /tmp/INC-2026-005-scene/logs/nightly.log
```

## 5. 調査課題

1. 再現し、元の RC と失敗ノードを記録します。
2. このノードの役割は何ですか？依存する**システムリソース**（一時ディレクトリ、書き込み権限、ディスク容量、子プロセス）を特定します。`system/jobs/job003-sort.sh` を読み、一時作業領域の作成箇所を探してください。
3. なぜこの失敗は **RC8 ではなく RC12** ですか？「データエラー」と「環境／リソース障害」を区別してください。
4. 重要な証拠：失敗後、実行ディレクトリ内に一時ディレクトリが**残っているか**、`publish/` が存在するか、営業日ロックが解放されたかを確認します。各項目で実行したコマンドと結果を示してください。
5. 復旧（一時領域／権限を修復して新しい run_id で再実行）と再発防止（事前リソース確認、ディスク使用率アラート、失敗時に公開しないこととロックの解放）を提示してください。

## 6. ヒント階層

[hints.md](hints.md) を参照してください。

## 7. プラグインとターミナルでの代替

```bash
ls -la /tmp/INC-2026-005-scene/work/ 2>/dev/null
ls -la /tmp/INC-2026-005-scene/publish 2>/dev/null
ls -la /tmp/INC-2026-005-db/locks 2>/dev/null
df -h /tmp
rg -n 'mktemp|temp space|system failure' \
   INC-2026-005/student/scene/source/job005-match.sh \
   INC-2026-005/student/scene/logs/nightly.log
```
