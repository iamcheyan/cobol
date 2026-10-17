# モジュール08：COBOL + データベース（Embedded SQL実践）

このモジュールでは**P1で検証済みの実際のEmbedded SQLツールチェーン**（GnuCOBOL 3.2 + 固定commitのGixSQL + 2つのローカルパッチ + PostgreSQL 17）を使用し、使い捨てDockerコンテナ/ネットワーク内でCOBOLカーソル、更新、トランザクションを実行します。mockではなく、教材のCOBOLカーソルを`psql`のファイルexportで代替するものでもありません。業務日はマシンの現在日付ではなく引数で渡します。すべて合成データで、使い捨てコンテナは終了時に削除され、ホストDBは参照しません。

レッスン：**08.1** Host/Indicator Variable、NULL、SQLCODE/SQLSTATE；**08.2** DECLARE/OPEN/FETCH/CLOSEカーソルとデータなし/エラーの区別；**08.3** 業務日で顧客snapshotを抽出し上流ファイルと突合；**08.4** 更新、一意制約、COMMIT/ROLLBACK、接続中断、トランザクション再試行。

- 設計詳細：[DESIGN.md](DESIGN.md)
- 独立した期待値と計算：[expected/README.md](expected/README.md)
- 学習者用証跡テンプレート：[evidence/README.md](evidence/README.md)
- 講師用参考実装：[instructor/modules/08-database/](../../../instructor/modules/08-database/)

## 1. 業務上の必要性 / 学習課題

夜間バッチは**DBとファイルの間**で連携します。業務日ごとに固定顧客ビューをDBから抽出して上流顧客ファイルと突合し、一致と差異を特定したうえで、その日の取引を台帳へ**冪等に**書き込み、残高を更新します。オンコール担当者が特に避けるべきなのはNULLを空白と扱うことと、再実行で二重に引き落とすことです。課題はこの処理経路を理解して修復し、同じ業務日の再実行で二重適用されないことを確認するとともに、「データなし、一意制約競合、接続失敗、commit結果不明」に対する再現可能な証跡を用意することです。

## 2. 入力、形式、前提

- 上流顧客ファイル：`fixtures/customer-upstream-20261009.dat`、CUSTOMER v1固定幅**27バイト** + LF。
- 取引ファイル：`fixtures/transactions-20261009.dat`、TRANSACTION v1固定幅**55バイト** + LF。
- DB seed：`db/seed.sql`（合成顧客/口座）、schemaは`db/schema.sql`。
- 前提：業務日`20261009`、テキストはASCII、LFはレコード幅に含めない、金額は最小通貨単位の整数。
- 凍結契約：CUSTOMER v1=27B、ACCOUNT v1=47B、TRANSACTION v1=55B。

## 3. clean checkoutからのビルド、実行、リセット

Docker（隔離ESQLツールチェーン用）とPython 3が必要です。

```bash
lab=$(cd curriculum/modules/08-database && pwd)
python3 "$lab/scripts/check.py"          # オフライン契約 + 独立oracle（Docker不要）
bash "$lab/scripts/check.sh"             # オフライン + 実DBエンドツーエンド + 学習者starter
```

実DB実験を個別に実行します（成果物は新規ディレクトリへ出力し、上書きは拒否されます）。

```bash
bash "$lab/scripts/run.sh" /tmp/m08-out 20261009
(cd /tmp/m08-out && sha256sum -c inputs.sha256 && sha256sum -c manifest.sha256)
```

単一ESQLソースを実行ファイルとしてビルドします（空白を含むパスにも対応）。

```bash
bash "$lab/scripts/build.sh" /tmp/probe "$lab/system/ESQL-PROBE.COB"
```

リセット：`bash "$lab/scripts/reset.sh" --containers`は残存する使い捨てコンテナ/ネットワークを削除します。`PGHOST=... bash "$lab/scripts/reset.sh" --db`は実行中のコースDBにschema+seedを再適用します。`run.sh`は実行ごとに一意の`m08-*-db`コンテナと`m08-*-net`ネットワークを作り、終了時（Ctrl-Cを含む）に削除します。ツールイメージは再利用のため保持します。派生ファイルは`manifest.sha256`を含め、すべて`<OUTPUT>`に書き込み、ソースディレクトリには書きません。

## 4. 期待出力、RC、件数、金額と独立計算

`run.sh 20261009`の正常結果（**独立計算は[expected/README.md](expected/README.md)にあり、プログラム出力に依存しません**）：

| シナリオ | 期待値 | 独立計算の根拠 |
|---|---|---|
| 08.1/08.2 probe | `PROBE=PASS`、RC0 | Indicator -1（NULL）、空文字indicator 0、`02000`データなし、`23514`実エラー、`23505`一意制約 |
| 08.3 snapshotと上流の突合 | RC4、`DIFFS=3`（MATCH2 / FIELD-DIFF1 / DB-ONLY1 / FILE-ONLY1） | seedと上流ファイルをキー単位で比較 |
| 08.3 差異なし上流 | RC0、すべてMATCH | 上流とDB snapshotがバイト単位で一致 |
| 08.4 rollbackモード | RC0、残高不変`100,200,300` | 期首残高、トランザクションrollback |
| 08.4 初回commit | RC0、残高`130,270,300`、台帳3行、commit1行 | 期首 + 各C/D取引 |
| 08.4 retry | RC0、残高は`130,270,300`のまま、台帳/commit行は増えない | 一意キーをskip、冪等 |
| 08.4 実行内重複 | RC8、台帳0行、残高不変 | 一意キー競合 + SAVEPOINT rollback |
| 接続失敗 | RC12、SQLSTATE `08xxx` | 無効ポート |

公開成果物：`snapshot.dat`（27B snapshot）、`snapshot-meta.txt`（業務日/schema版/layout版/cutoff/件数）、`snapshot[-nodiff]-reconcile.txt`と`-control.txt`、`apply-*.out`、`db-after-*.txt`（**独立psql接続**で読んだ残高/台帳/commit件数）、`probe.out`、`probe-fail.out`、`p1-patches.sha256`、`manifest.sha256`、`inputs.sha256`。

## 5. 変更箇所と維持するインターフェース

学習者は[starter/DBBATCH.COB](starter/DBBATCH.COB)から開始します（ビルド可能ですが未完成で、RC12を返し公開しません）。27B/55B契約、環境変数インターフェース（`M08_BIZ_DATE/M08_SNAPSHOT/M08_META/M08_UPSTREAM/M08_DIFF/M08_CONTROL`）、RC方針、一意業務キーを維持してください。既存の補助プログラム`system/ESQL-PROBE.COB`（08.1/08.2 probe）と`system/APPLY.COB`（08.4入金処理）は学習者パッケージに含まれ、`run.sh`が自動選択します。snapshotプログラムが**この課題の成果物**です。`run.sh`はデフォルトで学習者自身の`starter/DBBATCH.COB`をビルドします（または`COURSE_SOURCE`で外部ソースを指定）。講師参考の`instructor/modules/08-database/SNAPSHOT.COB`は学習者パッケージに含まれません。

### 学習者snapshot source入口（`COURSE_SOURCE`）

`run.sh`は`COURSE_SOURCE=<your snapshot source>`を指定すると`bin/snapshot`の代わりにそのソースを使います（08.2/08.3）。残りの手順は講師参考を使用します。**指定したソースは講師参考と同じ業務検証を受けます**。`COURSE_SOURCE`を設定しただけで無条件失敗にはなりません。

- 差異あり上流 → RC4、差異なし上流 → RC0。さらに27B snapshotが`expected/snapshot-20261009.dat`とバイト単位で一致する必要があります。すべて通過した後で08.4へ続き、公開します。
- システム障害（未完成`DBBATCH.COB`がRC12を返す等）→ RC12、公開なし。
- 意味的に誤った実装がRC4/RC0を返す場合（金額/符号/状態/行数不足・過剰）→ バイト比較でRC8となり、公開なし。

回帰確認：`scripts/check.sh`の第4–6節で、正しい参考実装を`COURSE_SOURCE`に指定した場合の正常公開、意味的に誤った学習者ソースの拒否、未完成starterがRC12で公開しないことを検証します。

## 6. 意図的な故障と調査/復旧（各レッスンに最低1つの再現可能な故障）

| レッスン | 変更 | 再現できる故障 | 調査と復旧 |
|---|---|---|---|
| 08.1 | `:HV-NOTE:HV-NOTE-IND`からindicatorを外す | NULL列のFETCHがNULLではなく空白となり、NULLと空文字を混同 | indicator -1でNULL判定し、indicatorを戻す |
| 08.2 | cursor `FETCH`後に`02000`を判定せず成功扱い | データ終端がエラー扱いになるか、行を取りこぼす | `FETCH`後に`IF SQLSTATE='02000'`なら正常終了、その他はエラー |
| 08.3 | 上流顧客の`balance_demo`を1桁変更 | DB snapshotと不一致になり`FIELD-DIFF`、RC4。フィールドとoffsetを特定 | 上流またはDB seedを戻してRC0で再実行。差分レポートは`19-26`を示す |
| 08.4 | 取引ファイルで`transaction_id`を複製 | 一意キー`23505` → 実行内重複 → RC8 rollback | 重複を除いて再実行。履歴再実行はSKIP分岐へ進む |

さらに強い故障例を2件、実測済みです。**72列超過**—複数列の`INSERT`を73列以降に並べるとGixSQL/cobraが識別子`sequence_no`を切り詰め、構文エラー`42601`になります。SQL行を72列以内にします。**PostgreSQL transaction abort**—`23505`後に同一トランザクション内で`SELECT`すると`25P02`となります。`SAVEPOINT`+`ROLLBACK TO SAVEPOINT`による局所復旧が必要です（DESIGN.md第4節参照）。

## 7. プラグイン操作とターミナル代替

- 固定形式の安全確認：cobol.nvimルーラーでArea A/Bと72列超過の赤い診断を確認。ターミナル代替：`awk 'length($0)>72{print NR}' <file>.COB`、`:set list`。
- 参考実装の段落を探す：`gd`/`:CobolGotoDef`で`1150-ONE`、`1200-DAY-COMMIT`へ移動。ターミナル代替：`rg -n '1150-ONE|1200-DAY-COMMIT' system/APPLY.COB`（学習者パッケージに含まれる既存補助プログラム）。
- COPYのCopybookを表示：`K`/`:CobolPreview`。ターミナル代替：`cat copybooks/CUSTOMER-V1.CPY`。
- 実バイト（LF/幅）を見る：ターミナルで`od -An -tc fixtures/customer-upstream-20261009.dat`。
- **プラグインの推定値をバイト配置の最終根拠にしないでください**。`check.py`の固定幅アサーションと`od`を使用します。

## 8. 提出する証跡と失敗条件

[evidence/README.md](evidence/README.md)に従い、compilerとDBツールのバージョン、イメージID、P1パッチSHA256、業務日、run_id、コマンド、**生RC**、`inputs.sha256`/`manifest.sha256`、DBの生状態（残高/台帳/commit）、突合表、制約事項を提出します。次の場合は失敗です：アサーションと公開成果物が不一致、manifest/input checksum不合格、27B snapshotが独立oracleと不一致、retry後に残高または台帳行が増加、実行内重複がrollbackされない、未完成の学習者ソースが成果物を公開、未検証のプラットフォーム/復旧範囲を「passed」と記載。
