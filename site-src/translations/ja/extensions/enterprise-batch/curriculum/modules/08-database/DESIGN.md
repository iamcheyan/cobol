# モジュール08設計：COBOL + 実データベース

本書ではモジュール08のschema、金額型、schema版、冪等キー、トランザクション境界を説明します。フィールド契約は[銀行システム設計](../../../docs/curriculum/BANK-SYSTEM.md)で凍結されています：CUSTOMER v1 = 27B、ACCOUNT v1 = 47B、TRANSACTION v1 = 55B。

## 1. ツールチェーン（P1で検証済み、P1は未変更）

| コンポーネント | バージョン/固定値 | 説明 |
|---|---|---|
| OSイメージ | `debian:13-slim@sha256:a29215f6…` | P1と同じdigest |
| GnuCOBOL | 3.2.0（Debian package `gnucobol3`） | 既定dialect、`-std=cobol85`は使わない |
| GixSQL | commit `69e26719ecaca2c31bdf91d7add270b1c0ce2286` | precompiler `gixpp` + `libgixsql` |
| PostgreSQL | `postgres:17@sha256:e3841145…` | 推奨baseline。コースでの実測はこの版のみ |
| ローカルpatch | `gixsql-cursor-null.patch`、`gixsql-closed-cursor.patch` | モジュール08 `db/Dockerfile`はP1の同名patchを直接参照 |

`db/Dockerfile`の命令はP1の`curriculum/validation/database/Dockerfile`と一致します。`scripts/docker-image.sh`はbuild context作成時にP1ディレクトリから2つのpatchをコピーし、**P1ファイルは変更しません**。ビルド後の`cobol-course-gixsql:m08`イメージはP1とlayerを共有します。`scripts/check.sh`はpatch回帰の証拠として`p1-patches.sha256`を記録します。実測環境はLinux x86-64のみです。

## 2. 論理テーブル（`db/schema.sql`、schema_version = 001）

コースの論理テーブルは`customer`、`account`、`account_balance`、`transaction_ledger`、`batch_run`、`batch_commit`です。加えて`schema_version`と教材用`probe_null`があります。

| テーブル | 主な列 | 制約/説明 |
|---|---|---|
| `customer` | `customer_id CHAR(8) PK`、`customer_name VARCHAR(10)`、`balance_demo NUMERIC(8,0)`、`status CHAR(1)`、`contact_note VARCHAR(20)`、`business_date CHAR(8)`、`layout_version` | CUSTOMER v1 27Bに対応。`business_date`はsnapshot次元で、27Bファイルには含めない |
| `account` | `account_id CHAR(10) PK`、`customer_id FK`、`currency`、`balance_sign`、`opening_balance NUMERIC(13,0)`、`closing_balance NUMERIC(13,0)`、`account_status`、`business_date`、`layout_version` | ACCOUNT v1 47Bに対応。期首と期末は別列 |
| `account_balance` | `account_id PK`、`balance NUMERIC(13,0)` | 口座ごとの累計。独立照合用 |
| `transaction_ledger` | `transaction_id CHAR(16)`、`account_id`、`business_date`、`sequence_no`、`direction`、`amount NUMERIC(13,0)`、`status`、`applied_run_id`、**UNIQUE(business_date, transaction_id)** | TRANSACTION v1 55Bに対応。一意業務キーが冪等キー |
| `batch_run` | `run_id PK`、`business_date`、`status` | 試行ごとに1行 |
| `batch_commit` | `business_date PK`、`run_id`、`applied_count` | 業務日ごとの成功commitは1回 |

### 金額型

すべての金額は最小通貨単位の整数（初期JPY=1円）で、`NUMERIC(x,0)`を使い、**浮動小数点は使いません**。テキストインターフェース（47B/55B）の金額は右寄せゼロ埋め13桁10進文字列です。COBOLは`PIC 9(13)`として受け、DBの`NUMERIC(13,0)`へbindします。暗黙の通貨換算はしません。

### Schema版

`schema_version`テーブルには`'001'`を保存します。snapshot抽出時、metadataには`SCHEMA_VERSION=001`と`LAYOUT_VERSION=001`の両方を書きます。版不一致は構造エラー（RC8）です。

## 3. 冪等キーと再実行

- 取引冪等キーは`(business_date, transaction_id)`で、`transaction_ledger`のunique constraintが強制します。
- 業務日commitキーは`batch_commit.business_date`（primary key）です。
- 再実行動作：同一業務日の2回目の実行では各取引で`23505`（unique violation）が発生します。`ROLLBACK TO SAVEPOINT`後に既存行の`applied_run_id`を確認します。
  - 今回の`run_id`と同じ → 同一実行内重複入力 → **RC8**、バッチ全体をrollback。
  - 異なる → 過去の実行で計上済み → **SKIP**、二重引落ししない。
  `batch_commit`の再insertも同じ`23505`となり、失敗にはせず`DAY-ALREADY-COMMITTED`を記録します。
- commit結果不明（commit後に呼出側が失敗と思った場合）：**独立接続**で再実行し、`account.closing_balance`、`transaction_ledger`件数、`batch_commit`件数が変わらないことを検証し、二重適用していないと証明します。

## 4. トランザクション境界と障害

- 接続では`autocommit=off`を明示します。PostgreSQL native cursorには明示的トランザクションblockが必要です。
- 各取引は`SAVEPOINT SP1`で囲みます。一意キー競合時は`ROLLBACK TO SAVEPOINT`でトランザクションを復旧してから重複種別を分類します。PostgreSQLの「statement失敗でトランザクション全体が中断」する仕様下で、これが正しい局所復旧方法です。
- `batch_commit`は`SAVEPOINT SP2`で囲み、`23505`時に局所rollbackします。
- 正常経路の最後は`COMMIT WORK`です。rollback mode、実行内重複、構造エラーは`ROLLBACK WORK`します。
- 接続失敗：無効ポートではSQLSTATE `08001`（connection class 08）→ program RC12。
- cursor経路は「データなし」と「エラー」を区別します。`FETCH`/`SELECT INTO`の枯渇は`02000`、それ以外のSQLSTATEはエラーです。constraint error `23514`で実際のエラー分類を示します。

## 5. RC方針

| RC | 意味 | 公開 |
|---:|---|---|
| 0 | 業務差異なし / commit成功 / retryで既存処理をskip | はい |
| 4 | snapshotと上流の業務データ差異 | はい（差分reportを添付） |
| 8 | 構造エラー / 実行内重複取引 | いいえ（rollback） |
| 12 | build、接続、SQL system error、照合失敗、公開失敗 | いいえ |

## 6. 既知の制限（検証済みと主張しない範囲）

- Linux x86-64のみ。macOS/WSL/ARMは未検証です。
- PostgreSQL 17のエラーコードのみ。`23505`/`23514`/`02000`/`08001`等はPostgreSQLの意味であり、DB2の`-803`等のhost error codeへ直接変換**してはいけません**。
- 実ネットワーク切断時の中断や並行lock競合は未検証です。「無効ポートの接続失敗」とcommit後の冪等再実行のみ実施しました。
- snapshotとSAVEPOINTの動作は固定commitのGixSQLと2つのローカルpatchに依存します。版を変えた場合は再検証が必要です。
