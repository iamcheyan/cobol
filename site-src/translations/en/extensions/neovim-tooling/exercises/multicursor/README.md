# Multi-Cursor Exercises

Companion exercises for [Multi-Cursor Batch Editing](../../tutorials/08-multicursor-batch-editing.md).

| File | Goal | Keys |
|---|---|---|
| `01-rename-field.cob` | `WS-CUSTOMER-*` → `WS-CLIENT-*` (8 places) | `<leader>A` + `ciW` |
| `02-unify-pic.cob` | Four `PIC` clauses → `PIC 9(9).` | `gaip` + `fP` + `C` |
| `03-split-selection.cob` | Four `VALUE "A".."D"` → `"N"` | `gaip` + `ci"` |
| `04-sequence-fill.cob` | Six `"000"` → `"001".."006"` | `gaip` + `g<C-a>` |
| `05-fixed-format-batch.cob` | Status codes and `PIC`, in two passes | `ci"` and `C` separately |

```sh
cd extensions/neovim-tooling/exercises/multicursor
nvim 01-rename-field.cob
```

Verify every file still compiles:

```sh
for f in *.cob; do printf '%-28s ' "$f"; cobc -fsyntax-only "$f" && echo OK; done
```
