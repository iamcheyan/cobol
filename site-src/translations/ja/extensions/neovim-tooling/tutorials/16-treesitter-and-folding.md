# 構文解析と折りたたみ：nvim-treesitter

正規表現によるハイライトは「この行に `IF` がある」ことしか分かりません。Treesitter は「この `IF` がどこで終わるか」まで認識します。この違いによって、折りたたみ、テキストオブジェクト、構造に沿った移動が正しく動くかどうかが決まります。

---

## 1. 解決する課題

| 要件 | 正規表現による方法 | Treesitter |
|---|---|---|
| 構文ハイライト | キーワード照合。ネストで誤る | 構文木に基づくため正確 |
| 折りたたみ | インデントから推測 | `IF ... END-IF` の実際の範囲に基づく |
| テキストオブジェクト | 文字の境界にしか対応できない | 構文ノードに基づく |
| 構造に沿った移動 | キーワードを検索 | 構文木をたどる |

COBOL の `IF` / `END-IF` は数十行にまたがり、何重にもネストすることがあります。この場合、正規表現による折りたたみはまったく信頼できません。

## 2. 現在の設定

`lua/plugins/treesitter.lua` の `ensure_installed` リストには 28 言語があります。

```text
bash c diff go html javascript java jsdoc json lua luadoc luap
markdown markdown_inline printf python query regex ruby sql
toml tsx typescript vim vimdoc xml yaml
```

**注意：リストに `cobol` はありません。**

### COBOL の実情

| 機能 | COBOL での利用可否 |
|---|---|
| 構文ハイライト | 一部利用可能（`cobol.nvim` の正規表現ハイライトによる） |
| 折りたたみ | **利用可能**（`cobol.nvim` が Division/Section/Paragraph の折りたたみを独自実装） |
| Treesitter テキストオブジェクト | **利用不可**（mini.ai の設定で意図的に空を返す） |
| `S`（flash のノード移動） | **利用不可** |

`cobol.nvim` の設定には次のように記載されています。

```lua
function M.attach(bufnr)
  setup_comment_syntax(bufnr)
  setup_folding(bufnr)
  ...
```

折りたたみはプラグイン独自の `folding.lua` が提供し、Treesitter に依存しません。

### COBOL parser をインストールすると

プラグインのリポジトリには `tree-sitter-cobol` ディレクトリがあり、自分でコンパイルできます。

```sh
cd ~/development/cobol.nvim/tree-sitter-cobol
make
```

インストールすると `S`（flash）と mini.ai の `o`/`f`/`c` が使えるようになります。**ただし、現在の設定には含まれていません**。デフォルトではインストールされません。

## 3. 折りたたみ（nvim-ufo）

`lua/plugins/ufo.lua` の provider は `{ "treesitter", "indent" }` です。

1. まず Treesitter の折りたたみ範囲を使う
2. Treesitter がなければインデントによる折りたたみに切り替える

COBOL では `cobol.nvim` が先に折りたたみを引き受け、`foldtext` を `"auto"` に設定します。n-ufo が buffer を管理している間は n-ufo が描画し、それ以外の場合はプラグインの要約形式を使います。

### 折りたたみのキー

| キー | 動作 |
|---|---|
| `za` | 現在の折りたたみを開閉 |
| `zc` | 閉じる |
| `zo` | 開く |
| `zR` | すべて開く |
| `zM` | すべて閉じる |
| `zr` / `zm` | 1 段階ずつ展開/折りたたむ |

### 折りたたみ表示

n-ufo のカスタム要約は次のような形式です。

```text
+-- 12 lines 󰁂
```

折りたたまれた行数を表示します。


![`:CobolCalcRecord` が出力する項目レイアウト表。オフセット、PIC、合計長。](images/16-treesitter-context.png)

`:CobolCalcRecord` が出力する項目レイアウト表。オフセット、PIC、合計長。

## 4. 構文ハイライト

### 有効化/無効化

```vim
:TSBufEnable highlight
:TSBufDisable highlight
```

通常は手動操作不要で、ファイルを開くと自動的に有効になります。

### 現在の buffer の parser 状態を確認

```vim
:InspectTree
```

構文木を表示します。COBOL の buffer に parser がない場合は、その旨が表示されます。

### 新しい parser をインストール

```vim
:TSInstall python
:TSUpdate
```

`ensure_installed` リストにあるものは自動でインストールされ、リストにないものは手動でインストールします。

## 5. COBOL での実際の使用感

### 使える機能

- **折りたたみ**（`cobol.nvim` の Division/Section/Paragraph の 3 階層）
- **構文ハイライト**（`cobol.nvim` のキーワードハイライト + 階層ハイライト）
- **72 列超過の警告**

### 使えない機能

- Treesitter テキストオブジェクト（`iao`、`iaf`、`iac`）
- flash の `S` によるノード移動
- `%` による構文上の対応箇所への移動（`cobol.nvim` 独自の `%` 実装があり、`IF`/`END-IF` 間を移動）

**つまり、COBOL の構造関連機能を提供するのは Treesitter ではなく `cobol.nvim` です。** これを理解しておくと、「ドキュメントでは使えるのに、なぜ自分の環境では動かないのか」という混乱を避けられます。

## 6. 練習

### 練習 1：折りたたみの精度を比較する

```sh
cd ~/development/cobol
nvim lessons/26_error-handling/lesson.cob
```

1. `IF ... END-IF` ブロックを探す
2. `zc` で閉じる
3. 折りたたみ範囲が `IF` から `END-IF` までちょうど一致しているか確認する

**合格基準**：折りたたみの境界が `END-IF` に合い、インデントから推測したものではない。

### 練習 2：COBOL に parser があるか確認する

1. `:InspectTree`
2. 出力を確認する

**合格基準**：cobol parser が見つからないというメッセージが表示される（`ensure_installed` にないため）。または、不完全な構文木が表示される。

### 練習 3：parser がある言語と比較する

1. 任意の `.lua` ファイルを開く
2. `:InspectTree`

**合格基準**：完全な構文木が表示され、ノードを展開できる。

### 練習 4：parser をインストールしてみる

```vim
:TSInstall python
```

続けて `:InspectTree` で Python ファイルの構文木を確認します。

**合格基準**：完全な構文構造が表示される。「parser がある場合」と「ない場合」の違いを確認できます。

### 練習 5：すべて折りたたむ

1. 長い COBOL ファイルを開く
2. `zM` ですべて折りたたむ
3. 各折りたたみの要約行を確認する

**合格基準**：要約に行数（`⋯ N lines`）が表示され、ファイル構造をすばやく把握できる。

## 7. よくある問題

### COBOL で `S` が反応しない

flash の `S` には Treesitter parser が必要です。COBOL にはインストールされていないため動作しません。構造上の対応箇所へ移動するには `cobol.nvim` の `%` を使うか、`cobol.nvim` の Aerial アウトラインを使ってください。

### 構文ハイライトが正しくない

COBOL のハイライトは Treesitter ではなく `cobol.nvim` の正規表現による実装です。一部の構造が完全にハイライトされない場合があります。これは既知の制限です。

### `:TSInstall` が失敗する

ビルドツールチェーン（`tree-sitter-cli` または C コンパイラ）が必要です。次のコマンドで確認します。

```sh
cc --version
```

### ufo と cobol.nvim で折りたたみが競合する

`cobol.nvim` の `foldtext = "auto"` は、ufo が管理しているかどうかを検出します。折りたたみ表示がおかしい場合は、次を確認してください。

```vim
:set foldmethod?
```

COBOL buffer ではプラグインが設定する `expr` になっているはずです。

### parser をインストールした後は再起動が必要

新しくインストールした parser を有効にするには、buffer を開き直します。または次を実行します。

```vim
:edit
```

## 8. 公式ドキュメント

```vim
:h treesitter
:h nvim-ufo
```

- `nvim-treesitter`：<https://github.com/nvim-treesitter/nvim-treesitter>
- `nvim-ufo`：<https://github.com/kevinhwang91/nvim-ufo>

## 9. 対象範囲

- `ensure_installed` リスト（`lua/plugins/treesitter.lua`）に **`cobol` は含まれていません**。COBOL の折りたたみとハイライトは Treesitter ではなく `cobol.nvim` が提供します。
- COBOL で Treesitter テキストオブジェクトと `S` による移動を使うには、`cobol.nvim` リポジトリにある `tree-sitter-cobol` を手動でコンパイルし、mini.ai の設定にある filetype の除外を解除する必要があります。
- この記事では parser を手動でコンパイルする詳しい手順は扱いません。これはプラグイン開発の範囲です。`cobol.nvim` リポジトリの `scripts/build_parser.sh` を参照してください。
