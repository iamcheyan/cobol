# マルチカーソル演習

[マルチカーソルによる一括編集](../../tutorials/08-multicursor-batch-editing.md) の演習ファイルです。

| ファイル | 目標 | キー |
|---|---|---|
| `01-rename-field.cob` | `WS-CUSTOMER-*` → `WS-CLIENT-*`（8 箇所） | `<leader>A` + `ciW` |
| `02-unify-pic.cob` | 4 つの `PIC` 句 → `PIC 9(9).` | `gaip` + `fP` + `C` |
| `03-split-selection.cob` | 4 つの `VALUE "A".."D"` → `"N"` | `gaip` + `ci"` |
| `04-sequence-fill.cob` | 6 つの `"000"` → `"001".."006"` | `gaip` + `g<C-a>` |
| `05-fixed-format-batch.cob` | 状態コードと `PIC` を 2 回に分けて | `ci"` と `C` を別々に |

```sh
cd extensions/neovim-tooling/exercises/multicursor
nvim 01-rename-field.cob
```

編集後は全ファイルがコンパイルできることを確認します。

```sh
for f in *.cob; do printf '%-28s ' "$f"; cobc -fsyntax-only "$f" && echo OK; done
```
