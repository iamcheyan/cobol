# モジュール 10：Shell / JCL / Scheduler — 夜間JOB運用

所要時間の目安は9時間です。前提：モジュール06（ファイル契約）、モジュール07（SORTと順序突合）。本モジュールでは「プログラム」を「ジョブ」へと発展させ、受信 → 検証 → ソート → DBスナップショット → 突合 → 冪等記帳 → コントロール合計 → 公開 → 完了の流れを構築し、RC、ロック、スナップショット、Manifestと4つのクラッシュ境界からの復旧を演習します。

> プラットフォーム：実際に検証したのはLinux x86-64（GnuCOBOL 3.2、Bash、GNU coreutils、Python 3）のみです。macOS/WSL/その他のアーキテクチャは未検証です。
>
> **DB層に関する説明（2つの経路。混同しないこと）**：
> 1. **既定の学習経路（オフライン）**：JOB004/JOB006は `lib/db.py` のクラッシュ安全なファイルチェックポイントを使い、DBトランザクションの意味を模擬します。証拠には「DB層 = オフラインファイルチェックポイント。実DB未検証」と明記し、オフラインのRC0を実DBでのエンドツーエンド検証として扱ってはいけません。
> 2. **実DB経路（R01）**：`scripts/real-db.sh` はDocker + PostgreSQL17 + GixSQLを使い、モジュール08のcanonical ESQLプログラムを再利用して、JOB004で実カーソル抽出、JOB006で単一トランザクションの冪等記帳を行い、**独立したpsql接続**で残高と台帳を照合します。恒久回帰チェックは `scripts/check-real-db.sh` です。実DBを利用できない場合、スクリプトは `UNVERIFIED`（RC2）を返し、成功を装いません。

## 1. 業務で必要な理由／依頼内容

銀行では毎晩、当日の取引を安全に記帳し、照合して下流へ公開しなければなりません。しかし**ファイル、DB、下流への公開をまとめたアトミックcommitはありません**（FR-08）。運用担当者としての依頼は、9つのJOBを夜間フローにつなぎ、**先行段階の失敗時に下流を実行しないこと、並行起動を拒否すること、同じ営業日の再実行で二重に引き落とさないこと、4つのクラッシュ境界すべてから状態の整合性を保って復旧できること**です。

## 2. 入力、ソース、形式、保証済みの前提

受信ディレクトリには `transaction.dat`（TRANSACTION v1、1件55バイト + LF）と `MANIFEST`（営業日、レイアウトバージョン、各ファイルのSHA256）が含まれます。DB層は初回に `account_seed.dat`（ACCOUNT v1、47バイト）と `customer_seed.dat`（CUSTOMER v1、27バイト）からオフラインstoreディレクトリへ初期投入します。

固定インターフェース（canonical定義は `curriculum/bank/copybooks/`、モジュール10には `copybooks/CUSTOMER-V1.CPY` も含まれます）：

- CUSTOMER v1：27バイト — id/name/demo_balance/status。
- ACCOUNT v1：47バイト — id/customer/currency/sign/balance/status/date/version。
- TRANSACTION v1：55バイト — account/txid/date/sequence/direction/amount/status。

保証事項：ASCIIの合成データ、LF改行、論理レコード長にLFを含めないこと、営業日にマシンの日付を既定使用しないこと。`transaction_id` の重複、短い／長いレコード、数字として不正な値は検出しなければならない異常です。

## 3. クリーンなcheckoutからビルド、実行、リセット

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
mod=curriculum/modules/10-jobs

# JOB002検証器をビルド（任意。run.shが自動ビルドします）
bash "$mod/scripts/build.sh" /tmp/bankval

# 夜間フロー全体を実行（入力ディレクトリ、出力ディレクトリ、DB store、営業日は必須）
set +e
bash "$mod/scripts/run.sh" \
  --input  "$mod/fixtures/normal" \
  --output /tmp/bank-night-20261009 \
  --db     /tmp/bank-db \
  --business-date 20261009 \
  --run-id n1
rc=$?
set -e
echo "nightly rc=$rc"      # このfixtureは取引ごとの業務拒否を含むため4を想定

# 状態と証拠を確認
bash "$mod/scripts/run.sh" \
  --input "$mod/fixtures/normal" --output /tmp/bank-night-20261009 \
  --db /tmp/bank-db --business-date 20261009 --command status
cat /tmp/bank-night-20261009/work/control/control.txt
python3 "$mod/lib/verify_publish.py" \
  --dir /tmp/bank-night-20261009/publish/n1 --run-id n1 --business-date 20261009

# リセット（run.env付きのコース実行ディレクトリだけを受け付け、リポジトリのパス／シンボリックリンク／マーカーのないディレクトリは拒否）
bash "$mod/scripts/reset.sh" /tmp/bank-night-20261009
```

派生ファイルを変更するのは `--output` ディレクトリ内だけです。**入力ディレクトリ、fixtures、DB seed、既存出力は上書きされません**。既存出力ディレクトリはRC12で拒否されます。

## 4. 期待出力、RC、件数と金額（独立計算）

`normal` fixture：期首残高1000 / 50 / 0の3口座、受信取引10件。

| 指標 | 値 | 根拠 |
|---|---:|---|
| 受信 | 10 | fixtureの行数 |
| JOB002受理／拒否 | 6 / 4 | 業務ルール |
| JOB003ソート | 6件 | accepted |
| JOB005受理／拒否（貸越） | 4 / 2 | 期末残高ルール |
| JOB006台帳記帳 | 4 | 冪等キー |
| 期首／貸方／借方／期末合計 | 1050 / 600 / 1100 / **550** | 保存則 |
| 期末残高 | acc1 400、acc2 150、acc3 0 | `closing = opening + C − D` |

全数値は `expected/normal.control.txt` と `expected/normal.closing.txt` を参照してください。本モジュールの期待値は `instructor/modules/10-jobs/tools/gen_course.py` 内の**独立oracle**（BANKVALの業務ルールと1:N貸越ルールを再実装）で計算し、コース実装の出力を転記したものではありません。`boundary-empty-tx`（RC0、期末=期首1050）と `boundary-single`（RC0、期末1150）にも独立したexpectedがあります。

RC：`normal`/`boundary-*` はRC4/RC0、3つの `invalid-*` はRC8で**正式公開なし**です。システム障害（mktemp／権限／ディスク／ロック）はRC12で**正式公開なし**です。

## 5. 変更する箇所と壊してはいけないインターフェース

- 学習者の開始点：`starter/BANKVAL.COB`（コンパイル可能で、RC12を返し、公開しません）。実際にJOB002検証器として動くよう完成させてください。参照実装は `instructor/modules/10-jobs/BANKVAL.COB` にあります。
- 壊してはいけないもの：3種類の固定レコード幅とフィールドオフセット、`work/` と `publish/` のディレクトリ契約、`control.txt` のキー、戻り値RCの意味（0/4/8/12）、冪等台帳キー `(business_date, transaction_id)`。
- JOB003/JOB005はモジュール07の参照実装を再利用します（複製しません）。評価の焦点は突合アルゴリズムの書き直しではなく、**接続**です。

## 6. 意図的な破壊と復旧（各実験で少なくとも1つ、再現可能な障害を扱う）

| 実験 | 破壊方法 | 現象 | 復旧 |
|---|---|---|---|
| 10.1 引数 | `--business-date` を指定しない | RC12で拒否 | 営業日を明示する |
| 10.2 RC | `invalid-short-record` fixtureを使う | JOB002がRC8、公開なし | レコード長を修正 |
| 10.2 RC12 | `PATH` に失敗する `mktemp` を挿入 | RC12、公開なし、ロック残留なし | 環境を復旧 |
| 10.3 ロック | `<db>/locks/<date>.lock`（生きたpid入り）を事前作成 | 同日並行実行がRC12 | ロックを解放 |
| 10.3 スナップショット | `db/snapshots/<date>/account_master.dat` を改ざん | JOB004がRC12 | DBから再取得 |
| 10.4 クラッシュ | `--crash-at {before,mid,after}-db-commit / during-publish / after-publish` | RC97で現場を保持 | 同じrun-idで続行し自動復旧 |
| 10.4 再実行 | 同じDB・営業日で新しい出力ディレクトリへ再実行 | RC4、残高／台帳は変化なし | — |
| 10.5 JCL | `lib/jcl/JOBFLOW.jcl` を読み、ローカルノードとの対応を確認 | — | 閲覧のみ。実行可能とは表明しない |

```bash
# 4つ（追加の境界も含む）のクラッシュ境界復旧実験を一括実行し、元の証拠を出力
bash "$mod/scripts/recovery-lab.sh" /tmp/m10-recovery-lab
```

## 7. プラグイン操作と端末だけでの代替

- プラグイン：`lib/db.py`／JOBスクリプトの問題箇所は `gd`/`:CobolGotoDef` で探します。`COPY "ACCOUNT-V1.CPY"` には `:CobolGotoCopybook` を使ってcanonicalインターフェースを確認し、COBOLの保存時には診断波線で72列／Area A/Bを確認します。
- 端末のみでの代替（プラグインがなくても最後まで実施できます）：
  ```bash
  rg -n 'BANKVAL_|--crash-at|ledger|Manifest|complete.marker' curriculum/modules/10-jobs
  od -An -tc curriculum/modules/10-jobs/fixtures/normal/transaction.dat | head
  (cd /tmp/bank-night-20261009/publish/n1 && sha256sum -c MANIFEST.sha256)
  ```

## 8. 提出する証拠と失敗条件

[evidence/README.md](evidence/README.md) に従って提出してください：営業日、run_id、コマンド、実際のRC、入力／出力チェックサム、コントロール合計、4つのクラッシュ境界における台帳／残高／状態、再実行前後の比較、変更点と回帰結果。

**失敗**と判定されるのは、いずれかのJOB失敗後に正式公開すること、同一営業日の再実行で二重に引き落とすこと、クラッシュ復旧後にDB／台帳／ファイル／状態が一致しないこと、古い `publish/<run_id>` またはCURRENTを今回の結果と偽ること、システム障害を成功として扱うこと、DBが実際に検証済みだと主張することです。

受け入れ時の自己検査：

```bash
bash curriculum/modules/10-jobs/scripts/check.sh
```

講師向け参照実装、根本原因、RED→GREENの記録は `instructor/modules/10-jobs/` にあります。
