# 03 データのバイト表現（03.1–03.3）

推奨学習時間は5時間。前提：モジュール02（PIC、`V`、暗黙小数、`S`）。本モジュールでは「同じ金額がメモリー/ファイル上で実際にどのバイトになるか」だけを説明し、銀行インターフェースは変更しません。凍結済み契約は不変です：CUSTOMER v1=27B、ACCOUNT v1=47B、TRANSACTION v1=55B（[BANK-SYSTEM](../../../docs/curriculum/BANK-SYSTEM.md) 参照）。

本モジュールでは P1 バイト実験（[validation/layout](../../validation/layout/README.md)）を完全なコースに拡張し、宣言上の桁数と物理バイト数の違い、ABI/エンディアン/ランタイム Data Exception、不正な Packed と誤った位置合わせによる解析を扱います。

## 1. 業務上の必要性（要件）

銀行の夜間バッチ処理は、メインフレームのレガシーファイルと連携する必要があります。これらのファイルでは金額はテキストではなく、`DISPLAY`、`COMP`（二進数）、`COMP-3`（Packed Decimal）のバイトで格納されています。当番開発者はソースを見ずに、生バイト列がいくらを表すか、暗黙小数があるか、符号がどこにあるか、何バイト使うか、別のマシンで変わるかを答えられなければなりません。誤ると Packed の `0x0C` を文字列として走査したり、ビッグエンディアンの二進数をリトルエンディアンとして扱ったりして、金額を誤っても **RC は 0 のまま**になります。本モジュールでは検証可能なバイトの見方を身につけ、「不正な金額は先に拒否し、算術には絶対に使わない」パーサーを作ります。

## 2. 入力元、形式、前提条件

- `M03BYTES` の参照実装は本リポジトリにあります（`instructor/modules/03-bytes/M03BYTES.COB`）。学習者用の開始コードは `starter/M03BYTES.COB` です。
- 03.1/03.2 は入力を読みません。プログラム自身が金額を生バイトとして書き出し、Hex Dump と照合します。
- 03.3 は**生の二進ファイル**を読みます。1レコードは固定長7バイトで、`PIC S9(11)V99 COMP-3`（数字半バイト13個 + 符号半バイト1個 = 14半バイト = 7バイト）です。LF もアラインメント用パディングもありません。
- 前提：GnuCOBOL 3.2、Linux x86-64、既定方言でのみ検収します（`COMP-3` と `FUNCTION TRIM` は GNU 拡張なので、§6のとおり `-std=cobol85` は**禁止**）。合成データは ASCII です。
- fixture：`fixtures/normal/`、`fixtures/boundary/`、`fixtures/invalid/`。SHA256 は [fixtures/SHA256SUMS](fixtures/SHA256SUMS) に記録され、[scripts/generate-fixtures.py](scripts/generate-fixtures.py) が決定的に生成します。

## 3. ビルド / 実行 / リセット（任意の起動ディレクトリから）

`scripts/*` は任意の cwd から実行でき、空白を含むパスにも対応します。出力ディレクトリは**存在してはいけません**（上書きなし）。

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
bash curriculum/modules/03-bytes/scripts/run.sh 03.1 /tmp/m03-l1
bash curriculum/modules/03-bytes/scripts/run.sh 03.2 /tmp/m03-l2
bash curriculum/modules/03-bytes/scripts/run.sh 03.3 /tmp/m03-l3 \
     curriculum/modules/03-bytes/fixtures/normal/mixed-valid.dat
cat /tmp/m03-l3/report.txt
```

- 03.3 の入力バイト数は7の整数倍でなければなりません。そうでなければランナーが RC8 と判定し、出力を**一切公開しません**。
- ランナーは非公開の stage ディレクトリに成果物を作り、すべての検証後にだけ出力ディレクトリへアトミックに名前変更します。失敗時、または同名ディレクトリが既にある場合は拒否します（RC12）。リポジトリのfixtureや他の実験を上書きしません。
- リセット：`bash curriculum/modules/03-bytes/scripts/reset.sh /tmp/m03-l3`。ファイル一式が完全で、`manifest.sha256` の検証に成功した場合だけ出力ディレクトリを削除します。

派生成果物（出力ディレクトリ内）：`report.txt`（stdout）、`stderr.txt`、`compiler.txt`、`source.sha256`、`manifest.sha256`。03.1 では `abi.bin`、03.2 では `amounts.bin`、03.3 では入力スナップショット `input.dat` と `inputs.sha256` も作成されます。

## 4. 期待される出力、RC、独立検算

- **03.1 RC0**：宣言上の桁数と `LENGTH OF` による物理バイト数を確認します。COMP はビッグエンディアン、COMP-5 はネイティブのリトルエンディアンです。期待値は [expected/03.1-declare.txt](expected/03.1-declare.txt) を参照してください。`abi.bin` の先頭8バイトは `01 02 03 04 04 03 02 01`（ビッグエンディアン COMP / リトルエンディアン COMP-5）です。
- **03.2 RC0**：同じ金額 `12345.67` と `-12345.67` の DISPLAY / SIGN SEPARATE / COMP-3 / 整数最小単位 COMP の生バイトを出力します。期待値は [expected/03.2-hexdump.txt](expected/03.2-hexdump.txt) を参照してください。`amounts.bin` は合計59バイトです。
- **03.3**：各レコードについてデコード値 `OK` または拒否理由 `REJECT` を出力します。`REJECTED=0` なら RC0、拒否があれば RC4 です（解析結果自体が納品物なので、レポートは公開されます）。
- 独立検算：`scripts/check.py` には独立した Python 参照モデルがあり、半バイト単位での検証、符号 C/D、暗黙小数点の挿入、ビッグエンディアン整数を使って、すべての hex 値と03.3の全レコードを再計算します。その後 `expected/` とコンパイル済み COBOL の出力を双方向に照合します。検算の説明は [expected/README.md](expected/README.md) を参照してください。
- **公開前の意味検証**：`scripts/run.sh` は公開前に `scripts/verify.py` を呼び出します（`check.py` と同じ独立モデルを使います）。入力の生バイトから期待される `report.txt` と `abi.bin`/`amounts.bin` を再計算し、項目ごとに照合します。完了フラグだけを `'Y'` に変更した場合、TODO のプレースホルダー報告、レコードのスキップ、誤った金額/符号/レコード数はすべて失敗となり、**公開されません**（§6の障害注入参照）。対応する回帰検査は `check.py` に追加されています。

## 5. 変更箇所と壊してはいけないもの

`starter/M03BYTES.COB` の03.1/03.2/03.3の TODO 段落を変更し、完了したら `WS-EXERCISES-DONE` を `'Y'` に設定します。**壊してはいけない**もの：

- 既存インターフェース CUSTOMER v1=27B / ACCOUNT v1=47B / TRANSACTION v1=55B。
- 出力レポートのフィールド順（検査プログラムは行ごとに完全一致で比較します）。
- 固定形式の80列規則（Area A/B、Tab なし、有効なコードは72列以内）。

## 6. 意図的な障害と復旧（再現可能な障害）

1. **不正な Packed 数字半バイト**：`fixtures/invalid/bad-digit-nibble.dat` には `0xA` が含まれます。算術の前に各半バイトを検証して拒否し、`DIGIT-NOT-0-9`、RC4 を出力しなければなりません。
2. **不正な符号半バイト**：`bad-sign-nibble.dat` の最後の半バイトは `0xF` です。`BAD-SIGN-NIBBLE`、RC4 になります。
3. **レコード境界のずれ/長さ誤り**：`truncated.dat`（6B）、`trailing-byte.dat`（8B）は7の倍数ではありません。ランナーは RC8 とし、公開をゼロにします。GnuCOBOL の固定長読取では不足分を `PIC X` の空白で補って `FILE STATUS 00` を返す場合があるため、`FILE STATUS` だけでは検出できません。
4. **厳格な COBOL 85 方言**：`cobc -std=cobol85 -fsyntax-only M03BYTES.COB` は `COMP-3` によりエラーになります。これが AGENTS/§6 でこの引数を禁止する理由です。`check.py` はこの手順が実際に失敗することを検証します。
5. **負のゼロの落とし穴**：`-0.00`（符号 D）と `+0.00`（符号 C）はバイトが異なりますが、数値はどちらも0です。パーサーは C/D をそれぞれ受け入れ、「値が0だから」といって不正扱いしてはいけません。
6. **ホストの Data Exception と GnuCOBOL の実際の動作**（本環境で実測）：数字以外のバイトを `PIC 9` に入れて算術を行うと、IBM メインフレームでは通常 data exception（ABEND `S0C7`）になります。一方、本機の GnuCOBOL 3.2 は**エラーにならず**、誤った値を計算します（実測では `ABC`→124、`XYZ`→901、RC0）。したがって本モジュールでは「まず半バイトごとに検証し、その後に算術」を徹底し、ランタイムの検出に依存しません。

**復旧**：03.3 の不正レコードは「解析後に拒否」するケースなので、レポートを公開します。長さのずれだけは RC8 で公開しません。入力またはパーサーを修正して再実行してください。ランナーは既存の出力ディレクトリを上書きしません。

## 7. プラグインの使い方とターミナルだけでの代替

- プラグイン（cobol.nvim）：細線ルーラーで Area A/B と72列を確認します。`:CobolCalcRecord` は推定にすぎず、**バイトレイアウトの最終判断に使ってはいけません**。`gd` でフィールドへ移動し、`K` でプレビューします。
- ターミナルで同等の確認：`xxd -g1 amounts.bin`、`od -An -tx1`、`sed -n`/`awk` で列ごとに照合します。最終的には `LENGTH OF`、`ADDRESS OF`、生バイトを根拠にします。本モジュールはどちらの方法でも独立して完了できる必要があります。

## 8. 提出する証拠と失敗条件

提出物：ソースファイルと SHA256、コンパイラー/ABI の版、各 lesson の元コマンドと RC、Hex Dump と説明表、不正 Packed の半バイトごとの判定、長さのずれが RC8 で未公開となる理由、`check.sh` の出力。テンプレートは [evidence/README.md](evidence/README.md) を参照してください。

**失敗条件**：生バイトを示さず DISPLAY テキストのスクリーンショットだけを提出する、Packed/二進データを文字列として走査する、不正データを算術に使う、GNU 拡張を隠すために厳格な `-std=cobol85` を使う、または `WS-EXERCISES-DONE` を `'Y'` に変えただけのプレースホルダー/誤ったレポートを提出する（`run.sh` の独立した意味検証が拒否し、公開しません）。いずれも失敗です。
