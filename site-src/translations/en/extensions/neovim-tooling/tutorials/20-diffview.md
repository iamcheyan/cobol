# Full Diffs and History: diffview.nvim

gitsigns answers “Did this line change?” diffview answers “**What changed in this commit as a whole?**” and “**How has this file changed over time?**”

It presents diffs side by side (old on the left, new on the right), with a file tree and per-file navigation.

---

## 1. What Problem It Solves

| Need | Without diffview | With diffview |
|---|---|---|
| Review changes in an entire commit | `git show` crammed into the terminal | Side-by-side view + file tree |
| Review files one by one | Scroll through a long diff | Select files in the tree |
| View a file's history | `git log -p file` | Sidebar lists all revisions |
| Three-way merge | Manual process | Built-in three-way view |


![`DiffviewOpen` in action: file panel on the left, old side in the middle, new side on the right, changed lines highlighted.](images/20-diffview.png)

`DiffviewOpen` in action: file panel on the left, old side in the middle, new side on the right, changed lines highlighted.

## 2. Your Configuration

`lua/plugins/diffview.lua`:

```lua
opts = {
  enhanced_diff_hl = true,
  view = {
    default = {
      layout = "diff2_horizontal",
    },
  },
  hooks = {
    diff_buf_read = function(bufnr)
      vim.opt_local.swapfile = false
    end,
    diff_buf_win_enter = function(bufnr, winid, ctx)
      vim.opt_local.swapfile = false
    end,
  },
}
```

| Option | Value | Meaning |
|---|---|---|
| `enhanced_diff_hl` | `true` | More precise, word-level diff highlighting |
| `layout` | `diff2_horizontal` | Side-by-side, split left and right |
| `swapfile` | `false` | Do not write a swap file (diff buffers are read-only views) |

## 3. Keybindings

| Key | Command | Action |
|---|---|---|
| `<leader>gd` | `:DiffviewOpen` | Open the current workspace diff |
| `<leader>gv` | `:DiffviewOpen` | Same as above (alias) |
| `<leader>gD` | `:DiffviewFileHistory %` | History of the **current file** |
| `<leader>gV` | `:DiffviewFileHistory` | History of the entire branch |
| `<leader>gq` | `:DiffviewClose` | Close |

### Common Commands (No Keybinding)

| Command | Action |
|---|---|
| `:DiffviewOpen HEAD~3` | Compare with three commits ago |
| `:DiffviewOpen main...feature` | Compare two branches |
| `:DiffviewOpen <commit>` | Compare with a commit |
| `:DiffviewToggleFiles` | Toggle the file panel |
| `:DiffviewFocusFiles` | Move focus to the file panel |
| `:DiffviewRefresh` | Refresh |

## 4. Interface Layout

After opening `:DiffviewOpen`:

```text
┌────────────────┬──────────────────────────────────────────┐
│ 文件树          │  差异视图（并排）                         │
│                │                                          │
│ M lessons/...  │  旧版本            │  新版本              │
│ M extensions/  │  ────────────────  │  ────────────────    │
│                │  - 旧行            │  + 新行              │
└────────────────┴──────────────────────────────────────────┘
```

### Keys Within the View

| Key | Action |
|---|---|
| `<Tab>` | Switch focus between the file tree and diff |
| `]c` / `[c` | Next / previous change hunk |
| `do` | Get from the other side (get from other) |
| `dp` | Put to the other side (put to other) |
| `g?` | Show help |
| `q` | Close |

`do` / `dp` are useful when resolving conflicts: apply the contents from one side to the other.

## 5. COBOL Scenarios

### Scenario 1: Review a Batch Replacement

After using grug-far to edit 8 files:

1. `<leader>gd`
2. Select each file in the tree
3. Use `]c` to move through the change hunks in each file

**Why this is better than scrolling through `git diff`**: The file tree shows at a glance which files changed, so none are missed.

### Scenario 2: See How a Field Name Evolved

```text
<leader>gD    当前文件的历史
```

The sidebar lists all commits involving this file. Select one to see what changed each time.

Use this to investigate questions like “When did `WS-RECORD-COUNT` change from `PIC 9(2)` to `PIC 9(3)`?”

### Scenario 3: Compare Two Branches

```vim
:DiffviewOpen main...feature
```

See what the feature branch changed relative to the main line. Useful for reviewing a PR.

### Scenario 4: Review Course Changes

```sh
cd ~/development/cobol
git log --oneline -3
```

```
ea537fc docs(tutorial): add search, jump and batch-replace guides
1e44647 docs(tutorial): add multicursor batch-editing guide with exercises
19a6f36 docs(lesson-17): verify fixed-length offsets with a column ruler
```

```vim
:DiffviewOpen 1e44647~1
```

Review all the changes in that commit.

## 6. Exercises

### Exercise 1: Open the Workspace Diff

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. Change a line
2. `<leader>gd`

**Check**: A side-by-side diff opens, with the HEAD version on the left and the current version (including your change) on the right.

### Exercise 2: Move Between Change Hunks in a Diff

1. Press `]c` in the diff view
2. Observe the cursor move to the next change

**Check**: The cursor moves between change hunks.

### Exercise 3: View File History

1. `<leader>gD` (current file)
2. Observe the commit list on the left
3. Select a commit

**Check**: You can see the file's diff at that commit.

### Exercise 4: View All Changes in a Commit

```vim
:DiffviewOpen 19a6f36~1
```

**Check**: All changes from that commit are displayed.

### Exercise 5: Close

1. `<leader>gq`

**Check**: diffview closes and you return to normal editing.

### Exercise 6: Navigate the File Tree

1. `<leader>gd`
2. Press `<Tab>` to move to the file tree
3. Use `j` / `k` to move, then `Enter` to open a file

**Check**: You can switch between diffs for multiple files.

## 7. Common Pitfalls

### `<leader>gd` and `gd` Are Different

- `gd` (without leader) = go to definition (`cobol.nvim` or LSP)
- `<leader>gd` = open diffview

**One character makes a completely different command.** A typo may open an unexpected window.

### The View Is Blank After Opening

There are no uncommitted changes in the current workspace. Use `:DiffviewOpen HEAD~1` or `<leader>gD` to view history.

### You Cannot Edit in the Diff

diffview buffers are **read-only views**. Return to the original file to edit the code.

### Pressing `do` / `dp` Has No Effect

They are useful only when **resolving conflicts** (in a `diff3` layout). They have no effect in a regular diff view.

### The Window Layout Changed After Closing

diffview rearranges windows. After `<leader>gq`, you may need `<C-w>=` to equalize them again.

### Opening a Large Repository Is Slow

`:DiffviewOpen` needs to calculate the full diff. It is normal to wait a few seconds when there are many changes.

## 8. How It Fits with gitsigns

| What you want to know | Use |
|---|---|
| Whether this line changed | gitsigns sign in the left gutter |
| What this change does | `<leader>gp` (gitsigns preview) |
| Stage only this hunk | `<leader>gs` (gitsigns) |
| **What changed in the entire commit** | `<leader>gd` (diffview) |
| **The history of this file** | `<leader>gD` (diffview) |
| Who wrote this line | `<leader>gb` (gitsigns blame) |

**Use gitsigns for line-level work, and diffview for files and history.**

## 9. Official Documentation

```vim
:h diffview
:h diffview-configuration
```

Repository: <https://github.com/sindrets/diffview.nvim>

## 10. Scope

- The keybindings in this tutorial come from `lua/plugins/diffview.lua`: `<leader>gd`, `<leader>gv`, `<leader>gD`, `<leader>gV`, and `<leader>gq`.
- The layout is fixed to `diff2_horizontal` (side by side). To use a top-and-bottom layout, change the configuration.
- Diff buffers are read-only, and `swapfile = false` is an intentional setting (to avoid writing swap files for read-only views).
- With no arguments, `:DiffviewOpen` compares the **workspace with the index**. To view history, provide a revision explicitly or use `<leader>gD`.
