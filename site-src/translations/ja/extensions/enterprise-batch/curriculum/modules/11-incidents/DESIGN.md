# モジュール11設計：障害調査フレームワーク、凍結スナップショット、保守変更

アウトライン11.1–11.5に対応します。本書では調査対象システム、障害パッケージの構造、証拠モデル、保守変更を定義します。学習者の課題と受け入れ基準は[README](README.md)、講師向け根本原因は`instructor/modules/11-incidents/`を参照してください。

## 1. 調査対象システム：凍結スナップショット `system/`

モジュール11には、モジュール10のJOB001–JOB009設計に由来する、**単独で実行可能な**銀行夜間システムのスナップショットが含まれます（正規のソースはモジュール07/10の参考実装です）。このスナップショットは「見知らぬシステムを引き継いだ」現場です。障害パッケージはこの環境で再現され、**モジュール01–10のファイルは変更しません**。

```mermaid
flowchart LR
  J1[JOB001 receive] --> J2[JOB002 validate<br/>M11VAL.COB]
  J2 --> J3[JOB003 sort<br/>system sort + verify]
  J3 --> J4[JOB004 db-snapshot<br/>db.py]
  J4 --> J5[JOB005 match<br/>M11MATCH.COB]
  J5 --> J6[JOB006 db-apply<br/>db.py idempotent]
  J6 --> J7[JOB007 control+cust<br/>control.py + M11CUST.COB]
  J7 --> J8[JOB008 publish<br/>atomic + manifest]
  J8 --> J9[JOB009 complete]
```

| JOB | 入力（読み取り専用） | 出力／チェックポイント | 許可される先行RC | 失敗後 |
|---|---|---|---|---|
| 001 | 受信ディレクトリ + MANIFEST | `snapshot/`（不変）+ チェックサム | — | RC8/12では検証に進まない |
| 002 | スナップショット + レイアウト契約 | `work/validate/` | RC0/4のみ | 構造エラーRC8、業務上の拒否RC4 |
| 003 | 受理済み取引 | `work/sorted_tx.dat` + 順序の証拠 | RC0のみ | 一時領域／権限エラーRC12 |
| 004 | 営業日 + DBストア | `work/db/`スナップショット | RC0のみ | 失敗はRC12、古いデータは使わない |
| 005 | スナップショット口座 + ソート済み取引 | `work/closing/`（候補、隔離） | RC0/4 | 逆順／オーバーフローRC8、候補は公開しない |
| 006 | 候補 + 冪等キー | 台帳 + commit | RC0/4 | まず台帳を確認し、復旧方法を判断 |
| 007 | 明細／拒否／台帳 + 顧客スナップショット | `work/control/`、`work/customer/` | RC0のみ | 不一致はRC8、公開不可 |
| 008 | 照合済み候補 | `publish/<run_id>/` + CURRENT | RC0のみ | commit済みなら公開だけを復旧 |
| 009 | 完了証拠 | `state/complete.marker` | RC0のみ | 状態を確認し、元の実行を上書きしない |

RCの意味はモジュール10と同じです：`0/4/8/12`。規約外の子プロセス終了コードはShell境界でRC12に変換します。

## 2. 障害パッケージの構造（11.1–11.4）

各`INC-2026-00X/`には次が含まれます。

```text
INC-2026-00X/student/
  README.md            症状と影響範囲 → タイムライン（根本原因は含まない）
  hints.md             段階式ヒント
  run.sh               このパッケージだけで再現（--keep-sceneで現場を保持）
  input/               元入力の複製（不正データを含む場合あり、未変更）
  scene/
    scheduler-status.txt  スケジューラのJOB状態とRC
    run.env               パラメータ（営業日/run_id/パス）
    MANIFEST              入力一覧（上流で宣言制御合計を指定する場合を含む）
    console.txt           スケジューラのコンソール出力
    logs/                 JOB Logとnightly.log
    source/               Shell、COBOL、Pythonソースの複製
    copybooks/            v1凍結インターフェースの複製
    db-schema.sql / sql-log.txt / ledger-victim.dat  （DB契約に関係する事象）
    published-*.txt/.dat  公開済み成果物（RC0の不具合事象）
```

講師用の`instructor/modules/11-incidents/inc-XX/`には、根本原因、発生条件、段階式ヒント、誤解を招く手掛かり、証拠、最小修正、復旧／再実行、再発防止、採点項目を保存します。コード不具合の事象には`fix/`とRED→GREENハーネスも含まれます。事象IDと講師番号の対応は講師パッケージの`INSTRUCTOR.md`だけに記載します。

## 3. 7種類の事象と期待動作（発生条件／根本原因は講師用パッケージを参照）

事象IDは中立で、根本原因を示しません。次の表は`as_found_rc`／`desired_rc`／`publish_before`／`publish_after`の契約だけを示し、`expected/incidents.txt`に記録します。

| 事象 | as-found RC | 期待RC | as-foundの公開 |
|---|---:|---:|---|
| INC-2026-001 | 8 | 8 | なし |
| INC-2026-002 | 0（不具合） | 8 | **あり（不具合）** |
| INC-2026-003 | 12 | 12 | なし |
| INC-2026-004 | 8 | 8 | なし |
| INC-2026-005 | 12 | 12 | なし |
| INC-2026-006 | 0（不具合） | 8 | **あり（不具合）** |
| INC-2026-007 | 8 | 8 | なし |

コード不具合事象の修正は`instructor/.../tools/red-green.sh`でRED→GREENを実演します。

## 4. 証拠と鮮度

- 入力は不変です。障害パッケージの`input/`は元データの複製です。`run.sh --keep-scene`は失敗時の`work/`現場を保持します。共有`fixtures/`は`SHA256SUMS`を持ち、`check.py`が実行前後に照合します。**実行によってfixtureを変更してはいけません**。
- 修正時に不正データを書き換えたり、アサーションを緩めたりしません。コード不具合の修正では**検証を追加**し、不正入力をRC8で止めます。「アサーションを通す」ために変更しません。
- 復旧では冪等台帳／commit／Manifest／チェックサムで事実を確認します。Shellログの最後の行だけからトランザクション状態を推測してはいけません。

## 5. 保守変更（11.5）の設計

要件：**独立したバージョン管理対象の企業顧客レイアウト**`ENTERPRISE-CLASS`にある顧客区分`CUSTOMER-CLASSIFICATION`を`PIC X(1)`から`PIC X(2)`へ、レイアウトを`001`から`002`へ変更し、値も`A→A1`などにします。旧ファイルをその場で書き換えてはいけません。この区分を27バイトのCUSTOMER v1の第27バイト（レコード状態A/D）に埋め込んでは**いけません**。CUSTOMER v1は変更しません。成果物の順序は、まず調査文書5点を作成し、レビュー後に実装します。

> **名称と関係**：コース正規版の大きなレコードはモジュール07 L4の`ENTERPRISE-CUSTOMER-V1`（175フィールド／1778バイト）です。本モジュールの23バイト演習レイアウトは、同名で異なるレイアウトとなるのを避けるため、意図的に独立名称`ENTERPRISE-CLASS-V1`を使用します（バージョンずれ防止）。両者は同じ区分フィールドの意味（`CUSTOMER-CLASSIFICATION`を`X(1)`から`X(2)`へ）を共有します。本モジュールはその意味を小さく投影した演習用です。

基準：`maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY`（レイアウト001、23B）。目標：`ENTERPRISE-CLASS-V2`（レイアウト002、24B）。詳細設計は`instructor/modules/11-incidents/maintenance/`を参照してください。成果物は`INFLUENCE-INVESTIGATION.md`（影響調査書）、`CHANGE-LIST.md`（修正対象一覧）、`CHANGE-PLAN.md`（修正方針）、`TEST-CASES.md`、`EVIDENCE-PLAN.md`、参考実装は`M11CUST2.COB` + `migrate-customer.py` + `check.sh`です。

重要なバイト効率：区分フィールドはレコードの**末尾**にあるため、V1→V2で増えるのは1バイトだけで、それ以前のフィールドのオフセットは変わりません。ただし、レコード全長の変更は固定長読み取り、チェックサム、下流の切り出しに影響します。

## 6. 再利用と境界

- スナップショットのオフラインDB／制御／公開補助（`db.py`／`control.py`／`manifest.py`／`verify_publish.py`／`common.sh`）は、障害現場用にモジュール10から**複製**したものです。正規版は引き続きモジュール10にあり、相互参照せず、ずれを避けます。
- 障害資料は**複製**です。モジュール01–10のファイルは変更しません。
- JCL/JP1は読むための対応表のみ（モジュール10が提供）。本モジュールはメインフレーム上で実行可能とは主張しません。
- 対象プラットフォームはLinux x86-64のみ。実DBは**未接続／未検証**であり、DB関連の証拠には「DB未検証」と記載します。

## 7. システム構成

小規模な障害fixtureは人手で検算できる規模を保ちます。スナップショットシステムはCOBOL、Shell、Pythonで構成され、コースの重点は見知らぬシステムを読み解いて問題を調査することです。
