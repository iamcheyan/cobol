# メッセージとコマンドラインの改善：noice.nvim

Neovim の標準表示では、メッセージ、コマンドライン、確認ダイアログが画面下部の同じ一行に詰め込まれます。**`-- INSERT --`、エラー表示、`:` コマンド、確認ダイアログがすべて混在し**、ほかのプラグインのフロートに隠れることもよくあります。

noice.nvim は、それぞれを分離して見やすくし、適切な位置に表示します。

---

## 1. 解決する問題

| 要件 | Neovim 標準 | noice |
|---|---|---|
| コマンドラインを見る | 下部の一行で、フロートに隠れる | 独立したコマンドライン表示 |
| 確認ダイアログ（未保存で `:q`） | 下部の一行で見落としやすい | 枠付きの中央フロート |
| コピー内容を見る | 下部に一瞬表示 | 下部の独立表示で2.2秒間表示 |
| エラーを見る | 下部の一行で、上書きされる場合がある | 種類に応じて表示先を振り分け |

## 2. 設定内容

`lua/plugins/noice.lua` の先頭コメントには設定の意図が記されています：

```lua
-- Keep Ex command entry at the bottom, but render Neovim's blocking confirm
-- prompts (for example :q with unsaved changes) in Noice's centered popup.
```

### コマンドライン

| オプション | 値 | 意味 |
|---|---|---|
| `cmdline.enabled` | `true` | コマンドラインを引き受ける |
| `view` | `cmdline` | 下部の表示を使う |
| `format.cmdline.icon` | `false` | 標準の `:` プロンプトを維持 |
| `format.input.view` | `cmdline` | 入力欄も下部に表示 |

noice の既定である `>` アイコンではなく、標準の `:` を維持しています。使い始めたばかりでも戸惑わないようにする意図的な設定です。

### メッセージ

```lua
messages = {
  enabled = true,
  view = "cmdline",
  view_error = "cmdline",
  view_warn = "cmdline",
  view_search = "cmdline",
  view_history = "messages",
}
```

通常のメッセージ、エラー、警告、検索メッセージは下部のコマンドライン表示に出ます。`view_history` は messages に送られるため、`:messages` で履歴を確認できます。

### コピー確認（yank）

```lua
routes = {
  {
    filter = { event = "msg_show", find = "yanked into" },
    view = "yank",
    opts = { stop = true },
  },
},
views = {
  yank = {
    backend = "popup",
    position = { row = "100%", col = 0 },
    size = { height = "auto", width = "100%" },
    timeout = 2200,
  },
},
```

コピー後、画面下部に**横長のバー**が2.2秒間表示されます。設定コメントには次のように記されています：

```lua
-- Keep yank confirmations in their own bottom view. They can stack while
-- copying, then the whole message group hides after the last yank.
```

続けてコピーするとメッセージが積み重なり、最後のコピーから一定時間後に一括で消えます。

### 確認ダイアログ

```lua
confirm = {
  position = { row = "50%", col = "50%" },
  size = { max_width = 64 },
  border = { style = "rounded", padding = { 1, 2 }, text = { top = " Confirm " } },
}
```

未保存の変更がある状態で `:q` を実行すると、タイトルが `Confirm` の**中央配置の角丸フロート**が表示されます。

### 明示的に無効化している機能

```lua
popupmenu = { enabled = false },
notify = { enabled = false },
lsp = {
  progress = { enabled = false },
  message = { enabled = false },
  hover = { enabled = false },
  signature = { enabled = false },
},
```

| 無効化項目 | 理由 |
|---|---|
| `popupmenu` | 補完メニューは blink.cmp に任せる |
| `notify` | 通知は snacks に任せる |
| `lsp.*` | LSP のホバー、シグネチャ、進捗は標準の動作を維持 |

**この設定で noice が担当するのは3つだけです**：コマンドライン、コピー通知、確認ダイアログ。

## 3. 使い方

### 確認ダイアログ

1. ファイルを変更し、保存せずにおきます
2. `:q`
3. 中央に `[Y]es [N]o [C]ancel` のフロートが表示されます

`y` / `n` / `c` で選択します。

### コピー通知

1. `yy` で一行をコピーします
2. 画面下部にコピー内容を示すバーが表示されます
3. 2.2秒後に消えます

続けて `yy` を実行すると通知が積み重なり、最後のコピーの後にまとめて消えます。

### コマンドライン

1. `:` を押します
2. 標準の `:` プロンプト付きで、画面下部にコマンドラインが表示されます

標準の操作感を保ちながら、フロートに隠れにくくなります。

## 4. 練習

### 練習 1：確認ダイアログ

```sh
cd ~/development/cobol
nvim
```

1. 任意のファイルを開き、文字を1つ変更します（保存しません）
2. `:q`
3. 表示されたフロートを確認します

**確認ポイント**：タイトルが `Confirm` の中央配置の角丸フロートに3つの選択肢が表示される。

### 練習 2：コピー通知

1. `yy`
2. 画面下部を確認します

**確認ポイント**：コピー内容を示すバーが表示され、約2.2秒後に消える。

### 練習 3：連続コピーで通知を積み重ねる

1. `yy` を素早く5回押します
2. 通知を確認します

**確認ポイント**：通知が複数表示され、最後のコピー後にまとめて消える。

### 練習 4：コマンドライン

1. `:` を押します
2. `echo "test"` と入力して Enter を押します

**確認ポイント**：コマンドラインが画面下部に表示され、noice 既定の `>` ではなく標準の `:` が使われる。

### 練習 5：noice が通知を扱っていないことを確認

1. 通知を発生させます（例：`:lua vim.notify("hi")`）
2. 表示を確認します

**確認ポイント**：通知は snacks が表示します（`notify.enabled = false` のため）。noice の表示ではありません。

## 5. よくある問題

### コマンドラインが見えない

noice がコマンドラインを引き受けています。異常終了後に状態が残った場合は、`:NoiceEnable` / `:NoiceDisable` を切り替えてください。

### 確認ダイアログが中央に表示されない

設定では `position = { row = "50%", col = "50%" }` と指定しています。中央に表示されない場合は、snacks など、ほかのプラグインもフロート位置を変更していないか確認してください。

### コピー通知がすぐ消える

`timeout = 2200`（2.2秒）です。長く表示するには設定を変更します。

### noice に LSP のホバーを任せたい

設定では明示的に無効化しています：

```lua
lsp = {
  hover = { enabled = false },
  signature = { enabled = false },
},
```

LSP の hover（`<leader>K`）は標準の動作を維持します。noice で装飾した表示を使うには設定変更が必要です。

### 通知が noice から表示されない

`notify = { enabled = false }` のため、通知は snacks が担当します。**意図した設定**であり、問題ではありません。

### 補完メニューの表示がおかしい

`popupmenu = { enabled = false }` のため、補完メニューは blink.cmp が表示します。

## 6. ほかのプラグインとの役割分担

| UI 要素 | 担当 |
|---|---|
| コマンドライン | noice |
| コピー通知 | noice |
| 確認ダイアログ | noice |
| 通知 | **snacks** |
| LSP hover / シグネチャ | **vim 標準** |
| 補完メニュー | **blink.cmp** |

この役割分担を把握しておけば、「noice のドキュメントにある機能がこちらでは見当たらない」と戸惑わずに済みます。

## 7. 公式ドキュメント

```vim
:h noice
:h noice-config
```

リポジトリ：<https://github.com/folke/noice.nvim>

## 8. 適用範囲

- このページの設定元は `lua/plugins/noice.lua` です。**noice が担当するのはコマンドライン、コピー通知、確認ダイアログの3つだけです**。
- `notify`、`lsp.*`、`popupmenu` はすべて無効です。それぞれ snacks、vim 標準、blink.cmp が担当します。
- コマンドラインでは標準の `:` プロンプトを維持します（noice の既定である `>` ではありません）。
- コピー通知の `timeout = 2200` はミリ秒単位です。連続コピーでは通知が積み重なります。
