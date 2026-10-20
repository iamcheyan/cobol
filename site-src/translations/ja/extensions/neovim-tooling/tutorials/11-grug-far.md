# ファイル横断の検索置換：grug-far.nvim

項目名が 8 ファイル 30 箇所にある。`:%s` は 1 ファイルだけ、`argdo` は先にファイル一覧を組む必要がある。**grug-far は「何を探す・何に置換する・範囲をどこまで」を 1 画面に集約し、確認してから書き込みます。**

---

## 1. 何を解決するか

| やり方 | 問題 |
|---|---|
| `:%s/old/new/g` | 現在のファイルのみ |
| `:argdo %s/.../g \| update` | ファイル一覧を先に作る必要がある。検索ミスに後で気づく |
| ファイルごとに手作業 | 20 箇所目でどこまで直したか忘れる |
| 外部の `sed -i` | エディタ外で実行。失敗しても戻しにくい |

grug-far の方法：**まず全一致（行番号と文脈つき）を提示し、納得してから置換する**。プレビューを 1 件ずつ確認することもできます。

## 2. 実際の設定

`lua/plugins/grug-far.lua`：

```lua
{
  "MagicDuck/grug-far.nvim",
  opts = { headerMaxWidth = 80 },
  cmd = { "GrugFar", "GrugFarWithin" },
  keys = {
    {
      "<leader>sr",
      function()
        local grug = require("grug-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        grug.open({
          transient = true,
          prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil,
          },
        })
      end,
      mode = { "n", "x" },
      desc = "Search and Replace",
    },
  },
}
```

### 3 つの入口

| 入口 | 動作 |
|---|---|
| `<leader>sr` | 開き、**現在のファイル拡張子を Files Filter に自動入力** |
| `:GrugFar` | フィルタを予備入力せずに開く |
| `:GrugFarWithin` | **ビジュアル選択範囲内だけ**置換 |

**自動予備入力が重要です**：`.cob` ファイルを編集中に押すと Files Filter が `*.cob` になり、`README.md` 内の同名テキストを誤って書き換えません。

`x`（ビジュアル）モードで `<leader>sr` を押すと選択範囲が引き継がれます。

### 主要オプション

`transient = true`：置換後にウィンドウを自動で閉じます。

`headerMaxWidth = 80`：ヘッダーの最大幅。

## 3. 画面構成

`<leader>sr` を押すと：

```text
┌─────────────────────────────────────────────────────────┐
│ Help g?   Replace \r   Sync All \s ...                  │
├──────────────────────────┬──────────────────────────────┤
│  Search:                 │  ← 検索パターン              │
│    e.g. foo              │                              │
│  Replace:                │  ← 置換内容                  │
│    e.g. bar              │                              │
│  Files Filter:           │  ← 例: *.cob                 │
│  Flags:                  │  ← --ignore-case など        │
│  Paths:                  │  ← ディレクトリ指定          │
├──────────────────────────┴──────────────────────────────┤
│  ⟪ ripgrep ⟫                                            │
│  4 matches in 2 files                                   │
│    f.cob                                                │
│      5   01 WS-ALPHA PIC X(10) VALUE "AAAAAAAAAA".  [1] │
│      9       DISPLAY WS-ALPHA                       [2] │
│    g.cob                                                │
└─────────────────────────────────────────────────────────┘
```

**入力欄と結果欄は同じバッファ内にあります。** `j` / `k` でフィールド間を移動し、`i` で編集します。

### フィールドの説明

| フィールド | 用途 | 例 |
|---|---|---|
| Search | 検索パターン（正規表現可） | `WS-ALPHA`、`foo([a-z0-9]*)` |
| Replace | 置換内容（キャプチャ参照可） | `WS-FIRST`、`${1}_foo` |
| Files Filter | ファイル種別・パスを限定 | `*.cob`、`*.{cob,cpy}`、`**/docs/*.md` |
| Flags | ripgrep へ渡す引数 | `--ignore-case`、`-i` |
| Paths | 検索ディレクトリを限定 | `./lessons/`、`../` |

### よく使う Flags

| Flag | 効果 |
|---|---|
| `-i` | 大文字小文字を無視 |
| `-.` | 隠しファイルを含める |
| `--no-ignore` | `.gitignore` を無視 |
| `--multiline` | 複数行にまたがって一致 |

## 4. 置換を実行する 3 つの方法

ここが通常の `:%s` との最大の違いです。**置換は一度に全部やる必要がありません。**

| キー | 動作 | 使いどころ |
|---|---|---|
| `\r` | **Replace**：置換を実行 | 確認済み、全部置換 |
| `\s` | **Sync All**：結果欄のテキストをファイルへ書き戻す | 結果を手で編集した後 |
| `\l` | **Sync Line**：現在の 1 件だけ同期 | 1 件ずつ確認 |
| `\n` | **Sync Next**：現在を同期して次へ | 見ながら進める |
| `\p` | **Sync Prev**：現在を同期して前へ | 逆方向 |
| `\v` | **Sync File**：このファイルの全結果を同期 | ファイル単位で進める |
| `g?` | ヘルプウィンドウを開く | キーを忘れたとき |

`\` は `localleader` です（設定では `vim.g.maplocalleader = "\\"`）。

### `\r` と `\s` の違い

- **`\r`（Replace）**：全置換。複数行の置換にも対応。
- **`\s`（Sync All）**：**結果欄に現在表示されているテキスト**を書き戻す。

結果欄の行を手で削除すれば、`\s` は残った行だけを同期します。これが特定の一致を除外する方法です。

## 5. 実測記録

このリポジトリの COBOL ファイルで `<leader>sr` を開き、`WS-ALPHA` を検索：

```text
4 matches in 2 files

   f.cob
     5        01 WS-ALPHA PIC X(10) VALUE "AAAAAAAAAA". [1]
     9            DISPLAY WS-ALPHA                      [2]

   g.cob
```

注目すべき点：

1. **入力と同時に検索**され、Enter は不要。
2. **`N matches in M files`** が表示される。まずこの数字で範囲を確認する。
3. 各結果に**ファイル名 + 行番号 + 文脈**が付き、`[1]` `[2]` はそのファイル内の一致番号。
4. 開いた `<leader>sr` の Files Filter は `*.cob` で予備入力されていた（`.cob` を編集中だったため）。

**この `matches in N files` が最重要の安全確認です。** 想定よりファイル数が多いなら、フィルタが緩すぎます。置換前に Files Filter を締めてください。

## 6. COBOL での 4 つの場面

### 場面 1：課をまたいで改名

`WS-ACCT-` は 32 課すべてに現れ、`WS-ACCOUNT-` に統一したい：

```text
Search:        WS-ACCT-
Replace:       WS-ACCOUNT-
Files Filter:  *.cob
```

**まず一致数を確認**します。1 課だけに限定するなら Paths に `./lessons/17_fixed-length-files/` を入れます。

### 場面 2：コピーブックの宣言と全参照を同時に変更

`.CPY` と `.cob` の両方が対象：

```text
Files Filter: *.{cob,cpy}
```

Files Filter は glob のブレース記法に対応しています。

### 場面 3：`VALUE "A"` をすべて `VALUE "P"` に

```text
Search:        VALUE "A"
Replace:       VALUE "P"
Files Filter:  *.cob
```

**注意**：コメント内の `VALUE "A"` も書き換わります。検索欄は正規表現に対応しているので、コード行だけに限定できます：

```text
Search:        ^(?!      \*).*VALUE "A"
```

より簡単なのは、置換後に `git diff` でコメントの誤変更を確認する方法です（後述）。

### 場面 4：選択した数行だけ変更

1. `V` で数行を選択
2. ビジュアルモードで `<leader>sr`
3. 検索と置換は選択範囲にだけ作用

「このブロックの `WS-X` だけ改名し、他は触らない」ときに使います。

## 7. Git を安全網として使う

grug-far は速く直せますが、速く壊せます。**置換前に作業ツリーがきれいなことを確認し、置換後すぐに diff を見てください。**

```sh
cd ~/development/cobol
git status --short          # 変更は 1 ファイルだけのはず
git diff                    # 何が変わったか行単位で読む
```

壊した場合：

```sh
git checkout -- ファイルパス   # 1 ファイルを戻す
git restore .              # 未コミット変更をすべて戻す
```

設定には `<leader>gd`（diffview）もあるので、並べて確認できます。

## 8. 演習

### 演習 1：実行せずに観察する

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. `<leader>sr`
2. Search に `WS-RECORD-COUNT`
3. **`N matches in M files` を確認するだけ**で置換しない
4. `<Esc>` で閉じる

**合格条件**：一致数とファイル数を言えること。この手順ではファイルを変更しません。

### 演習 2：Files Filter の効果を確認

1. `<leader>sr` で Search に `FILE STATUS`
2. Files Filter が `*.cob` か確認
3. Files Filter を空にして一致数の変化を見る

**合格条件**：フィルタを空にすると一致数が増える（`.md` 内の `FILE STATUS` も拾う）。**だから気軽に空にしてはいけない**と分かること。

### 演習 3：実際の置換（コピー上で）

```sh
cd /tmp && cp -r ~/development/cobol/lessons/17_fixed-length-files /tmp/grugtest
cd /tmp/grugtest && nvim lesson.cob
```

1. `<leader>sr`
2. Search: `WS-RECORD-COUNT`
3. Replace: `WS-WRITE-COUNT`
4. `matches in 1 files` を確認
5. `\r` で実行
6. `:wq`
7. `cobc -fsyntax-only lesson.cob`

**合格条件**：コンパイルが通ること。失敗したら意図しない箇所を変更しています。

### 演習 4：1 件ずつ確認

1. コピー上で 3 回出現する語を検索
2. 置換値を入力
3. `\n` で 1 件ずつ同期し、カーソルの移動先を確認
4. 最後に `\s` で残りをまとめて同期

**合格条件**：`\n`（1 件ずつ）と `\s`（全体）の違いを説明できること。

### 演習 5：結果欄だけで制御

1. 5 件の一致を検索
2. 結果欄で**2 行を手で削除**
3. `\s` を押す

**合格条件**：残った 3 行だけがファイルへ同期されること。これが一致の除外方法です。

## 9. つまずきやすい点

### `\r` を押しても反応しない

`\` は `localleader` です。設定が `vim.g.maplocalleader = "\\"`（バックスラッシュ 1 つ）か確認してください。`:lua print(vim.g.maplocalleader)` で分かります。

### 意図しない箇所が置換された

よくある 3 つの原因：

1. **Files Filter 未設定**：全ファイルを検索した。
2. **一致数を確認していない**：いきなり `\r` を押した。
3. **正規表現が緩すぎる**：`WS-ACCT` は `WS-ACCT-OLD` の一部にも一致する。

**対策**：必ず `N matches in M files` を先に読む。数字がおかしければフィルタを直す。

### コメントまで変更された

`VALUE "A"` のようなパターンはコメント内にも現れます。`git diff` で確認するか、行頭を固定した正規表現を使います：

```text
Search:        ^(?!      \*).*VALUE "A"
```

（`^(?!      \*)` は 7 桁目が `*` のコメント行を除外します。）

### `\s` の後でファイルが壊れた

`\s` は**結果欄の現在のテキスト**を書き戻します。結果欄を誤って編集していると、その編集も書き込まれます。`u` で戻すか `git checkout` で復元してください。

### 複数行の置換が効かない

ripgrep は既定で行をまたぎません。Flags に次を追加します：

```text
--multiline
```

## 10. 他のプラグインとの関係

| 目的 | 道具 |
|---|---|
| 探すだけで変更しない | `<leader>fg`（snacks picker） |
| 現在ファイルの数箇所だけ変更 | `:%s/old/new/g` |
| **ファイル横断の一括変更** | `<leader>sr`（grug-far） |
| 同一ファイルの複数行を同時に変更 | マルチカーソル（[チュートリアル 08](08-multicursor-batch-editing.md)） |
| 何が変わったか見る | `<leader>gd`（diffview）、`git diff` |

**選び方**：1 箇所なら通常コマンド、同一ファイルの隣接数行ならマルチカーソル、ファイル横断の同一パターンなら grug-far です。

## 11. 公式ドキュメント

```vim
:h grug-far
:h grug-far-config
```

リポジトリ：<https://github.com/MagicDuck/grug-far.nvim>

組み込みヘルプ（完全なキー表）を開く：

```text
<leader>sr を押してから g?
```

## 12. 範囲と限界

- 本ページのキーはローカル設定（`lua/plugins/grug-far.lua`）由来です：`<leader>sr`、`:GrugFar`、`:GrugFarWithin`。
- `<leader>sr` が現在の拡張子を Files Filter に予備入力するのは、あなたの設定が加えた便宜機能で、プラグインの既定動作ではありません。
- 画面のキー（`\r`、`\s`、`\l`、`\n`、`\p`、`\v`、`g?`）はプラグイン既定のキー表に基づき、本機で確認済みです。
- 実測は「開く・リアルタイム検索・一致数と位置の表示」までです。**実際の置換はまずコピーで練習してください**（演習 3）。本番のコースファイルを操作する可能性があるためです。
- 置換前に作業ツリーがきれいなことを確認し、置換後すぐに `git diff` を実行してください。
