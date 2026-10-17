# 01 COBOL とレガシーシステム（3時間）

推奨学習時間は3時間（読解、実験、証拠の整理を含む）。前提：ターミナルを使えること、テキストを編集できること、変数・条件・ループを理解していること。
メインフレームやデータベースの経験は不要です。Linux x86-64 のみ実機で検証済みです。macOS/WSL/ARM は未検証です。

## 1. 業務背景：銀行に夜間バッチが必要な理由

この模擬銀行は日中、**オンライン（online）**チャネルで顧客の要求を受け付け、1件ずつ即時に反映します。夜間には**夜間 Batch（バッチ）**を実行し、営業日終了時点で固定された入力をまとめて処理して、翌日の期首残高、拒否明細、異常一覧、後続システム向けファイルを作成します。オンライン処理が重視するのは**低遅延、単件処理**です。Batch が重視するのは**再実行可能性、照合可能性、1回の実行で1バッチを処理すること**です。

学習者の課題：レガシーシステムを引き継いだばかりの保守開発者として、まず環境と全体像を把握し、「これはプログラムか JOB か」「入力元と出力先はどこか」「JOB が失敗したら何が起きるか」に答えられるようにします。自分でコンパイルして実行し、ビルド失敗を特定します。本モジュールでは**環境の証拠**、**最小限の銀行バッチ入口**、**ソースから実行ファイルまでの関係図**を作成し、後続モジュールで実際の口座・取引データを拡張する土台にします。

本モジュールで説明できるようにする重要な区別：

- **Program（プログラム）**：コンパイルして実行できる COBOL の単位で、明確なデータ処理を担当します。
- **JOB（ジョブ）**：パラメーター、入力スナップショット、作業ディレクトリ、ロック、検証、公開、ログ、リターンコードを組み合わせた実行オーケストレーションです。本モジュールでは `scripts/run.sh` が JOB、`BANK-ENTRY.COB` が Program の役割を担います。
- **営業日（business date）**：パラメーターで明示します。マシンの現在日付を既定値として使ってはいけません。
- **RC 0/4/8/12**：本コースでは 0=正常、4=許容される業務警告、8=業務または契約上の異常、12=システム異常と定めます。

初期システム図（後続モジュールで段階的に拡張します）：

```mermaid
flowchart LR
  ONL[オンライン取引] --> TX[取引入力]
  TX --> J001[JOB001 受領と検証]
  J001 --> J002[JOB002 検証とクレンジング]
  J002 --> J005[JOB005 突合/記帳]
  J005 --> J008[JOB008 後続ファイル公開]
  J008 --> RPT[日次レポート/拒否明細]
```

## 2. 入力元、形式、前提条件

入力は `ACCOUNT v1`（[銀行システム設計](../../../docs/curriculum/BANK-SYSTEM.md) 第2節と一致する**凍結済みインターフェース**）です。**1レコード47バイト**、ASCII、各レコードの後ろに `LF` が付きます。`LF` はレコード長に含めません。フィールドのオフセット、文字コード、有効値は [DESIGN](DESIGN.md) を参照してください。営業日は JOB パラメーターで指定します（本モジュールの既定例は `20261009`）。上流が保証するのは当営業日の口座スナップショットだけです。長さ、文字種、ソート順はこの JOB 自身で検証する必要があり、信頼してはいけません。

## 3. クリーンな checkout からのビルド、実行、リセット

必要環境：Linux x86-64、GnuCOBOL 3.2、Bash、coreutils、Python 3（検収ドライバーのみ）。参照実装は `instructor/modules/01-foundations/` にあります。`starter/` はコンパイルできますが未実装で、RC12 を返します。すべての出力は**新しい**出力ディレクトリに書き込みます。入力や既存出力は上書きしません。

> **学生用パッケージ（`instructor/` なし）の動作**：公開リポジトリには参照実装が含まれ、`run.sh` は既定でそれをコンパイルするため、以下の `normal` 例は RC0 を返します。`package-student.sh` で生成した学生用パッケージには `instructor/` が含まれないため、`run.sh`/`build.sh` は既定で自分の `starter/BANK-ENTRY.COB` をコンパイルします。starter はコンパイル可能なので `build.sh` は RC0 のままですが、TODO を完成するまでは設計どおり `run.sh` は RC12 を返し、公開もしません。別のソース（自分で保存した完成版など）を検証する場合は `COURSE_SOURCE=/path/to/BANK-ENTRY.COB` を設定してください。

```bash
lab=curriculum/modules/01-foundations
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/account.dat" /tmp/bank-m01-run 20261009
rc=$?
set -e
test "$rc" -eq 0
diff -u "$lab/expected/normal.control.txt" /tmp/bank-m01-run/control.txt
bash "$lab/scripts/check.sh"            # 契約のエンドツーエンド検収
```

```bash
bash "$lab/scripts/build.sh" /tmp/bankentry   # 練習コードだけをコンパイル
bash "$lab/scripts/env-report.sh"             # 環境とソース→実行ファイルの関係を示す証拠
bash "$lab/scripts/reset.sh" /tmp/bank-m01-run # リセット（マーカー付き出力ディレクトリのみ許可）
```

実行で上書きされる**派生ファイル**：新しい出力ディレクトリ内の `control.txt`、`accepted.dat`、`rejected.dat`、`inputs.sha256`、`outputs.sha256`、`run.txt`、`compiler.txt`、`source.sha256`。ソースfixtureと `expected/` は変更されません。`reset.sh` が削除するのは `run.txt/inputs.sha256/outputs.sha256/control.txt` のマーカーを含み、リポジトリ内にないディレクトリだけです。

## 4. 期待される出力、RC、件数、独立検算

`control.txt` は固定幅サンプルです（件数は 12 桁固定幅で、07モジュールと同じです）：

```text
JOB|BANK-ENTRY|V1
BUSINESS-DATE|20261009
CONTROL|READ=000000000003|ACCEPTED=000000000003|REJECTED=000000000000
```

| fixture | RC | READ | ACCEPTED | REJECTED | 意味 |
|---:|---:|---:|---:|---:|---|
| normal | 0 | 3 | 3 | 0 | A/F/C はすべて有効 |
| empty | 0 | 0 | 0 | 0 | 契約上、空ファイルを許可 |
| single | 0 | 1 | 1 | 0 | 最終レコード |
| unknown-status | 4 | 1 | 0 | 1 | 状態 Z を個別に拒否し、公開は継続 |
| 構造fixture 9件 | 8 | — | — | — | 長さ/LF/CR/口座/レイアウト/日付/ソート。公開しない |

期待値は ACCOUNT v1 契約から手作業で検算します。**プログラム出力のコピーではありません**。検算手順は [expected/README.md](expected/README.md) を参照してください。`check.py` は制御レポートをバイト単位で比較し、元のfixtureから `accepted.dat`/`rejected.dat` を独立して導出します。ランナー内の `verify-publish.py` も独立に再計算し、両者が一致しなければ失敗します。

> 本モジュールは「環境と入口」の基礎であり、**金額計算は行いません**（金額の意味はモジュール02の `balance_demo` から導入し、残高は口座モデルから導入します）。そのため制御レポートには読取・受領・拒否件数の整合性だけがあり、金額列はありません。金額の整合性はモジュール07の記帳演習で検収します。

## 5. どこを変更するか、壊してはいけないインターフェース

入口コードは `starter/BANK-ENTRY.COB` にあります（TODO はファイル内コメント参照）。参照実装は `instructor/modules/01-foundations/BANK-ENTRY.COB` です（公開リポジトリにのみ存在します。学生用パッケージにはありません）。`COURSE_SOURCE` に自分の完成版を指定すれば、`run.sh`/`check.sh` で検収できます。**壊してはいけない**インターフェース：

- ACCOUNT v1 の47バイトレイアウトとフィールドオフセット（本モジュールでは読み取り専用で、再定義しません）。
- `control.txt` の行形式と12桁固定幅のカウント。
- ランナーの CLI 契約 `run.sh INPUT NEW_OUTPUT YYYYMMDD` と RC の規約。

## 6. 意図的に条件を壊す方法、調査、復旧

各レッスンには少なくとも1つ、再現可能な障害があります：

- **01.1 営業日の誤り**：`bash scripts/run.sh fixtures/boundary/empty.dat /tmp/x 20260230`
  → JOB が営業日を検証（`TEST-DATE-YYYYMMDD`）し、失敗します。RC8、出力なし。調査では「日付形式/暦」と「レコード日付と営業日の不一致」を別のエラーとして区別します。
- **01.2 ビルド失敗**：`experiments/build-failure/BROKEN-PERFORM.COB`（未定義段落）と `BROKEN-AREA.COB`（Area A から文が開始）。`cobc -fsyntax-only` は非0を返します。コンパイラーの行番号/列番号で箇所を特定します。
- **01.3 列の切り捨て**：`experiments/columns/TRUNC-BAD.COB.src` の `COMPUTE` 行は73列目に数字があり、コンパイラーに黙って無視されます。`111110` が `11111` になり、結果は `111111` から `11112` に変わります。復旧例は `TRUNC-GOOD.COB`（リテラルを12〜72列に置く）です。

調査の原則：元のfixtureと元のRCを保持し、コンパイラー/ランナーの診断から原因を特定し、最後に最小限の修正で検証します。fixture やアサーションを変更して「修復」してはいけません。

## 7. プラグインの使い方とターミナルでの代替

- **プラグイン**：固定形式ルーラーで第7/8/12/72列を確認します。ソースの任意の行にカーソルを置き、Winbar の Area A/B 表示と72列超過の赤い波線を確認します。`:CobolGotoDef` で `PERFORM` の対象段落へ移動します。`COPY` 行では `:CobolGotoCopybook` で正規インターフェースを開きます。
- **ターミナルでの代替**：`awk '{print NR, length($0)}' ファイル` で72列を超えていないか確認します。`rg -n 'PERFORM|DIVISION|SECTION' ファイル` で構造を確認し、`cobc -fsyntax-only ファイル` で診断を発生させます。プラグインの推定値をバイトレイアウトの最終判断に使ってはいけません。

## 8. 提出する証拠と失敗条件

[evidence/README.md](evidence/README.md) のテンプレートに従い、環境証拠（`cobc -V`、`uname`、`file`/`ldd` の出力）、normal/empty/single/unknown-status の実行コマンドと元のRC、control レポート、RC8で公開されない証拠、列切り捨ての前後の結果、入力 SHA256 を提出します。**失敗条件**：`check.py` または `verify-publish.py` がアサーションと一致しない、RC8のfixtureで出力ディレクトリが作られる、ソースfixtureの SHA256 が変わる、プログラムの現在出力を expected として使う。

## レッスン課題とプラグイン/ターミナルの対応

### レッスン 01.1 営業日、オンライン対夜間 Batch、Program 対 JOB

- システム図を読み、内容を説明します。営業日を明示的に渡す必要がある理由を説明します（`env-report.sh` 実行後、`run.txt` の `business_date` を確認）。
- **変更演習**：`run.sh` の営業日を `20240229`（うるう年）と `20260230`（無効日）に変えて、RCを予測して照合します。
- **再現可能な障害**：第3引数を省略すると使い方エラー RC12、不正な暦日を渡すと RC8。
- **プラグイン/ターミナル**：プラグインでは Winbar に現在の段落を表示します。ターミナルでは `sed -n` で `run.txt` を確認します。

### レッスン 01.2 GNUCOBOL のコンパイル/リンク/ランタイム/ビルドディレクトリ

- `env-report.sh` を実行し、`BANK-ENTRY.COB → cobc → C → cc → bankentry(ELF) → libcob` の関係図を描きます（[DESIGN](DESIGN.md) 参照）。
- **変更演習**：`starter/BANK-ENTRY.COB` をコンパイルして、まず RC12 を返すことを確認します。次に TODO を完成させて normal を成功させます（`instructor` の参照実装と比較）。
- **再現可能な障害**：`experiments/build-failure/BROKEN-PERFORM.COB` と `BROKEN-AREA.COB` をそれぞれコンパイルし、診断から失敗行を特定して理由を説明します。
- **プラグイン/ターミナル**：プラグインでは診断の波線を使い、ターミナルでは `cobc -fsyntax-only` を使います。

### レッスン 01.3 DIVISION/SECTION/Paragraph、ピリオドとスコープ、固定/自由形式

- 参照ソースから4つの DIVISION、`1000-MAIN` 段落、各段落のピリオド境界を見つけます。
- **変更演習**：`experiments/columns/FIXED.COB` と `FREE.COB`（同じロジック、2種類の形式）を比べ、出力が一致することを確認します。次に `TRUNC-BAD.COB.src` を `.COB` にコピーしてコンパイル・実行し、結果が `11112` になる理由を説明します。その後 `TRUNC-GOOD.COB` で `111111` に修正します。
- **再現可能な障害**：意図的に行を第72列より長くし、コンパイラーが黙って切り捨てる様子を観察します（エラーは出ず、結果が誤ります）。
- **プラグイン/ターミナル**：プラグインのルーラーと列超過警告を使います。ターミナルでは `awk` で列幅を数え、`cobc` でコンパイルを確認します。

参照実装、根本原因、ヒントの段階、採点説明は `instructor/modules/01-foundations/` を参照してください。
