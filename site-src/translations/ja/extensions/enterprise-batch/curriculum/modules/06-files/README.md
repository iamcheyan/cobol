# 06 ファイル処理（6時間）

推奨6時間。モジュール05修了後に取り組みます。カリキュラム06.1 SELECT/FD/SD/OPEN/READ/WRITE/CLOSE/FILE STATUS/EOF、06.2 固定バイトレコードとLINE SEQUENTIAL、論理幅にLFを含めない扱いと長さ異常検出、06.3 欠落/空ファイル、短/長行、数値不正、ID重複、未知status、入力control合計、06.4 相対/索引ファイルのREWRITE/DELETEとロックの読み取り実験および適用範囲を扱います。

業務要件：夜間バッチの**JOB002長さ/業務検証**は上流のACCOUNT v1マスタ（47バイト固定長）を読み、各行をフィールド単位の理由付きで受理/拒否に分類し、ファイル状態と入力control合計を記録し、モジュール07の順次突合に渡す**有効かつ整列済み**ACCOUNT v1ファイルを作ります。成果物は検証プログラム`FILEVAL.COB`です。

## 1. 入力、形式、前提

- 入力はLF終端のASCII ACCOUNT v1ファイルです。各論理レコードは**47バイト**（**LFを除く**）：位置1–10 `account_id`、11–18 `customer_id`、19–21 `currency`、22 `balance_sign`、23–35 `opening_balance`、36 `account_status`、37–44 `business_date`、45–47 `layout_version`。
- 凍結インターフェース`curriculum/bank/copybooks/ACCOUNT-V1.CPY`を再利用します。本モジュールでは変更しません。
- 前提：`account_id`昇順。業務日は引数で与え、レコード内の`business_date`と一致する必要があります。初期対応通貨は`JPY`、`layout_version`は`001`です。
- 空ファイル（0バイト）は**許可**され、その日の口座数0を意味します。欠落/読取不能ファイルはシステム障害（RC12）です。
- 固定バイト読込では1..47バイトを数えてLFを識別するため、短/長行、CRLF、最終LF欠落を検出できます。

## 2. clean checkoutからのビルド、実行、リセット

Linux x86-64、GnuCOBOL 3.2（`cobc -info`でBDB索引backendを確認）、Bash、GNU coreutils、Python 3（受入確認のみ）が必要です。macOS/WSLは未検証です。`-std=cobol85`は**使わないでください**。

```bash
lab=curriculum/modules/06-files
bash "$lab/scripts/build.sh" /tmp/fileval
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/valid.dat" \
  /tmp/bank-fileval-normal 20261009
bash "$lab/scripts/check.sh"
bash "$lab/scripts/reset.sh" /tmp/bank-fileval-normal
```

`run.sh`は存在しない新しい出力ディレクトリだけを受け付け、非公開stageへ先に書き、検証後に結果全体を公開します。出力内の派生ファイル：`accepted.dat`、`rejected.dat`、`report.txt`、`filestatus.log`、`run.txt`、`compiler.txt`、`source.sha256`、`inputs.sha256`、`outputs.sha256`、`account.input.dat`（入力snapshot）。フィクスチャ原本は上書きしません。`reset.sh`はコース標識がありリポジトリ外にある出力ディレクトリのみ削除します。

## 3. 期待出力、RC、件数、残高

```text
ACCT|<id>|ACCEPT|<A|C|F>|<符号><18桁>
ACCT|<id>|REJECT|<reason>
CONTROL|BUSINESS-DATE=<YYYYMMDD>|READ=n|ACCEPT=n|REJECT=n|BALANCE=<符号><18桁>
```

`accepted.dat`は有効な元47バイトレコード、`rejected.dat`は元47バイト + `|` + 理由です。`filestatus.log`には`OPEN|ACCOUNT|00`と`EOF|ACCOUNT|10`を記録します。RC方針：

| RC | 意味 | 出力方針 |
|---:|---|---|
| 0 | 業務拒否なし。読込 = 受理 + 拒否 | 公開 |
| 4 | フィールド単位の業務拒否 | 拒否明細付き検証結果を公開 |
| 8 | 契約違反：長さ、CRLF、最終LF欠落、降順、layout不正、業務日不一致 | 全体失敗、公開なし |
| 12 | ファイル/権限/システム障害（入力欠落、FILE STATUS 35を含む） | 全体失敗、公開なし |

フィールド拒否理由（**固定優先順位**）：

| 理由 | 発生条件 |
|---|---|
| `BAD-ACCOUNT-ID` | `account_id`が数値でない |
| `DUPLICATE-ID` | 数値IDが直前と同じ（降順はRC8） |
| `BAD-CUSTOMER-ID` | `customer_id`が数値でない |
| `UNKNOWN-CURRENCY` | `currency` ≠ `JPY` |
| `BAD-SIGN` | `balance_sign`が`{+,-}`以外 |
| `BAD-BALANCE` | `opening_balance`が数値でない |
| `BAD-DATE` | `business_date`が数値でない/実在日付でない |
| `DATE-MISMATCH` | 有効日付だがJOB業務日と異なる |
| `UNKNOWN-STATUS` | `account_status`が`{A,C,F}`以外 |

**control合計**：`READ = ACCEPT + REJECT`。`BALANCE`は受理されたレコードの符号付き期首残高合計（正確な18桁10進数）で、拒否レコードは含めません。`expected/`は手計算で独立に決め、`check.py`がフィクスチャからaccepted/rejectedをバイト単位で再構築します。

## 4. 変更箇所と維持するインターフェース

`starter/FILEVAL.COB`に読込、検証、分類、3種類の出力を実装します。ACCOUNT v1の47バイト配置、業務日引数の意味、RC規約、reason code表記、`TRANSACTION v1`契約を**変更しないでください**。参考実装：[`instructor/modules/06-files/FILEVAL.COB`](../../../instructor/modules/06-files/FILEVAL.COB)。

## 5. 意図的な故障と復旧（再現可能）

1. `fixtures/normal/valid.dat`を一時ディレクトリへコピーして最終LFを削除：RC8 `MISSING-FINAL-LF`、公開なし。
2. `currency`を`USD`へ変更：RC4 `UNKNOWN-CURRENCY`、他の行は通常処理。
3. `business_date`を`20261008`へ変更：RC4 `DATE-MISMATCH`。
4. `layout_version`を`002`へ変更：RC8 `BAD-LAYOUT-VERSION`、公開なし。
5. 2レコードを交換：RC8 `UNSORTED-INPUT`。

調査順：stderrのreason codeとRCを確認し、`report.txt`を入力行と照合し、`sha256sum -c inputs.sha256`で入力snapshot不変を確認します。失敗時は出力ディレクトリがないことも確認します。

## 6. プラグイン操作とターミナル代替

- プラグイン：`:CobolGotoCopybook`で47バイトの`ACCOUNT-V1.CPY`、`:CobolCalcRecord`でフィールド幅、`gd`で段落を確認し、ルーラーでArea A/Bを確認します。
- ターミナル代替：`rg -n 'FILE STATUS|EOF|TEST-DATE|SEARCH'`、`awk '{print length($0)}'`、`od -An -tc`でLF/CRLFと生バイトを調べます。両経路で同じ業務目標を達成できます。

## 7. 受入証跡と失敗条件

ソース、正常例、少なくとも1件のRC4、公開なしのRC8、欠落ファイルのRC12、入力SHA256、読込 = 受理 + 拒否、`BALANCE`保存、`filestatus.log`を提出します。テンプレート：[evidence/README.md](evidence/README.md)。**失敗条件**：RC/理由不一致、失敗ケースで出力を公開、原フィクスチャの変更、または`filestatus.log`が契約と不一致。

## 8. 06.2 / 06.4 読み取り実験（この環境で実測）

- [`scripts/line-seq-probe.COB`](scripts/line-seq-probe.COB)：同じ5バイト論理レコードを`LINE SEQUENTIAL`で書くとLF込み6生バイト、固定`SEQUENTIAL`では5バイトです。lineファイルをバイト単位で読むと`X'0A'`を確認できます。**LFは存在するが論理幅に含まれない**こと、固定バイト逐次モデルで可視化できることを示します。
- [`scripts/indexed-probe.COB`](scripts/indexed-probe.COB)：BDB索引ファイルの`WRITE/READ/REWRITE/DELETE`とstatus code（同一プロセスで再OPENした場合の`41`を含む）。
- [`scripts/indexed-hold-probe.COB`](scripts/indexed-hold-probe.COB)：`OPEN I-O`後にstdinで停止するholder。**実際の2プロセスロック競合実験**に使用します（同一プロセスでの再OPENではありません）。
- [`scripts/relative-probe.COB`](scripts/relative-probe.COB)：`RELATIVE KEY`を使う相対ファイルの`WRITE/READ/REWRITE/DELETE`。
- [`scripts/sort-sd-probe.COB`](scripts/sort-sd-probe.COB)：`SD SORT-WORK`と`SORT … ASCENDING KEY … USING/GIVING`を組み合わせ、未整列`LINE SEQUENTIAL`入力を整列します（06.1のSD/SORT宣言で、モジュール07の突合アルゴリズムではありません）。

実測status codeと**適用限界**は[DESIGN.md](DESIGN.md)第5節を参照してください。重要な結論（文書からの推測ではなく、この環境で実測）：

- 同一プロセスで同じファイルを再OPENすると`41`ですが、**これは2プロセスでの挙動を示しません**。
- 2プロセスが同じBDB索引ファイルを同時に`OPEN I-O`すると、**両方とも`00`を得ます**（`check.py::check_cross_process_lock`が`indexed-hold-probe`を実際に並行実行）。既定のGnuCOBOL/BDBハンドル層は**プロセス間排他を提供しません**。
- よって並行整合性はJOB層の外部ロックで保証する必要があります。本課の`run.sh`は`output.lock`ディレクトリで単一実行を保護します。`check.py::check_protection`は2つの`run.sh`を起動し、一方が`RC0`、他方がstderr `Run locked`付きの`RC12`となり、結果ディレクトリとロックがクリーンになることを確認します。06.4ではこの境界を理解します。

## 9. カリキュラム要件 ↔ 実行可能な実習

各行は`check.sh`がアサートする実在の実行可能なソース/フィクスチャを指します。

| カリキュラム要件 | ソース | 入力 | 学習者の変更/故障 | expected / check | 証跡 |
|---|---|---|---|---|---|
| 06.1 SELECT/FD/OPEN/READ/WRITE/CLOSE/FILE STATUS/EOF | `instructor/.../FILEVAL.COB` | `fixtures/normal/valid.dat` | 最終LFを削除 | `filestatus.log`、`expected/normal-valid.txt`；`run_case` | `evidence/README.md` |
| 06.1 SD（sort description） | [`scripts/sort-sd-probe.COB`](scripts/sort-sd-probe.COB) | 一時的な未整列`in.dat` | `ASCENDING`を`DESCENDING`に | `check_line_sequential_and_sd`：`ALICE/BOB/CAROL` | `check_probes` |
| 06.2 固定幅とLINE SEQUENTIAL | [`scripts/line-seq-probe.COB`](scripts/line-seq-probe.COB) | 一時的な`line.dat`/`fixed.dat` | `LINE SEQUENTIAL`読みに変更 | `LINE-RAW-BYTES=06` vs `FIXED-RAW-BYTES=05` | `check_probes` |
| 06.2 長さ異常検出 | `FILEVAL.COB`のバイト単位読込 | `fixtures/invalid/{short,long}-record.dat`、`no-trailing-lf.dat`、`crlf.dat` | 短く/長くする、CR追加 | RC8、公開なし；`run_case` | `evidence/README.md` |
| 06.3 欠落/空ファイル/数値不正/ID重複/未知status/control合計 | `FILEVAL.COB` | `fixtures/boundary`、`invalid` | 欠落→RC12、空→RC0 | `expected/*.txt`；`run_case` + `verify-publish.py` | 同左 |
| 06.4 索引ファイルWRITE/READ/REWRITE/DELETE | [`scripts/indexed-probe.COB`](scripts/indexed-probe.COB) | 一時的な`ix.dat` | 重複/欠落キー | `DUPLICATE=22`、`MISSING=23`、`REOPEN=41` | `check_probes` |
| 06.4 相対ファイル | [`scripts/relative-probe.COB`](scripts/relative-probe.COB) | 一時的な`rel.dat` | 範囲外キー9 | `READ9=23` | `check_probes` |
| 06.4 2プロセスの競合と適用範囲 | [`scripts/indexed-hold-probe.COB`](scripts/indexed-hold-probe.COB) + `run.sh` `.lock` | holder 2つ / `run.sh` 2つを並行実行 | `run.sh`の`.lock`削除 | 両holder `HOLD-OPEN=00`；JOBロックは`RC0`/`RC12 Run locked` | `check_cross_process_lock`、`check_protection` |
