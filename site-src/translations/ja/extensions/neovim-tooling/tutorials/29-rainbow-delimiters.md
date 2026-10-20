# 括弧の色分け：rainbow-delimiters.nvim

`IF ... END-IF` の中にさらに `EVALUATE` が入るような構造では、インデントだけで対応関係を読み取るのは困難です。

rainbow-delimiters は**括弧やキーワードを階層ごとに異なる色で表示**し、ネスト構造を一目で分かるようにします。

---

## 1. 解決する問題

| 要件 | 単色の括弧 | 色分けした括弧 |
|---|---|---|
| ネストの深さを把握 | 空白を数える | 色で区別 |
| 対応する閉じ括弧を探す | `%` を順に試す | 同じ色が対応 |
| 括弧の対応を確認 | LSP のエラーに頼る | 色の変化で判断 |

## 2. 設定内容

`lua/plugins/rainbow-delimiters.lua`：

```lua
vim.g.rainbow_delimiters = {
  strategy = {
    [""] = rainbow.strategy["global"],
    vim = rainbow.strategy["local"],
  },
  query = {
    [""] = "rainbow-delimiters",
    lua = "rainbow-blocks",
  },
  highlight = {
    "RainbowDelimiterYellow",
    "RainbowDelimiterCyan",
    "RainbowDelimiterBlue",
    "RainbowDelimiterOrange",
    "RainbowDelimiterGreen",
    "RainbowDelimiterViolet",
    "RainbowDelimiterRed",
  },
}
```

| オプション | 意味 |
|---|---|
| `strategy[""]` | `global`：バッファ全体で階層を計算 |
| `strategy.vim` | vim ファイルでは `local`（局所スコープ単位）を使う |
| `query[""]` | 既定で `rainbow-delimiters` クエリを使う |
| `query.lua` | Lua では `rainbow-blocks` を使う（括弧ではなくブロック単位） |
| `highlight` | 7色を循環させる |

### 7色の循環

```
Yellow → Cyan → Blue → Orange → Green → Violet → Red → (回到 Yellow)
```

8階層目は1階層目と同じ色になります。ただし、8階層までネストしているコードはリファクタリングを検討しましょう。

## 3. COBOL での実際の動作

**重要**：rainbow-delimiters は Treesitter クエリに依存します。COBOL には parser がないため（[Treesitter のページ](16-treesitter-and-folding.md)を参照）、次のようになります：

| 言語 | 括弧の色分け |
|---|---|
| Lua、Python、JS など | **有効** |
| COBOL | **無効** |

COBOL の構造の対応付けには `cobol.nvim` を使います（第02課で扱った `%` による移動と構造マーカー）。虹色の括弧ではありません。

**COBOL のバッファに色付きの括弧が見えないのは正常**です。設定の故障ではありません。

### 確認方法

```vim
:InspectTree
```

COBOL のバッファでは parser がないことが表示されます。

## 4. 効果を確認できる場所

任意の Lua ファイル（例：`~/nvim/lua/plugins/flash.lua`）を開きます：

```lua
return {
  {                                    ← 第 1 层（Yellow）
    "folke/flash.nvim",
    keys = {
      { "s", function()                 ← 第 2 层（Cyan）
        require("flash").jump()          ← 第 3 层（Blue）
      end, desc = "Flash" },
    },
  },
}
```

階層ごとに `{` `}` の色が異なります。

## 5. 練習

### 練習 1：COBOL で無効であることを確認

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/lesson.cob
```

1. `IF ... END-IF` の色を確認します

**確認ポイント**：括弧やキーワードに虹色が**付きません**（COBOL parser がないため）。これは想定された動作です。

### 練習 2：Lua での効果を確認

1. `~/nvim/lua/plugins/flash.lua` を開きます
2. ネストした `{` `}` を確認します

**確認ポイント**：階層によって括弧の色が異なり、7色が循環する。

### 練習 3：階層を数える

1. Lua ファイルで4階層のネストを探します
2. 色が4種類循環しているか数えます

**確認ポイント**：色を見て階層を判別できる。

### 練習 4：vim ファイルと比較

1. `.vim` ファイルがあれば開きます

**確認ポイント**：`local` 戦略で局所スコープごとに階層を計算します（Lua の `rainbow-blocks` とは異なります）。

### 練習 5：クエリ設定を確認

```vim
:lua =vim.g.rainbow_delimiters.query
```

**確認ポイント**：`[""] = "rainbow-delimiters"`、`lua = "rainbow-blocks"` になっている。

## 6. よくある問題

### COBOL でまったく効果がない

正常です。Treesitter の COBOL parser がありません。構造の対応付けには `cobol.nvim` の `%` と Aerial のアウトラインを使ってください。

### 7色では足りない（ネストが7階層を超える）

7色が循環し、8階層目は1階層目の色に戻ります。7階層を超えるネストは、コードのリファクタリングを検討してください。

### Treesitter のハイライトと競合する

両方が括弧の色を変更します。色がおかしい場合は、テーマが `RainbowDelimiter*` グループを上書きしていないか確認します：

```vim
:hi RainbowDelimiterYellow
```

### 無効にしたい

`lua/plugins/rainbow-delimiters.lua` の読み込みを削除またはコメントアウトするか、`enabled = false` を追加します。

### Lua では括弧ではなくブロック単位で色が付く

設定の `query.lua = "rainbow-blocks"` によって、Lua の `function ... end` は `{}` だけでなくブロック単位に色分けされます。

## 7. 公式ドキュメント

```vim
:h rainbow-delimiters
```

リポジトリ：<https://github.com/HiPhish/rainbow-delimiters.nvim>

## 8. 適用範囲

- このページの設定元は `lua/plugins/rainbow-delimiters.lua` です：7色を循環し、Lua では `rainbow-blocks`、vim では `local` 戦略を使います。
- **Treesitter に依存します**。COBOL parser がないため、**COBOL のバッファでは動作しません**。
- COBOL の構造の対応付けには `cobol.nvim`（`%` による移動、Aerial アウトライン、構造マーカー）を使います。このプラグインではありません。
- 7階層を超えると色が循環して重複します。
