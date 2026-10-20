# コード整形：conform.nvim

整形の目的は「見た目をよくする」ことではなく、**diff に実際の変更だけを反映すること**です。保存のたびに空白が並べ替えられると、コードレビューがノイズだらけになります。

conform.nvim はファイルタイプに応じた整形ツールを呼び出し、全体に適用される切り替え設定を尊重します。

---

## 1. 解決する課題

| 要件 | conform なし | conform あり |
|---|---|---|
| 保存時の自動整形 | 言語ごとに別のプラグインを設定 | 1 つの設定で全言語を管理 |
| 手動整形 | `:!stylua %` などを覚える | `<leader>F` |
| 自動整形を一時停止 | 設定を変更 | `<leader>uf` で切り替え |
| 利用可能な整形ツールを確認 | 自分で調べる | `:ConformInfo` |

## 2. 現在の設定

`lua/plugins/conform.lua`：

```lua
keys = {
  {
    "<leader>F",
    function()
      require("conform").format({ async = true, lsp_fallback = true })
    end,
    mode = { "n", "x" },
    desc = "Format (conform)",
  },
},
```

### 言語ごとの整形ツール

| ファイルタイプ | ツール |
|---|---|
| `lua` | `stylua` |
| `sh` / `bash` / `zsh` | `shfmt` |
| `python` | `ruff_fix` → `ruff_format` |
| `javascript` / `typescript` / `tsx` | `prettierd` → `prettier`（`stop_after_first`） |
| `css` / `html` / `json` / `yaml` / `markdown` | `prettierd` → `prettier` |
| `rust` | `rustfmt` |
| `go` | `gofumpt` → `goimports` |
| `c` / `cpp` | `clang_format` |

**注意：リストに `cobol` はありません。**

### 保存時の自動整形：デフォルトでは無効

```lua
format_on_save = function(bufnr)
  if vim.g.autoformat == false then
    return nil
  end
  return { timeout_ms = 500, lsp_fallback = true }
end,
```

```lua
init = function()
  vim.g.autoformat = false
end,
```

**デフォルトで `autoformat = false` のため、保存しても自動整形されません。** これは意図的です。COBOL は列位置に敏感なので、自動整形のリスクが大きいためです。

設定コメントでは、関数形式を使う理由を次のように説明しています。

```lua
-- The function form is evaluated on each save, so toggling takes effect
-- immediately instead of being frozen at startup.
```

この関数は保存のたびに評価されるため、切り替えがすぐ反映されます。

## 3. 使い方

### 手動で整形

| キー | 動作 |
|---|---|
| `<leader>F` | 現在の buffer を整形（`n` / `x` モード） |

ビジュアルモードでは選択範囲だけを整形します。

### 利用可能なツールを確認

```vim
:ConformInfo
```

現在の buffer で使われる整形ツール、インストール状況、パスを表示します。

### 自動整形を切り替える

| キー | 動作 |
|---|---|
| `<leader>uf` | 自動整形を全体で切り替え |
| `<leader>uF` | 現在の buffer で切り替え |

（この 2 つのキーは LazyVim 風の UI 切り替えから提供され、設定では conform がその状態を尊重すると記されています。）

## 4. COBOL の場合

**COBOL の整形ツールはありません。** 理由は次のとおりです。

1. 標準的な COBOL formatter がありません（Go の `gofmt` のようなもの）。
2. COBOL の固定形式では列位置に厳格な制約があり、自動で並べ替えると簡単に壊れます。
3. `cobol.nvim` が提供する `:CobolFormatCase` は、予約語を大文字にするだけで、コードの並べ替えはしません。

### COBOL で使える代替手段

| やりたいこと | ツール |
|---|---|
| 予約語を大文字に統一 | `:CobolFormatCase`（`cobol.nvim`） |
| インデントを揃える | 手動、または `cobol.nvim` のスマート Tab |
| 列位置を確認 | `cobol.nvim` の超過ハイライト + `awk` によるチェック |
| 構文を検証 | `cobc -fsyntax-only` |

**COBOL コードの「整形」は基本的に手作業です。** これがこの言語の現状です。

### 列位置の確認（整形の代わり）

第 17 課では、ショートカットに設定できる 3 つの `awk` コマンドを紹介しています。

```sh
LC_ALL=C awk '/^      \*/ {next} {if (length($0)>72) print "over72", NR, length($0)}' lesson.cob
LC_ALL=C awk '/^      \*/ {next} {i=match($0,/[^ ]/); if (i>0 && i<12 && i!=8 && i!=11) print "bad column", NR, i}' lesson.cob
```

## 5. 練習

### 練習 1：現在のファイルで使われる整形ツールを確認

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. `:ConformInfo`
2. 出力を確認する

**合格基準**：COBOL buffer に利用可能な整形ツールがないと表示される。

### 練習 2：ツールがある言語と比較

1. 任意の `.lua` ファイルを開く
2. `:ConformInfo`

**合格基準**：`stylua` とそのパスが表示される。

### 練習 3：手動で整形

Lua ファイルで次の操作をします。

1. わざとインデントを崩す
2. `<leader>F`
3. インデントが修正されたことを確認する

**合格基準**：標準的なインデントに戻る。

### 練習 4：デフォルトで自動整形されないことを確認

1. `.lua` ファイルを開く
2. インデントを変更する
3. `:w`
4. インデントが自動修正されるか確認する

**合格基準**：`autoformat = false` のため、**自動修正されない**。

### 練習 5：自動整形を切り替える

1. `<leader>uf` で自動整形を有効にする
2. もう一度インデントを変更する
3. `:w`

**合格基準**：今度は保存時に自動整形される。その後、もう一度 `<leader>uf` を押して無効に戻します。

### 練習 6：COBOL の整形代替手段

1. COBOL ファイルを開く
2. `:CobolFormatCase`
3. 予約語が大文字になったか確認する

**合格基準**：`move`、`display` などが `MOVE`、`DISPLAY` になる一方、インデントと列位置は変わらない。

## 6. よくある問題

### `<leader>F` が反応しない

`ConformInfo` でツールが利用可能か確認します。利用可能なツールがなければ、整形は何もせず終了します（設定コメントによると、conform 自身が `Formatter 'stylua' unavailable` と警告します）。

### 保存時に整形されない

デフォルトでは無効です（`vim.g.autoformat = false`）。`<leader>uf` で有効にするか、手動で `<leader>F` を実行してください。

### COBOL で `<leader>F` を押しても何も起きない

COBOL formatter がないため、これは正常な動作です。故障ではありません。

### 整形後に diff が大きくなる

整形ツールのスタイルが既存のコードと一致していない可能性があります。**まず `git diff` で変更内容を確認してください**。受け入れられない場合は `git checkout --` で復元します。

**これが `autoformat = false` の利点です**。予期しない大規模な並べ替えを防げます。

### `prettierd` が見つからない

`prettierd` は prettier の常駐プロセス版です。インストールされていない場合は `prettier` に切り替わります（設定の `stop_after_first = true` がこれを保証します）。

## 7. 公式ドキュメント

```vim
:h conform
:h conform-options
```

リポジトリ：<https://github.com/stevearc/conform.nvim>

## 8. 対象範囲

- 設定は `lua/plugins/conform.lua` にあり、12 種類のファイルタイプに対応しています。**COBOL は含まれません**。
- **自動整形はデフォルトで無効**（`vim.g.autoformat = false`）です。COBOL は列位置に敏感なため、意図的にこの設定にしています。
- COBOL の「整形」には `:CobolFormatCase`（予約語の大文字化）、手動インデント、`awk` による列位置チェックを使います。
- `format_on_save` は関数形式のため、`<leader>uf` の切り替えが再起動なしですぐ反映されます。
