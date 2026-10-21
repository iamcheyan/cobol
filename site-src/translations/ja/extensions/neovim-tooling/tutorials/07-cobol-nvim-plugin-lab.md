# cobol.nvim プラグイン演習

このチュートリアルでは、`extensions/standalone-examples/` の COBOL サンプルを使い、日常的なソース閲覧にプラグインを活用する方法を紹介します。プラグインは GnuCOBOL の代わりにはなりません。構文チェックとプロジェクトのビルドは引き続き `cobc` またはプロジェクトのコマンドで行います。

## 準備

Neovim でサンプルを開きます。

```sh
nvim extensions/standalone-examples/INPUTCSV.COB
```

プラグインは `cobol`、`cbl`、`cob` の filetype に対応しています。固定形式の例では、まず列ルーラーを確認してください。パーサーがない場合、Tree-sitter の対応範囲マーカー、パンくず、テキストオブジェクトは表示されません。Aerial と blink.cmp は任意の依存関係です。

## 列ルーラーと編集

1. `g7`、`g8`、`g12`、`g73` で固定形式の重要な列へ移動します。
2. 行頭の空白部分で Insert モードに入り、`<Tab>` / `<S-Tab>` を押して 7、8、12 列目に移動する動作を試します。
3. `:CobolGuideToggle` で列ルーラーと Winbar の表示を切り替えます。`:CobolGuideEnable` / `:CobolGuideDisable` でガイドと診断の紐付けを明示的に有効・無効にできます。
4. `gcc`、Visual モードの `gc`、または `<leader>c*` でコメントを切り替えます。`:CobolFormatCase` で予約語の大文字・小文字を整えます。範囲を指定しない場合はバッファ全体を、範囲を指定した場合はその範囲だけを処理します。

## 構造ナビゲーション、アウトライン、Copybook

1. `PERFORM 1000-INITIALIZE` の Paragraph 名にカーソルを置いて `gd` を押し、`<C-o>` で戻ります。`<C-i>` で jumplist の次の位置へ進みます。
2. `COPY "EMP-REC.CPY".` で `gf` を押すと Copybook を開き、`K` を押すとプレビューできます。
3. パーサーが利用できる場合、IF ブロック内にカーソルを置くと、最も内側の構造を示す色付きマーカー、接続線、ELSE/WHEN マーカーが表示されます。`%` で構造キーワード間を移動し、`vaf` / `vif` で IF ブロックの外側／内側を選択します。
4. Aerial を別途インストールし、このプラグインが提供する COBOL バックエンドを有効にする必要があります。`:AerialToggle` で開きます。このプラグインは `<leader>cs` を既定で割り当てません。

## PIC 推定、診断、折りたたみ

1. レベル 01 のレコード上で `<leader>cr` / `:CobolCalcRecord` を実行し、フィールドのオフセットとサイズ推定を確認します。グループレベルの `OCCURS` 回数は子フィールドに乗算されず、大きな `REDEFINES` の重ね合わせも合計を増やしません。そのため、ABI の保証値として扱わないでください。
2. `<leader>cl` / `:CobolLint` で GnuCOBOL のチェックをすぐに実行し、`<leader>cq` / `:CobolQuickfix` で Quickfix を開きます。診断は保存時、編集後のデバウンス時、Insert モードを抜けたときにも自動実行できます。
3. `za`、`zc`、`zo` で Division、Section、Paragraph、データ項目の折りたたみを操作します。ネイティブ折りたたみは IF/EVALUATE の折りたたみを作りません。他の fold provider が制御ブロックの折りたたみを作成する場合、プラグインは構造の要約を表示できます。

## キーマップとコマンド

| 操作 | 機能 |
|---|---|
| `g7` / `g8` / `g12` / `g73` | 固定形式の列へ移動 |
| `gd` / `gf` / `K` | 定義へ移動／Copybook を開く／プレビュー |
| `%`、`af`/`if`、`ae`/`ie`、`ap`/`ip` | Tree-sitter の対応構造間移動と構造テキストオブジェクト |
| `<leader>cr` / `<leader>cl` / `<leader>cq` | レコード推定／即時診断／Quickfix |
| `:CobolGuideToggle` | 列ルーラーと Winbar を切り替え |
| `:CobolLint` / `:CobolBuild` / `:CobolRun` / `:CobolTest` | プロジェクトのチェック、ビルド、実行、テスト |

設定とコマンドの詳細は、プラグインリポジトリの README と Neovim ヘルプ `:help cobol.nvim` を参照してください。
