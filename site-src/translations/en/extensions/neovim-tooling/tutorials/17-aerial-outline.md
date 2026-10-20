# Code Outline: aerial.nvim

COBOL programs can easily run to hundreds of lines and contain dozens of paragraphs. **To edit `2200-POST-TRANSACTION`, you first have to find it.** Should you scroll, search, or use an outline?

Aerial lists the entire structure tree in an outline sidebar: DIVISION → SECTION → PARAGRAPH. Click an item to jump to it.

---

## 1. What Problem It Solves

| Need | Without an outline | With Aerial |
|---|---|---|
| Find a paragraph | Search for `PERFORM`, then trace back to the definition | See all paragraph names directly in the sidebar |
| Understand file structure | Scroll through the file | See the hierarchy at a glance |
| Navigate | `:line number` or search | Move the cursor and press Enter |
| Know which level the cursor is on | Check the Winbar breadcrumb | The current item is highlighted automatically in the sidebar |

## 2. Your Configuration

`lua/plugins/aerial.lua`:

```lua
layout = {
  default_direction = "left",
  placement = "window",
  width = 32,
  min_width = 32,
  max_width = 32,
  resize_to_content = false,
  win_opts = {
    foldcolumn = "1",
    statuscolumn = " ",
  },
},
show_guides = true,
manage_folds = true,
link_tree_to_folds = true,
link_tree_to_window = true,
```

### Key Settings

| Setting | Value | Meaning |
|---|---|---|
| `default_direction` | `left` | Open on the left |
| `width` | 32 | Fixed width of 32 columns |
| `resize_to_content` | `false` | Do not expand to fit the content |
| `show_guides` | `true` | Show hierarchy guide lines |
| `link_tree_to_folds` | `true` | Synchronize folding with the outline |
| `link_tree_to_window` | `true` | Keep the highlight in sync with cursor movement |

### Backend Configuration (Important)

```lua
backends = {
  ["_"] = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
  cobol = { "cobol" },
  cbl = { "cobol" },
  cob = { "cobol" },
  dosbatch = { "batch" },
  batch = { "batch" },
  sh = { "treesitter", "lsp" },
},
```

**COBOL uses the dedicated backend provided by `cobol.nvim`**, not Treesitter. This matters: COBOL has no Treesitter parser, but Aerial still works because `cobol.nvim` parses the structure itself.

## 3. Opening and Using It

### Toggle

| Key / Command | Action |
|---|---|
| `<leader>cs` | Toggle the outline sidebar |
| `:AerialToggle` | Same |
| `:AerialOpen` | Open |
| `:AerialInfo` | Show which backend the current buffer uses |

### Actions in the Sidebar

| Key | Action |
|---|---|
| `Enter` | Jump to the selected item |
| `j` / `k` | Move up/down |
| `o` / `zo` | Expand a node |
| `c` / `zc` | Collapse a node |
| `>` | Switch to the next symbol group |
| `<` | Switch to the previous symbol group |
| `?` | Show sidebar help |
| `q` | Close |

In your configuration, `<` and `>` are rebound to “cycle symbol groups” (`sidebar_tabs.cycle`), so you can switch between symbols from multiple files.

## 4. What the COBOL Outline Shows

The `cobol.nvim` backend parses three levels:

```text
▾ IDENTIFICATION DIVISION
▾ DATA DIVISION
  ▾ WORKING-STORAGE SECTION
      01 WS-ACCOUNT-TABLE
      01 WS-BATCH-COUNTS
▾ PROCEDURE DIVISION
  ▾ 0000-MAIN
  ▾ 1000-READ-AND-WRITE
  ▾ 1100-WRITE-BALANCE-RECORD
  ▾ 9000-CLOSE-FILES
```

**Paragraph names (such as `0000-MAIN`) are the most useful part**—COBOL organizes its control flow around paragraphs and `PERFORM`, so the outline reveals the program's overall skeleton directly.

### Working with the Winbar Breadcrumb

The Winbar from `cobol.nvim` shows `[ PROCEDURE DIVISION > 2000-PROCESS-SECTION > 2100-PROCESS-RECORD ]`, while the Aerial sidebar displays the global structure.

One shows your current location; the other shows the overall structure. `link_tree_to_window = true` automatically highlights the paragraph under the cursor in the sidebar.

## 5. Exercises

### Exercise 1: Open the Outline and Inspect the Structure

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/lesson.cob
```

1. Press `<leader>cs`.
2. Inspect the structure tree on the left.

**Acceptance criteria**: You can see the three levels DIVISION → SECTION → PARAGRAPH, including paragraph names.

### Exercise 2: Jump to a Paragraph

1. Move to a paragraph name in the outline (for example, `1000-READ-AND-WRITE`).
2. Press `Enter`.

**Acceptance criteria**: The cursor jumps to that paragraph's location in the source.

### Exercise 3: Follow the Cursor

1. With the outline open, scroll down through the source.
2. Watch the sidebar highlight.

**Acceptance criteria**: The sidebar highlight follows the paragraph under the cursor (`link_tree_to_window = true`).

### Exercise 4: Synchronized Folding

1. In the source, press `zM` to fold everything.
2. Inspect the outline.

**Acceptance criteria**: Expanding and collapsing items in the outline tracks folds in the source (`link_tree_to_folds = true`).

### Exercise 5: Confirm the Backend

1. Run `:AerialInfo`.
2. Check the backends line.

**Acceptance criteria**: The COBOL buffer shows that it uses the `cobol` backend, not `treesitter`.

### Exercise 6: Compare with a Language That Has an LSP

1. Open a `.lua` file.
2. Press `<leader>cs`.
3. Run `:AerialInfo`.

**Acceptance criteria**: The Lua file uses the `treesitter`/`lsp` backend. The comparison shows how COBOL is handled specially.

## 6. Pitfalls

### The COBOL Outline Is Empty

Check:

```vim
:AerialInfo
```

If the backend shows `cobol` but the list is empty, `cobol.nvim` did not get any content from its structure parser. Confirm that `cobol.nvim` is loaded:

```vim
:lua =require("cobol")
```

### `<leader>cs` Opens Something Other Than Aerial

In your configuration, `<leader>cs` calls `config.sidebar_tabs.toggle_symbols()`, a custom toggle that supports multiple tabs. It should behave like `:AerialToggle`; if anything seems wrong, use the command directly to troubleshoot.

### The Sidebar Width Cannot Be Changed

The configuration fixes `width = 32`, `min_width = 32`, `max_width = 32`, and `resize_to_content = false`. To change the width, edit the configuration; dragging will not work.

### It Conflicts with Neo-tree for Space

Both sidebars are on the left (`default_direction = "left"`). Opening them at the same time makes them compete for space. Use `<` / `>` in `sidebar_tabs` to switch between them.

### The Outline Disappears After Session Restoration

The `auto-session` configuration handles this specifically (`config/sidebar_session.lua`). If the outline is missing after restoration, run `:AerialToggle` to reopen it.

## 7. How It Fits with Other Plugins

| What you want to know | Use |
|---|---|
| The file's structural skeleton | Aerial (`<leader>cs`) |
| Which paragraph the cursor is in | Winbar breadcrumb (shown automatically) |
| The directory structure | Neo-tree (`<leader>fe`) |
| Where a name is defined | `gd` (`cobol.nvim`) |
| Where a name is used | `<leader>fw` (snacks grep) |

**Aerial is a structural view, not a search tool.** Grep is faster for finding a specific name.

## 8. Official Documentation

```vim
:h aerial
:h aerial-usage
```

Repository: <https://github.com/stevearc/aerial.nvim>

The COBOL backend comes from `cobol.nvim`: <https://github.com/iamcheyan/cobol.nvim>

## 9. Boundaries

- This tutorial's configuration comes from `lua/plugins/aerial.lua`: the width is fixed at 32 columns, the direction is fixed to the left, and `<` / `>` are rebound to cycle symbol groups.
- **COBOL uses the dedicated backend provided by `cobol.nvim`** and does not depend on Treesitter. This is why COBOL can have an outline while `S` node navigation is unavailable (see [the Treesitter tutorial](16-treesitter-and-folding.md)).
- Aerial is an **optional dependency**: the other `cobol.nvim` features work as usual without it.
- `auto-session`'s `sidebar_session` module saves and restores the sidebar during session restoration; Aerial does not handle that itself.
