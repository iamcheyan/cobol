# Smart Pasting: smart-paste.nvim

When you paste code into Neovim from a browser, chat window, or another file, the most common problem is **broken indentation**: the pasted content retains its original indentation, which combines with the current position and creates a jagged result.

`smart-paste.nvim` handles this by **preserving relative indentation inside the block while aligning the whole block to the current line.**

---

## 1. What problem does it solve?

| Paste method | Problem |
|---|---|
| `p` (default) | Characterwise paste; indentation in multiline content is inserted as-is and can accumulate at each level |
| `P` | Same, but inserted before |
| `:set paste` | Disables all indentation processing, but also disables completion and autoindent |
| `]p` | Adjusts to the current indentation, but reformats every line |

smart-paste **preserves relative indentation inside the block** and realigns only the “first line” to the current line; the rest follow its relative indentation.

## 2. Your configuration

`lua/plugins/smart-paste.lua`. This plugin's configuration is longer than the others because it handles three paste sources:

1. **Internal yank** (Vim register)
2. **System clipboard** (`+` register)
3. **Terminal paste** (`<C-S-v>` or middle-click)

The key logic is clearly explained in the configuration comments:

```lua
-- External clipboard registers are often characterwise. Keep their
-- relative indentation intact while rebasing the block to this line.
```

```lua
-- Characterwise yanks omit whitespace before the first selected byte.
-- Remember that missing prefix instead of guessing from nested lines.
```

**The second comment captures the key insight**: a characterwise yank doesn't include whitespace at the start of the line. When pasting, you must remember “how many spaces were missing” instead of guessing from the indentation of nested lines.

## 3. Basic behavior

### Internal yank

```text
yy        复制一行
p         粘贴（自动对齐到当前缩进）
```

When yanking a multiline block:

```cobol
       IF WS-STATUS = "A"
           DISPLAY "ACTIVE"
       END-IF
```

If you paste it at a location with the same 7-space indentation, the relative structure of the whole block is preserved (`DISPLAY` is 4 spaces further in than `IF`) and the first line aligns to the paste location.

### System clipboard

Copy COBOL code from a browser, then press `p` in Neovim; it will be aligned in the same way.

### Terminal paste

If the terminal supports bracketed paste, large pasted blocks use the same behavior.

## 4. Practical value in COBOL

### Scenario 1: Copy example code from documentation

The course README files contain many code blocks. When you copy one into a `.cob` file:

**Without smart-paste**: The code block in the README has no indentation, but COBOL requires Area B to start in column 12. After pasting, you have to add 11 spaces to every line manually.

**With smart-paste**: Put the cursor in column 12 and paste; the entire block starts in column 12 automatically.

### Scenario 2: Copy an `IF` block and change the condition

```cobol
           IF WS-ACCOUNT-STATUS = "A"
               PERFORM 2000-POST-TRANSACTION
               ADD 1 TO WS-ACCEPTED-COUNT
           END-IF
```

Copy these 4 lines and paste them below. Their relative indentation is preserved (`PERFORM` is still 4 spaces further in than `IF`).

### Scenario 3: Move code from another lesson

Move the file-matching logic from lesson 20 to lesson 32. If the indentation levels match, you won't need to reformat it after pasting.

## 5. Exercises

### Exercise 1: Compare default `p` with smart-paste

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. Find an indented `IF` block, select several lines with `V`, then press `y`.
2. Move to a blank line near the bottom of the file and press `p`.
3. Undo with `u`.

**Check**: After pasting, the block's relative indentation is preserved (the inner statements are indented farther than the outer ones) rather than everything starting in column 1.

### Exercise 2: Copy code from a README

1. Open `lessons/17_fixed-length-files/README.md`.
2. Copy a code block (`V` to select it, then `y`).
3. Switch to the `.cob` file.
4. Move the cursor to column 12 (`12|`).
5. Press `p`.

**Check**: The whole block starts in column 12, not column 1.

### Exercise 3: System clipboard

1. Copy several lines of text from a browser or terminal.
2. Press `p` in Neovim.

**Check**: Pasting doesn't create indentation that accumulates in a jagged pattern from line to line.

### Exercise 4: Paste an entire function into a new file

1. Copy a complete `0100-INIT.` paragraph.
2. Open a new buffer with `:new`.
3. Press `p`.

**Check**: The paragraph's indentation levels are preserved.

## 6. Pitfalls

### Indentation increases after pasting

The terminal may be sending the pasted content character by character as keystrokes, triggering autoindent. Check that bracketed paste is enabled in the terminal (it is enabled by default in most modern terminals).

Check with:

```vim
:set paste?
```

If it shows `nopaste`, that means `:set paste` hasn't interfered—which is good.

### The first line loses its indentation when pasting from the clipboard

This is an inherent issue with characterwise yanks (mentioned in the configuration comments). smart-paste remembers “how much was missing,” but if the source itself had no indentation, it can only treat it as 0.

**Workaround**: Before pasting, put the cursor at the target indentation; the paste uses the cursor position as its reference.

### `p` and `P` behave differently

`p` pastes after the cursor/on the next line; `P` pastes before the cursor/on the previous line. The difference is noticeable with multiline blocks. **When in doubt, undo with `u` and try the other one.**

### Pasting a large block is slow

smart-paste processes indentation line by line. Pasting thousands of lines may take a second or two; this is normal.

### Conflict with `:set paste`

`:set paste` disables all automatic behavior, including smart-paste's adjustments. **Don't use `:set paste`**; let the plugin handle it.

## 7. Official documentation

Repository: <https://github.com/nemanjamalesija/smart-paste.nvim>

Inspect the current register contents:

```vim
:reg +
:reg "
```

`+` is the system clipboard; `"` is the unnamed register.

## 8. Boundaries

- This plugin is configured in your `lua/plugins/smart-paste.lua`. Its configuration is longer than the others because it handles internal yanks, the system clipboard, and terminal paste separately.
- “Preserve relative indentation and rebase to the current line” is its design goal; **it does not guarantee exact alignment with any particular indentation rule (such as `shiftwidth`)**.
- Content copied from a browser may contain invisible characters (zero-width spaces, NBSP). The plugin can't fix these; use `:set list` to inspect them.
- After pasting, it's still a good idea to validate with `cobc -fsyntax-only`, because COBOL is sensitive to column positions.
