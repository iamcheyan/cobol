# On-Screen Jumping: flash.nvim

The `snacks picker` is "I know what I'm looking for, search by text". **flash is "I can see it, but I can't get the cursor there".**

A 72-column COBOL statement, fifty lines on screen, cursor at line 8 column 12, target at line 45 column 60. Counting lines and spaces, or `45G` + `60|` — both require knowing the numbers first.

flash lets you **type at the target you can see**: press `s`, type one character near the target, and every match on screen gets a letter label. Press that letter and you are there.

---

## 1. What Problem It Solves

Three inefficient jumps:

| Habit | Problem |
|---|---|
| `j` / `k` line by line | Dozens of presses for a long jump |
| `45G` | You must count lines first |
| `/pattern` + `<CR>` | Needs a unique searchable string; only goes to the next one |

flash wins because **one input, many candidates, direct label jump**. It is not weaker than a regex, just faster than one.

## 2. Your Actual Configuration

Defined in `lua/plugins/flash.lua`, only three keys:

```lua
{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
{ "S", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump (Shift)" },
{ "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
```

| Key | Mode | Action |
|---|---|---|
| `s` | n / x / o | Jump anywhere |
| `S` | n / x / o | Flash character jump, same as `s` |
| `<C-s>` | command line | Toggle flash while searching |

**`r` and `R` were removed** (commented out in the config) to avoid clashing with `substitute.nvim`. So `r` (remote flash) from online tutorials **does not work here**.

The `o` mode is operator-pending, for combinations like `d` `s`.

![Three steps: cursor where it is → press `s` and type a target character → press the label that appears. No line counting, no regex.](images/10-flash-flow.png)

Three steps: cursor where it is → press `s` and type a target character → press the label that appears. No line counting, no regex.

## 3. Basic Usage: `s` + Character + Label

### Three steps

```text
1. Press s
2. Type one character at the target
3. Press the label letter shown on screen
```

Measured (pressing `s` then `A` in a file where `A` appears many times):

```text
   IDENTIFICAaION DIVISION.
   PROGRAM-ID. FLAdHTEST.
   DAfAgDIVISION.
   WORKING-STORAhE SECTION.
   01 WS-AjPHAkPIC X(10) VAlUE "Aqwertyuiop.
```

Every `A` (case-insensitive) is followed by a lowercase label:

| Label | Position |
|---|---|
| `a` | the `A` in `IDENTIFICATION` on line 1 |
| `d` | the `A` in `FLASHTEST` on line 2 |
| `f` | the `A` in `DATA` on line 3 |
| `h` | the `A` in `WORKING-STORAGE` on line 4 |
| `j` | the `A` in `WS-ALPHA` on line 5 |
| `k` | the `A` after `PIC` on line 5 |

Pressing `j` jumped to the `A` of `WS-ALPHA` on line 5 (measured `col(".")` returned `14`).

### When there are too many candidates

Once the labels run out (usually 26), flash asks for another character to narrow the range. **Just keep typing** — you do not start over.

### Cancelling

`<Esc>` exits without moving the cursor.

## 4. `s` With Operators: Jump and Act

Because `s` also works in `o` (operator-pending) mode, it composes with `d`, `c`, `y`, `v`:

| Combination | Meaning |
|---|---|
| `d` `s` `)` | Delete up to the next `)` |
| `c` `s` `X` | Change up to the next `X` |
| `y` `s` `;` | Yank up to the next `;` |
| `v` `s` `}` | Select up to the next `}` |

The idea: with the cursor at the start of a line, `ds"` then pick a label — delete up to **that** quote. **This is stronger than `dt"`**, which can only reach the nearest one.

### Useful combinations in COBOL

```text
d s )      delete to a paren — handy with PIC X(10)
v s "      select to a quote — grab a string literal
c s .      change to a period — rewrite half a sentence
```

## 5. `S`: Alternate Flash Jump Key

`S` invokes the same Flash character-jump action as `s`. It is an alternate entry key and no longer selects Treesitter nodes or falls through to Neovim’s native whole-line replace command.

Press `S`, type a target character, then choose a label to jump to that match.

```text
abcIDENTIFICATION DIVISION.
PROGRAM-ID. FLASHTEST.a
```

The labels depend on the target character you type and the visible matches; they are no longer filtered by Treesitter nodes.

### When to use `S`

| Want to jump to | Use |
|---|---|
| A specific character | `s` |
| A second Flash entry key, or when the terminal interferes with `s` | `S` |
| A bracket or quote | `s` |
| Jump to a character match | `s` or `S` |

`S` does not filter matches by COBOL syntax. To jump to a paragraph or Division, type a distinctive character and choose its label.

This mapping invokes Flash’s regular character jump and does not require a Tree-sitter parser.

```vim
:lua print(vim.treesitter.language.add("cobol"))
```

## 6. `<C-s>`: flash in the Command Line

Pressing `<C-s>` in command-line mode turns `/` search into flash mode: matches are labelled live and you jump by label.

```text
/WS-RECORD<C-s>
```

Useful when the pattern is long and there are many matches: jump straight to the Nth one instead of pressing `n` repeatedly.

## 7. Measured Observations

| Action | Observed |
|---|---|
| Press `s` | Enters a wait-for-input state, no labels |
| Type `A` | Lowercase labels appear after every `A` |
| Press `j` | Jumps to `WS-ALPHA` on line 5, `col()` = 14 |
| Press `S` and type a character | Shows character-match labels, just like `s` |
| Press `<Esc>` | Exits without moving |

## 8. Exercises

### Exercise 1: Basic jump

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. Press `s`
2. Type `D`
3. Look at the label distribution, press one

**Accept:** the cursor lands on the `D` you labelled. Confirm with `:echo line(".").":".col(".")`.

### Exercise 2: Jump across the screen

1. `gg` to the top
2. Press `s`, type `PIC`
3. Pick a label in the second half of the file

**Accept:** one keypress reaches the second half; no line counting.

### Exercise 3: Combine with an operator

On a disposable copy:

1. Cursor at the start of a line
2. `d` `s`, type `"`, pick a label
3. `u` to undo

**Accept:** the deletion runs from the cursor to **the quote you chose**, not the nearest one.

### Exercise 4: Use `S` for a Flash jump

1. `gg`
2. Press `S` and type a distinctive character.
3. Choose a label and confirm the cursor jumps to that match.

**Accept:** the same character-jump behavior as `s`, without filtering by syntax nodes.

**Contrast:** run `s` and `S` with the same character; both show character-match labels.

### Exercise 5: Command-line flash

1. `/WS-RECORD-COUNT<C-s>`
2. Watch the matches get labelled
3. Jump by label

**Accept:** you reach the chosen occurrence without pressing `n`.

## 9. Pitfalls

### `r` / `R` do nothing

Your config **deliberately removed** those mappings (to avoid a `substitute.nvim` clash). Remote flash and Treesitter search from online tutorials are unavailable. **This is not a bug.**

To use them you must add them back and resolve the conflict:

```lua
{ "r", mode = "o", function() require("flash").remote() end },
```

### `s` replaced native `s`

Native vim `s` deletes a character and enters insert. flash takes it over. For the native behaviour use `c` `l`, or `<C-s>` (which in your config only applies to command-line mode, leaving normal mode free).

### Labels are hard to read

Controlled by the `FlashLabel` highlight group. Inspect it with:

```vim
:hi FlashLabel
```

### Jumps are off for CJK text

flash positions by byte, so multi-byte characters (kana in Japanese comments) can shift labels by one. Pure ASCII code lines are unaffected. COBOL code areas are ASCII, so the practical impact is small.

## 10. Official Documentation

```vim
:h flash.nvim
:h flash-jump
```

Repository: <https://github.com/folke/flash.nvim>

Check current mappings:

```vim
:verbose nmap s
:verbose nmap S
```

## 11. Limits

- Keys here come from your local config (`lua/plugins/flash.lua`): only `s`, `S`, `<C-s>`, with `r`/`R` removed.
- `S` invokes the same Flash character jump as `s`; it does not depend on a Tree-sitter parser.
- Measurements come from real terminal sessions; the specific label letters are decided by flash's internal algorithm, so pressing `s` twice on the same file may produce different label layouts.
