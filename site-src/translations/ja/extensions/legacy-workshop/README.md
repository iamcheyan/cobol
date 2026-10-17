# GNUCOBOLフルスタック課程：最初のDISPLAYからバッチプロジェクトまで

> このディレクトリには、旧版の00–29課を任意の補足資料としてアーカイブしています。新しい主課程はリポジトリルートの[`lessons/`](../../lessons/README.md)から始まります。

新しい主課程の課番号から旧トピックの対応演習を探すには、[拡張課程インデックス](../README.md)を参照してください。旧課は補足読書や反復練習に適しています。学習順序、課程の契約、最終プロジェクトについては、リポジトリルートの32課主課程に従ってください。

この課程では、COBOL言語、GnuCOBOLツールチェーン、Bashによる自動化、`cobol.nvim`の学習ワークフローを、実行可能な演習にまとめています。学習者が実用的なバッチプログラムを読み、独力で完成できることを目指します。レコード定義、ファイル読み込み、データ検証、業務計算、結果の書き出し、集計表示、信頼性の高いシェルビルドと回帰テストを扱います。

> 課は「概念 -> 実行 -> 変更 -> 意図的にエラーを起こす -> ツールで場所を特定する -> 自分で説明する」の順に構成されています。例はGnuCOBOLを対象とし、従来形式のソースコードは固定形式に従います。具体的な記憶域レイアウトや拡張動作は、インストールされているGnuCOBOLと対象プラットフォームに依存します。

## 環境の準備

GNU/Linux、macOS、またはWSLが必要です。GnuCOBOL（`cobc`）、GNU Make、Bashを用意してください。Neovimと`iamcheyan/cobol.nvim`の追加もおすすめします。インストール例：

```sh
# Debian / Ubuntu
sudo apt install gnucobol make
# Arch Linux
sudo pacman -S gnucobol make
# macOS
brew install gnu-cobol make

cobc --version
make check
```

各課のディレクトリには`README.md`と独立した`.COB`の例があります。複数ファイルやテストデータを必要とする課では、同じディレクトリに`.CPY`、データfixture、またはBashスクリプトもあります。課のディレクトリに移動した後、通常は次のようにコンパイルして実行します。

```sh
cobc -x -Wall -o build/lesson lesson.COB
./build/lesson
```

先に`build/`を作成します：`mkdir -p build`。スクリプトを含む課では、READMEにより詳しいコマンドを記載しています。構文だけを確認するには`cobc -fsyntax-only lesson.COB`を使います。

## 学習の道筋

### 段階 A：言語とデータの基礎

| 課 | 内容 |
|---|---|
| [00](lessons/00-environment/) | 環境と最初のプログラム |
| [01](lessons/01-program-anatomy/) | 4つの部、プログラムの骨組み、段落 |
| [02](lessons/02-source-format/) | 固定形式、Area A/B、列境界 |
| [03](lessons/03-names-comments-literals/) | 名前、コメント、リテラル、ピリオド |
| [04](lessons/04-data-hierarchy/) | レベル番号、グループ項目、データ部 |
| [05](lessons/05-picture-storage/) | PIC、数値、編集形式、記憶域 |
| [06](lessons/06-values-move-arithmetic/) | VALUE、MOVE、算術、オーバーフロー |

### 段階 B：制御フローとデータ処理

| 課 | 内容 |
|---|---|
| [07](lessons/07-conditions-88/) | 条件式とレベル88の条件名 |
| [08](lessons/08-branching-evaluate/) | IF、EVALUATE、分岐範囲 |
| [09](lessons/09-loops-perform/) | PERFORMとループ |
| [10](lessons/10-tables-occurs-search/) | OCCURS、テーブル、SEARCH |
| [11](lessons/11-strings-unstring-inspect/) | STRING、UNSTRING、INSPECT |
| [12](lessons/12-sequential-files/) | 順編成ファイルとREAD/WRITE |
| [13](lessons/13-file-status-errors/) | ファイル状態、検証、エラー経路 |

### 段階 C：モジュール化と本番プログラム

| 課 | 内容 |
|---|---|
| [14](lessons/14-copybooks-redefines/) | COPY、Copybook、REDEFINES |
| [15](lessons/15-subprograms-linkage/) | CALL、LINKAGE、引数の受け渡し |
| [16](lessons/16-intrinsic-functions-dates/) | 組み込み関数、日付、型変換 |
| [17](lessons/17-reports-control-break/) | レポート、累計器、制御ブレーク |
| [18](lessons/18-sort-merge/) | ソート、マージ、ジョブストリーム |
| [19](lessons/19-modules-environment/) | 複数ファイルのプロジェクトと実行環境 |
| [20](lessons/20-debugging-diagnostics/) | デバッグ、コンパイラー診断、問題箇所の特定 |
| [21](lessons/21-compiler-options/) | cobcオプション、形式、方言 |

### 段階 D：Bash、エンドツーエンドプロジェクト、プラグイン連携

| 課 | 内容 |
|---|---|
| [22](lessons/22-bash-build-run/) | Bashによるコンパイル・実行スクリプト |
| [23](lessons/23-bash-tests-batch/) | 一括ビルドと回帰テスト |
| [24](lessons/24-bash-pipelines-scheduling/) | パイプライン、ログ、スケジューリング、再実行性 |
| [25](lessons/25-project-csv-pipeline/) | 総合プロジェクト：区切りファイルからCSVへ |
| [26](lessons/26-project-fixed-records/) | 総合プロジェクト：固定長レコード |
| [27](lessons/27-plugin-learning-workflow/) | cobol.nvimを使った練習とトラブルシューティング |
| [28](lessons/28-capstone-night-batch/) | 卒業プロジェクト：完全なバッチシステム |
| [29](lessons/29-reference-topic-map/) | トピック一覧とGnuCOBOLの発展学習ルート |

## 各課の学習サイクル

1. `README.md`の目標、概念、注意事項を読む。
2. まず元の例を実行し、期待される出力を保存する。
3. 「変更演習」に沿って小さな変更を加え、構文確認、コンパイル、実行を行う。
4. 意図的に制御可能なエラーを起こし、`cobc`とプラグインの両方で場所を特定する。
5. 修正後、入力、出力、終了コード、境界ケースを確認する。
6. 学んだ規則を自分の言葉で書き、まだ不明な点を記録する。

課程のプログラムは、リポジトリの固定形式規約に従います。第7列は指示列、Area Aは第8列から、Area Bは第12列から始まり、有効なプログラムテキストは第72列までです。自由形式は独立したトピックとして練習できますが、このリポジトリの固定形式の例に`-free`の習慣を適用しないでください。

## プラグイン学習カード

Neovimプラグインは補助ツールであり、コンパイラーの代わりではありません。該当する各課には「プラグイン演習」があります。

- 固定形式：ルーラー、`g7` / `g8` / `g12` / `g73`、スマートコメント、大小文字の整形。
- 構造ナビゲーション：Aerialアウトライン、Winbarのパンくず、`gd`、`<C-o>`、折りたたみ。
- データ：`<leader>cr` / `:CobolCalcRecord`でレコード長を確認する。配列、再定義、コンパイラーABIは対象プラットフォームと照合する。
- モジュール：`gf`でCopybookを開き、`K`でプレビューし、`<C-o>`で戻る。
- 診断：`<leader>cl` / `:CobolLint`、`<leader>cq` / `:CobolQuickfix`。

プラグインのインストールとキーの詳細は、[リポジトリREADME](../../README.md)のプラグイン索引と[第27課](lessons/27-plugin-learning-workflow/)を参照してください。

## 課程の範囲と参考資料

この課程では、COBOLプログラム構造、データ記述、演算、条件とループ、テーブル、文字列、順編成ファイル、モジュール化、サブプログラム、レポート、ソート、コンパイル、診断、ジョブ自動化などの実践的な開発トピックを扱います。COBOL規格やベンダー方言は広範囲に及ぶため、GnuCOBOLの動作を明示しますが、単一のチュートリアルですべての歴史的な方言キーワードを網羅するとはしていません。続けて、ローカルの`info gnucobol`、`cobc --help`、GnuCOBOL Programmer's Guide、ISO COBOL規格を参照してください。

Neovimエディター補助については[`neovim-tooling/`](../neovim-tooling/README.md)、4つの独立した実践例については[`standalone-examples/`](../standalone-examples/README.md)を参照してください。
