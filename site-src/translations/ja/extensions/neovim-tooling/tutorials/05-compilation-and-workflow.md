# GnuCOBOL のビルドワークフローと cobol.nvim

`cobol.nvim` を使うと、GnuCOBOL の構文チェック、ビルド、実行の各コマンドを Neovim から利用できます。最終的な構文チェックとプログラム生成は引き続き COBOL コンパイラーが担当します。プラグインはプロジェクトに設定されたコマンドをエディターから実行し、その結果を表示します。

## GnuCOBOL のよく使うコマンド

| コマンド | 用途 |
|---|---|
| `cobc -fsyntax-only INPUTCSV.COB` | 構文のみをチェック |
| `cobc -x -o INPUTCSV INPUTCSV.COB` | 実行可能ファイルをコンパイルしてリンク |
| `cobc -I copy ...` | Copybook の検索ディレクトリを指定 |

## 独立サンプルのワークフロー

リポジトリのルートから次を実行します。

```sh
make -C extensions/standalone-examples check
make -C extensions/standalone-examples run-csv
```

`check` は 4 つの独立プログラムをすべてチェックします。`run-csv` は `INPUTCSV.COB` をコンパイルして実行し、`input.txt` を読み込んで `output.csv` を作成します。サンプルディレクトリの Makefile には `run-fixed`、`run-table`、`run-report`、`clean` もあります。

![COBOL プロジェクトの構造折りたたみ例](images/folding.png)

スクリーンショットでは、Division、Section、Paragraph、データ項目のネイティブ折りたたみと要約を示しています。ネイティブ折りたたみは IF/EVALUATE 制御ブロックの折りたたみを作成しません。他の fold provider が制御ブロックの折りたたみを作成した場合、プラグインは構造の要約を提供できます。

## Neovim からコマンドを実行する

COBOL バッファ内で次のコマンドを使います。

- `:CobolLint` または `<leader>cl`：GnuCOBOL の構文チェックをすぐに実行します。
- `:CobolBuild`：プロジェクトのビルドコマンドを実行します。単一ファイルの場合は `cobc` を使います。
- `:CobolRun`：プロジェクトで設定されたプログラムを実行します。ビルドターゲットがあっても実行入口がなければ、実行ファイル名を推測しません。
- `:CobolTest`：プロジェクトのテストコマンドを実行するか、単一ファイルの構文チェックを行います。

プロジェクトコマンドは `.cobol.json` の `commands` または Makefile のターゲットから読み込みます。プロジェクトのビルドコマンドはディスク上のファイルを読むため、実行前に現在のバッファを保存してください。コマンドは引数配列で渡され、シェル経由では実行されません。Makefile もプロファイルもない場合、単一ファイルのビルドや実行では `cobc` の使用を試みます。

プロジェクト設定の例：

```json
{
  "compiler": "cobc",
  "source_format": "fixed",
  "copybook_paths": ["copy", "cpy"],
  "commands": {
    "build": ["make", "build"],
    "run": ["make", "run"],
    "test": ["make", "test"]
  }
}
```

プロファイルの詳細な設定項目は `:help cobol-projects` を参照してください。
