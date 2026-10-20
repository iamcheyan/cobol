# 多光标练习

配合 [多光标批量编辑](../../tutorials/08-multicursor-batch-editing.md) 使用。

```sh
cd extensions/neovim-tooling/exercises/multicursor
nvim 01-rename-field.cob
```

| 文件 | 练习目标 | 关键按键 |
|---|---|---|
| `01-rename-field.cob` | `WS-CUSTOMER-*` → `WS-CLIENT-*`（8 处） | `<leader>A` + `ciW` |
| `02-unify-pic.cob` | 四个不同长度的 `PIC` 统一为 `PIC 9(9).` | `gaip` + `fP` + `C` |
| `03-split-selection.cob` | 四个 `VALUE "A".."D"` 改成 `"N"` | `gaip` + `ci"` |
| `04-sequence-fill.cob` | 六个 `"000"` 变成 `"001".."006"` | `gaip` + `g<C-a>` |
| `05-fixed-format-batch.cob` | 状态码与 `PIC` 两步批量改 | `ci"` 与 `C` 分开用 |

改完用语法检查确认没有改坏：

```sh
for f in *.cob; do printf '%-28s ' "$f"; cobc -fsyntax-only "$f" && echo OK; done
```

五个文件在改动前都能通过 `cobc -fsyntax-only`，改动后也应保持通过。如果编译报错，最常见的原因是用了 `cw` 而不是 `C`，导致 `PIC` 子句留下残余字符。
