# 起動画面：dashboard-nvim

引数なしで `nvim` を起動すると、既定では空の `[No Name]` バッファが表示されます。ファイルも自分で探す必要があります。

dashboard-nvim は起動画面に置き換え、最近使ったファイルやショートカットを表示します。キーを1つ押すだけで作業を始められます。

---

## 1. 解決する問題

| 要件 | 空の起動画面 | dashboard あり |
|---|---|---|
| 最近のファイルを開く | `:b` や `:e` でパスを入力 | リストから選ぶ |
| 作業の始め方 | 自分で考える | ショートカットを表示 |
| 最近の作業を確認 | 手がかりなし | MRU リスト |

## 2. 設定内容

`lua/plugins/dashboard.lua`：

| オプション | 値 | 意味 |
|---|---|---|
| `theme` | `hyper` | Hyper テーマ |
| `change_to_vcs_root` | `false` | Git のルートへ自動移動しない |
| `header` | ASCII art `NVIM` | 上部に大きな文字を表示 |
| `project.enable` | `false` | プロジェクト一覧を表示しない |
| `mru.enable` | `true` | 最近使ったファイルを表示 |
| `mru.limit` | `10` | 最大10件 |
| `mru.cwd_only` | `false` | 現在のディレクトリに限定しない |

### 重要：読み込みタイミング

```lua
-- dashboard-nvim installs its startup hook on UIEnter. Load it before
-- that event so a no-argument launch never leaves the initial [No Name]
-- buffer on screen.
lazy = false,
```

`lazy = false` は必須です。dashboard は `UIEnter` にフックを設定するため、遅れて読み込まれると空のバッファが一瞬表示されます。

### Snacks の dashboard は無効

```lua
{
  "folke/snacks.nvim",
  opts = {
    dashboard = { enabled = false },
  },
}
```

どちらのプラグインでも起動画面を作れますが、この設定では**dashboard-nvim を選び**、snacks の起動画面を無効にしています。

## 3. ショートカット

起動画面ではアルファベット1文字で操作できます：

| キー | 動作 |
|---|---|
| `n` | 新しいファイルを作成 |
| `o` | フォルダを開く |
| `f` | ファイルを検索（Snacks picker） |
| `s` | テキストを検索（Snacks picker） |
| `l` | Lazy を開く（プラグイン管理） |

### 最近使ったファイルの一覧

`mru` は最近使ったファイルを最大10件表示し、**現在のディレクトリに限定されません**。項目にカーソルを移動して Enter を押すと開きます。

### セッションとの関係

起動時に `auto-session` がそのプロジェクトのセッションを見つけると、**先にセッションが復元されます**。復元できるセッションがない場合にだけ dashboard が表示されます。

そのため、昨日このディレクトリで作業していた場合、今日 `nvim` を起動すると昨日のレイアウトに戻り、起動画面が表示されないことがあります。

起動画面を表示するには：

```vim
:Dashboard
```

## 4. 練習

### 練習 1：起動画面を表示

```sh
cd ~/development/cobol
nvim
```

**確認ポイント**：大きな `NVIM` 文字とショートカットがある起動画面が表示される。

**昨日のファイルが表示される場合**：auto-session がセッションを復元しています。セッションのないディレクトリで試すか、`:Dashboard` を実行してください。

### 練習 2：ショートカットでファイルを探す

1. 起動画面で `f` を押します
2. 表示を確認します

**確認ポイント**：Snacks のファイル検索が開く。

### 練習 3：最近使ったファイルを開く

1. 起動画面で `j` / `k` を使い、最近使ったファイルに移動します
2. Enter を押します

**確認ポイント**：そのファイルが開く。

### 練習 4：snacks の dashboard が無効であることを確認

1. 設定を確認します

```vim
:lua =require("snacks").config.dashboard
```

**確認ポイント**：設定によって `enabled = false` になっている。

### 練習 5：起動画面を手動で開く

1. 任意のファイルを開きます
2. `:Dashboard`

**確認ポイント**：起動画面が表示されます（開いているファイルは閉じません）。`:q` またはバッファ切り替えで戻れます。

## 5. よくある問題

### 起動時に dashboard が表示されない

次の2つが考えられます：

1. **auto-session がセッションを復元した** — 先に復元されるため、起動画面は表示されません。
2. ファイル名などの引数を付けて起動した（例：`nvim file.cob`） — 起動画面は表示されません。

`:Dashboard` で手動表示するか、セッションのないディレクトリで起動してください。

### 起動時に空の画面が一瞬見える

`lazy = false` はこれを防ぐ設定です。それでも表示される場合は、ほかのプラグインが `UIEnter` より前にバッファを奪っていないか確認してください。

### プロジェクト一覧が表示されない

`project.enable = false` の設定です。これは意図的にプロジェクト一覧を無効にし、MRU とショートカットを使うためです。

### 最近使ったファイルの一覧が空

初回起動時、または `vim.v.oldfiles` を消去した場合は空です。何度か使うと一覧に表示されます。

### `change_to_vcs_root = false` の意味

Git ルートへ自動移動しません。`~/development/cobol/lessons/17_xxx/` で起動すると、cwd はそのディレクトリのままで、リポジトリのルートには移動しません。リポジトリ全体を検索する場合は `ff` ではなく `<leader>fF`（Git ルート検索）を使います。

### `f` / `s` キーが反応しない

これらのキーは `Snacks.picker` を呼び出します。snacks が読み込まれていないと失敗します。`:Lazy` で snacks の状態を確認してください。

## 6. ほかのプラグインとの関係

| 場面 | 担当 |
|---|---|
| 起動画面 | dashboard-nvim（snacks の機能は無効） |
| セッション復元 | auto-session（dashboard より**優先**） |
| ファイル検索 | snacks picker（dashboard の `f` が呼び出す） |
| 新規ファイル作成 | `config.file_actions.new_file()` |

**優先順位を把握しましょう**：auto-session が先にセッションを復元し、セッションがない場合にだけ dashboard が表示されます。

## 7. 公式ドキュメント

```vim
:h dashboard-nvim
```

リポジトリ：<https://github.com/nvimdev/dashboard-nvim>

## 8. 適用範囲

- このページの設定元は `lua/plugins/dashboard.lua` です：`theme = "hyper"`、MRU は最大10件、プロジェクト一覧は無効、`lazy = false`。
- **snacks の dashboard は無効**（`snacks.dashboard.enabled = false`）で、dashboard-nvim のみを使います。
- **auto-session が dashboard より優先**されます。セッションがあると起動画面は表示されません。
- `change_to_vcs_root = false` のため、起動時に Git ルートへ自動移動しません。
