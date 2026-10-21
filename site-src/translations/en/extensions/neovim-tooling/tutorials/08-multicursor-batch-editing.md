# Multi-Cursor Batch Editing with multicursor.nvim

Renaming COBOL fields, unifying `PIC` clauses, or swapping status codes line by line is slow and easy to get wrong. `multicursor.nvim` puts a cursor on every position you need so a single edit applies to all of them.

This page uses the **official configuration**: no customisation, no patched keymaps. Every key and action below comes from the plugin author's recommended setup.

---

## 1. Why COBOL Needs This

COBOL data declarations are repetitive by nature:

```cobol
       01  WS-ACCT-ID          PIC X(10).
       01  WS-ACCT-NAME        PIC X(20).
       01  WS-ACCT-BAL         PIC 9(7)V99.
       01  WS-ACCT-STATUS      PIC X(1).
```

Four fields, four nearly identical lines. When you need to:

- rename the `WS-ACCT-*` prefix to `WS-ACCOUNT-*` (4 declarations plus 3 references);
- widen every `PIC X(...)` to `PIC X(100)`;
- change `VALUE "A"` to `VALUE "P"` on three records;
- fill six placeholder lines with sequence numbers 001–006;

the single-cursor approach is "change one, `n` to the next, change again". The multi-cursor approach is "place cursors everywhere, change once".

**The difference is not speed, it is whether you miss one.** A COBOL program with one missed field usually still compiles — that one field just keeps its old width until it fails at runtime.

---

## 2. Installation and Configuration

The official recommended setup (`lazy.nvim`):

```lua
{
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- Add a cursor above/below, or skip a line
    set({"n", "x"}, "<up>", function() mc.lineAddCursor(-1) end)
    set({"n", "x"}, "<down>", function() mc.lineAddCursor(1) end)
    set({"n", "x"}, "<leader><up>", function() mc.lineSkipCursor(-1) end)
    set({"n", "x"}, "<leader><down>", function() mc.lineSkipCursor(1) end)

    -- Add a cursor on the next/previous match, or skip it
    set({"n", "x"}, "<leader>n", function() mc.matchAddCursor(1) end)
    set({"n", "x"}, "<leader>s", function() mc.matchSkipCursor(1) end)
    set({"n", "x"}, "<leader>N", function() mc.matchAddCursor(-1) end)
    set({"n", "x"}, "<leader>S", function() mc.matchSkipCursor(-1) end)

    -- Mouse: Ctrl + left click adds/removes, Ctrl + drag
    set("n", "<c-leftmouse>", mc.handleMouse)
    set("n", "<c-leftdrag>", mc.handleMouseDrag)
    set("n", "<c-leftrelease>", mc.handleMouseRelease)

    -- Temporarily disable/enable cursors
    set({"n", "x"}, "<c-q>", mc.toggleCursor)

    -- A layer that only applies while multiple cursors exist
    mc.addKeymapLayer(function(layerSet)
      layerSet({"n", "x"}, "<left>", mc.prevCursor)
      layerSet({"n", "x"}, "<right>", mc.nextCursor)
      layerSet({"n", "x"}, "<leader>x", mc.deleteCursor)
      layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    -- Cursor appearance
    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { reverse = true })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
  end
}
```

### Three extra actions used on this page

The official example config is deliberately minimal. The three below come from the "Advanced Actions" section of the official documentation and are used throughout this page:

```lua
-- After selecting lines, ga plus a motion adds one cursor per line:
-- gg vip gaip  → one cursor per line of the paragraph
set({"n", "x"}, "ga", mc.addCursorOperator)

-- Match every occurrence of the word/selection under the cursor in the file
set({"n", "x"}, "<leader>A", mc.matchAllAddCursors)

-- Treat all cursors as one sequence when incrementing
set({"n", "x"}, "g<c-a>", mc.sequenceIncrement)
set({"n", "x"}, "g<c-x>", mc.sequenceDecrement)
```

### The critical distinction: `n` versus `<leader>n`

This trips people up constantly, so state it plainly:

| Key | Effect | Use for |
|---|---|---|
| `n` | Native vim search, next match | Ordinary movement |
| `<leader>n` | **Add a cursor** at the next match | Multi-cursor |
| `<leader>s` | Skip the next match, **no cursor** | Multi-cursor |
| `<leader>A` | Add a cursor at **every** match in the file | Multi-cursor |

`<leader>A` is the lazy option: put the cursor on `WS-ACCT`, press it once, and every `WS-ACCT` in the file has a cursor.

---


![Four `01` declarations whose field names and `PIC` clauses line up in the same columns — the shape multi-cursor was made for.](images/08-multicursor-context.png)

Four `01` declarations whose field names and `PIC` clauses line up in the same columns — the shape multi-cursor was made for.

## 3. Five Actions That Cover 90% of Cases

### Action 1: One cursor per line (`ga` + motion)

The most common move. Select lines, press `ga`, then a motion.

```text
gg vip gaip
```

Meaning: go to the start, select the document, `ga` enters add-cursor mode, `ip` (a paragraph motion) gives **one cursor per line**.

You can also target a visual selection: press `V` to select lines, then `ga` (with `mc.addCursorOperator` mapped).

Measured result (first four lines of `02-unify-pic.cob`):

```text
before                          after gaip
│ 01 WS-ACCT-ID      PIC X(10). │ 01 WS-ACCT-ID      PIC X(10).
│ 01 WS-ACCT-NAME    PIC X(20). │ 01 WS-ACCT-NAME    PIC X(20).
│ 01 WS-ACCT-BAL     PIC 9(7)V99│ 01 WS-ACCT-BAL     PIC 9(7)V99
│ 01 WS-ACCT-STATUS  PIC X(1).  │ 01 WS-ACCT-STATUS  PIC X(1).
```

The `│` on the left is the cursor marker (`MultiCursorCursor`, drawn reversed).

### Action 2: Column-aligned edits (`f` + `C`)

Once cursors exist, all of them respond to **the same** vim command. This is the crucial mental model:

> **It is not "run this per cursor", it is "run this one command at every cursor".**

So each cursor must sit at a semantically equivalent position. `fP` means "find the letter P forward on this line", so each cursor jumps to its own line's `PIC`:

```text
gg gaip        " one cursor per line (all in column 1)
fP             " each jumps forward to the P of PIC on its own line
C              " change from here to end of line
PIC 9(9).      " type the replacement
<Esc>          " leave insert, cursors remain
```

Measured result:

```text
       01  WS-ACCT-ID          PIC 9(9).
       01  WS-ACCT-NAME        PIC 9(9).
       01  WS-ACCT-BAL         PIC 9(9).
       01  WS-ACCT-STATUS      PIC 9(9).
```

The four original `PIC` clauses had different lengths (`X(10)`, `X(20)`, `9(7)V99`, `X(1)`), but `C` changes **to end of line**, so it replaces everything regardless of length.

**One trap to remember:** `cw` only changes one word, so it leaves the rest. `PIC X(10).` becomes `9(9) X(10).` — a syntax error.

| Command | Range | Good for |
|---|---|---|
| `cw` | To end of word | Replacing a single identifier |
| `ciW` | Whole whitespace-delimited word | `WS-ACCT-NAME` (contains hyphens) |
| `C` | **To end of line** | Replacing "everything from here on" |
| `ci"` | Inside quotes | String literals |
| `cc` | Whole line | Rewriting a whole line |

### Action 3: Replace whole identifiers (`ciW`)

`WS-CUSTOMER-ID` and `WS-CUSTOMER-NAME` differ in length, so `cw` stops at the hyphen. To replace the whole identifier, use `ciW`:

```text
gg gaip            " one cursor per line
w                  " each jumps to the 2nd word (WS-CUSTOMER-xxx)
ciW                " select the whole whitespace-delimited word
WS-CLIENT-XX       " type the new name
<Esc>
```

Measured:

```text
before                                    after
       01 WS-CUSTOMER-ID     PIC X(8).  →  01 WS-CLIENT-XX     PIC X(8).
       01 WS-CUSTOMER-NAME   PIC X(10). →  01 WS-CLIENT-XX   PIC X(10).
       01 WS-CUSTOMER-STATUS PIC X(1).  →  01 WS-CLIENT-XX PIC X(1).
```

When `-` is not part of `iskeyword`, `ciw` only selects up to the hyphen. `ciW` uses whitespace boundaries and covers the whole run.

### Action 4: Batch-replace quoted content (`ci"`)

Changing status codes, classification values, and fixed literals is the highest-frequency job:

```text
gg gaip      " one cursor per line
f" l         " each jumps to the first quote, then one right into the content
ci"          " change everything inside the quotes
N            " type the new value
<Esc>
```

Measured (exercise `03-split-selection.cob`):

```text
before                            after ci" + N
01 WS-FLAG-A PIC X(1) VALUE "A".  →  ... VALUE "N".
01 WS-FLAG-B PIC X(1) VALUE "B".  →  ... VALUE "N".
01 WS-FLAG-C PIC X(1) VALUE "C".  →  ... VALUE "N".
01 WS-FLAG-D PIC X(1) VALUE "D".  →  ... VALUE "N".
```

Four different values become the same value in one pass. **Because `ci"` is scoped to "inside the quotes", content length does not matter.**

### Action 5: Sequential numbering (`g<C-a>`)

For numbering records or generating test data:

```text
gg gaip      " one cursor per line
f" l         " into the digits inside the quotes
g<C-a>       " increment
```

Measured:

```text
before                                after g<C-a>
01 WS-LINE-01 PIC X(40) VALUE "000".  →  VALUE "001".
01 WS-LINE-02 PIC X(40) VALUE "000".  →  VALUE "002".
01 WS-LINE-03 PIC X(40) VALUE "000".  →  VALUE "003".
01 WS-LINE-04 PIC X(40) VALUE "000".  →  VALUE "004".
```

The difference from native `Ctrl-a`: `g<C-a>` (`mc.sequenceIncrement`) **treats every cursor as one continuous sequence**. Native `Ctrl-a` increments each independently, so all four become `001`; `g<C-a>` yields `001 002 003 004`.

---

## 4. Managing and Debugging Cursors

### Count the cursors

```vim
:lua require("multicursor-nvim.core").action(function(ctx) vim.print("cursors=" .. ctx:numCursors()) end)
```

### Common states

| Appearance | Meaning | Recovery |
|---|---|---|
| Marker is `│` | Cursors active | — |
| Marker is `┃` (solid) | Cursors disabled by `<c-q>`; only the main cursor moves | Press `<c-q>` or `<Esc>` |
| Markers gone | Cursors cleared | Add them again |
| Only one line changed | Other cursors were not where you expected | Re-place with `:call cursor(line,col)` and retry |

### What `<c-q>` actually does

It does not "turn off multi-cursor". It **freezes the other cursors so the main cursor can move alone**. Typical use: you added 3 cursors and the 4th landed wrong; press `<c-q>`, move the main cursor into place, press `<Esc>` to resume.

### `<Esc>` has two behaviours

In the official config `<Esc>` is:

```lua
if not mc.cursorsEnabled() then
  mc.enableCursors()   -- was disabled → resume
else
  mc.clearCursors()    -- normal state → clear all
end
```

So **one `<Esc>` clears every cursor.** Do not press it reflexively while checking your result.

---

## 5. Five Exercises

Exercise files live in [`exercises/multicursor/`](../exercises/multicursor/) in the course repository, and all pass `cobc -fsyntax-only`.

### Exercise 1: Rename a field prefix

`01-rename-field.cob` — change `WS-CUSTOMER-*` to `WS-CLIENT-*` (4 declarations plus 4 `DISPLAY` references, 8 in total).

```sh
cd extensions/neovim-tooling/exercises/multicursor
nvim 01-rename-field.cob
```

Steps: cursor on any `WS-CUSTOMER` → `<leader>A` → `ciW` → type the new name → `<Esc>`.

**Accept:** all 8 occurrences changed, and `cobc -fsyntax-only 01-rename-field.cob` still passes.

### Exercise 2: Unify PIC

`02-unify-pic.cob` — four `PIC` clauses of different lengths become `PIC 9(9).`

Steps: `gg` → `gaip` → `fP` → `C` → `PIC 9(9).` → `<Esc>`.

**Accept:** all four lines end with `PIC 9(9).`

**Trap check:** if you used `cw`, you will see broken results like `9(9) X(10).` — undo and use `C`.

### Exercise 3: Batch-change literals

`03-split-selection.cob` — four `VALUE "A"` `"B"` `"C"` `"D"` all become `"N"`.

Steps: `gg` → `gaip` → `f"` → `l` → `ci"` → `N` → `<Esc>`.

**Accept:** all four lines read `VALUE "N".`

### Exercise 4: Fill a sequence

`04-sequence-fill.cob` — six `VALUE "000"` become `"001"` through `"006"`.

Steps: `gg` → `gaip` → `f"` → `l` → `g<C-a>`.

**Accept:** 001, 002, 003, 004, 005, 006 in order.

**Contrast test:** try native `Ctrl-a` once and observe that everything becomes `001` — that is why `g<C-a>` exists.

### Exercise 5: Combined

`05-fixed-format-batch.cob` — two separate passes:

1. three `VALUE "A"` become `"P"` (use `ci"`);
2. three `PIC X(1)` become `PIC X(2)` (use `C`).

**Why two passes:** the two operations have different scopes (inside quotes versus to end of line). Mixing them in one pass makes them interfere. This is the most important multi-cursor habit — **do one thing at a time**.

---

## 6. Working With COBOL Fixed Format

COBOL has column rules, so keep these in mind:

1. **`C` (to end of line) swallows any trailing comment after column 72.** Check the line first.
2. **`cc` (whole line) destroys the column-7 indicator.** Never use `cc` on a comment line (column 7 is `*`).
3. **Watch column alignment when adding cursors.** `gaip` puts every cursor in column 1; move each with `f`/`w`, or use a block selection so cursors start aligned.
4. **Always compile afterwards.** Multi-cursor edits fast, and breaks fast:

```sh
cobc -fsyntax-only your-file.cob
```

---

## 7. Quick Reference

| Action | Keys | Notes |
|---|---|---|
| Add cursor below | `<down>` | Line by line |
| Add cursor above | `<up>` | Line by line |
| Skip a line and add | `<leader><down>` | Skips the current line |
| Add cursor at next match | `<leader>n` | Word or selection match |
| Add cursor at previous match | `<leader>N` | Reverse direction |
| Skip next match | `<leader>s` | No cursor added |
| Add cursors at all matches | `<leader>A` | Whole file at once |
| Add per motion | `ga` + motion | `gaip` = one per line |
| Switch main cursor | `<left>` / `<right>` | Only with multiple cursors |
| Delete current cursor | `<leader>x` | Only with multiple cursors |
| Freeze/resume others | `<c-q>` | Main cursor moves alone |
| Clear all cursors | `<Esc>` | In the normal state |
| Mouse add cursor | `<c-leftmouse>` | Ctrl + left click |
| Sequential numbers | `g<C-a>` / `g<C-x>` | All cursors as one sequence |

### Text-object choices

| Command | Range | COBOL use |
|---|---|---|
| `cw` | To end of word | Single word |
| `ciw` | Whole word | Identifier (when it has no `-`) |
| `ciW` | Whitespace-delimited word | `WS-ACCT-NAME` (has hyphens) |
| `C` | To end of line | A whole `PIC` clause |
| `ci"` | Inside quotes | Literals, status codes |
| `cc` | Whole line | Line rewrite (never on comment lines) |

---

## 8. Official Documentation

This page covers the common subset. For the full action list (`splitCursors`, `transposeCursors`, `alignCursors`, `operator`, diagnostic actions and more), see the bundled help:

```vim
:h multicursor
:h multicursor-actions
:h multicursor-api
```

Repository: <https://github.com/jake-stewart/multicursor.nvim>

---

## 9. Limits

- Every key on this page comes from the **official example configuration**, with no customisation. Your local setup may differ; check with `:map <leader>n`.
- The "measured" results come from real terminal sessions on Neovim 0.10+, not from inference. The cursor glyph (`│` versus `┃`) may vary slightly between versions.
- Multi-cursor does not change COBOL semantics; it applies the same edit at several positions. **The `cobc` result remains the source of truth.**
