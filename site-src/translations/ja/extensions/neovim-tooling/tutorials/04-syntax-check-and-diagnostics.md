# GnuCOBOL の構文チェックと Neovim の診断

COBOL ソースには、固定形式、句読点、宣言に関するルールがあります。`cobol.nvim` は現在のバッファに対して GnuCOBOL の構文チェックを実行し、認識できた問題を Neovim の診断として表示できます。

## チェックの実行方法

- 既定では、保存時、テキスト変更後の 600 ms のデバウンス後、Insert モードを抜けたときに非同期チェックを実行します。
- `<leader>cl` / `:CobolLint` は現在のバッファをすぐにチェックします。
- `<leader>cq` / `:CobolQuickfix` は現在の診断を Neovim の Quickfix リストに入れます。
- `:CobolDiagnosticsToggle` は自動診断の有効・無効を切り替えます。
- 可能な場合、未保存のバッファ内容を標準入力経由で `cobc` に渡します。
- Copybook の診断は、可能な場合、Copybook のバッファとソースプログラムの `COPY` 行に関連付けられます。

![Neovim に表示された GnuCOBOL コンパイラー診断](images/compiler-diagnostics.png)

スクリーンショットでは、未定義フィールドに関するコンパイラーエラーがソースの横に表示されています。診断の範囲は GnuCOBOL の出力とプラグインの解析結果に依存します。`cobc` がない場合はコンパイラーによるチェックを実行できません。

## 簡単な演習

一時コピーに次の短いプログラムを作成し、`:CobolLint` を実行します。

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CHECK-DEMO.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
           DISPLAY WS-COUNT.
           STOP RUN.
```

`WS-COUNT` の参照を一時的に `WS-MISSING` に変更し、自動チェックを待つか、もう一度 `:CobolLint` を実行します。コンパイラーが認識可能な形式でエラー位置を出力すれば、Neovim に診断が表示されます。`:CobolQuickfix` で一覧を開き、`<CR>` を押すと該当箇所へ移動します。名前を修正して再チェックし、診断が消えることを確認します。

## 設定

```lua
{
  "iamcheyan/cobol.nvim",
  opts = {
    diagnostics = {
      enable = true,
      on_save = true,
      on_change = true,
      debounce_ms = 600,
      warnings = { "all", "no-obsolete" },
    },
  },
}
```

`cobc_command` でコンパイラーを指定し、`cobc_extra_args` で引数を追加します。プロジェクトプロファイルでは `compiler`、`compiler_args`、`dialect`、`copybook_paths` も設定できます。詳細はプラグインのヘルプ `:help cobol-projects` を参照してください。
