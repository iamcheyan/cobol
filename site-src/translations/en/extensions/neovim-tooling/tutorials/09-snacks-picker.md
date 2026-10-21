# File and Content Search: snacks.nvim picker

You are in a 32-lesson repository hunting for a field name, a copybook, or a `PERFORM` paragraph. **Search speed decides how fast you can read code.**

The `snacks.nvim` picker is the main entry point in the current configuration: find files, grep content, switch buffers, browse help — all through one interface. Learn it first; the other plugins build on it.

This page reflects your local configuration, not a generic tutorial.

---

## 1. What Problem It Solves

Three inefficient habits without a picker:

| Habit | Problem |
|---|---|
| `:e path/to/file` | You must memorise paths; deep trees make that impossible |
| `:vimgrep /pattern/ **/*` | Blocks the editor; results pile into quickfix |
| Clicking through Neo-tree | Shows directory structure, not content |

The picker approach: **type a few characters, filter live, see a preview on the right**. You know "is this the one?" without leaving the window.

## 2. Your Actual Keymaps

Defined in `lua/config/keymaps-defaults.lua`. `<leader>` is **space**.

### Finding files

| Key | Action | When to use |
|---|---|---|
| `<leader><space>` | Find files (project root) | The one to memorise |
| `<leader>ff` | Find files (current cwd) | Working inside a subdirectory |
| `<leader>fF` | Find files (Git root) | Deep in a subdirectory but searching the whole repo |

**The only difference is where the search starts.** `<leader>fF` walks up to `.git` first, so from `lessons/17_xxx/` you can still reach files under `extensions/`.

### Searching content (grep)

| Key | Action |
|---|---|
| `<leader>fg` | Grep the whole repo |
| `<leader>fG` | Same implementation in this config |
| `<leader>/` | Same, another entry point |
| `<leader>fw` | **Grep the word under the cursor** (cwd) |
| `<leader>fW` | Grep the word under the cursor (root) |
| `<leader>fc` | Grep the word under the cursor |

`<leader>fw` is the lazy option: put the cursor on `WS-RECORD-COUNT`, press it, and skip the typing.

### Buffers and the rest

| Key | Action |
|---|---|
| `<leader>fb` or `<leader>,` | Switch open buffers |
| `<leader>fr` | Recently opened files |
| `<leader>fR` | **Resume the last picker** (results intact) |
| `<leader>fh` or `<leader>?` | Search help |
| `<leader>fS` | Treesitter symbols in the current file |

`<leader>fR` is easy to overlook but very useful: you searched halfway, went off to edit something, and pressing it brings back the same query and results.


![Grepping for `WS-ACCT`: hits with file:line:column on the left, live preview on the right.](images/09-snacks-picker.png)

Grepping for `WS-ACCT`: hits with file:line:column on the left, live preview on the right.

## 3. Working Inside the Picker

Once open you face three areas:

```text
┌──────────────────────────────────────────────┐
│  Input (typing filters immediately)          │
├────────────────────────┬─────────────────────┤
│  Result list           │  Preview (follows)  │
│  ↑↓ to select          │  Syntax highlighted │
└────────────────────────┴─────────────────────┘
```

### Moving and opening

| Key | Action |
|---|---|
| Keep typing | Live filter, results update immediately |
| `<C-n>` / `<C-p>` or `↑` `↓` | Move the selection |
| `<CR>` | Open (replaces the current window) |
| `<C-s>` | Open in a horizontal split |
| `<C-v>` | Open in a vertical split |
| `<C-t>` | Open in a new tab |
| `<Esc>` | Close |

### Adjusting the view

| Key | Action |
|---|---|
| `<a-p>` | Toggle the preview pane |
| `<a-m>` | Maximise / restore |
| `<a-w>` | Cycle focus between input and results |
| `/` | Toggle focus |
| `<a-h>` | Toggle hidden files |
| `<a-i>` | Toggle gitignored files |
| `<a-r>` | Toggle regex mode |
| `<a-f>` | Toggle follow mode |
| `<C-d>` / `<C-u>` | Page the result list |
| `<C-f>` / `<C-b>` | Page the preview |
| `<a-d>` | Inspect the current item's internal data (debugging) |

### Sending results elsewhere

| Key | Action |
|---|---|
| `<C-q>` | Send all results to the quickfix list |
| `<Tab>` | Select the current item and move to the next (multi-select) |
| `<S-Tab>` | Select and move back |
| `<c-a>` | Select all |

`<C-q>` deserves its own practice: once grep results are in quickfix you can walk them with `:cnext` / `:cprev`, and combine with `quicker.nvim` to expand context.

## 4. Measured Observations

The following come from real sessions in this repository, not inference.

### Finding files

Press `<leader>ff` and type `account-master`:

```text
lessons/17_fixed-length-files/account-master-200.dat
extensions/…/labs/03-one-to-many/starter/BATCHL2.COB
extensions/…/labs/04-many-to-many/starter/BATCHL3.COB
…
```

The input area showed `2624/2624` (matches/total). Pressing `<CR>` opened the file, and **the position-ruler column guide appeared immediately**:

```text
1...+...10....+...20....+...30....+...40....+...50....+...60....+...70....+...80
0001234567C0001042TANAKA ICHIRO                 BR-TOKYO2020011520261014ORDINARY
```

This is where two plugins cooperate: the picker finds the file, position-ruler shows the fixed-length field positions.

### Searching content

Press `<leader>fg` and type `WS-RECORD-COUNT`:

```text
WS-RECORD-COUNT                        30/30

lessons/17_fixed-length-files/lesson.cob:42:10
lessons/17_fixed-length-files/lesson.cob:85:24
lessons/17_fixed-length-files/lesson.cob:106:48
lessons/17_fixed-length-files/README.md:119:27  计数字段宽度
lessons/…/lesson.cob:21:10        01 WS-RECORD-COUNT P
lessons/…/INPUTCSV.COB:50:15            05  WS-RECO
```

**30 hits across 3+ files**, each with `file:line:column`. The preview on the right shows the surrounding context without opening anything.

### Switching buffers

Press `<leader>fb`:

```text
2/2
10  #a  account-master-200.dat:1:33
1    h  lesson.cob:1:6
```

Shows the buffer number, a modification marker (`#` = modified), and line:column. The numeric prefix is the buffer number `<C-^` jumps to.

## 5. Five High-Frequency COBOL Uses

### Use 1: Find every reference to a field

Put the cursor on `WS-ACCOUNT-STATUS` and press `<leader>fw`.

Every reference appears immediately. Do this **before** changing a field — know how many places are affected, then decide whether to use multi-cursor (see [the multi-cursor tutorial](08-multicursor-batch-editing.md)).

### Use 2: Compare implementations across lessons

To compare fixed-length handling in lesson 17 and lesson 32:

```text
<leader>ff → type fixed-length → select
```

Or grep: `<leader>fg` → `RECORD CONTAINS 27` shows every related lesson at once.

### Use 3: Find a copybook declaration

Search `01  ACCOUNT-REC` or `PIC X(10)` to locate the declaration inside a `.CPY`.

With `<leader>fF` (Git root search), you can find copybooks under `extensions/enterprise-batch/` even from a deep experiment directory.

### Use 4: Check whether a key is taken

Press `<leader>fh` to search help, or `<leader>?`.

To see what a key is bound to, use `:verbose nmap <leader>fw`; it shows the final mapping and the file that defined it.

### Use 5: Send results to quickfix

After grepping 30 `WS-RECORD-COUNT` hits, press `<C-q>`:

```vim
:cnext    " next hit
:cprev    " previous hit
:copen    " open the quickfix window
```

More focused than bouncing around inside the picker.

## 6. Exercises

### Exercise 1: Find and open a fixture

```sh
cd ~/development/cobol
nvim
```

1. `<leader>ff`
2. Type `account-master`
3. Press `<CR>`

**Accept:** it opens `lessons/17_fixed-length-files/account-master-200.dat` and a column guide like `1...+...10` appears at the top of the window.

### Exercise 2: grep the word under the cursor

In the same file (switch to `lesson.cob` if you opened the `.dat`), put the cursor on any `WS-` word:

1. `<leader>fw`
2. Note the number of results

**Accept:** the input is pre-filled with that word and the list shows every reference.

**Contrast:** run `<leader>fg` and type the same word by hand — results are identical; `<leader>fw` only saves typing.

### Exercise 3: quickfix round trip

1. `<leader>fg` → `FILE STATUS`
2. Press `<C-q>` to send results to quickfix
3. `:copen`
4. `:cnext` three times

**Accept:** the quickfix window exists and each `:cnext` lands on a new `FILE STATUS` location.

### Exercise 4: Resume a search

1. `<leader>fg` → search for a word
2. `<Esc>` to close
3. Edit something
4. `<leader>fR`

**Accept:** the picker reopens with the same query and results.

### Exercise 5: Multi-select to quickfix

1. `<leader>fg` → `PIC X(`
2. Use `<Tab>` to select the first 3 entries
3. `<C-q>` sends only the selected ones

**Accept:** quickfix contains only your 3 selections, not everything.

## 7. Pitfalls

### `<leader>ff` cannot find the file you want

Three possibilities:

1. **Gitignored**: press `<a-i>`.
2. **Hidden** (starts with `.`): press `<a-h>`.
3. **Outside the cwd**: use `<leader>fF` (Git root).

### grep finds nothing

`<leader>fg` uses ripgrep and respects `.gitignore` by default. Searching generated files under `build/site/` also needs `<a-i>`.

### Cursor stays in the picker after `<Esc>`

In this config `<Esc>` closes the picker. If you pressed `<C-c>` (cancel in insert mode) you drop back to the input instead — press `<Esc>` once more.

### The first search in a big repo is slow

ripgrep builds its cache on the first scan; repeat searches are much faster. For 500+ files, a few hundred milliseconds is normal.

## 8. How It Relates to Other Plugins

| Goal | Tool |
|---|---|
| Find a **file** | `<leader>ff` (snacks) |
| Find **content** | `<leader>fg` (snacks) |
| Jump to a **character you can see** | `s` (flash, see [the flash tutorial](10-flash-jump.md)) |
| **Batch replace across files** | `<leader>sr` (grug-far, see [the grug-far tutorial](11-grug-far.md)) |
| Read **directory structure** | `<leader>fe` (Neo-tree) |

**The key distinction:** snacks finds a position by text, flash finds a position by eye. Use the former when you know what you are looking for, the latter when you can see it but cannot be bothered counting lines.

## 9. Official Documentation

```vim
:h snacks-picker
:h snacks-picker-config
```

Repository: <https://github.com/folke/snacks.nvim>

List your current keys:

```vim
:map <leader>f
```

## 10. Limits

- Keys here come from your local config (`lua/config/keymaps-defaults.lua`), not plugin defaults. Re-check with `:map <leader>f` after config changes.
- `<leader>fg` and `<leader>fG` point to the same implementation in this config; there is no practical difference.
- Measurements come from real Neovim sessions; layout ratios (`width = 0.85`) make the preview pane wider or narrower depending on terminal width.
