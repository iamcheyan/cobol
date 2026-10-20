# Language Server：LSP とコードインテリジェンス

`cobol.nvim` が提供するのは COBOL 専用の機能（ルーラー、構造、PIC の計算）です。**LSP が提供するのは汎用的なコードインテリジェンス**、つまり定義への移動、参照の検索、名前の変更、エラー診断、コードアクションです。

両者は互いを補完します。COBOL には公式の LSP server がありませんが、この設定では GnuCOBOL のコンパイル診断で不足を補っています。これが `cobol.nvim` の diagnostics モジュールです。

---

## 1. 解決する問題

| 必要な機能 | LSP なし | LSP あり |
|---|---|---|
| 定義へ移動 | 全体検索または `ctags` | `gd` で一度に移動 |
| すべての参照を検索 | grep して自分で判断 | `gr` で一覧表示 |
| 名前の変更 | すべての箇所を手作業で変更 | `<leader>cr` で一度に変更 |
| 引数のシグネチャを確認 | ドキュメントを調べる | `gK` で浮動ウィンドウを表示 |
| lint の問題を修正 | 手動で確認 | `<leader>ca` でコードアクション |
| エラーを確認 | コンパイル後に出力を確認 | 行内 mark でリアルタイム表示 |

## 2. 設定内容

`lua/plugins/lsp.lua` にあります。キーは **server の能力に応じて**動的に登録されます。server が機能に対応していない場合、そのキーは割り当てられません。

### 移動

| キー | 動作 | 前提条件 |
|---|---|---|
| `gd` | 定義へ移動 | definitionProvider がある |
| `gr` | 参照一覧を表示 | referencesProvider がある |
| `gy` | 型定義へ移動 | typeDefinitionProvider がある |
| `gI` | 実装へ移動 | implementationProvider がある |
| `K` | ホバードキュメントを表示 | hoverProvider がある |
| `gK` | シグネチャヘルプ | signatureHelpProvider がある |
| `<C-k>` | シグネチャヘルプ（挿入モード） | 同上 |

### 編集

| キー | 動作 | 前提条件 |
|---|---|---|
| `<leader>ca` | コードアクション（`n` / `x` モード） | codeActionProvider がある |
| `<leader>cr` | シンボル名を変更 | renameProvider がある |
| `<leader>cR` | ファイル名を変更 | Snacks |
| `<leader>co` | import を整理 | — |

### 情報

| キー | 動作 |
|---|---|
| `<leader>cl` | 現在の buffer の LSP 設定情報（稼働中の server） |
| `<leader>cm` | Mason を開く（server とツールを管理） |

### 参照間の移動

| キー | 動作 |
|---|---|
| `]]` | 次の参照 |
| `[[` | 前の参照 |
| `<a-n>` | 次の参照（一時的に強調表示） |
| `<a-p>` | 前の参照 |

この4つは `Snacks.words` を使います。LSP references より軽量で、同じ名前のシンボルを手早く確認するのに向いています。

## 3. COBOL の場合

**COBOL には LSP server がありません。** そのため、COBOL では次のようになります。

| 機能 | COBOL での方法 |
|---|---|
| 定義へ移動 | `cobol.nvim` の `gd` / `:CobolGotoDef` |
| Copybook へ移動 | `cobol.nvim` の `gf` / `:CobolGotoCopybook` |
| 定義をプレビュー | `cobol.nvim` の `K` / `:CobolPreview` |
| 構文診断 | `cobol.nvim` が `cobc -fsyntax-only` を実行 |
| 構造アウトライン | `cobol.nvim` が Aerial backend を提供 |
| 名前の変更 | **機能なし**。grug-far または grep + マルチカーソルを使う |

**つまり、COBOL の `gd` と `K` は LSP ではなく `cobol.nvim` が実装しています。** 2つのプラグインで同じキーが割り当てられているため、混同しやすい点です。

現在の buffer でどの client が動いているか確認するには：

```vim
:lua =vim.lsp.get_clients({ bufnr = 0 })
```

COBOL buffer で空の一覧が返れば、LSP は動作しておらず、`gd` は `cobol.nvim` によって処理されています。

## 4. LSP が使える言語

設定では `mason-lspconfig` が自動インストールします。インストール済みのものを確認するには：

```vim
:Mason
```

一般的なものには Lua、Python、TypeScript、Bash、JSON、YAML などがあります。**COBOL は利用可能な server がないため一覧にありません。**

### ファイルタイプに LSP があるか確認する

```vim
:lua =vim.lsp.get_clients({ bufnr = 0 })
```

空の一覧が返った場合は、ありません。

### 新しい server をインストールする

```vim
:Mason
```

画面内で検索し、`i` を押してインストールします。インストール後、Neovim を再起動すると有効になります。

## 5. 診断

LSP 診断と GnuCOBOL 診断は別々の仕組みですが、表示方法（行内 mark）は同じです。

| 発生元 | 実行タイミング | 内容 |
|---|---|---|
| LSP server | リアルタイム | 型エラー、未定義シンボル |
| `cobol.nvim` diagnostics | 保存時、編集後の debounce、挿入モード終了時 | `cobc` の構文エラーと警告 |

### 診断関連のキー

| キー | 動作 |
|---|---|
| `]d` / `[d` | 次 / 前の診断へ移動 |
| `<leader>cd` | 現在行の診断を表示（浮動ウィンドウ） |
| `<leader>xq` | 診断を quickfix に送る |

COBOL の診断は `cobc` から得られます。次のコマンドで確認してください。

```vim
:CobolLint
```

## 6. 練習

### 練習1：COBOL に LSP がないことを確認する

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. `:lua =vim.lsp.get_clients({ bufnr = 0 })` を実行する
2. 戻り値を確認する

**確認ポイント**：空の一覧 `{}` が返り、COBOL に LSP がないことが分かります。

### 練習2：LSP がある言語と比較する

1. 任意の `.lua` ファイルを開く（例：`~/.config/nvim/lua/plugins/flash.lua`）
2. `:lua =vim.lsp.get_clients({ bufnr = 0 })` を実行する
3. 戻り値を確認する

**確認ポイント**：`lua_ls` などの server 情報が表示されます。練習1と比べると違いが分かります。

### 練習3：LSP で移動する

Lua ファイルで：

1. 関数呼び出しにカーソルを置く
2. `gd` を押す

**確認ポイント**：関数の定義に移動し、`<C-o>` で戻れます。

### 練習4：名前を変更する

Lua ファイルで：

1. 変数にカーソルを置く
2. `<leader>cr` を押す
3. 新しい名前を入力して Enter を押す

**確認ポイント**：すべての参照箇所が変更されます。**COBOL では renameProvider がないため、このキーは利用できません。**

### 練習5：COBOL の診断を確認する

1. COBOL ファイルを開く
2. ピリオドを1つ意図的に削除する
3. 保存する（`:w`）
4. 診断 mark が表示されるか確認する

**確認ポイント**：エラー mark が表示され、`<leader>cd` で `cobc` のエラー情報を確認できます。`u` で元に戻してください。

## 7. つまずきやすい点

### COBOL の `gd` は LSP のように動くが、LSP ではない

これは `cobol.nvim` の `:CobolGotoDef` です。動作は似ていますが、実装は異なります。ジャンプに失敗した場合は、**どのプラグインが処理しているかを先に確認してください**。

```vim
:verbose nmap gd
```

出力にマッピングの登録元が表示されます。

### COBOL で `<leader>cr` が効かない

renameProvider がないため、このキーは登録されません。代わりに grug-far（`<leader>sr`）または grep とマルチカーソルを使います。

**注意**：`cobol.nvim` では `<leader>cr` が「レコードレイアウト計算」（`:CobolCalcRecord`）に割り当てられており、LSP の rename とキーが衝突します。COBOL buffer では `cobol.nvim` 側の機能が実行されます。

### Mason で server をインストールできない

ネットワークの問題か、システム依存パッケージが不足している可能性があります。`:Mason` の画面で `?` を押してヘルプを確認するか、`:MasonLog` を確認してください。

### 診断が更新されない

LSP 診断は非同期なので、編集後に少し待ってください。COBOL の診断は `cobol.nvim` が保存時または debounce 後に実行します。`on_change = true`、`debounce_ms = 600` に設定されています。

## 8. 公式ドキュメント

```vim
:h lsp
:h lsp-config
:h vim.lsp.buf
```

- `nvim-lspconfig`：<https://github.com/neovim/nvim-lspconfig>
- `mason.nvim`：<https://github.com/mason-org/mason.nvim>

## 9. 適用範囲

- この記事のキー設定は `lua/plugins/lsp.lua` に基づき、**server の能力に応じて動的に登録されます**。server が対応していない機能のキーは割り当てられません。
- **COBOL には LSP server がありません**。COBOL の `gd`、`K`、`gf`、診断はすべて LSP ではなく `cobol.nvim` によるものです。
- COBOL buffer では `<leader>cr` が `cobol.nvim` のレコードレイアウト機能に割り当てられており、LSP の rename とは別の機能です。
- LSP 診断と `cobc` 診断は独立した仕組みです。COBOL で使われるのは後者です。
