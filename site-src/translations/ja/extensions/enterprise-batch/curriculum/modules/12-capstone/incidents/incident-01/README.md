# 事故 01：20261010 夜間処理が公開前に失敗（配布資料）

> 本ファイルは**配布資料**であり、現象と利用できる証拠のみを記載します。**根本原因と修正は含みません**。
> 根本原因、最小修正、採点ポイントは `instructor/modules/12-capstone/INCIDENT-01.md` にあります。

## 現象（当直への報告）

営業日 20261010 の夜間処理は**公開前に失敗**しました。下流には当日の `closing-master.dat` / `customer-day.dat` が届かず、`publish/CURRENT` も更新されませんでした。ログを見る限り前半のノード（受信、検証、ソート）は正常に完了したようですが、処理は後半で停止しました。

## 影響範囲

- 当日の正式公開はありません。下流の照合が待機しています。
- DB store の台帳は汚染**されていない**ようです（自分で検証してください。ログの最終行だけで結論を出してはいけません）。
- 二重引落しは発生していません（これも証拠で確認してください）。

## 受け取った資料

| ファイル | 内容 |
|---|---|
| `materials/params.txt` | 当夜の営業日、layout、入力ディレクトリ、run_id |
| `materials/feed/` | 受信した入力スナップショット（TRANSACTION/CUSTOMER/ACCOUNT + MANIFEST） |
| `materials/scheduler-state.txt` | スケジューラに記録された JOB 状態と RC |
| `materials/logs/` | JOB ログと `nightly.log` の抜粋 |
| `materials/operator-notes.md` | 当直引き継ぎメモ |
| `reproduce/reproduce.sh` | 同じパラメータで夜間処理を再実行し、生の証拠をエクスポート |

## 課題

`AUTHORING-STANDARD` 第 5 節の順序で提出してください：現象と影響範囲 → タイムライン → 仮説と証拠 → 最小再現 → 根本原因 → 修正/ロールバック → 復旧と再実行 → 再発防止。

必須要件：

- 事故を「修正」するために**元の入力を変更してはいけません**。復旧には監査可能な業務訂正を使います。
- 根本原因は資料から再現でき、問題のデータと処理段階を特定できること。
- ログの最終行ではなく証拠を使い、台帳が汚染されていない（または汚染された）理由を説明すること。
- 二重引落しを防ぐ復旧コマンドと元の RC を示すこと。

## 推奨する確認方法（ターミナル。プラグインは任意）

```bash
incident=curriculum/modules/12-capstone/incidents/incident-01
cat "$incident/materials/scheduler-state.txt"
sed -n '1,80p' "$incident/materials/logs/nightly.log"
bash "$incident/reproduce/reproduce.sh" /tmp/m12-incident-01
```

提出する証拠は `curriculum/modules/12-capstone/evidence/README.md` を参照してください。
