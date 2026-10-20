# Buffer Tabs: bufferline.nvim

When a dozen files are open, `:ls` shows only numbers, so it is hard to tell which buffer is active or has unsaved changes.

bufferline turns buffers into a tab bar at the top of the window: the active buffer is highlighted, modified buffers get a dot, and file types get icons.

---

## 1. What Problem It Solves

| Need | Without a tab bar | With bufferline |
|---|---|---|
| See which files are open | `:ls` + guess the number | See them all in one row at the top |
| Know which one is active | Rely on the Winbar or memory | The active tab is highlighted |
| Know which one has unsaved changes | Look for `+` in `:ls` | A dot appears on the tab |
| Switch | `:b3` | Click a tab or use `<leader>bb` |

## 2. Your Configuration

`lua/plugins/bufferline.lua`:

| Option | Value | Meaning |
|---|---|---|
| `mode` | `buffers` | Show buffers (not tabs) |
| `diagnostics` | `false` | Do not show LSP diagnostic icons |
| `color_icons` | `false` | Icons inherit the tab text color instead of using file type colors |
| `show_tab_indicators` | `false` | Do not show tab numbers |
| `show_buffer_close_icons` | `true` | Each tab has a close button |
| `separator_style` | `""` | Seamless, compact layout |
| `buffer_padding` | `1` | Leave one space on each side of a tab |

### Working with Sidebars

```lua
offsets = {
  { filetype = "neo-tree", text = "", padding = 1 },
  { filetype = "aerial", text = "", padding = 1 },
  { filetype = "snacks_layout_box" },
}
```

When Neo-tree or Aerial is open, the tab bar **leaves room for its width** instead of covering it. `padding = 1` aligns the first tab with the editor's winbar.

### Conditional Enablement

```lua
enabled = vim.env.WDIFF_NVIM ~= "1"
```

It is not loaded when `WDIFF_NVIM=1` (for a specific diff workflow). This variable is usually unset, so bufferline is enabled by default.

## 3. Keybindings

Buffer operations are in the `<leader>b` group (which-key dynamically lists the current buffers):

| Key | Action |
|---|---|
| `<leader>bb` | Switch to the previous buffer (alternate) |
| `<leader>bd` | Delete the current buffer |
| `<leader>bo` | Delete all other buffers |
| `<leader>bi` | Delete hidden buffers |
| `<leader>bD` | Delete the buffer and close its window |
| `<leader>bl` / `<leader>bn` | Next buffer |
| `<leader>bh` / `<leader>bp` | Previous buffer |

**`<leader>bb` is the most useful** for switching back and forth between two files.

### Mouse

| Action | Effect |
|---|---|
| Left-click a tab | Switch to it |
| Click the close icon | Close that buffer |
| Click `+` at the end of the tab bar | Create a file |
| Click the list icon | Open the buffer list (snacks picker) |

## 4. What the Tab Bar Shows

| Marker | Meaning |
|---|---|
| Highlighted background | Current buffer |
| Dot on the left | Unsaved changes |
| File icon | Based on file type |
| Close button | Clickable with the mouse |

**Diagnostic icons are disabled** (`diagnostics = false`), so LSP errors do not appear on tabs. See gitsigns and inline marks for those.

## 5. Exercises

### Exercise 1: Observe the Tab Bar

```sh
cd ~/development/cobol
nvim
```

1. `:e lessons/17_fixed-length-files/lesson.cob`
2. `:vsplit lessons/20_file-matching/lesson.cob`
3. Observe the tab bar at the top

**Check**: You can see two tabs, and the active one is highlighted.

### Exercise 2: Observe the Modified Marker

1. Change one character in the current file without saving.
2. Observe that tab.

**Check**: A dot appears on the tab to mark unsaved changes. The dot disappears after `:w`.

### Exercise 3: Switch Buffers

1. `<leader>bb`

**Check**: You can switch back and forth between the two buffers.

### Exercise 4: Delete the Other Buffers

1. Open three files.
2. `<leader>bo`

**Check**: Only the current buffer remains; the others are deleted.

### Exercise 5: Make Room for a Sidebar

1. Press `<leader>fe` to open Neo-tree.
2. Check whether the tab bar leaves room on the left.

**Check**: The tab bar starts to the right of Neo-tree without overlapping it.

## 6. Troubleshooting

### The Tab Bar Does Not Appear

`enabled = vim.env.WDIFF_NVIM ~= "1"`. Check the environment variable:

```vim
:echo $WDIFF_NVIM
```

If it is non-empty, its value will be `1`, and bufferline will not load.

### Too Many Tabs Are Cramped into One Row

The tab bar has limited width. Use `<leader>bo` to remove unused buffers, or use `<leader>fb` (snacks) to switch buffers.

### Clicking `+` Does Nothing

Creating a file uses `config.file_actions.new_file()`, while the close icon is native. If nothing happens, check that you did not click another element by mistake.

### The Colors Do Not Match the Theme

Highlights are generated together by `config.ui_highlights.bufferline_highlights()`. They change with the theme.

### Diagnostics Are Not Visible

They are disabled in the configuration (`diagnostics = false`). Use inline marks or `<leader>xq` to view diagnostics.

## 7. Official Documentation

```vim
:h bufferline
:h bufferline-configuration
```

Repository: <https://github.com/akinsho/bufferline.nvim>

## 8. Scope

- This page describes `lua/plugins/bufferline.lua`: `mode = "buffers"`, diagnostics disabled, `color_icons = false`, and seamless separators.
- It is not loaded when `WDIFF_NVIM=1`.
- The `<leader>b*` keybindings are provided by snacks' bufdelete, not by bufferline itself.
- The tab bar shows **buffers**, not tabs (tabs opened with `:tabnew` do not appear here).
