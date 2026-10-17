# モジュール11 期待結果の説明（独立検算）

`expected/`は`instructor/modules/11-incidents/tools/gen_course.py`によって生成されます。この生成器は、凍結契約（CUSTOMER 27B / ACCOUNT 47B / TRANSACTION 55B）の検証と1:Nの超過貸越／孤立口座ルールを**独立して再実装**し、**コースプログラムの出力は読み取りません**。ルール：

- **JOB002の検証**：長さ≠55、キー／金額が数字以外、または取引番号がすべて空白 → 構造エラー（バッチ全体がRC8）。方向がC/D以外、状態がN以外、営業日が不一致、または金額が0 → 業務上の拒否（レコードごとにRC4）。
- **JOB005の突合**：口座が存在しない → ORPHAN（孤立）；出金によって期末残高が<0になる → OVERDRAFT（超過貸越）；それ以外は`closing = opening + credit − debit`。口座と取引のストリームは順序どおりでなければならず、そうでない場合はRC8。
- **制御合計**：`opening_total + credit_total − debit_total = closing_total`。

| ファイル | 内容 |
|---|---|
| `normal.control.txt` | 基準制御合計（received=4、closing_total=1475） |
| `normal.closing.txt` | 基準期末Master（acc1 1300／acc2 150／acc3 25） |
| `incidents.txt` | 各事象の`as_found_rc / desired_rc / publish_before / publish_after` |
| `customer-v1.txt` | CUSTOMER v1 状態抽出（`STATUS\|id\|A/D`） |
| `enterprise-class-v1.txt` | 企業顧客区分 v1 抽出（`CLASS\|id\|A`） |
| `enterprise-class-v2.txt` | 企業顧客区分 v2 抽出（`CLASS\|id\|A1`） |

`incidents.txt`で`as_found_rc=0`かつ`publish_before=yes`の事象は、**現状の欠陥**を表します。システムはRC0で誤った結果を公開しました。対応する`desired_rc=8`と`publish_after=no`は、**修正後に満たすべき**契約上の動作です。どの事象がこの条件に該当するかは契約データそのものから判断するため、ここでは個別に示しません（根本原因は講師用パッケージを参照）。

`check.py`はこれらの独立した期待値をアサーションの根拠として使用し、プログラム自身の標準出力を正解として扱うことはありません。
