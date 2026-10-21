# Multi-Cursor Batch Editing with multicursor.nvim

Renaming COBOL fields, unifying `PIC` clauses, or swapping status codes line by line is slow and easy to get wrong. `multicursor.nvim` puts a cursor on every position you need so a single edit applies to all of them.

This page follows the actual keymaps in the local `lua/plugins/multicursor.lua`: VS Code-style `Ctrl-n`, `Ctrl+Shift+n` and `Ctrl-d` are added on top of the plugin, and the line-wise and skip mappings are kept.

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
- fill six placeholder lines with different sequence numbers;

the single-cursor approach is "change one, `n` to the next, change again". The multi-cursor approach is "place cursors everywhere, change once".

**The difference is not speed, it is whether you miss one.** A COBOL program with one missed field usually still compiles — that one field just keeps its old width until it fails at runtime.

---

## 2. Local Configuration and Keymaps

The local configuration (`lua/plugins/multicursor.lua`) adds VS Code-style keys to the plugin and loads it eagerly so `Ctrl+Shift+n` works on the first press:

| Key | Mode | Action |
|---|---|---|
| `Ctrl-n` | Normal / Visual | Add the next match for the word or selection |
| `Ctrl+Shift+n` | Normal / Visual | Add cursors at all matches for the word or selection |
| `Ctrl-d` | Normal / Visual | Skip the next match without adding a cursor |
| `<up>` / `<down>` | Normal / Visual | Add a cursor above / below |
| `<leader><up>` / `<leader><down>` | Normal / Visual | Skip a line, then add a cursor |
| `ga` + motion | Normal / Visual | Add cursors by motion, for example `gaip` |
| `<leader>a` | Normal | Align cursor columns |
| `<leader>gv` | Normal | Restore the previous cursor set |
| `<C-q>` | Normal / Visual | Pause or resume the other cursors |
| `<Esc>` | With active cursors | Clear cursors; if paused, enable them first |

The plugin's example configuration uses `<leader>n`, `<leader>s`, `<leader>N` and `<leader>S`; those are not the local match mappings. This guide uses the local keys in the table above.

---

## 3. Five Common Actions

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
| `c` | Current selection | Replacing matched text after `Ctrl+Shift+n` |

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

### Action 4: Select every match with `Ctrl+Shift+n`

The first three actions use `gaip` to add a cursor per line. When the target is a repeated piece of text (for example `CUSTOMER`), match selection is more direct:

```text
Select CUSTOMER in Visual mode
Ctrl+Shift+n    " every CUSTOMER in the file is selected
c               " change all selections
CLIENT
<Esc>
```

To change only some occurrences, add them one at a time with `Ctrl-n` and skip unwanted matches with `Ctrl-d`.

### Action 5: Batch-replace quoted content (`ci"`)

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

In the local configuration `<Esc>` is:

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

Steps: select `CUSTOMER` in Visual mode → `Ctrl+Shift+n` to select all matches → `c` → type `CLIENT` → `<Esc>`.

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

### Exercise 4: Skip a match you do not want to edit

Use `01-rename-field.cob` to practice Visual selection and skipping:

1. Put the cursor on the `C` in `CUSTOMER` and select `CUSTOMER` in Visual mode.
2. Press `Ctrl-n` to add the next matching selection.
3. Press `Ctrl-d` to skip a match you do not want to change.
4. Press `c` on the remaining matches, type `CLIENT`, then press `<Esc>`.

**Check**: only the selected `CUSTOMER` fragments become `CLIENT`; the skipped match stays unchanged.
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
| Add cursor at next match | `Ctrl-n` | Word or selection match |
| Skip next match | `Ctrl-d` | No cursor added |
| Add cursors at all matches | `Ctrl+Shift+n` | Whole file at once |
| Add per motion | `ga` + motion | `gaip` = one per line |
| Switch main cursor | `<left>` / `<right>` | Only with multiple cursors |
| Delete current cursor | `<leader>x` | Only with multiple cursors |
| Freeze/resume others | `<c-q>` | Main cursor moves alone |
| Clear all cursors | `<Esc>` | In the normal state |
| Mouse add cursor | `<c-leftmouse>` | Ctrl + left click |

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

This page covers the common subset, with keys as configured locally. For the full action list (`splitCursors`, `transposeCursors`, `alignCursors`, `operator`, diagnostic actions and more), see the bundled help:

```vim
:h multicursor
:h multicursor-actions
:h multicursor-api
```

Repository: <https://github.com/jake-stewart/multicursor.nvim>

---

## 9. Limits

- This page follows the current `lua/plugins/multicursor.lua`. Match keys are customized to `Ctrl-n`, `Ctrl+Shift+n` and `Ctrl-d`; the local setup also maps `ga`, `<leader>a` and `<leader>gv`.
- The "measured" results come from real terminal sessions on Neovim 0.10+, not from inference. The cursor glyph (`│` versus `┃`) may vary slightly between versions.
- Multi-cursor does not change COBOL semantics; it applies the same edit at several positions. **The `cobc` result remains the source of truth.**
