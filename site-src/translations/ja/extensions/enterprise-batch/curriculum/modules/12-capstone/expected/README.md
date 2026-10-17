# 期待結果と独立照合

このディレクトリの期待結果は、参照実装を実行する前に業務ルールから独立して計算します。プログラム出力を expected として保存することはありません（AUTHORING-STANDARD 第 4 節）。

- 生成器：`instructor/modules/12-capstone/tools/gen_course.py`。BANKVAL の業務ルールとモジュール 07 L2 の 1:N 当座貸越ルールを独立して再実装しています。コース実装の出力を読み込まず、モジュール 10 の生成器も import しません。
- 固定された決定的データ（FR-10）、営業日 20261010。

| ファイル | 意味 |
|---|---|
| `<case>.control.txt` | 件数・金額の整合指標（`k=v`） |
| `<case>.closing.txt` | `account_id=±13桁の期末残高` |
| `<case>.customerday.txt` | `customer_id|区分|口座数|±13桁の顧客合計` |
| `<case>.rc` | 当該日タイプに対する期待プロセス RC |

## 独立照合の手順

- **受け入れ／拒否**：方向が C/D 以外 → BADDIR；status ≠ N → BADSTATUS；営業日不一致 → BADDATE；金額が 0 → BADZERO。
- **残高**：`(account_id, sequence_no, transaction_id)` 順に取引を 1 件ずつ適用します。出金によって残高が <0 になる場合、その取引を拒否（OVERDRAFT）し、金額集計から除外します。
- **整合性**：`期首残高 + 貸方 − 借方 = 期末残高`（口座ごと、および合計）。
- **顧客日次レポート**：customer_id ごとに口座数と期末残高合計を集計します。企業 v1 の A/B/C/D 区分は `<code>1` に拡張されます（A1..D1）。

## 日タイプごとの期待結果

| case | RC | 要点 |
|---|---:|---|
| normal | 0 | 6 件すべてを記帳 |
| abnormal | 4 | 検証で 4 件拒否 + 当座貸越で 1 件拒否 |
| rerun | 0 | normal と同じ feed；2 回目の記帳は 0 件 |
| extension | 0 | v2 区分、`D1` の顧客を含む |
| broken | 8 | transaction_id が重複し、何も公開しない |
