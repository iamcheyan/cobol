# Line-Level Git Operations: gitsigns.nvim

Opening `git diff` to review the entire file after editing is a blunt approach. **What you want to know is “are the three lines I just added correct?”, not the entire history of changes to the file.**

gitsigns shows Git changes at the line level: the sign column marks added, changed, and deleted lines, and you can stage or reset an individual **hunk** (a contiguous block of changes) directly.

---

## 1. What Problem It Solves

| Need | Without gitsigns | With gitsigns |
|---|---|---|
| See whether this line changed | Run `git diff` | See a marker in the sign column |
| Commit only some changes | Use interactive `git add -p` | Put the cursor on a hunk and press a key |
| Undo a block of changes | Delete it manually | Reset with `<leader>gr` |
| See who wrote this line | Run `git blame` on the whole file | Show only the current line with `<leader>gb` |
| Preview a block of changes | Switch windows | Open a floating window with `<leader>gp` |

## 2. Your Configuration

`lua/plugins/gitsigns.lua`, `version = "v2.1.0"`, `event = "LazyFile"`.

### Signs

```lua
signs = {
  add = { text = "▎" },
  change = { text = "▎" },
  delete = { text = "" },
  topdelete = { text = "" },
  changedelete = { text = "▎" },
  untracked = { text = "▎" },
},
```

A vertical bar `▎` appears in the sign column. Deletions use an `` arrow. Colors distinguish the types (as determined by the highlight group).

`signs_staged` uses the same configuration; staged changes have their own colors.

## 3. All Keybindings

### Navigation

| Key | Action |
|---|---|
| `]h` | Next hunk |
| `[h` | Previous hunk |
| `]H` | Last hunk |
| `[H` | First hunk |

### Staging (`<leader>gh` family)

| Key | Action (in `n` / `x` mode) |
|---|---|
| `<leader>ghs` | Stage the current hunk |
| `<leader>ghr` | Reset the current hunk (discard changes) |
| `<leader>ghS` | Stage the entire buffer |
| `<leader>ghR` | Reset the entire buffer |
| `<leader>ghu` | Undo the last stage operation |
| `<leader>ghp` | Preview the current hunk inline |
| `<leader>ghb` | Show blame for the current line |
| `<leader>ghB` | Show blame for the entire buffer |
| `<leader>ghd` | Diff against the index |
| `<leader>ghD` | Diff against HEAD (`~`) |

### Shortcuts (`<leader>g` family)

A configuration comment says these are LazyVim-style shortcuts, **without the `h`**:

| Key | Action |
|---|---|
| `<leader>gs` | Stage the current hunk |
| `<leader>gr` | Reset the current hunk |
| `<leader>gS` | Stage the entire buffer |
| `<leader>gR` | Reset the entire buffer |
| `<leader>gu` | Undo staging |
| `<leader>gp` | Preview the current hunk |
| `<leader>gb` | Blame the current line |
| `<leader>gB` | Blame the entire buffer |
| `<leader>gy` | Copy the current hunk (in `n` / `v` mode) |

### Select a Hunk as a Text Object

| Key | Action |
|---|---|
| `ih` | **Text object**: select the current hunk (in `o` / `x` mode) |

`ih` is useful: `dih` deletes the entire hunk, `yih` copies it, and `vih` selects it. It can be combined with other operators.

### Toggle Sign Display

| Key | Action |
|---|---|
| `<leader>uG` | Toggle Git signs |


![The `┃` markers on the left are gitsigns hunks — one near line 5, another near line 16.](images/19-gitsigns-hunks.png)

The `┃` markers on the left are gitsigns hunks — one near line 5, another near line 16.

## 4. Typical Workflows

### Workflow 1: Commit Only Some Changes

You made three changes and want to commit only two of them:

1. Press `]h` to jump to the first hunk.
2. Press `<leader>gs` to stage it.
3. Press `]h` to jump to the second hunk.
4. Press `<leader>gs` to stage it.
5. Press `<leader>gr` to reset the third hunk (the one you do not want).
6. Run `:!git commit -m "..."`.

**This is the visual equivalent of `git add -p`**, without answering y/n in the terminal.

### Workflow 2: Undo a Block of Changes You Got Wrong

1. Move the cursor to the part you got wrong.
2. Press `<leader>gp` to preview and confirm the hunk.
3. Press `<leader>gr` to reset it.

**`<leader>gr` is destructive** (except that you can use `u` to undo it), so always preview before resetting.

### Workflow 3: See Who Wrote This Line

1. Put the cursor on the suspicious line.
2. Press `<leader>gb`.
3. A floating window shows the commit, author, date, and commit message.

This is very useful when investigating “when and by whom was this strange condition added?”

### Workflow 4: Copy a Hunk to Share

1. Use `vih` or `yih` to select or copy the entire hunk.
2. Paste it into a chat window.

No need to select the range manually.

## 5. COBOL Scenarios

### Scenario 1: Review Each Hunk After a Batch Field Change

You used grug-far to change 8 files. Return to one of them:

1. Press `]h` to visit each hunk.
2. Preview each one with `<leader>gp`.
3. Once everything looks right, commit them together.

**This is more reliable than scrolling through `git diff`**—you are less likely to miss a change.

### Scenario 2: Undo a Failed Replacement

A `\r` replacement in grug-far went wrong:

1. Press `]h` to find the incorrect hunk.
2. Press `<leader>gr` to reset it.

**Note**: Only **unstaged** changes can be reset this way. Use `git revert` for changes that have already been committed.

### Scenario 3: Make Sure You Did Not Break Column Positions

After editing COBOL:

1. Press `]h` to inspect each hunk.
2. Check whether the changes affected the indentation at the start of the line.

COBOL is column-sensitive, and the inline `<leader>gp` preview makes it easy to spot broken indentation.

### Scenario 4: Find Where a Bug Was Introduced

A field is being processed incorrectly:

1. Move the cursor to the line with the problem.
2. Press `<leader>gb` to see its blame.
3. Find the commit that introduced the change.

## 6. Exercises

### Exercise 1: Observe the Signs

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. Change a few characters on any line.
2. Observe the sign that appears in the sign column.
3. Press `u` to undo; the sign disappears.

**Acceptance criteria**: The changed line gets a `▎` marker, which disappears after undoing the change.

### Exercise 2: Preview a Hunk

1. Make a change.
2. Press `<leader>gp`.

**Acceptance criteria**: A floating window shows the diff for this change (`-` for the old line, `+` for the new line).

### Exercise 3: Reset One Hunk

1. Make two changes far apart.
2. Press `]h` to jump to the first one.
3. Press `<leader>gr` to reset it.
4. Check that the second change is still there.

**Acceptance criteria**: Only the first change is undone; the second remains.

### Exercise 4: The `ih` Text Object

1. Make a change.
2. Type `vih`.
3. Inspect the selected range.

**Acceptance criteria**: The selection covers exactly the changed lines in this hunk.

### Exercise 5: Blame

1. Put the cursor on a line from an earlier commit.
2. Press `<leader>gb`.

**Acceptance criteria**: The floating window shows the commit hash, author, and time.

### Exercise 6: Partial Staging (Important)

**⚠️ Do this in a copy of the repository, not in this repository.**

1. Make two changes.
2. Press `<leader>gs` to stage the first change.
3. Run `:!git diff --cached` to confirm that only the first change is staged.
4. Run `:!git reset` to undo staging.

**Acceptance criteria**: You can distinguish staged changes from unstaged changes.

## 7. Pitfalls

### There Are No Signs in the Sign Column

Possible causes:

1. The file is not in a Git repository.
2. The changes have been committed (there is no uncommitted diff).
3. `<leader>uG` turned the signs off.

Check with:

```vim
:Gitsigns toggle_signs
```

### You Cannot Recover a Change After `<leader>gr` Resets It

`<leader>gr` **discards changes** and is protected only by Vim's undo history. You can undo it with `u`, but only until you exit Neovim.

**Preview with `<leader>gp` before resetting with `<leader>gr`.**

### Confusing `<leader>gs` with `<leader>gS`

`gs` = stage the **hunk** (the current block); `gS` = stage the **buffer** (the whole file). Lowercase means local; uppercase means everything.

### The Blame Details Are Too Brief

`<leader>gb` uses `blame_line({ full = true })`, which is already the most detailed single-line version. Use `<leader>gB` to see blame for the whole file.

### The Sign Colors Do Not Match the Theme

The sign itself is fixed by the configuration (`▎`); colors come from highlight groups such as `GitSignsAdd`. The colors change with the theme.

## 8. Official Documentation

```vim
:h gitsigns
:h gitsigns-usage
```

Repository: <https://github.com/lewis6991/gitsigns.nvim>

## 9. Boundaries

- The keybindings in this tutorial come from `lua/plugins/gitsigns.lua`: both `<leader>gh*` and `<leader>g*` families (the latter are shortcuts) are available.
- `version = "v2.1.0"` pins the version; behavior is based on that release.
- **`<leader>gr` / `<leader>gR` discard changes** and are protected only by Vim's undo history. Always preview with `<leader>gp` before resetting.
- Staging only changes the Git index; it **does not commit automatically**. You still need `git commit`.
