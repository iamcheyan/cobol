# Cross-File Search and Replace: grug-far.nvim

A field name appears in 8 files across 30 places. `:%s` handles one file. `argdo` needs a file list first. **grug-far puts "what to search, what to replace, how wide" into one interface: look first, then write.**

---

## 1. What Problem It Solves

| Habit | Problem |
|---|---|
| `:%s/old/new/g` | Current file only |
| `:argdo %s/.../g \| update` | Must build the file list; you discover a bad search only afterwards |
| Editing file by file | By place 20 you forget which ones you already changed |
| External `sed -i` | Outside the editor; hard to undo |

grug-far's approach: **show every match (with line numbers and context) first, then replace once you are sure.** The preview can be reviewed match by match.

## 2. Your Actual Configuration

Defined in `lua/plugins/grug-far.lua`:

```lua
{
  "MagicDuck/grug-far.nvim",
  opts = { headerMaxWidth = 80 },
  cmd = { "GrugFar", "GrugFarWithin" },
  keys = {
    {
      "<leader>sr",
      function()
        local grug = require("grug-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        grug.open({
          transient = true,
          prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil,
          },
        })
      end,
      mode = { "n", "x" },
      desc = "Search and Replace",
    },
  },
}
```

### Three entry points

| Entry | Action |
|---|---|
| `<leader>sr` | Open and **pre-fill the Files Filter with the current file extension** |
| `:GrugFar` | Open with no pre-filled filter |
| `:GrugFarWithin` | Replace only inside the visual selection |

**The automatic pre-fill matters:** pressing `<leader>sr` while editing a `.cob` file sets Files Filter to `*.cob`, so you will not accidentally rewrite matching text in `README.md`.

In `x` (visual) mode, `<leader>sr` carries the selection.

### Key options

`transient = true` closes the window after a replace instead of staying open.

`headerMaxWidth = 80` caps the header width.

## 3. The Interface

After `<leader>sr`:

```text
┌─────────────────────────────────────────────────────────┐
│ Help g?   Replace \r   Sync All \s ...                  │
├──────────────────────────┬──────────────────────────────┤
│  Search:                 │  ← the search pattern        │
│    e.g. foo              │                              │
│  Replace:                │  ← the replacement           │
│    e.g. bar              │                              │
│  Files Filter:           │  ← e.g. *.cob                │
│  Flags:                  │  ← --ignore-case etc.        │
│  Paths:                  │  ← restrict to a directory   │
├──────────────────────────┴──────────────────────────────┤
│  ⟪ ripgrep ⟫                                            │
│  4 matches in 2 files                                   │
│    f.cob                                                │
│      5   01 WS-ALPHA PIC X(10) VALUE "AAAAAAAAAA".  [1] │
│      9       DISPLAY WS-ALPHA                       [2] │
│    g.cob                                                │
└─────────────────────────────────────────────────────────┘
```

**Input fields and results live in one buffer.** Move between fields with `j` / `k` and press `i` to edit a field.

### Field reference

| Field | Purpose | Examples |
|---|---|---|
| Search | Pattern (regex supported) | `WS-ALPHA`, `foo([a-z0-9]*)` |
| Replace | Replacement (capture groups supported) | `WS-FIRST`, `${1}_foo` |
| Files Filter | Restrict file types or paths | `*.cob`, `*.{cob,cpy}`, `**/docs/*.md` |
| Flags | Passed to ripgrep | `--ignore-case`, `-i` |
| Paths | Restrict search directories | `./lessons/`, `../` |

### Common flags

| Flag | Effect |
|---|---|
| `-i` | Ignore case |
| `-.` | Include hidden files |
| `--no-ignore` | Ignore `.gitignore` |
| `--multiline` | Match across lines |

## 4. Three Ways to Apply

This is where grug-far differs most from plain `:%s`: **replacing is not all-or-nothing.**

| Key | Action | When |
|---|---|---|
| `\r` | **Replace**: perform it | Confirmed, replace everything |
| `\s` | **Sync All**: write the result-area text back to the files | After hand-editing results |
| `\l` | **Sync Line**: sync just this result | Confirm one at a time |
| `\n` | **Sync Next**: sync this one and move to the next | Review as you go |
| `\p` | **Sync Prev**: sync and move back | Reverse direction |
| `\v` | **Sync File**: sync all results in this file | File-by-file |
| `g?` | Open the help window | When you forget a key |

Note that `\` is `localleader` (your config sets `vim.g.maplocalleader = "\\"`).

### `\r` versus `\s`

- **`\r` (Replace)** applies everything and supports multiline replacements.
- **`\s` (Sync All)** writes back **the text currently shown in the result area**.

If you delete some result lines by hand, `\s` only syncs what remains — that is how you exclude specific matches.

## 5. Measured Observations

Pressing `<leader>sr` on a COBOL file and searching `WS-ALPHA`:

```text
4 matches in 2 files

   f.cob
     5        01 WS-ALPHA PIC X(10) VALUE "AAAAAAAAAA". [1]
     9            DISPLAY WS-ALPHA                      [2]

   g.cob
```

What to notice:

1. **Search happens as you type**; no Enter required.
2. It shows **`N matches in M files`** — read this number first to confirm the scope.
3. Each result has **file name + line number + context**, with `[1]` `[2]` numbering matches within that file.
4. The opened `<leader>sr` had Files Filter pre-filled as `*.cob` (because I was editing a `.cob` file).

**That `matches in N files` line is the key safety check.** If the file count is larger than expected, tighten the filter before replacing.

## 6. Four COBOL Scenarios

### Scenario 1: Rename across lessons

`WS-ACCT-` appears in all 32 lessons and should become `WS-ACCOUNT-`:

```text
Search:        WS-ACCT-
Replace:       WS-ACCOUNT-
Files Filter:  *.cob
```

**Check the match count first.** To limit to one lesson, put `./lessons/17_fixed-length-files/` in Paths.

### Scenario 2: Change a copybook declaration and all references

Both `.CPY` and `.cob` need updating:

```text
Files Filter: *.{cob,cpy}
```

Files Filter accepts glob braces.

### Scenario 3: Change every `VALUE "A"` to `VALUE "P"`

```text
Search:        VALUE "A"
Replace:       VALUE "P"
Files Filter:  *.cob
```

**Careful:** this also rewrites `VALUE "A"` inside comments. The search box supports regex, so match code lines only:

```text
Search:        ^(?!      \*).*VALUE "A"
```

Or simpler: replace, then check `git diff` for accidental comment edits (see below).

### Scenario 4: Change only the selected lines

1. Select lines with `V`
2. Press `<leader>sr` (in visual mode)
3. Search and replace apply only to the selection

Good for "rename `WS-X` in this block, nowhere else".

## 7. Using Git as a Safety Net

grug-far edits fast, and breaks fast. **Make sure the working tree is clean before replacing, and look at the diff immediately after.**

```sh
cd ~/development/cobol
git status --short          # expect one file changed
git diff                    # read exactly what changed
```

If you broke something:

```sh
git checkout -- path/to/file    # revert one file
git restore .                   # revert everything uncommitted
```

Your config also has `<leader>gd` (diffview) for side-by-side inspection.

## 8. Exercises

### Exercise 1: Observe without executing

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. `<leader>sr`
2. Set Search to `WS-RECORD-COUNT`
3. **Only observe** `N matches in M files`; do not replace
4. `<Esc>` to close

**Accept:** you can state the match count and number of files. This step modifies nothing.

### Exercise 2: See what Files Filter does

1. `<leader>sr` with Search `FILE STATUS`
2. Check whether Files Filter is `*.cob`
3. Clear Files Filter and watch the match count change

**Accept:** clearing the filter increases the count (it now finds `FILE STATUS` inside `.md` docs). **That is why you should not casually clear it.**

### Exercise 3: A real replace (on a copy)

```sh
cd /tmp && cp -r ~/development/cobol/lessons/17_fixed-length-files /tmp/grugtest
cd /tmp/grugtest && nvim lesson.cob
```

1. `<leader>sr`
2. Search: `WS-RECORD-COUNT`
3. Replace: `WS-WRITE-COUNT`
4. Confirm `matches in 1 files`
5. Press `\r`
6. `:wq`
7. `cobc -fsyntax-only lesson.cob`

**Accept:** it still compiles. If not, the replace touched something it should not have.

### Exercise 4: Confirm one at a time

1. On the copy, search a word that appears 3 times
2. Fill in a replacement
3. Use `\n` repeatedly, watching where the cursor moves
4. Finish with `\s` for the rest

**Accept:** you can distinguish `\n` (one at a time) from `\s` (everything).

### Exercise 5: Work only in the result area

1. Search and get 5 matches
2. **Manually delete 2 lines** in the result area
3. Press `\s`

**Accept:** only the remaining 3 lines are written back. That is how you exclude matches.

## 9. Pitfalls

### `\r` does nothing

`\` is `localleader`. Confirm it is `vim.g.maplocalleader = "\\"` (a single backslash). Check with `:lua print(vim.g.maplocalleader)`.

### It replaced things you did not want

The three usual causes:

1. **No Files Filter** — searched every file.
2. **Did not read the match count** — pressed `\r` immediately.
3. **Pattern too loose** — `WS-ACCT` also matches inside `WS-ACCT-OLD`.

**Countermeasure:** always read `N matches in M files` first. Wrong number means a wrong filter.

### It changed comments

Patterns like `VALUE "A"` also appear in comments. Check with `git diff`, or anchor the pattern:

```text
Search:        ^(?!      \*).*VALUE "A"
```

(`^(?!      \*)` excludes comment lines whose column 7 is `*`.)

### The files are mangled after `\s`

`\s` writes back **the current result-area text**. If you accidentally edited the result area, those edits are written too. Undo with `u`, or restore with `git checkout`.

### Multiline replace does not work

ripgrep does not cross lines by default. Add this to Flags:

```text
--multiline
```

## 10. How It Relates to Other Plugins

| Need | Tool |
|---|---|
| Find only, no change | `<leader>fg` (snacks picker) |
| Change a few spots in one file | `:%s/old/new/g` |
| **Batch change across files** | `<leader>sr` (grug-far) |
| Change several lines in one file at once | Multi-cursor ([tutorial 08](08-multicursor-batch-editing.md)) |
| See what changed | `<leader>gd` (diffview), `git diff` |

**How to choose:** one spot uses a normal command; several adjacent lines in one file uses multi-cursor; the same pattern across files uses grug-far.

## 11. Official Documentation

```vim
:h grug-far
:h grug-far-config
```

Repository: <https://github.com/MagicDuck/grug-far.nvim>

Open the built-in help (with the full key table):

```text
<leader>sr then press g?
```

## 12. Limits

- Keys here come from your local config (`lua/plugins/grug-far.lua`): `<leader>sr`, `:GrugFar`, `:GrugFarWithin`.
- `<leader>sr` pre-fills the current file extension into Files Filter; that is a convenience added by your config, not a plugin default.
- The interface keys (`\r`, `\s`, `\l`, `\n`, `\p`, `\v`, `g?`) come from the plugin's default keymap table and were verified here.
- Measurements cover only "open, live search, show match count and positions". **Practise the actual replace on a copy first** (Exercise 3), since you may be operating on production course files.
- Make sure the working tree is clean before replacing, and run `git diff` immediately after.
