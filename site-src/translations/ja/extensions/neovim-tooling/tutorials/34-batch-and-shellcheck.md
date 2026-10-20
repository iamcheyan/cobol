# バッチスクリプトと Shell のチェック：batch.nvim / nvim-lint

COBOL コースには `.sh` スクリプト（`build.sh`、`check.sh`、`install-toolchain.sh`）がたくさんあります。これらも読むべきコードです。

この設定では、バッチスクリプト（`.bat`／`.cmd`）と Shell スクリプトに言語サポートと lint を提供します。

---

## 1. 解決する問題

| 要件 | サポートなし | サポートあり |
|---|---|---|
| `.bat` ファイルの構文ハイライト | テキストのみ | `batch.nvim` が提供 |
| `.bat` の構造アウトライン | なし | `batch.nvim` が提供 |
| Shell スクリプトの問題検出 | 実行するまで分からない | `shellcheck` がリアルタイムで通知 |

## 2. batch.nvim（Windows バッチ）

`lua/plugins/batch.lua`：

| オプション | 値 | 意味 |
|---|---|---|
| `enable_diagnostics` | `true` | 診断を有効化 |
| `enable_folding` | `true` | 折りたたみを有効化 |
| `enable_statusline` | `true` | ステータスラインに情報を表示 |
| `map_keys` | `false` | **キーを割り当てない** |

`ft = { "dosbatch" }` —— dosbatch ファイルタイプでのみ有効です。

`map_keys = false` は重要な選択です。**既存のキーを奪いません**。機能にはコマンドまたは Aerial からアクセスします。

### Aerial との連携

設定では `batch.nvim` は `contextline.nvim` の依存関係です。Aerial の backend 設定には次の記述があります。

```lua
dosbatch = { "batch" },
batch = { "batch" },
```

そのため `.bat` ファイルの構造を Aerial（`<leader>cs`）で確認できます。

### COBOL コース内での位置づけ

コースの中心は Linux／Shell ですが、バッチ関連の内容もあります。`extensions/enterprise-batch/` は企業向けバッチ処理コースです（Windows の `.bat` ではなく COBOL のバッチ処理です）。

## 3. nvim-lint + shellcheck（Shell スクリプト）

`lua/plugins/shellcheck.lua`：

```lua
lint.linters_by_ft = {
  sh = { "shellcheck" },
  bash = { "shellcheck" },
}
```

実行されるタイミング：

```lua
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  callback = function(args)
    if vim.tbl_contains({ "sh", "bash" }, vim.bo[args.buf].filetype) then
      lint.try_lint("shellcheck")
    end
  end,
})
```

| イベント | 動作 |
|---|---|
| `BufEnter` | バッファに入ったときにチェック |
| `BufWritePost` | 保存後にチェック |
| `InsertLeave` | 挿入モードを抜けた後にチェック |

### 前提条件：`shellcheck` がインストールされていること

```sh
which shellcheck
```

未インストールの場合、lint は何も表示せずにスキップします（エラーも通知もありません）。

インストール方法：

```sh
sudo apt install shellcheck
```

### 診断の表示

`shellcheck` の警告は、`cobc` の診断と同様に診断として表示されます（行内マーク）。例：

- 引用符がなく、単語分割が起こる問題
- 未使用の変数
- 移植性の問題
- よくあるタイプミス

## 4. COBOL コースでの実用性

### 場面1：コースのスクリプトをチェックする

コース内には次のファイルがあります。

```sh
lessons/32_bank-reconciliation-project/build.sh
lessons/32_bank-reconciliation-project/check.sh
lessons/29_embedded-sql/install-toolchain.sh
extensions/standalone-examples/ 里的 Makefile 相关脚本
```

`.sh` ファイルを開くと、`shellcheck` が潜在的な問題を示します。

### 場面2：ビルドスクリプトを書く

`build.sh` を変更すると、保存時にチェックされるため、実行するまで構文の問題に気付かないという事態を避けられます。

### 場面3：Shell のベストプラクティスを学ぶ

`shellcheck` の指摘自体が Shell の教材になります。特定の書き方にどんなリスクがあるか説明してくれます。

## 5. 練習

### 練習1：shellcheck がインストール済みか確認する

```sh
which shellcheck || echo "not installed"
```

**合格条件**：インストール済みならパスが表示され、未インストールならメッセージが表示される。

### 練習2：スクリプトを開いて診断を見る

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/build.sh
```

1. 診断マークがあるか確認する
2. 一度保存（`:w`）してチェックを実行する

**合格条件**：スクリプトに問題があれば診断マークが表示される。問題がなければ表示されない（どちらも正常です）。

### 練習3：意図的に問題を入れる

1. スクリプトに `echo $UNQUOTED_VAR` と書く（引用符なし）
2. `:w`
3. 結果を見る

**合格条件**：変数を引用符で囲むよう `shellcheck` が指摘する。元に戻すとマークが消える。

### 練習4：sh／bash のみで有効なことを確認する

1. `.cob` ファイルを開く
2. 意図的に何か書き込む
3. `:w`

**合格条件**：shellcheck の診断は**表示されない**（sh／bash のみが対象です）。

### 練習5：batch.nvim がキーを奪わないことを確認する

```vim
:verbose nmap <buffer>
```

`.bat` ファイルがあれば開き、batch.nvim のキー割り当て（`map_keys = false`）がないことを確認します。

## 6. つまずいたとき

### shellcheck が動作しない

確認項目：

1. `shellcheck` がインストールされているか：`which shellcheck`
2. ファイルタイプが `sh` または `bash` か：`set ft?`

未インストールなら何も表示せずにスキップされます。

### 診断が多すぎて確認しきれない

`shellcheck` はデフォルトで厳密にチェックします。スクリプトにコメントを追加して、特定の警告を無効にできます。

```sh
# shellcheck disable=SC2086
```

または `shellcheck` の `-e` 引数を設定します。

### `.bat` ファイルがハイライトされない

`batch.nvim` は `ft = { "dosbatch" }` で対象が制限されています。ファイルタイプを確認します。

```vim
:set ft?
```

### batch.nvim のキーがない

**これは意図した設定です**（`map_keys = false`）。Aerial またはコマンドから使います。

### conform の shfmt と競合する

conform は `shfmt` で Shell をフォーマットし、lint は `shellcheck` で検査します。**一方は整形、もう一方は問題の検出**を行うため、競合しません。

### 大きなスクリプトのチェックが遅い

`shellcheck` は外部プロセスです。非常に大きなスクリプトでは一時的に待たされる場合があります。これは正常です。

## 7. 公式ドキュメント

- `nvim-lint`：<https://github.com/mfussenegger/nvim-lint>
- `batch.nvim`：<https://github.com/iamcheyan/batch.nvim>
- `shellcheck`：<https://www.shellcheck.net/>

## 8. 適用範囲

- `shellcheck` は外部インストールが必要です。未インストールの場合、lint は**何も表示せずにスキップ**します（エラーは出ません）。
- nvim-lint は `sh`／`bash` のみが対象で、他のファイルタイプには作用しません。
- `batch.nvim` の `map_keys = false` は、既存のキー割り当てを奪わないための意図的な設定です。
- コースの中心は COBOL で、Shell スクリプトは補助的なものです。この2つは「付随的なサポート」です。
