# バッファタブバー：bufferline.nvim

ファイルを十数個開くと、`:ls` では番号しか見えず、どれが現在のファイルで、どれに未保存の変更があるのか分かりません。

bufferline はバッファをウィンドウ上部のタブバーに表示します。現在のタブは強調表示され、変更済みのタブには丸印が付き、ファイルタイプごとのアイコンも表示されます。

---

## 1. 解決する問題

| 要件 | タブバーなし | bufferline あり |
|---|---|---|
| 開いているファイルを確認 | `:ls` を見て番号を推測 | 上部の一行ですべて確認 |
| 現在のファイルを確認 | Winbar や記憶に頼る | 現在のタブを強調表示 |
| 未保存の変更を確認 | `:ls` の `+` を見る | タブに丸印が付く |
| 切り替え | `:b3` | タブをクリック、または `<leader>bb` |

## 2. 設定内容

`lua/plugins/bufferline.lua`：

| オプション | 値 | 意味 |
|---|---|---|
| `mode` | `buffers` | バッファを表示（タブページではない） |
| `diagnostics` | `false` | LSP 診断アイコンを表示しない |
| `color_icons` | `false` | アイコンをファイルタイプ色にせず、タブ文字色を継承 |
| `show_tab_indicators` | `false` | タブ番号を表示しない |
| `show_buffer_close_icons` | `true` | 各タブに閉じるボタンを表示 |
| `separator_style` | `""` | 継ぎ目のないコンパクトなレイアウト |
| `buffer_padding` | `1` | タブの左右にそれぞれ1文字分の余白 |

### サイドバーとの連携

```lua
offsets = {
  { filetype = "neo-tree", text = "", padding = 1 },
  { filetype = "aerial", text = "", padding = 1 },
  { filetype = "snacks_layout_box" },
}
```

Neo-tree や Aerial を開くと、タブバーは**対応する幅を空ける**ため、その上に重なりません。`padding = 1` は、先頭のタブを編集領域の winbar に揃えるための設定です。

### 条件付き有効化

```lua
enabled = vim.env.WDIFF_NVIM ~= "1"
```

`WDIFF_NVIM=1` のときは読み込まれません（特定の diff 用）。通常はこの変数を設定しないため、既定で有効です。

## 3. キー操作

バッファ操作はすべて `<leader>b` グループにあります（which-key が現在のバッファを動的に表示します）：

| キー | 動作 |
|---|---|
| `<leader>bb` | 直前のバッファに切り替え（alternate） |
| `<leader>bd` | 現在のバッファを削除 |
| `<leader>bo` | ほかのバッファをすべて削除 |
| `<leader>bi` | 非表示のバッファを削除 |
| `<leader>bD` | バッファを削除してウィンドウを閉じる |
| `<leader>bl` / `<leader>bn` | 次のバッファ |
| `<leader>bh` / `<leader>bp` | 前のバッファ |

**最もよく使うのは `<leader>bb`** です。2つのファイルを行き来できます。

### マウス

| 操作 | 動作 |
|---|---|
| タブを左クリック | そのタブに切り替え |
| 閉じるアイコンをクリック | そのバッファを閉じる |
| タブバー末尾の `+` をクリック | 新しいファイルを作成 |
| リストアイコンをクリック | バッファ一覧を開く（snacks picker） |

## 4. タブバーで分かること

| 表示 | 意味 |
|---|---|
| 強調表示された背景 | 現在のバッファ |
| 左側の丸印 | 未保存の変更あり |
| ファイルアイコン | ファイルタイプを表す |
| 閉じるボタン | マウスでクリック可能 |

**診断アイコンは無効です**（`diagnostics = false`）。そのため、LSP エラーはタブに表示されません。gitsigns や行内 mark で確認してください。

## 5. 練習

### 練習 1：タブバーを確認

```sh
cd ~/development/cobol
nvim
```

1. `:e lessons/17_fixed-length-files/lesson.cob`
2. `:vsplit lessons/20_file-matching/lesson.cob`
3. 上部のタブバーを確認します

**確認ポイント**：2つのタブが見え、現在のタブが強調表示される。

### 練習 2：変更マークを確認

1. 現在のファイルの文字を1つ変更します（保存しません）
2. そのタブを確認します

**確認ポイント**：タブに丸印（未保存マーク）が付きます。`:w` で保存すると消えます。

### 練習 3：切り替え

1. `<leader>bb`

**確認ポイント**：2つのバッファを行き来できる。

### 練習 4：ほかのバッファを削除

1. ファイルを3つ開きます
2. `<leader>bo`

**確認ポイント**：現在のバッファだけが残り、ほかは削除される。

### 練習 5：サイドバー分の余白を確認

1. `<leader>fe` で Neo-tree を開きます
2. タブバーが左側の幅を空けているか確認します

**確認ポイント**：タブバーは Neo-tree の右側から始まり、重ならない。

## 6. よくある問題

### タブバーが表示されない

`enabled = vim.env.WDIFF_NVIM ~= "1"` が設定されています。環境変数を確認します：

```vim
:echo $WDIFF_NVIM
```

値が `1` なら bufferline は読み込まれません。

### タブが多くて一行に収まらない

タブバーの幅には限りがあります。使わないバッファを `<leader>bo` で削除するか、`<leader>fb`（snacks）で切り替えてください。

### `+` をクリックしても反応しない

新規ファイルの作成には `config.file_actions.new_file()` が使われ、閉じるアイコンは標準機能です。クリックしても反応しない場合は、別の要素を誤って押していないか確認してください。

### テーマと色が合わない

ハイライトは `config.ui_highlights.bufferline_highlights()` で一括生成されます。テーマを変更すると色も追従します。

### 診断が見えない

設定で無効になっています（`diagnostics = false`）。診断は行内 mark または `<leader>xq` で確認してください。

## 7. 公式ドキュメント

```vim
:h bufferline
:h bufferline-configuration
```

リポジトリ：<https://github.com/akinsho/bufferline.nvim>

## 8. 適用範囲

- このページの設定元は `lua/plugins/bufferline.lua` です：`mode = "buffers"`、診断無効、`color_icons = false`、継ぎ目のない区切り。
- `WDIFF_NVIM=1` の場合は読み込まれません。
- `<leader>b*` のキー操作は snacks の bufdelete が提供するもので、bufferline 自体の機能ではありません。
- タブバーに表示されるのは**バッファ**で、タブページではありません（`:tabnew` で開いたタブページはここに表示されません）。
