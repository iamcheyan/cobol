# モジュール04 複雑なデータ構造（04.1–04.3）

目安は5時間です。前提としてモジュール02（01/05/77/88、グループ項目）とモジュール03（バイト配置）を学習してください。
本モジュールでは構造と配置のみを扱い、凍結済み契約CUSTOMER v1=27B、ACCOUNT v1=47B、TRANSACTION v1=55Bは変更しません。04.3ではモジュール07の175フィールド企業顧客レコードを再利用します。

## 1. 業務上の必要性（要件）

未知のBatchを引き継ぐと、レコードに**別名ビュー**（同じバイト列を二通りに読む）、**繰り返し可能な部分**（住所行、電話番号）、**可変長部分**（個数によって長さが決まる）が含まれていることがあります。さらに厄介なのは、顧客分類フィールドを1桁から2桁に広げると、その後にある**すべてのフィールドのオフセットが移動する**ことです。本モジュールではこれらの構造を読み解き、追跡可能なフィールドカタログを作り、「あるフィールドを変更すると後続のどの項目が移動するか」に答えられるようにします。

## 2. 入力元、形式、前提条件

- 04.1/04.2では入力を読みません。プログラム内で構造を宣言し、`LENGTH OF` / オフセットの証拠を出力します。
- 04.3では**生のバイナリ**レコードストリームを読みます。各 `ENTERPRISE-CUSTOMER-V1` は1,778バイトで、区切り文字はありません。canonical Copybookは `instructor/modules/07/05-large-record/ENTERPRISE-CUSTOMER-V1.CPY` にあり、**読み取り専用で再利用**します。
- フィールドカタログ [FIELD-CATALOG.csv](FIELD-CATALOG.csv) はモジュール07 canonicalカタログの複製で、名前付きの葉フィールドが175個あります。オフセットは1起算、グループ項目はバイトを占めず、数合わせのFILLERもありません。
- フィクスチャは [scripts/generate-fixtures.py](scripts/generate-fixtures.py) で決定的に生成します（正常/境界/不正）。SHA256は [fixtures/SHA256SUMS](fixtures/SHA256SUMS) を参照してください。
- 前提環境：GnuCOBOL 3.2、Linux x86-64、デフォルト方言。

## 3. ビルド / 実行 / リセット（任意の作業ディレクトリから）

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
bash curriculum/modules/04-structures/scripts/run.sh 04.1 /tmp/m04-shape
bash curriculum/modules/04-structures/scripts/run.sh 04.2 /tmp/m04-copy
bash curriculum/modules/04-structures/scripts/run.sh 04.3 /tmp/m04-ent \
     curriculum/modules/04-structures/fixtures/normal/enterprise-2.dat
cat /tmp/m04-ent/report.txt
```

- 04.3の入力バイト数が1,778の整数倍でない場合、ランナーは先にRC8を判定し、**公開しません**。
- 出力先は存在してはなりません（上書き禁止）。非公開のstageをすべて検証した後にのみ原子的に公開します。失敗時または同名ディレクトリが既にある場合は拒否します（RC12）。
- リセット：`bash curriculum/modules/04-structures/scripts/reset.sh /tmp/m04-ent`。ファイル一式がそろい、`manifest.sha256` の検証に成功した場合に限って出力ディレクトリを削除します。

生成ファイル：`report.txt`、`stderr.txt`、`compiler.txt`、`source.sha256`、`manifest.sha256`。04.3では入力スナップショット `input.dat` と `inputs.sha256` も生成します。

## 4. 期待される出力、RC、独立検算

- **04.1 RC0**：`REDEFINES` の別名ビューを重複して長さに数えません（親グループ=18バイト）。`66 RENAMES` の長さは7です。`OCCURS ... INDEXED BY` は索引で値を取得します。`OCCURS DEPENDING ON` の `LENGTH OF` はカウントに応じて変わります（count=3→17、count=7→37）。[expected/04.1-structures.txt](expected/04.1-structures.txt) を参照してください。
- **04.2 RC0**：V1=1,778、V2（`CUSTOMER-CLASSIFICATION` を `X(1)` から `X(2)` に拡張）=1,779、シフトは+1です。[expected/04.2-copy-shift.txt](expected/04.2-copy-shift.txt) を参照してください。
- **04.3**：正常/境界ケースはRC0で、レコードごとの位置フィールドを出力します。構造エラー（長さ、バージョン、ABI、非数値キー）はRC8で公開物はゼロです。[expected/04.3-normal.txt](expected/04.3-normal.txt) などを参照してください。
- **独立検算**：`scripts/check.py` はGnuCOBOLの `ADDRESS OF` を使って175個の葉フィールドを測るプローブプログラムを二つ生成し、カタログと比較します。さらにV1/V2の `LENGTH OF` と主要フィールドのアドレスを測り、「フィールドを一つ広げると後続オフセットが+1になる」ことを確認します。プログラム出力を正解として扱いません。
- **公開前の意味検証**：`scripts/run.sh` は公開前に `scripts/verify.py` を呼びます。04.1/04.2では構造の意味から期待レポートを再計算し、04.3では `FIELD-CATALOG.csv` のオフセットとPICを使い、入力の生バイトから各レコードのID/STATUS/SURNAME/CLASS/RISK/SYNCとレコード数を再計算します。`WS-EXERCISES-DONE` を `'Y'` に変えただけの変更、プレースホルダーレポート、レコードの読み飛ばし、誤ったフィールド値はすべて失敗し、**公開されません**。`check.py` に回帰チェックがあります。

## 5. 変更箇所と維持すべき契約

`starter/M04SHAPE.COB`、`starter/M04COPY.COB`、`starter/M04ENTERPRISE.COB` のTODOを実装し、完了後に各 `WS-EXERCISES-DONE` を `'Y'` にします。次の項目を壊してはいけません。

- モジュール07 canonical Copybook（読み取り専用で再利用し、別実装として複製しない）。
- 175フィールドのカタログとオフセット（フィールド幅の変更には§6のV2影響調査が必要）。
- CUSTOMER/ACCOUNT/TRANSACTIONの凍結契約、および固定形式80列ルール。

## 6. 意図的な破壊と復旧（再現可能な障害）

1. **ODOがグループ内の最後にない**：`faults/odo-not-last.COB` は実際の `cobc` エラーでコンパイルを拒否されます。
2. **REDEFINESが再定義対象に隣接していない**：`faults/redefines-not-adjacent.COB` はコンパイルを拒否されます。
3. **フィールド拡張の連鎖オフセット**：`CUSTOMER-CLASSIFICATION` を `X(1)` から `X(2)` に変更すると、当該フィールドのオフセットは変わらず（460）、その後の**すべての**フィールドが+1となり、総長は1,778から1,779になります。V1ファイルをその場で書き換えてはいけません。V2（レイアウトバージョン002）、旧ファイルの拒否/変換、並行比較、ロールバックを設計してください。
4. **構造エラー**：`invalid/` の長さずれ、バージョン、ABI、非数値キーはすべてRC8で公開物ゼロです。

**復旧**：構造または実装を修正して再実行します。ランナーは既存出力ディレクトリを上書きせず、V1フィクスチャも変更しません。

## 7. プラグインの手順と端末での代替手段

- プラグイン：`gd` でフィールド定義へ移動、`K` でCOPYをプレビュー、Aerialで階層を表示、`:CobolCalcRecord` でレコードサイズを推定します。プラグインの推定値を配置の最終根拠にしてはいけません。
- 端末のみで行う場合：`rg -n 'REDEFINES|OCCURS|DEPENDING|COPY REPLACING'`、`awk -F,` で `FIELD-CATALOG.csv` のoffsetに基づいて切り出し、`od -An -tc` / `xxd` で生レコードを確認します。いずれも単独で検算できます。

## 8. 提出する証拠と失敗判定

提出物：ソースとSHA256、コンパイラーのバージョン、各レッスンのコマンドと実際のRC、175フィールドカタログと `ADDRESS OF` 実測値の照合、V1→V2拡張後のオフセット移動一覧、構造エラー時のRC8・公開物ゼロの証拠、`check.sh` の出力。テンプレートは [evidence/README.md](evidence/README.md) にあります。

**失敗判定**：FILLERでフィールド数を合わせる、REDEFINES/OCCURSを二重に長さへ数える、可変長ODOを固定長と扱う、PIC変更前に影響調査をしない、実測オフセットの代わりにプラグインのスクリーンショットだけを提出する、または `WS-EXERCISES-DONE` を `'Y'` にしただけのプレースホルダー/誤ったレポートを提出する（`run.sh` の独立意味検証が拒否し公開しません）。いずれも失敗です。
