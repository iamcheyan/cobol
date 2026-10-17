# 独立した期待値（モジュール05）

`expected/*.txt`は`report.txt`全体の期待値です。DESIGN.mdの業務方針に基づく**手計算例**から決め、`check.py`がフィクスチャからaccepted/rejectedを独立に再構築し、バイト単位で照合します。参考実装の出力を正解として扱わないでください。命名規則は`<group>-<case>.txt`です。

- `normal-clean.txt`：3件すべて受理。status `a`→`A`、`D`はそのまま。AMOUNT=60。
- `boundary-empty.txt`：READ=ACCEPT=REJECT=0、AMOUNT=0（空ファイルは有効）。
- `boundary-min-amount.txt`：金額0は有効、AMOUNT=0。
- `boundary-max-amount.txt`：金額50,000,000は有効。2件の合計は50,000,001。
- `boundary-single.txt`：1件、AMOUNT=1。
- `invalid-missing-name.txt` / `bad-id` / `non-numeric-amount` / `amount-over-cap` /
  `unknown-status` / `duplicate-id`：各1件を拒否し、理由は上記の一覧どおり。`duplicate-id`は受理1件 + 拒否1件、AMOUNT=50。
- `invalid-mixed.txt`：DESIGNの手計算例。READ=6、ACCEPT=1、REJECT=5、AMOUNT=50。

構造/契約エラーフィクスチャ（`unsorted`、`short-record`、`long-record`、`no-trailing-lf`、`crlf`）には期待レポートが**ありません**。期待結果はRC8で、出力ディレクトリを公開しません。

計算例（`boundary-max-amount.dat`）：レコード1の金額は50,000,000、レコード2は1です。両方とも有効なので、AMOUNT = 50,000,000 + 1 = 50,000,001。読込2件 = 受理2件 + 拒否0件。
