# コードのアウトライン：aerial.nvim

COBOL のプログラムは数百行、数十個の段落に及ぶこともあります。**`2200-POST-TRANSACTION` を編集するには、まず見つける必要があります。** スクロール、検索、それともアウトラインを見る？

Aerial はアウトラインのサイドバーに構造全体を表示します。DIVISION → SECTION → PARAGRAPH。項目を選ぶとそこへ移動します。

---

## 1. 解決する課題

| 要件 | アウトラインなし | Aerial あり |
|---|---|---|
| 段落を探す | `PERFORM` を検索して定義を逆引き | サイドバーですべての段落名を確認 |
| ファイル構造を把握 | 全体をスクロール | 階層を一目で確認 |
| 移動 | `:行番号` または検索 | カーソルを移動して Enter |
| 現在の階層を把握 | Winbar のパンくずを見る | 現在の項目を自動でハイライト |

## 2. 現在の設定

`lua/plugins/aerial.lua`：

```lua
layout = {
  default_direction = "left",
  placement = "window",
  width = 32,
  min_width = 32,
  max_width = 32,
  resize_to_content = false,
  win_opts = {
    foldcolumn = "1",
    statuscolumn = " ",
  },
},
show_guides = true,
manage_folds = true,
link_tree_to_folds = true,
link_tree_to_window = true,
```

### 主なパラメーター

| パラメーター | 値 | 意味 |
|---|---|---|
| `default_direction` | `left` | 左側に開く |
| `width` | 32 | 幅を 32 列に固定 |
| `resize_to_content` | `false` | 内容に合わせて幅を広げない |
| `show_guides` | `true` | 階層ガイド線を表示 |
| `link_tree_to_folds` | `true` | 折りたたみとアウトラインを連動 |
| `link_tree_to_window` | `true` | カーソル移動時にハイライトを追従 |

### backend の設定（重要）

```lua
backends = {
  ["_"] = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
  cobol = { "cobol" },
  cbl = { "cobol" },
  cob = { "cobol" },
  dosbatch = { "batch" },
  batch = { "batch" },
  sh = { "treesitter", "lsp" },
},
```

**COBOL では `cobol.nvim` が提供する専用 backend を使い、Treesitter は使いません。** これは重要です。COBOL には Treesitter parser がありませんが、`cobol.nvim` が自分で構造を解析するため Aerial は動作します。

## 3. 開き方と操作

### 開閉

| キー / コマンド | 動作 |
|---|---|
| `<leader>cs` | アウトラインサイドバーを開閉 |
| `:AerialToggle` | 同上 |
| `:AerialOpen` | 開く |
| `:AerialInfo` | 現在の buffer が使う backend を表示 |

### サイドバー内の操作

| キー | 動作 |
|---|---|
| `Enter` | 選択項目へ移動 |
| `j` / `k` | 上下に移動 |
| `o` / `zo` | ノードを展開 |
| `c` / `zc` | ノードを折りたたむ |
| `>` | 次のシンボルグループへ |
| `<` | 前のシンボルグループへ |
| `?` | サイドバーのヘルプを表示 |
| `q` | 閉じる |

設定では `<` と `>` を「シンボルグループの切り替え」（`sidebar_tabs.cycle`）に再割り当てしており、複数ファイルのシンボル間を切り替えられます。

## 4. COBOL のアウトラインに表示される内容

`cobol.nvim` の backend は次の 3 階層を解析します。

```text
▾ IDENTIFICATION DIVISION
▾ DATA DIVISION
  ▾ WORKING-STORAGE SECTION
      01 WS-ACCOUNT-TABLE
      01 WS-BATCH-COUNTS
▾ PROCEDURE DIVISION
  ▾ 0000-MAIN
  ▾ 1000-READ-AND-WRITE
  ▾ 1100-WRITE-BALANCE-RECORD
  ▾ 9000-CLOSE-FILES
```

**段落名（`0000-MAIN`）が特に役立ちます**。COBOL では処理の流れを段落で構成し、`PERFORM` で呼び出すため、アウトラインを見るとプログラム全体の骨格を直接把握できます。

### Winbar のパンくずとの併用

`cobol.nvim` の Winbar は `[ PROCEDURE DIVISION > 2000-PROCESS-SECTION > 2100-PROCESS-RECORD ]` を表示し、Aerial サイドバーは全体の構造を表示します。

一方は現在位置、もう一方は全体構造を示します。`link_tree_to_window = true` により、サイドバーではカーソルがある段落が自動的にハイライトされます。

## 5. 練習

### 練習 1：アウトラインを開いて構造を見る

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/lesson.cob
```

1. `<leader>cs`
2. 左側の構造ツリーを確認する

**合格基準**：DIVISION → SECTION → PARAGRAPH の 3 階層が見え、段落名を確認できる。

### 練習 2：段落へ移動

1. アウトラインで段落名（例：`1000-READ-AND-WRITE`）へ移動する
2. `Enter`

**合格基準**：カーソルがソース内の段落位置へ移動する。

### 練習 3：カーソルへの追従

1. アウトラインを開いたまま、ソースを下へスクロールする
2. サイドバーのハイライトを確認する

**合格基準**：サイドバーのハイライトがカーソルのある段落を追う（`link_tree_to_window = true`）。

### 練習 4：折りたたみとの連動

1. ソースで `zM` を実行してすべて折りたたむ
2. アウトラインを確認する

**合格基準**：アウトラインの展開/折りたたみがソースの折りたたみと連動する（`link_tree_to_folds = true`）。

### 練習 5：backend を確認

1. `:AerialInfo`
2. backends の行を確認する

**合格基準**：COBOL buffer が `treesitter` ではなく `cobol` backend を使っている。

### 練習 6：LSP がある言語と比較

1. `.lua` ファイルを開く
2. `<leader>cs`
3. `:AerialInfo`

**合格基準**：Lua ファイルが `treesitter`/`lsp` backend を使う。COBOL に固有の設定との違いを確認できます。

## 6. よくある問題

### COBOL のアウトラインが空

次を確認します。

```vim
:AerialInfo
```

backend が `cobol` なのに一覧が空なら、`cobol.nvim` が構造を解析できていません。`cobol.nvim` が読み込まれているか確認します。

```vim
:lua =require("cobol")
```

### `<leader>cs` で Aerial が開かない

設定では `<leader>cs` が `config.sidebar_tabs.toggle_symbols()` を呼び出します。これは複数タブをサポートする独自の切り替え処理です。動作は `:AerialToggle` と同じはずですが、問題がある場合はコマンドで直接確認してください。

### サイドバーの幅を変えられない

設定で `width = 32`、`min_width = 32`、`max_width = 32`、`resize_to_content = false` に固定されています。幅を変えるには設定を編集します。ドラッグでは変更できません。

### Neo-tree と位置が競合する

どちらも左サイドバーです（`default_direction = "left"`）。同時に開くと場所を取り合います。`sidebar_tabs` の `<` / `>` で切り替えてください。

### セッション復元後にアウトラインが消える

`auto-session` の設定（`config/sidebar_session.lua`）でこのケースに対応しています。復元後に表示されない場合は、`:AerialToggle` で再度開けます。

## 7. 他のプラグインとの役割分担

| 知りたいこと | 使うもの |
|---|---|
| ファイルの構造 | Aerial（`<leader>cs`） |
| 現在の段落 | Winbar のパンくず（自動表示） |
| ディレクトリ構造 | Neo-tree（`<leader>fe`） |
| 名前の定義位置 | `gd`（`cobol.nvim`） |
| 名前の使用箇所 | `<leader>fw`（snacks grep） |

**Aerial は構造表示であり、検索ツールではありません。** 特定の名前を探すなら grep のほうが速く見つかります。

## 8. 公式ドキュメント

```vim
:h aerial
:h aerial-usage
```

リポジトリ：<https://github.com/stevearc/aerial.nvim>

COBOL backend は `cobol.nvim` が提供します：<https://github.com/iamcheyan/cobol.nvim>

## 9. 対象範囲

- このページの設定は `lua/plugins/aerial.lua` にあります。幅は 32 列固定、方向は左側固定で、`<` / `>` はシンボルグループの切り替えに再割り当てされています。
- **COBOL は `cobol.nvim` が提供する専用 backend を使い**、Treesitter には依存しません。そのため COBOL のアウトラインは使えますが、`S` によるノード移動は使えません（[Treesitter の記事](16-treesitter-and-folding.md)を参照）。
- Aerial は**オプションの依存関係**です。Aerial がなくても `cobol.nvim` の他の機能は通常どおり動きます。
- セッション復元時のサイドバーの保存と復元は、Aerial ではなく `auto-session` の `sidebar_session` モジュールが担当します。
