# もうひとつのマルチカーソル：vim-visual-multi

あなたの設定には**マルチカーソルプラグインが 2 つ**あります。`multicursor.nvim`（第 08 篇）と `vim-visual-multi` です。

本篇では後者と、**そのために設定に加えた特別な変更**について説明します。両者の役割分担を理解するうえで重要なポイントです。

---

## 1. なぜ 2 つあるのか

| プラグイン | 位置づけ |
|---|---|
| `multicursor.nvim` | モダンな実装。Treesitter と連携し、`gaip` で行ごとにカーソルを追加 |
| `vim-visual-multi` | 老舗プラグイン。`Ctrl-n` で単語を選択してカーソルを追加する、より「従来型」の機能 |

どちらも `lazy-lock.json` にあります。`multicursor-line.nvim` は `vim-visual-multi` を依存関係に指定しています。

```lua
dependencies = { "mg979/vim-visual-multi" },
```

したがって余分なプラグインではありません。`multicursor-line` の行頭・行末カーソル機能は、このプラグインを土台にしています。

## 2. 設定で行っていること

`lua/plugins/vim-visual-multi.lua` はプラグインを読み込むだけではなく、**`Ctrl-n` の動作を再定義しています**。

### 中核となるロジック

```lua
local last_linewise_mode = nil

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    last_linewise_mode = nil
  end,
})
```

挿入モードを抜けると、記憶していたモードをクリアします。

```lua
local function insert_ctrl_n()
  local vm = vim.g.Vm
  local vm_active = type(vm) == "table" and (tonumber(vm.buffer) or 0) > 0
  local extending = vm_active and tonumber(vm.extend_mode) == 1

  local cur_col = vim.fn.col(".")
  local end_col = vim.fn.col("$")
  local at_line_end = (cur_col >= end_col) or (cur_col == end_col - 1 and cur_col > 1)
  local at_line_start = (cur_col <= 1)
  ...
```

### 判定している 3 つのこと

| 変数 | 意味 |
|---|---|
| `vm_active` | vim-visual-multi にアクティブな選択範囲がすでにあるか |
| `at_line_end` | カーソルが行末にあるか |
| `at_line_start` | カーソルが行頭にあるか |

### 行末モード（`eol`）

カーソルが行末にあるときに `Ctrl-n` を押すと、次の処理が行われます。

```lua
if is_eol_mode then
  last_linewise_mode = "eol"
  vim.cmd("stopinsert")
  vim.cmd("normal! $")
  vim.fn["vm#commands#add_cursor_at_pos"](08-multicursor-batch-editing.md)
  vim.cmd("normal! j$")
  vim.fn["vm#commands#add_cursor_at_pos"](08-multicursor-batch-editing.md)
  vim.cmd("call b:VM_Selection.Insert.key('A')")
end
```

動作の流れ：

1. 現在行の末尾にカーソルを追加する。
2. 次の行の末尾にもカーソルを追加する。
3. `A`（行末に追加）で挿入モードに入る。

**典型的な用途**：連続する複数行の末尾に同じ内容を追加する。

### 行頭モード（`bol`）

カーソルが行頭にあるときに `Ctrl-n` を押すと、行頭モードに入ります。

```lua
if is_bol_mode then
  last_linewise_mode = "bol"
  ...
  vim.cmd("call b:VM_Selection.Insert.key('A')")
end
```

同様の処理を行頭で行います（`I` の動作）。

**注意**：コードの `bol` 分岐も `Insert.key('A')` を使っています。実際の動作はあなたの環境で確認してください。単純な誤記かもしれませんし、意図的な指定（`A` は行末に追加）かもしれません。

### 通常モード（行頭・行末以外）

vim-visual-multi 標準の `Ctrl-n` が動作します。カーソル下の単語を選択し、さらに押すと次の一致箇所を選択します。

## 3. multicursor.nvim との役割分担

| 場面 | 使用するプラグイン |
|---|---|
| 単語や選択範囲にカーソルを追加 | `multicursor.nvim`（`<leader>n`） |
| 段落内の各行にカーソルを追加 | `multicursor.nvim`（`gaip`） |
| **行末に続けて追加** | `vim-visual-multi`（行末で `Ctrl-n`） |
| 行頭にまとめて挿入 | `vim-visual-multi`（行頭で `Ctrl-n`） |
| `multicursor-line` で行単位にカーソル追加 | `multicursor-line`（`<leader>mh` など） |

`multicursor-line.nvim` の `<leader>mh`/`mt`/`ma` などは、`vim-visual-multi` を使って「行単位でカーソルを追加」します。手動で `Ctrl-n` を繰り返すより便利です。

## 4. 基本的な使い方（vim-visual-multi 標準機能）

独自設定を考慮しなくても、このプラグインには一通りの機能があります。

| キー | 動作 |
|---|---|
| `Ctrl-n` | カーソル下の単語を選択（もう一度押すと次の一致を選択） |
| `Ctrl-Down` / `Ctrl-Up` | 上下にカーソルを追加 |
| `Ctrl-x` | 現在の一致をスキップ |
| `Ctrl-p` | 現在のカーソルを削除 |
| `Tab` | 「カーソルモード」と「拡張モード」を切り替え |
| `\\a` | 一致箇所をすべて選択 |
| `q` | マルチカーソルを終了 |

Visual モードでは、選択範囲を基準に `Ctrl-n` でカーソルを追加できます。

## 5. COBOL での使用例

### 例 1：複数行の末尾に同じサフィックスを追加

```cobol
01 WS-FLAG-A PIC X(1) VALUE "A".
01 WS-FLAG-B PIC X(1) VALUE "B".
01 WS-FLAG-C PIC X(1) VALUE "C".
```

すべての行に ` - DONE` を追加する手順：

1. 1 行目の末尾にカーソルを置く。
2. `Ctrl-n` を押す（行末モードに入り、カーソルを 2 つ追加する）。
3. ` - DONE` と入力する。
4. `Esc` を押す。

**確認**：複数行の末尾に内容が追加されています。

先に行を選択する必要がないため、**multicursor の `gaip` + `A` より速くできます**。

### 例 2：連続した複数行の行頭にコメントを追加

カーソルを行頭に置き、`Ctrl-n` を押して行頭モードに入り、`*`（COBOL のコメント記号）を入力します。

**注意**：対象行全体がコメントになります。COBOL のコメントは 7 桁目に置く必要があるため、行頭モードで実際に挿入される位置を確認してください。

### 例 3：識別子をまとめて変更

`WS-ACCT` 上にカーソルを置き、`Ctrl-n` で選択します。さらに `Ctrl-n` を押して次の一致を追加し、`c` で変更します。

これは `multicursor.nvim` の `<leader>n` と機能が重複します。使いやすいほうを選んでください。

## 6. 練習

### 練習 1：行末に追加

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. 連続する行をいくつか探します（`01` 宣言など）。
2. 1 行目の**末尾**にカーソルを移動します。
3. `Ctrl-n` を押します。
4. 内容を入力します。
5. `Esc` を押します。

**確認**：複数行の末尾に内容が追加されています。

### 練習 2：行頭モード

1. カーソルを行の**先頭**に移動します。
2. `Ctrl-n` を押します。
3. 内容を入力します。
4. `Esc` を押します。

**確認**：複数行の行頭に内容が追加されています。

### 練習 3：単語を選択

1. `WS-` で始まる単語にカーソルを置きます。
2. `Ctrl-n` を押します（行頭・行末以外で）。
3. もう一度 `Ctrl-n` を押して次の一致を追加します。

**確認**：一致する単語が複数選択されています。

### 練習 4：multicursor と比較

1. `multicursor.nvim` の `<leader>n` でも同じ操作をします。
2. 使い心地を比較します。

**確認**：両者の違いを説明できます（`<leader>n` はより「モダン」で、行末で使う `Ctrl-n` モードはより直接的です）。

### 練習 5：終了

1. マルチカーソル状態で `q` または `Esc` を押します。

**確認**：カーソルが 1 つの状態に戻ります。

## 7. トラブルシューティング

### 挿入モードで `Ctrl-n` が反応しない

独自関数は `vm_active` を判定します。vim-visual-multi の状態に異常があると、処理が呼び出されない場合があります。`:echo g:Vm` で確認してください。

### 行末モードでカーソルが 1 つしか追加されない

コードは `at_line_end` を判定します。カーソルが本当の行末にない（後ろに空白が残っているなど）場合、行末モードに入りません。まず `$` で行末へ移動してください。

### 補完メニューと競合する

`Ctrl-n` は通常、補完候補の「次へ」に使われます。挿入モードでは blink.cmp が割り当てている場合があります。**実際にどちらのマッピングが有効かテストしてください。**

### 2 つのマルチカーソルプラグインが競合する

`multicursor.nvim` と `vim-visual-multi` を同時に使うと、一部のキーが競合する場合があります。**役割を明確に分ける**ことをおすすめします。単語には `<leader>n`、行末では `Ctrl-n` を使います。

### `last_linewise_mode` が残ってしまう

挿入モードを抜けるとクリアされます（`InsertLeave` 自動コマンドが自動で処理します）。動作がおかしい場合、`:lua last_linewise_mode = nil` は局所変数なので使えません。挿入モードに入り直してください。

## 8. 公式ドキュメント

リポジトリ：<https://github.com/mg979/vim-visual-multi>

```vim
:h vim-visual-multi
```

## 9. 適用範囲

- 本篇は `lua/plugins/vim-visual-multi.lua` の設定を説明しています。`Ctrl-n` を**再定義**しており、行頭・行末では特殊なモード、それ以外の位置では標準動作になります。
- `multicursor-line.nvim` の依存関係であり、余分なプラグインではありません。
- `multicursor.nvim` と機能が重なるため、役割を明確にすると混乱を避けられます。
- 挿入モードの `Ctrl-n` は blink.cmp の補完キーと競合する可能性があります。実際に有効になるマッピングをテストしてください。
