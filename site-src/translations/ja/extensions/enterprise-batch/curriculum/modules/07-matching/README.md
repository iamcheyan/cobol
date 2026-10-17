# モジュール07：Enterprise Batchの中核アルゴリズム（12時間）

モジュール07は企業向け夜間銀行バッチの処理中核であり、コース難度と受入基準のベンチマークです。モジュール06のファイル契約、モジュール10のJOB編成、モジュール11の障害調査を、共通の突合/ソートモデルで結びます。SORTとMERGEで**順序が保証された**入力を作り、L1で1:1分類、L2で1:NのKey Break・残高・取消、L3で複数ストリーム/N:Nの顧客日集計、L4で150以上のフィールドを個別比較します。**中核のソート、突合、残高処理、フィールド単位比較はCOBOLの順次読み込みと有界状態で実装します**。Pythonはデータ生成、独立oracle、JOBゲートに限り、教えるアルゴリズムをSQL JOINや全量配列に置き換えません。

## レッスンと実験ユニット

| レッスン | 実験ユニット | テーマ |
|---|---|---|
| 07.1 | [labs/02-sort-merge/01-sort](labs/02-sort-merge/01-sort/README.md) | SD SORT、INPUT/OUTPUT PROCEDURE、実作業ファイル、一時領域障害 |
| 07.2 | [labs/02-sort-merge/02-merge](labs/02-sort-merge/02-merge/README.md) | 2つ以上の整列済みストリームのMERGE、ソートキー、同一キー内順序 |
| 07.3 | [labs/01-one-to-one](labs/01-one-to-one/README.md) | Boss L1：1:1、3種類の出力、二重EOFの組合せ |
| 07.4 | [labs/03-one-to-many](labs/03-one-to-many/README.md) | Boss L2：1:N Key Break、残高保存、拒否、原取引参照付き取消 |
| 07.5 | [labs/04-many-to-many](labs/04-many-to-many/README.md) | Boss L3：Master/取引/snapshot/前日情報の4ストリーム、業務N:N顧客日集計 |
| 07.6 | [labs/05-large-record](labs/05-large-record/README.md) | Boss L4：175個の名前付きフィールド、フィールドカタログ、RAW/TEXT-NORM/NUMERIC/IGNOREの個別比較 |

関連する演習経路（同一銀行モデル、凍結インターフェースを使用）：

```text
モジュール06 検証済み出力 ──未整列取引──▶ 07.1 SORT ──整列済み──▶ 07.2 MERGE（複数ストリーム）
             │                                                                  │
             ▼                                                                  ▼
ACCOUNT/TRANSACTION v1 ──▶ 07.3 L1分類 ──▶ 07.4 L2残高/取消 ──accepted──▶ 07.5 L3顧客日集計
                                                                                                      │
                                       企業顧客バイナリsnapshot（1778B/175フィールド）──────────▶ 07.6 L4フィールド差分
```

- 07.1/07.2の`common/`は通常SORT/MERGEストリームからL2へ渡すブリッジを固定します（金額0によるブリッジRC4とバイト単位の期待出力を含む）。
- 07.5の公式ランナーは生のACCOUNT/TRANSACTION/REVERSAL-LINKを実際のL2へ渡し、そのaccepted結果から顧客集計を進めます。accepted取引を捏造したり二重適用したりしません。
- 07.6はファイル突合から独立した企業顧客バイナリsnapshotを使い、フィールド単位の比較に集中します。

## 凍結契約（暗黙に変更しない）

- CUSTOMER v1 = 27バイト、ACCOUNT v1 = 47バイト、TRANSACTION v1 = 55バイト（[bank/copybooks](../../bank/copybooks/)および[BANK-SYSTEM.md](../../../docs/curriculum/BANK-SYSTEM.md)参照）。
- 取引の全ソートキーは`(account_id, sequence_no, transaction_id)`です。55個の元バイトを保持し、出力をLF終端にします。
- RC方針：0 正常、4 業務拒否/差分だが検証済み結果を公開、8 致命的データエラーで公開なし、12 システムエラーで公開なし。
- 取消には独立したバージョン管理のREVERSAL-LINKインターフェースを使い、55バイト取引フィールドを別の意味に読み替えません。
- 150以上のフィールドを持つ企業顧客レコードは1,778バイト固定バイナリです。[labs/05-large-record/FIELD-CATALOG.csv](labs/05-large-record/FIELD-CATALOG.csv)参照。

## clean checkoutから実行

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
bash curriculum/modules/07-matching/check.sh        # モジュール07の全実験を簡易受入確認
bash curriculum/check.sh                            # モジュール07と全基準を含むリポジトリ全体の入口
python3 curriculum/modules/07-matching/labs/05-large-record/scripts/pressure.py   # L4大レコード全経路の負荷試験
```

各実験は任意の開始ディレクトリ、空白を含むパスに対応します。ランナーは候補を隔離し、独立検証してから既存を上書きせず公開します。失敗時に正式出力を残さず、他プロセスのロックも削除しません。学習者用starterと講師参考実装は分離されています。参考実装は[instructor/modules/07](../../../instructor/modules/07/)にあります。

## 学習者パッケージ

`bash curriculum/scripts/package-student.sh <target-directory>`で、`instructor/`、講師用根因分析、解答snapshotを除外した再現可能で内容が安定した学習者用演習パッケージを生成します。パッケージ内のrun/checkコマンドはそのまま実行できます。解答を見る場合は、完全な講師用リポジトリ内の`instructor/`を参照してください。

## 受入基準

- SORT/MERGEは実際のSD/RELEASE/RETURNおよびMERGE USINGを使用し、降順入力、全体重複ID、バイト単位のフィールド不正を拒否します。
- L1は二重EOFと3出力件数の保存、L2は同一キー集計、順序、取引重複、オーバーフロー、取消、2段階の金額保存を扱います。L3は4ストリーム件数、status消費、snapshotの日付/バージョン、顧客単位の分割保存を確認します。L4は175フィールドカタログと独立差分一覧（見落とし/誤検出なし）を確認します。
- メモリとディスク使用量は有界です。順次処理の作業領域はファイル総量や同一キーグループの大きさに比例して増えません。SORTの実際のspillと資源障害には個別証跡があります。
- 各実験に正常/境界/異常フィクスチャ、独立した期待値、starter、参考実装、故障演習、学習者向け証跡テンプレートがあります。
- プラグイン（outline、段落移動、Copybook preview、PIC見積り）とターミナルでの代替経路を併記します。

主担当エージェントによる独立受入記録は[tasks/enterprise-cobol-review.md](../../../tasks/enterprise-cobol-review.md)にあります。
