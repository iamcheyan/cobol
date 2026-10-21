# 差分と履歴の全体像：diffview.nvim

gitsigns が「この行は変更されたか」を解決するのに対し、diffview は「**今回のコミット全体で何が変わったか**」と「**このファイルは過去にどう変化したか**」を確認するためのプラグインです。

差分を左右に並べたビュー（左が旧、右が新）で表示し、ファイルツリーとファイル単位の移動機能も備えています。

---

## 1. 解決する問題

| 要件 | diffview なし | diffview あり |
|---|---|---|
| コミット全体の変更を見る | `git show` が端末上で詰め込まれる | 左右並列ビュー + ファイルツリー |
| ファイルごとにレビューする | 長い diff をスクロール | ファイルツリーから選択 |
| ファイルの履歴を見る | `git log -p ファイル` | サイドバーに全バージョンを表示 |
| 三方向マージ | 手作業 | 三方向ビューを内蔵 |

## 2. 設定内容

`lua/plugins/diffview.lua`：

```lua
opts = {
  enhanced_diff_hl = true,
  view = {
    default = {
      layout = "diff2_horizontal",
    },
  },
  hooks = {
    diff_buf_read = function(bufnr)
      vim.opt_local.swapfile = false
    end,
    diff_buf_win_enter = function(bufnr, winid, ctx)
      vim.opt_local.swapfile = false
    end,
  },
}
```

| パラメーター | 値 | 説明 |
|---|---|---|
| `enhanced_diff_hl` | `true` | より細かな差分ハイライト（単語単位） |
| `layout` | `diff2_horizontal` | 左右に並べて表示 |
| `swapfile` | `false` | スワップファイルを書き込まない（diff buffer は読み取り専用ビュー） |

## 3. キー操作

| キー | コマンド | 動作 |
|---|---|---|
| `<leader>gd` | `:DiffviewOpen` | 現在の作業ツリーの差分を開く |
| `<leader>gv` | `:DiffviewOpen` | 同上（別名キー） |
| `<leader>gD` | `:DiffviewFileHistory %` | **現在のファイル**の履歴 |
| `<leader>gV` | `:DiffviewFileHistory` | ブランチ全体の履歴 |
| `<leader>gq` | `:DiffviewClose` | 閉じる |

### よく使うコマンド（キー割り当てなし）

| コマンド | 動作 |
|---|---|
| `:DiffviewOpen HEAD~3` | 3つ前のコミットと比較 |
| `:DiffviewOpen main...feature` | 2つのブランチを比較 |
| `:DiffviewOpen <commit>` | 指定したコミットと比較 |
| `:DiffviewToggleFiles` | ファイルパネルの表示切り替え |
| `:DiffviewFocusFiles` | ファイルパネルにフォーカスを移す |
| `:DiffviewRefresh` | 更新 |


![`DiffviewOpen` の実画面。左がファイルパネル、中央が旧版、右が新版で、変更行がハイライトされます。](images/20-diffview.png)

`DiffviewOpen` の実画面。左がファイルパネル、中央が旧版、右が新版で、変更行がハイライトされます。

## 4. 画面構成

`:DiffviewOpen` を開くと、次のように表示されます。

```text
┌────────────────┬──────────────────────────────────────────┐
│ ファイルツリー   │  差分ビュー（左右並列）                   │
│                │                                          │
│ M lessons/...  │  旧バージョン        │  新バージョン       │
│ M extensions/  │  ────────────────  │  ────────────────    │
│                │  - 旧行            │  + 新行              │
└────────────────┴──────────────────────────────────────────┘
```

### ビュー内のキー操作

| キー | 動作 |
|---|---|
| `<Tab>` | ファイルツリーと diff の間でフォーカスを切り替える |
| `]c` / `[c` | 次 / 前の変更ブロックへ移動 |
| `do` | 旧バージョンを取り込む（get from other） |
| `dp` | 新バージョンを反映する（put to other） |
| `g?` | ヘルプを表示 |
| `q` | 閉じる |

`do` / `dp` は競合の解決に便利です。片側の内容をもう片側に適用できます。

## 5. COBOL での利用例

### 例1：一括置換をレビューする

grug-far で8個のファイルを変更した後：

1. `<leader>gd`
2. ファイルツリーから順にファイルを選択
3. `]c` で各ファイル内の変更ブロックを順に移動

**`git diff` をスクロールする場合との違い**：ファイルツリーを見るだけで変更ファイルを把握でき、見落としを防げます。

### 例2：フィールド名の変遷を調べる

```text
<leader>gD    現在のファイルの履歴
```

サイドバーにこのファイルに関係するコミットが並び、選択すると各回の変更を確認できます。

「`WS-RECORD-COUNT` が `PIC 9(2)` から `PIC 9(3)` に変わったのはいつか」といった問題の調査に使えます。

### 例3：2つのブランチを比較する

```vim
:DiffviewOpen main...feature
```

特性ブランチで主線から何が変わったかを確認できます。PR のレビューに向いています。

### 例4：教材の変更をレビューする

```sh
cd ~/development/cobol
git log --oneline -3
```

```
ea537fc docs(tutorial): add search, jump and batch-replace guides
1e44647 docs(tutorial): add multicursor batch-editing guide with exercises
19a6f36 docs(lesson-17): verify fixed-length offsets with a column ruler
```

```vim
:DiffviewOpen 1e44647~1
```

そのコミット全体で何が変わったかを確認します。

## 6. 練習

### 練習 1：作業ツリーの差分を開く

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. 1行変更する
2. `<leader>gd`

**確認**：左右並列の diff が開き、左側が HEAD の内容、右側が現在の内容（変更を含む）になっている。

### 練習 2：diff 内で変更ブロックへ移動する

1. diff ビューで `]c` を押す
2. カーソルが次の変更箇所へ移動することを確認する

**確認**：カーソルが変更ブロック間を移動する。

### 練習 3：ファイル履歴を見る

1. `<leader>gD`（現在のファイル）
2. 左側にコミット一覧が表示されることを確認する
3. コミットを1つ選択する

**確認**：そのコミット時点でのファイルの diff を表示できる。

### 練習 4：特定コミット全体の変更を見る

```vim
:DiffviewOpen 19a6f36~1
```

**確認**：その commit の変更全体が表示される。

### 練習 5：閉じる

1. `<leader>gq`

**確認**：diffview が閉じ、通常の編集画面に戻る。

### 練習 6：ファイルツリーで移動する

1. `<leader>gd`
2. `<Tab>` でファイルツリーに切り替える
3. `j` / `k` で移動し、`Enter` でファイルを開く

**確認**：複数ファイルの diff を切り替えて確認できる。

## 7. つまずきやすい点

### `<leader>gd` と `gd` は別の操作

- `gd`（leader なし）= 定義へ移動（`cobol.nvim` または LSP）
- `<leader>gd` = diffview を開く

**1文字の違いで機能がまったく異なります。** 間違えると予期しないウィンドウが開きます。

### 開いた画面が空白

現在の作業ツリーに未コミットの変更がない状態です。`:DiffviewOpen HEAD~1` または `<leader>gD` で履歴を確認してください。

### diff 内を編集できない

diffview の buffer は**読み取り専用ビュー**です。コードを変更するには元のファイルに戻ります。

### `do` / `dp` を押しても反応しない

これらが有効なのは**競合解決**の場面（`diff3` レイアウト）です。通常の diff ビューでは使えません。

### 閉じた後にウィンドウ配置が変わった

diffview はウィンドウを再配置します。`<leader>gq` の後、必要に応じて `<C-w>=` で均等に分割し直してください。

### 大きなリポジトリで開くのが遅い

`:DiffviewOpen` は差分全体を計算します。変更が多い場合、数秒かかるのは正常です。

## 8. gitsigns との使い分け

| 確認したいこと | 使う機能 |
|---|---|
| この行が変更されたか | gitsigns の左サイン列 |
| この変更箇所の内容 | `<leader>gp`（gitsigns のプレビュー） |
| この変更箇所だけをステージする | `<leader>gs`（gitsigns） |
| **コミット全体で何が変わったか** | `<leader>gd`（diffview） |
| **このファイルの履歴** | `<leader>gD`（diffview） |
| この行を書いた人 | `<leader>gb`（gitsigns blame） |

**行単位では gitsigns、ファイル単位と履歴には diffview を使います。**

## 9. 公式ドキュメント

```vim
:h diffview
:h diffview-configuration
```

リポジトリ：<https://github.com/sindrets/diffview.nvim>

## 10. 対象範囲

- ここで紹介するキー操作は `lua/plugins/diffview.lua` の設定に基づきます：`<leader>gd`、`<leader>gv`、`<leader>gD`、`<leader>gV`、`<leader>gq`。
- レイアウトは `diff2_horizontal`（左右並列）に固定されています。上下レイアウトにするには設定変更が必要です。
- diff buffer は読み取り専用です。`swapfile = false` は読み取り専用ビュー用のスワップファイルを作らないための意図的な設定です。
- 引数なしの `:DiffviewOpen` は**作業ツリーとインデックス**を比較します。履歴を見るには revision を明示するか、`<leader>gD` を使います。
