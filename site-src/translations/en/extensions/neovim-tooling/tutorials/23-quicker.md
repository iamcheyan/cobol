# Enhanced Quickfix: quicker.nvim

A quickfix list opened with `:copen` shows only a one-line summary by default—**you cannot see the context, so you cannot tell whether this is the match you want**.

quicker.nvim adds “expand context” to quickfix: press `>` to show the 2 lines before and after the match, and `<` to collapse them.

---

## 1. What Problem It Solves

| Need | Native quickfix | quicker |
|---|---|---|
| See the context around a match | Jump there, then jump back | Expand in place with `>` |
| Decide whether this is the match you need | Jump back and forth | See the surrounding lines at a glance |
| Edit results | Can only jump to them | Can edit them in place |

## 2. Your Configuration

`lua/plugins/quicker.lua`:

```lua
{
  "stevearc/quicker.nvim",
  ft = "qf",
  opts = {
    keys = {
      {
        ">",
        function()
          require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
        end,
        desc = "Expand quickfix context",
      },
      {
        "<",
        function() require("quicker").collapse() end,
        desc = "Collapse quickfix context",
      },
    },
  },
}
```

| Option | Value | Meaning |
|---|---|---|
| `before` | 2 | Show 2 lines **before** the match when expanded |
| `after` | 2 | Show 2 lines **after** the match |
| `add_to_existing` | `true` | Pressing `>` again adds to the existing context (expand more lines each time) |

`ft = "qf"` means it is loaded only in quickfix buffers.

## 3. Keybindings

| Key | Action |
|---|---|
| `>` | Expand context (2 lines before + 2 lines after) |
| `<` | Collapse |
| `<Tab>` | Expand and jump to the next result |
| `<S-Tab>` | Expand and jump to the previous result |
| `q` | Close quickfix |

You can press `>` repeatedly; each time it expands more context (`add_to_existing = true`).

## 4. Complete Workflow

### From Search to Quickfix

```text
1. <leader>fg            搜内容
2. 输入搜索词
3. <C-q                 结果全部送进 quickfix
4. :copen               打开列表
5. >                    展开当前项上下文
6. j / k                在结果间移动
7. Enter                跳到源码位置
```

### From Diagnostics to Quickfix

```text
1. <leader>xq           诊断送进 quickfix
2. :copen
3. >                    展开看错误上下文
```

## 5. COBOL Scenarios

### Scenario 1: Check Whether a Reference Is the One You Want to Change

Use `<leader>fw` to search for `WS-RECORD-COUNT`; there are 30 matches. The question is: **which are declarations, and which are uses?**

1. Send them to quickfix with `<C-q>`
2. `:copen`
3. Expand the first result with `>` → see the lines around `01 WS-RECORD-COUNT PIC 9(2).`

**The expanded view makes it obvious that this is in the WORKING-STORAGE declaration area, not a use.** This is much faster than jumping there with `Enter` and then jumping back.

### Scenario 2: Review the Impact of a Batch Replacement

After grug-far changes 8 files, check whether each change is appropriate:

1. `<leader>fg` to search for the new pattern
2. `<C-q`
3. `:copen`
4. Expand each result with `>` and review it

### Scenario 3: View Context for Compiler Diagnostics

COBOL reports that a period is missing on a line:

1. `<leader>xq`
2. `:copen`
3. Expand with `>` → see the previous statement and the following lines

**You often need context to locate a COBOL period error**—the problem is not apparent from a single line.

### Scenario 4: Find the Same Kind of Problem Across Lessons

Search for `PIC 9(2)` to find every two-digit counter. Expanded results show which might overflow (Lesson 17 discussed that `WS-RECORD-COUNT` can only hold `00`–`99`).

## 6. Exercises

### Exercise 1: Basic Expansion

```sh
cd ~/development/cobol
nvim
```

1. `<leader>fg` → search for `WS-RECORD-COUNT`
2. `<C-q>` to send results to quickfix
3. `:copen`
4. Press `>`

**Check**: Two context lines appear above and two below the current match, with line numbers.

### Exercise 2: Expand Further

1. From the previous step, press `>` again

**Check**: The context expands to 4 lines (`add_to_existing = true`).

### Exercise 3: Collapse

1. Press `<`

**Check**: The display returns to one line per result.

### Exercise 4: Move Between Results and Expand

1. Use `j` to move to the next result
2. Press `>`
3. Press `j` again, then `>`

**Check**: Each result can be expanded independently, and previously expanded results stay expanded.

### Exercise 5: Jump

1. Press `Enter` on a result

**Check**: You jump to the corresponding source location. Use `:copen` to return.

### Exercise 6: Diagnostics Scenario

1. Open a COBOL file and delete a period
2. Save with `:w` to trigger diagnostics
3. `<leader>xq`
4. `:copen` + `>`

**Check**: You can see the context around the error line. Restore the period with `u`.

## 7. Common Pitfalls

### `>` Does Nothing

It only works inside a **quickfix buffer** (`ft = "qf"`). Confirm that the current window is quickfix:

```vim
:echo &filetype
```

It should output `qf`.

### The Expanded View Does Not Show the Whole Function

`before = 2, after = 2` is a fixed number of lines. If that is not enough context, press `>` more times to expand further.

### `>` and `<` Conflict with Other Plugins

In regular buffers, these keys mean **indent / unindent**. quicker's mappings apply only in quickfix buffers, so there is no conflict.

### The Quickfix List Is Empty

If `:copen` opens an empty list, nothing has been sent to it. First use `<C-q>` (snacks) or `<leader>xq` (diagnostics).

### The List Does Not Update After Editing

Quickfix entries are a snapshot. After a file is edited, `:copen` still shows the old line numbers. Search again.

### Expanding a Large List Is Slow

Expansion inserts virtual lines for every entry. Hundreds of entries may cause a slowdown. Collapse with `<` first, then expand results one by one.

## 8. How It Relates to Other Plugins

| What you want to do | Use |
|---|---|
| Search content and see results | `<leader>fg` (snacks) |
| View results with context | `<C-q>` + `quicker` |
| Move between results | `:cnext` / `:cprev` or `j` / `k` |
| View diagnostics | `<leader>xq` + `quicker` |
| Review changes after editing | `<leader>gd` (diffview) |

**quicker enhances the quickfix display**; it does not produce results. Results come from search or diagnostics.

## 9. Official Documentation

```vim
:h quicker
```

Repository: <https://github.com/stevearc/quicker.nvim>

## 10. Scope

- The keybindings in this tutorial come from `lua/plugins/quicker.lua`: `>` and `<`, with `before = 2`, `after = 2`, and `add_to_existing = true`.
- `>` and `<` have these meanings only in buffers with the `qf` filetype; in regular buffers, they still indent and unindent.
- quicker does not create quickfix contents; first use `<C-q>` (snacks) or `<leader>xq` (diagnostics).
- Quickfix is a snapshot: after files change, line numbers become invalid, so search again.
