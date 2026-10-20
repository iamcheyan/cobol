# キー操作の見つけ方：which-key.nvim

48個のプラグインを設定し、キー操作は数百個。**すべて覚える必要はありませんし、覚えきれなくても問題ありません。**

which-key は `<leader>` を押して少し待つと、「次に何を押せるか」をポップアップで表示します。キー操作はグループごとに分類され、説明も付いています。

---

## 1. 解決する問題

| 要件 | which-key なし | which-key あり |
|---|---|---|
| キーを忘れた | 設定やドキュメントを探す | プレフィックスから一覧を見る |
| どんな機能があるか分からない | 設定をすべて読む | 階層ごとに展開する |
| 新しいプラグインのキーを覚える | README を調べる | キーを押して説明を見る |

**この設定で最初に覚える価値のあるプラグインです**。他のすべてのプラグインのキー操作を見つけるのに役立ちます。

## 2. 設定内容

`lua/plugins/which-key.lua`：

```lua
opts = {
  preset = "helix",
  show_keys = false,
  win = {
    border = "single",
    title = false,
  },
  icons = {
    breadcrumb = "»",
    group = "",
    keys = {
      Space = "SPC ",
    },
  },
},
```

| パラメーター | 値 | 説明 |
|---|---|---|
| `preset` | `helix` | Helix 形式のレイアウトを使用 |
| `show_keys` | `false` | キーの列を表示しない（説明のみ表示） |
| `border` | `single` | 1本線の枠線 |
| `breadcrumb` | `»` | 階層の区切り記号 |
| `Space` | `SPC ` | Space キーを `SPC` と表示 |

## 3. グループ一覧

設定には15個のグループがあります。

| プレフィックス | グループ名 | 内容 |
|---|---|---|
| `<leader>` | Leader | トップレベル |
| `<leader><tab>` | tabs | タブページ |
| `<leader>b` | buffer | バッファ（動的に展開） |
| `<leader>c` | code | コード操作、名前変更、フォーマット |
| `<leader>d` | debug | デバッグ |
| `<leader>dp` | profiler | パフォーマンス分析 |
| `<leader>f` | file/find | ファイルと検索 |
| `<leader>g` | git | Git 操作 |
| `<leader>gh` | hunks | Git の行単位の操作 |
| `<leader>q` | quit/session | 終了とセッション |
| `<leader>m` | bookmarks | ブックマーク |
| `<leader>s` | search | 検索 |
| `<leader>u` | ui | UI の切り替え |
| `<leader>w` | windows | ウィンドウ（`<C-w>` をプロキシ） |
| `<leader>x` | diagnostics/quickfix | 診断と quickfix |

leader 以外にも、いくつかのプレフィックスがあります。

| プレフィックス | グループ名 |
|---|---|
| `g` | goto |
| `gs` | surround |
| `z` | fold |
| `<c-w>` | windows |

### 2つの特別なグループは動的に展開される

```lua
{
  "<leader>b",
  group = "buffer",
  expand = function()
    return require("which-key.extras").expand.buf()
  end,
},
{
  "<leader>w",
  group = "windows",
  proxy = "<c-w>",
  expand = function()
    return require("which-key.extras").expand.win()
  end,
},
```

`<leader>b` は**現在開いているすべてのバッファ**を一覧表示します（固定の説明だけではありません）。
`<leader>w` は `<C-w>` のサブコマンドを**プロキシ**するため、`w` グループの操作は `<C-w>` とまったく同じです。

## 4. 使い方

### 基本操作

1. `<leader>`（Space）を押す
2. **少し待つ**（約1秒、または設定した `delay` の時間）
3. 一覧が表示される
4. 対応するキーを押す

### 階層をたどる

```text
<leader>     → すべてのグループを表示
<leader>g    → git 配下のキーを表示
<leader>gh   → hunks 配下のキーを表示
<leader>ghs  → 「hunk をステージ」を実行
```

### キーを忘れたとき

```text
<leader>?    ヘルプ検索を開く
:WhichKey   手動で表示する
```

### 特定のプレフィックスだけを見る

```vim
:WhichKey <leader>f
```

キーを先に押さなくても、`<leader>f` 配下のキーを一覧表示できます。

## 5. 覚える順序

設定の作者は `docs/plugins/PLUGINS.md` でおすすめの順序を示しています。ここではキー操作の観点から並べ直します。

### 第1段階：入口（`<leader>f`）

```text
<leader>ff     ファイルを探す
<leader>fg     内容を検索
<leader>fe     ファイルツリー
<leader>fb     バッファ
```

この4つで日常操作の80%をカバーできます。

### 第2段階：編集（`g` と `gs`）

```text
g7 g8 g12 g73    COBOL の列へ移動
gsa gsd gsr      囲み記号を追加/削除/置換
gcc             コメント化
```

### 第3段階：Git（`<leader>g`）

```text
<leader>gd      差分ビュー
<leader>gs      hunk をステージ
<leader>gb      blame
```

### 第4段階：コード（`<leader>c`）

```text
<leader>ca      コードアクション
<leader>cr      名前変更
<leader>cl      LSP の状態
```

## 6. 練習

### 練習 1：トップレベルを調べる

1. `<leader>`（Space）を押す
2. 1秒待つ
3. 表示されたグループ一覧を確認する

**確認**：15個のグループ名（file/find、git、code など）が見える。

### 練習 2：階層をたどる

1. `<leader>` → 待つ → 一覧を見る
2. `g` を押す
3. 待つ → git グループのキーを見る
4. `h` を押す
5. 待つ → hunks グループを見る

**確認**：コマンドを実行せず（表示を見るだけで）3階層を続けてたどれる。

### 練習 3：バッファの動的展開

1. ファイルを3つ開く
2. `<leader>b` を押して待つ
3. 表示されたバッファを確認する

**確認**：開いた3つのファイルがファイル名付きで一覧に表示される。

### 練習 4：コマンドで確認する

```vim
:WhichKey <leader>f
```

**確認**：キー操作を押さなくても `<leader>f` グループのキーが直接一覧表示される。

### 練習 5：which-key で新しいプラグインを覚える

1. [チュートリアル一覧](../README.md)から、まだ使ったことのないプラグインを選ぶ
2. which-key でそのキーを探す
3. 実際に1回実行する

**確認**：ドキュメントを読まずに、知らない機能のキーを見つけて実行できる。

## 7. つまずきやすい点

### `<leader>` を押しても表示されない

which-key は `event = "VeryLazy"` で読み込まれます。起動後、使えるようになるまで少し時間がかかります。1〜2秒待ってから試してください。

### 表示が速すぎる、または遅すぎる

デフォルトの遅延は約1000msです。設定ではこの値を変更していません。変えたい場合は `delay` オプションを追加してください。

### `show_keys = false` でキー名が見えない

設定ではキーの列を非表示にしているため、説明だけが表示されます。具体的なキーを確認するには：

```vim
:WhichKey <leader>f
```

出力にはキー名も表示されます。

### 一覧が長すぎて読みにくい

`<C-f>` / `<C-b>` でページを切り替えてください（which-key のバージョンによります）。または `:WhichKey` で特定のプレフィックスを検索できます。

### キーが一覧に表示されない

考えられる理由：
1. プラグインが動的に登録するキーで、which-key が取得できていない。
2. より高い優先度のマッピングに上書きされている。
3. その機能の server が未対応（LSP のキーは機能に応じて登録されます）。

実際の登録元は `:verbose nmap キー` で確認します。

## 8. 他のプラグインとの関係

which-key は**メタプラグイン**です。独自の機能を提供するのではなく、他のプラグインの機能を見つけやすくします。

| 確認したいこと | 使う機能 |
|---|---|
| どんなキーがあるか | which-key（`<leader>` + 少し待つ） |
| キーに何が割り当てられているか | `:verbose nmap キー` |
| 機能の使い方 | `<leader>?` でヘルプを検索 |
| 詳細なドキュメント | 各チュートリアル + `:help` |

## 9. 公式ドキュメント

```vim
:h which-key
:h which-key-configuration
```

リポジトリ：<https://github.com/folke/which-key.nvim>

## 10. 対象範囲

- ここで紹介する設定は `lua/plugins/which-key.lua` に基づきます：`preset = "helix"`、`show_keys = false`、15個の静的グループ。
- `<leader>b`（バッファ）と `<leader>w`（ウィンドウ）は**動的に展開**され、現在の状態に応じて内容が変わります。
- `<leader>w` には `proxy = "<c-w>"` が設定されているため、サブコマンドは `<c-w>` と完全に同じです。
- which-key が表示するのは**登録済み**のマッピングだけです。LSP など、プラグインが機能に応じて動的に登録するキーは、対応する server がないと表示されません。
