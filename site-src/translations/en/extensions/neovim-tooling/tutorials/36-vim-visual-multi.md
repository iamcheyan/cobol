# Another Multicursor Option: vim-visual-multi

Your configuration has **two multicursor plugins**: `multicursor.nvim` (Tutorial 08) and `vim-visual-multi`.

This tutorial covers the latter and **the special customization in your configuration**—understanding it is key to knowing how the two plugins divide their work.

---

## 1. Why There Are Two

| Plugin | Role |
|---|---|
| `multicursor.nvim` | Modern implementation; works with Treesitter, and `gaip` adds cursors line by line |
| `vim-visual-multi` | Long-established plugin; `Ctrl-n` adds a cursor by selecting a word, with a more "traditional" feature set |

Both are in `lazy-lock.json`. `multicursor-line.nvim` lists `vim-visual-multi` as a dependency:

```lua
dependencies = { "mg979/vim-visual-multi" },
```

So it isn't redundant: the line-start and line-end cursor features in `multicursor-line` are built on top of it.

## 2. What Your Configuration Does

`lua/plugins/vim-visual-multi.lua` doesn't simply load the plugin; it **redefines the behavior of `Ctrl-n`**.

### Core Logic

```lua
local last_linewise_mode = nil

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    last_linewise_mode = nil
  end,
})
```

Leaving Insert mode clears the remembered mode.

```lua
local function insert_ctrl_n()
  local vm = vim.g.Vm
  local vm_active = type(vm) == "table" and (tonumber(vm.buffer) or 0) > 0
  local extending = vm_active and tonumber(vm.extend_mode) == 1

  local cur_col = vim.fn.col(".")
  local end_col = vim.fn.col("$")
  local at_line_end = (cur_col >= end_col) or (cur_col == end_col - 1 and cur_col > 1)
  local at_line_start = (cur_col <= 1)
  ...
```

### The Three Things It Checks

| Variable | Meaning |
|---|---|
| `vm_active` | Whether vim-visual-multi already has an active selection |
| `at_line_end` | Whether the cursor is at the end of the line |
| `at_line_start` | Whether the cursor is at the start of the line |

### End-of-Line Mode (`eol`)

When the cursor is at the end of a line, pressing `Ctrl-n` runs:

```lua
if is_eol_mode then
  last_linewise_mode = "eol"
  vim.cmd("stopinsert")
  vim.cmd("normal! $")
  vim.fn["vm#commands#add_cursor_at_pos"](08-multicursor-batch-editing.md)
  vim.cmd("normal! j$")
  vim.fn["vm#commands#add_cursor_at_pos"](08-multicursor-batch-editing.md)
  vim.cmd("call b:VM_Selection.Insert.key('A')")
end
```

In effect:

1. Add a cursor at the end of the current line.
2. Add another at the end of the next line.
3. Enter Insert mode with `A` (append at end of line).

**Typical use**: append the same content to the ends of consecutive lines.

### Beginning-of-Line Mode (`bol`)

When the cursor is at the start of a line, pressing `Ctrl-n` enters beginning-of-line mode:

```lua
if is_bol_mode then
  last_linewise_mode = "bol"
  ...
  vim.cmd("call b:VM_Selection.Insert.key('A')")
end
```

The behavior is similar, but at the start of the line (the behavior of `I`).

**Note**: The `bol` branch also uses `Insert.key('A')` in the code. Check the actual behavior in your setup; it might be a typo, or it might be intentional (`A` appends at the end of a line).

### Normal Mode (Away from the Line Start and End)

The plugin's default `Ctrl-n` behavior applies: select the word under the cursor, then press it again to select the next matching word.

## 3. How It Divides Work with multicursor.nvim

| Scenario | Plugin to use |
|---|---|
| Add cursors by word or selection | `multicursor.nvim` (`<leader>n`) |
| Add cursors line by line (each line in a paragraph) | `multicursor.nvim` (`gaip`) |
| **Append repeatedly at line ends** | `vim-visual-multi` (`Ctrl-n` at line end) |
| Batch insertion at line starts | `vim-visual-multi` (`Ctrl-n` at line start) |
| Add cursors by line with `multicursor-line` | `multicursor-line` (`<leader>mh` and others) |

The `<leader>mh`/`mt`/`ma` and similar keys from `multicursor-line.nvim` implement "add cursors by line" using `vim-visual-multi`, which is more convenient than adding them manually with `Ctrl-n`.

## 4. Basic Usage (Native vim-visual-multi)

Even without your customizations, it has a full set of features:

| Key | Action |
|---|---|
| `Ctrl-n` | Select the word under the cursor (press again to select the next one) |
| `Ctrl-Down` / `Ctrl-Up` | Add a cursor vertically |
| `Ctrl-x` | Skip the current match |
| `Ctrl-p` | Remove the current cursor |
| `Tab` | Switch between "cursor mode" and "extend mode" |
| `\\a` | Select all matches |
| `q` | Exit multicursor mode |

In Visual mode, `Ctrl-n` adds a cursor based on the selection.

## 5. COBOL Scenarios

### Scenario 1: Add the Same Suffix to Several Line Ends

```cobol
01 WS-FLAG-A PIC X(1) VALUE "A".
01 WS-FLAG-B PIC X(1) VALUE "B".
01 WS-FLAG-C PIC X(1) VALUE "C".
```

To append ` - DONE` to all of them:

1. Put the cursor at the end of the first line.
2. Press `Ctrl-n` (enter end-of-line mode and add two cursors).
3. Type ` - DONE`.
4. Press `Esc`.

**Check**: The content was added to the ends of several lines.

**This is faster than `gaip` + `A` with multicursor**, because you don't have to select the lines first.

### Scenario 2: Add a Comment at the Start of Consecutive Lines

Put the cursor at the start of a line and press `Ctrl-n` to enter beginning-of-line mode, then type `*` (the COBOL comment marker).

**Note**: This turns the whole batch of lines into comments. COBOL comments must be in column 7, so confirm the actual insertion position for beginning-of-line mode.

### Scenario 3: Change an Identifier in Several Places

Put the cursor on `WS-ACCT`, press `Ctrl-n` to select it, press `Ctrl-n` again to add the next match, then press `c` to change it.

This overlaps with the `<leader>n` feature in `multicursor.nvim`; choose whichever feels more comfortable.

## 6. Exercises

### Exercise 1: Append at Line Ends

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. Find several consecutive lines, such as a few `01` declarations.
2. Move the cursor to the **end** of the first line.
3. Press `Ctrl-n`.
4. Type some content.
5. Press `Esc`.

**Check**: The content was added to the ends of multiple lines.

### Exercise 2: Beginning-of-Line Mode

1. Move the cursor to the **start** of a line.
2. Press `Ctrl-n`.
3. Type some content.
4. Press `Esc`.

**Check**: The content was added to the starts of multiple lines.

### Exercise 3: Select Matching Words

1. Put the cursor on a word beginning with `WS-`.
2. Press `Ctrl-n` (away from the start or end of the line).
3. Press `Ctrl-n` again to add the next match.

**Check**: Multiple matching words are selected.

### Exercise 4: Compare with multicursor

1. Do the same thing with `<leader>n` from `multicursor.nvim`.
2. Compare how each feels.

**Check**: You can describe the difference (`<leader>n` feels more "modern", while the `Ctrl-n` line-end mode is more direct).

### Exercise 5: Exit

1. While in multicursor mode, press `q` or `Esc`.

**Check**: You are back to a single cursor.

## 7. Troubleshooting

### `Ctrl-n` Does Nothing in Insert Mode

Your custom function checks `vm_active`. If the vim-visual-multi state is abnormal, it might not trigger. Check with `:echo g:Vm`.

### End-of-Line Mode Adds Only One Cursor

The code checks `at_line_end`. If the cursor isn't at the true end of the line (for example, trailing spaces follow it), end-of-line mode won't start. Move to the line end with `$` first.

### Conflict with the Completion Menu

`Ctrl-n` is normally used for the next completion item. blink.cmp may claim it in Insert mode. **Test to see which mapping takes effect in your setup.**

### The Two Multicursor Plugins Conflict

When `multicursor.nvim` and `vim-visual-multi` are both present, some keys may conflict. We recommend **giving them clear roles**: use `<leader>n` for word matches and `Ctrl-n` at line ends.

### `last_linewise_mode` Is Left Behind

Leaving Insert mode clears it (the `InsertLeave` autocommand does this automatically). If behavior is abnormal, `:lua last_linewise_mode = nil` won't work because it's a local variable—just enter Insert mode again.

## 8. Official Documentation

Repository: <https://github.com/mg979/vim-visual-multi>

```vim
:h vim-visual-multi
```

## 9. Boundaries

- This tutorial describes the configuration in `lua/plugins/vim-visual-multi.lua`. It **redefines `Ctrl-n`**: there are special modes at the start and end of a line, while other positions use the native behavior.
- It is a dependency of `multicursor-line.nvim`, not a redundant plugin.
- Its features overlap with `multicursor.nvim`; giving each a clear role helps avoid confusion.
- In Insert mode, `Ctrl-n` may conflict with blink.cmp completion shortcuts. Test to see which mapping takes effect in your setup.
