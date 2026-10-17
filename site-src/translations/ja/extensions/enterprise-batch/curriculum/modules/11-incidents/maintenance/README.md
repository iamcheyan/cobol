# メンテナンス変更 11.5：企業顧客区分を1桁から2桁へ（学習者課題）

> これは LEGACY メンテナンス変更の**調査段階**です。まず影響調査を提出し、レビュー承認後に実装変更と移行／ロールバックを行ってください。**調査より先に PIC を変更してはいけません**。
> インターフェース変更仕様は [LAYOUT-V1-V2.md](LAYOUT-V1-V2.md) を参照してください。

## 1. 要件

上流業務から、**企業顧客マスター**の顧客区分（classification）を **1桁**から**2桁**へ拡張する要望があります。この区分は**独立してバージョン管理される企業顧客レイアウト**にあり、27バイトの canonical CUSTOMER v1 の第27バイトではありません（そこはレコード状態 A/D であり、教材インターフェースは変更しません）。

- V1：`CUSTOMER-CLASSIFICATION PIC X(1)`、値 `A/B/C/D`、レイアウトバージョン `001`、レコード幅 **23バイト**（ベースライン契約）。
- V2：`CUSTOMER-CLASSIFICATION PIC X(2)`、値 `A1/B1/C1/D1`、レイアウトバージョン `002`、レコード幅 **24バイト**。
- **既存の V1 ファイルをその場で書き換えてはいけません**。移行に加え、並行検証とロールバック手順が必要です。

> CUSTOMER v1 の第27バイトを使えない理由：canonical の規約では、このバイトは**レコード状態**（A は有効、D は停止）です。これを「顧客区分」として扱うと、凍結契約を壊します。`curriculum/bank/README.md` と `../../../../docs/curriculum/BANK-SYSTEM.md` §2 を参照してください。コース canonical の大規模レコードはモジュール07 L4 の `ENTERPRISE-CUSTOMER-V1`（175フィールド／1778バイト）です。本演習の23バイトレイアウトは、同じ区分フィールドの意味だけを保つ独立名称 `ENTERPRISE-CLASS-V1`（Copybook の先頭コメントを参照）を使用し、canonical と同名にしてバージョン間のずれを招かないようにしています。

## 2. 対象システム

調査対象はモジュール11の凍結スナップショット `system/` です。企業顧客区分は、**独立してバージョン管理される企業レイアウト**と、それを読み込む／移行する経路にあります。

- ベースライン Copybook：`maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY`（レイアウト `001`、23バイト：version/id/status/name/classification）。
- 区分を読み取り出力する参考プログラム：`instructor/modules/11-incidents/maintenance/M11CUST2.COB`（V2、24バイト）。
- 移行／ロールバック／並行検証ツール：`instructor/modules/11-incidents/maintenance/migrate-customer.py`。
- 入力：`fixtures/enterprise-customer/customer.v1`（V1、23バイト）。
- 下流インターフェース（企業区分抽出）：行形式 `CLASS|<id>|<class>`（1桁から2桁へ）。
- **注意**：夜間フローの `system/cobol/M11CUST.COB` は canonical CUSTOMER v1 の**レコード状態**を読み、下流公開物 `publish/<run_id>/customer-status.txt`（`STATUS|<id>|<status>`）を出力します。企業区分とは**別のもの**なので変更しないでください。
- 文書：リポジトリルートの `../../../../docs/curriculum/BANK-SYSTEM.md`（凍結契約）、`../../../../docs/curriculum/AUTHORING-STANDARD.md` §6（変更の納品要件）。

## 3. 納品物（レビュー前）

1. **影響調査書**（必須）：
   - フィールド定義：フィールド名、PIC、バイトオフセット、長さ、許容値、バージョン。
   - **すべての使用箇所**：Copybook、プログラム、ソート／比較キー、ファイル、DB、Shell、JOB、帳票、下流インターフェース（項目ごとにファイルパスと行番号）。
   - **依存関係図**：読み手と書き手、上流／下流の方向。
   - **未確認事項**：不確実または未検証の項目（例：実DBの列定義、外部利用者）。
2. **修正対象一覧**：Copybook／プログラム／ファイル／DB／Shell／JOB／設計書／下流インターフェース／担当者ロールについて、変更内容、理由、リスクを項目ごとに列挙します。
3. **修正方針**：V1/V2 互換戦略、移行手順、ロールバック手順、データ切り替えと並行検証（V1/V2 比較）計画。
4. **テストケース**：正常、境界、異常、バージョン間、全フロー、復旧を対象に、各項目を `入力 → 期待する RC/出力 → 証拠の場所` で記述します。
5. **Evidence 計画**：各テストの期待結果と証拠の保存場所。

> 納品物は Markdown で提出してください。必要に応じてこのディレクトリに `TEMPLATES/` を作成し、表のひな形を置けます。レビュー後（実装段階）の参考実装と証拠は `instructor/modules/11-incidents/maintenance/` にあります。

## 4. レビュー後（実装段階）の参考

実装要件：`ENTERPRISE-CLASS-V2`（24バイト、`X(2)`）の追加／実装、読取プログラムと下流インターフェース形式の更新、移行／ロールバックツールの提供、V1/V2 の並行検証、全フローの回帰および復旧検証。**CUSTOMER v1（27バイト）は変更しません**。参考実装と証拠は `instructor/modules/11-incidents/maintenance/` にあり、`starter/M11CUST2.COB` には（ビルド可能ですが未完成時は RC12 を返す）初期骨組みがあります。

## 5. 既存実装の実行と回帰（調査用の読み取り専用証拠）

> 移行／ロールバックツールは **Python スクリプト**（`migrate-customer.py`、shebang は `#!/usr/bin/env python3`）です。`python3` またはスクリプトの直接実行を使ってください。**bash で実行してはいけません**（bash は Python ソースをシェルとして扱い、構文エラーになります）。以下のコマンドはリポジトリルートで実行し、各パスはリポジトリ相対です。

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"   # 拡張コースのルート
mod=curriculum/modules/11-incidents
ins=instructor/modules/11-incidents

# V1 -> V2 へ移行（python3；元の V1 は変更せず、新しいファイルを書き出す）
python3 "$ins/maintenance/migrate-customer.py" \
  to-v2 "$mod/fixtures/enterprise-customer/customer.v1" /tmp/ent.v2
cat /tmp/ent.v2                      # 00200000001AALICE     A1 ...

# 参考 v2 抽出器をビルドして実行
rm -f /tmp/m11cust2
bash "$mod/system/scripts/build.sh" /tmp/m11cust2 "$ins/maintenance/M11CUST2.COB"
M11CUST_INPUT=/tmp/ent.v2 M11CUST_EXTRACT=/tmp/class.v2 \
M11CUST_REPORT=/tmp/rep.v2 /tmp/m11cust2 && cat /tmp/class.v2
# CLASS|00000001|A1 ...

# canonical CUSTOMER v1 状態抽出（回帰：この変更の影響を受けない）
rm -f /tmp/m11cust
bash "$mod/system/scripts/build.sh" /tmp/m11cust "$mod/system/cobol/M11CUST.COB"
M11CUST_INPUT="$mod/fixtures/normal/customer_seed.dat" \
M11CUST_EXTRACT=/tmp/status.v1 M11CUST_REPORT=/tmp/rep.v1 /tmp/m11cust
cat /tmp/status.v1          # STATUS|00000001|A ...

# 参考実装のメンテナンス自己検査（移行／ロールバック／並行／バージョン間／異常／オフセットと正解バイト）
bash "$ins/maintenance/check.sh"
```

## 6. 必ず回答する項目（AUTHORING §6）

- フィールド定義、すべての使用箇所、依存関係図、未確認事項は何ですか？
- フィールド幅を変更すると、後続フィールドのどのオフセットが移動しますか？ソートキーや比較にはどう影響しますか？
- V1 ファイルをどう扱いますか（拒否／変換）？その場で書き換えてはいけない理由は何ですか？
- 移行、切り替え、ロールバックをそれぞれどう行いますか？並行検証で同等性をどう証明しますか？
- CUSTOMER v1 の第27バイトと企業区分はどういう関係ですか？混同してはいけない理由は何ですか？
- どの外部インターフェースと下流を対象にしましたか？未検証項目をどう明記しましたか？
