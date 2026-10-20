# パンくずドロップダウン：contextline.nvim

Winbar のパンくずは**一行**なので、階層が深いと途中で切れます。また、表示するだけで「操作」はできません。

contextline はパンくずにドロップダウンメニューを追加します。現在のファイルの構造全体を一覧表示し、項目を選んで移動できます。

---

## 1. 解決する問題

| 要件 | Winbar のパンくずのみ | contextline を追加 |
|---|---|---|
| 階層全体を見る | 一行なので長いと切れる | ドロップダウンにすべて表示 |
| ノードへ移動する | スクロールして探す | メニューから選択 |
| ファイルパス／ファイル名を見る | 設定による | メニュー内に表示可能 |

## 2. 設定

`lua/plugins/contextline.lua`：

| オプション | 値 | 意味 |
|---|---|---|
| `separator` | ``  `` | 階層の区切り文字 |
| `show_path` | `false` | ファイルパスを表示しない |
| `show_file` | `false` | ファイル名を表示しない |
| `show_icons` | `true` | アイコンを表示 |
| `use_lsp` | `true` | 利用可能なら LSP シンボルを使う |
| `use_navic` | `true` | navic を使う |
| `use_treesitter` | `true` | Treesitter を使う |

### キー

| キー | コマンド | 動作 |
|---|---|---|
| `<leader>cb` | `:ContextlineMenu` | 構造のドロップダウンメニューを開く |

### データソースの優先順位

3つのデータソースが有効です：`use_lsp`、`use_navic`、`use_treesitter`。

実際に使われるものは、**現在のファイルタイプがどの機能に対応しているか**によります。

| ファイルタイプ | 利用可能なソース |
|---|---|
| LSP のある言語 | LSP シンボル |
| Treesitter parser のある言語 | Treesitter |
| COBOL | **`cobol.nvim` が提供しているかどうかによる** |

COBOL には LSP も parser もないため、contextline は COBOL の構造を**取得できない場合があります**。その場合、ドロップダウンは空になります。

## 3. `cobol.nvim` のパンくずとの比較

`cobol.nvim` には組み込みの Winbar パンくずがあります（第02篇で説明）。`[ PROCEDURE DIVISION > 2000-PROCESS-SECTION > 2100-PROCESS-RECORD ]` のように表示します。

| | `cobol.nvim` | contextline |
|---|---|---|
| 表示場所 | Winbar（常時表示） | ドロップダウン（必要なときに開く） |
| データ | COBOL を独自に解析 | LSP / Treesitter / navic |
| COBOL 対応 | **あり** | なし（プラグインが提供しない限り） |

**COBOL では `cobol.nvim` のパンくずと Aerial のアウトラインで十分です**。contextline は主に他の言語向けです。

## 4. 練習

### 練習1：メニューを開く

1. 任意のファイルを開く
2. `<leader>cb`

**合格条件**：構造メニューが開く（構造があれば階層を表示し、なければ空またはメッセージが表示される）。

### 練習2：COBOL での結果を見る

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/lesson.cob
```

1. `<leader>cb`
2. 結果を見る

**合格条件**：**COBOL では空の可能性が高い**（LSP も parser もありません）。故障ではありません。代わりに Aerial（`<leader>cs`）を使います。

### 練習3：LSP のある言語で使う

1. Lua ファイルを開く
2. `<leader>cb`

**合格条件**：関数や変数など、LSP が提供するシンボル階層が表示される。

### 練習4：設定を確認する

```vim
:lua =require("contextline").config or vim.inspect(_G)
```

（具体的な API はプラグインにより異なります。）少なくとも `separator` と `show_icons` の値を確認します。

### 練習5：Aerial と比較する

1. `<leader>cb` でドロップダウンを見る
2. `<leader>cs` で Aerial のサイドバーを見る

**合格条件**：両者は異なるデータソースを使います。COBOL では Aerial に内容が表示され、contextline は空になります。

## 5. つまずいたとき

### メニューが空

考えられる原因は2つです。

1. 現在のファイルタイプに LSP／Treesitter の対応がない（**COBOL はこれに該当します**）。
2. プラグインがまだデータを取得していない（少し待ってから再試行してください）。

### `cobol.nvim` の Winbar と重複する

どちらも階層を表示しますが、場所が異なります（Winbar に常時表示されるものと、必要なときに開くドロップダウン）。**COBOL では `cobol.nvim` の表示を使ってください。**

### `show_path`／`show_file` が無効

設定が `false` なので、メニューにはパスとファイル名が表示されません。表示したい場合は設定を変更します。

### アイコンが四角になる

`show_icons = true` ですが、アイコンフォントが必要です。端末のフォントが対応していない場合、四角で表示されます。

### navic との関係

`use_navic = true` は navic が提供する LSP パンくずデータを使います。navic がインストールされていなければ、このオプションは効果がありません（ただしエラーにはなりません）。

## 6. 公式ドキュメント

リポジトリ：<https://github.com/iamcheyan/contextline.nvim>

## 7. 適用範囲

- このページの設定は `lua/plugins/contextline.lua` に基づきます。`<leader>cb` でメニューを開き、パスとファイル名の表示は無効です。
- データは LSP / navic / Treesitter から取得します。**COBOL では3つとも利用できない**ため、メニューは通常空です。
- **COBOL では `cobol.nvim` の Winbar パンくずと Aerial のアウトラインを使ってください**。contextline は使いません。
- このプラグインは自作（`iamcheyan/`）のため、挙動はバージョンによって変わる可能性があります。
