# Scrollbar Markers: satellite.nvim

Neovim's native scrollbar is just a thin line, so it does not show where changes, errors, or search results are located in a file.

satellite draws a **minimap** along the scrollbar, marking the cursor, search results, diagnostics, and Git changes.

---

## 1. What Problem It Solves

| What you want to know | Native scrollbar | satellite |
|---|---|---|
| Where changes are concentrated | Not visible | Git markers |
| Which line has an error | Scroll to find it | Diagnostic marker |
| How search results are distributed | Press `n` repeatedly | See every match at once |
| Where the cursor is in the file | Scrollbar position | Highlighted marker |

## 2. Your Configuration

`lua/plugins/scrollbar.lua` (the file is named scrollbar, but it installs satellite):

| Option | Value | Meaning |
|---|---|---|
| `current_only` | `false` | Show markers in all windows |
| `winblend` | `0` | Opaque |
| `zindex` | `40` | Layering order |

### Excluded File Types

```lua
excluded_filetypes = {
  "contextline_menu", "dropbar_menu", "dropbar_menu_fzf",
  "DressingInput", "cmp_docs", "cmp_menu", "blink-cmp-menu",
  "noice", "prompt", "TelescopePrompt",
  "neo-tree", "aerial", "help", "lazy", "mason",
}
```

Interfaces such as Neo-tree, Aerial, help, lazy, and mason **do not show markers**, to avoid clutter.

### Four Types of Markers

```lua
handlers = {
  cursor = { enable = true, overlap = true, priority = 100 },
  search = { enable = true },
  diagnostic = { enable = true },
  gitsigns = { enable = true },
}
```

| Marker | Source | Meaning |
|---|---|---|
| `cursor` | Cursor position | Highest priority (100), drawn over other markers |
| `search` | Search results | Every match position |
| `diagnostic` | LSP / `cobc` | Errors and warnings |
| `gitsigns` | Git diff | Changes, additions, and deletions |

`overlap = true` allows markers to overlap; `priority = 100` keeps the cursor marker on top.

## 3. How to Read It

Markers appear on the **right side of the window**, along the scrollbar:

```text
内容行 1                    │
内容行 2                    ▎  ← Git 改动
内容行 3                    │
  ...                       ▪  ← 错误
内容行 40                   ┃  ← 光标
```

Without scrolling, you can tell that this file has three changes and an error near line 5.

## 4. COBOL Use Cases

### Scenario 1: Review the Scope After a Batch Edit

After editing several places with multiple cursors or grug-far:

1. Look at the Git markers on the right.
2. Dense areas show where changes are concentrated.
3. There is no need to jump through changes one by one with `:Gitsigns`.

### Scenario 2: Find Syntax Errors

After `cobc` reports diagnostics:

1. Look for diagnostic markers on the right.
2. Scroll directly to the marked position.

**COBOL compiler errors often cluster around a few lines**; the markers reveal the area immediately.

### Scenario 3: See How Search Results Are Distributed

After searching for `WS-RECORD-COUNT` with `<leader>fg`, the picker shows results. If you search with `/` instead:

1. Look for search markers on the right.
2. See at a glance where all 30 matches are located.

### Scenario 4: Locate the Cursor in a Long File

In a program hundreds of lines long, like the one in Lesson 32:

1. See where the cursor marker is on the minimap.
2. Tell which part of the file you are in.

## 5. Exercises

### Exercise 1: Observe Git Markers

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. Change a few lines without saving.
2. Look at the right side.

**Check**: Git markers appear at the positions of the changed lines.

### Exercise 2: Observe Diagnostic Markers

1. Deliberately remove a period.
2. Run `:w` to trigger diagnostics.
3. Look at the right side.

**Check**: A diagnostic marker appears. It disappears after you undo with `u`.

### Exercise 3: Search Markers

1. Search for `/WS-RECORD-COUNT`.
2. Look at the right side.

**Check**: Every match position has a marker.

### Exercise 4: Cursor Marker

1. Jump to line 100 in a long file.
2. Observe the cursor marker's position.

**Check**: The marker indicates roughly where you are in the file.

### Exercise 5: Confirm Exclusions

1. Press `<leader>fe` to open Neo-tree.
2. Look at the right side of the Neo-tree window.

**Check**: There are **no** satellite markers because its file type is in `excluded_filetypes`.

## 6. Troubleshooting

### Markers Do Not Appear

Check whether the current file type is excluded:

```vim
:echo &filetype
```

Compare it with the `excluded_filetypes` list. `help`, `mason`, `lazy`, `neo-tree`, and `aerial` are all excluded.

### Marker Colors Do Not Match the Theme

Marker colors come from the corresponding highlight groups (`DiagnosticError`, `GitSignsAdd`, and so on). They change with the theme.

### Disable a Marker Type

Set the corresponding `enable` value to `false` in `handlers`. For example, to hide search markers:

```lua
search = { enable = false },
```

### Conflict with Another Scrollbar Plugin

This configuration uses satellite and disables snacks' scroll feature (see the snacks tutorial). Do not enable both at once.

### Markers Are Not Visible in a Narrow Window

A very narrow window can squeeze out the scrollbar. Widen the window or accept that markers may not appear.

### What `current_only = false` Means

Markers appear in every window, not just the current one. Set it to `true` to show them only in the current window.

## 7. How It Works with Other Plugins

| Marker content | Data source |
|---|---|
| Git changes | gitsigns |
| Diagnostics | LSP or `cobc` (through `cobol.nvim`) |
| Search results | vim's `/` search |
| Cursor | satellite itself |

**satellite does not produce data**; it only draws data from other plugins on the scrollbar. Change marker behavior in the configuration of the plugin that provides the data.

## 8. Official Documentation

```vim
:h satellite
:h satellite-configuration
```

Repository: <https://github.com/lewis6991/satellite.nvim>

## 9. Scope

- This page describes `lua/plugins/scrollbar.lua` (the file is named scrollbar, but it installs satellite).
- The four marker types are `cursor`, `search`, `diagnostic`, and `gitsigns`.
- Fifteen file types are excluded (Neo-tree, Aerial, help, mason, lazy, and others **do not show** markers).
- satellite does not produce data; it only displays data from other plugins.
- snacks' scroll feature is disabled; satellite provides the scroll markers.
