# Breadcrumb Dropdown: contextline.nvim

The breadcrumb in the Winbar is **one line**, so deeper hierarchies get truncated. And it can only show information; you can't interact with it.

contextline adds a dropdown menu to the breadcrumb: it lists the full structure of the current file and lets you jump by selecting an item.

---

## 1. What Problem It Solves

| Need | Winbar breadcrumb alone | With contextline |
|---|---|---|
| See the full hierarchy | One line; long paths are truncated | Everything is listed in a dropdown |
| Jump to a node | Scroll to find it | Select it from the menu |
| See the file path/name | Depends on configuration | Can be shown in the menu |

## 2. Your Configuration

`lua/plugins/contextline.lua`:

| Option | Value | Meaning |
|---|---|---|
| `separator` | ``  `` | Separator between hierarchy levels |
| `show_path` | `false` | Don't show the file path |
| `show_file` | `false` | Don't show the filename |
| `show_icons` | `true` | Show icons |
| `use_lsp` | `true` | Use LSP symbols (when available) |
| `use_navic` | `true` | Use navic |
| `use_treesitter` | `true` | Use Treesitter |

### Keybinding

| Key | Command | Action |
|---|---|---|
| `<leader>cb` | `:ContextlineMenu` | Open the structure dropdown |

### Data Source Priority

All three sources are enabled: `use_lsp`, `use_navic`, and `use_treesitter`.

Which one is actually used depends on **the capabilities available for the current filetype**:

| Filetype | Available source |
|---|---|
| Language with an LSP | LSP symbols |
| Has a Treesitter parser | Treesitter |
| COBOL | **Depends on whether `cobol.nvim` provides support** |

COBOL has neither an LSP nor a parser, so contextline **may not be able to get its structure** in COBOL. In that case, the dropdown is empty.

## 3. Comparing It with the `cobol.nvim` Breadcrumb

`cobol.nvim` includes its own Winbar breadcrumb (covered in Tutorial 02), showing `[ PROCEDURE > SECTION > PARA ]`.

| | `cobol.nvim` | contextline |
|---|---|---|
| Display location | Winbar (always visible) | Dropdown menu (opened on demand) |
| Data | Parses COBOL itself | LSP / Treesitter / navic |
| COBOL support | **Yes** | No (unless provided by the plugin) |

**For COBOL, the `cobol.nvim` breadcrumb and Aerial outline are enough**; contextline is mainly for other languages.

## 4. Exercises

### Exercise 1: Open the Menu

1. Open any file
2. Press `<leader>cb`

**Check**: The structure menu appears (it shows hierarchy if available, or is empty or displays a message if not).

### Exercise 2: See What Happens in COBOL

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/lesson.cob
```

1. Press `<leader>cb`
2. Observe

**Check**: **The menu will most likely be empty in COBOL** (no LSP and no parser). Nothing is broken—use Aerial (`<leader>cs`) instead.

### Exercise 3: Open a Filetype with an LSP

1. Open a Lua file
2. Press `<leader>cb`

**Check**: You can see the symbol hierarchy provided by the LSP (functions, variables, and so on).

### Exercise 4: Confirm the Configuration

```vim
:lua =require("contextline").config or vim.inspect(_G)
```

(The exact API depends on the plugin.) At minimum, confirm the values of `separator` and `show_icons`.

### Exercise 5: Compare with Aerial

1. Press `<leader>cb` to view the dropdown
2. Press `<leader>cs` to view the Aerial sidebar

**Check**: They use different structure sources; in COBOL, Aerial has content while contextline is empty.

## 5. Common Issues

### The Menu Is Empty

There are two possible reasons:

1. The current filetype has no LSP or Treesitter support (**this is the case for COBOL**);
2. The plugin hasn't received data yet (wait a moment and try again).

### It Duplicates the `cobol.nvim` Winbar

Both show hierarchy, but in different places (one stays in the Winbar, while the other is a dropdown opened on demand). **In COBOL, use the `cobol.nvim` breadcrumb.**

### `show_path` / `show_file` Are Disabled

They are set to `false`, so the menu won't show the path or filename. Change the configuration if you want to see them.

### Icons Appear as Boxes

`show_icons = true` requires an icon font. If your terminal font doesn't support it, icons appear as boxes.

### How It Relates to navic

`use_navic = true` uses LSP breadcrumb data provided by navic. If navic isn't installed, this option has no effect (but won't cause an error).

## 6. Official Documentation

Repository: <https://github.com/iamcheyan/contextline.nvim>

## 7. Boundaries

- This tutorial describes `lua/plugins/contextline.lua`: `<leader>cb` opens the menu, and path and filename display are disabled.
- Data comes from LSP / navic / Treesitter. **COBOL has none of these**, so the menu is usually empty in COBOL.
- **For COBOL, use the `cobol.nvim` Winbar breadcrumb and Aerial outline** instead of contextline.
- This is a plugin you develop (`iamcheyan/`), so its behavior may change between versions.
