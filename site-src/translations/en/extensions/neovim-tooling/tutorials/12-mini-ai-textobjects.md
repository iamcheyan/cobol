# Text Objects: mini.ai

`ciw` (change a word) and `di(` (delete inside parentheses) are built-in Vim text objects. **mini.ai upgrades text objects from character boundaries to semantic boundaries.**

A typical COBOL use case: the cursor is somewhere inside `WS-ACCOUNT-STATUS`, and you want to replace the entire identifier. `ciw` stops at the hyphen because `-` is not part of `iskeyword`. You need `cia` (change an “argument”) or `cii` (change an indentation block).

---

## 1. What problem does it solve?

Vim's built-in text objects only have character-level boundaries such as `w`, `s`, `(`, and `"`. In real code, you want to select by **structure**:

| What you want to select | Built-in approach | mini.ai |
|---|---|---|
| Entire function call `foo(a, b)` | Manually `f(` `%` | `au` (around usage) |
| Content inside quotes (any quote type) | `ci"` or `ci'`, guessing which | `ciq` (any quote) |
| Entire file | `ggVG` | `a g` (`ag`) |
| An indentation block | `vii` won't work | `aii` / `iii` |
| A number | `diw`, then edit manually | `did` (digit) |

mini.ai's approach: **inspect the cursor's context and automatically find suitable boundaries**.


![The four `PIC` widths differ. `ciw` stops at the hyphen; `ciW` replaces the whole word.](images/12-textobjects-context.png)

The four `PIC` widths differ. `ciw` stops at the hyphen; `ciW` replaces the whole word.

## 2. Your configuration

`lua/plugins/mini-ai.lua`, with `n_lines = 500` (maximum search range: 500 lines).

### Custom text objects

| Object | Meaning | Notes |
|---|---|---|
| `o` | block / conditional / loop | Treesitter block |
| `f` | function | Function |
| `c` | class | Class |
| `t` | tag | HTML/XML tag |
| `d` | digit | Number |
| `e` | CamelCase / snake_case | Compound word |
| `g` | entire buffer | Entire file |
| `u` | usage / function call | Inside function-call parentheses |
| `U` | usage (excluding dot) | Same, with `.` excluded from the function name |
| `a` | argument | Argument |
| `i` | indent | Indentation block |
| `q` | quote | Any quote (`"` `'` `` ` ``) |
| `b` | any bracket pair | `()` `[]` `{}` |
| ` ` | whitespace | Consecutive whitespace |

### Prefixes

`i` (inner, excluding boundaries) and `a` (around, including boundaries):

```text
ia   一个参数
aa   参数及其逗号
ii   缩进块内部（不含首尾行）
ai   缩进块整体
iq   引号内内容
aq   连同引号
```

## 3. Useful combinations in COBOL

### Scenario 1: Change an entire identifier

Anywhere within `WS-ACCOUNT-STATUS`:

```text
cia      改一个参数（整个 word，包含连字符）
```

**What happens with `ciw`**: `-` is not a keyword character, so `ciw` selects only `WS`, leaving `new-name-ACCOUNT-STATUS` after you type a replacement.

**Note**: `a` (argument) depends on how mini.ai identifies an “argument.” In `PIC X(10)`, it may select `X(10)` rather than an entire identifier. **The safest approach is to check the selection visually first, or use `viW` directly** (`W` in Vim selects a whitespace-delimited WORD).

### Scenario 2: Select an entire PIC clause

```text
vi(      选括号内（10）
va(      连同括号（X(10)）
```

### Scenario 3: Select an entire string literal

```text
viq      引号内内容（不管单双引号）
vaq      连同引号
```

`ciq` means “change everything inside the quotes, whatever the original value”—more flexible than `ci"` because you don't need to check whether the quotes are single or double first.

### Scenario 4: Select an entire DIVISION block

This requires a COBOL parser for Treesitter. The configuration explicitly says:

```lua
-- COBOL currently has no Treesitter parser in this configuration.
-- Keep mini.ai's Treesitter objects available for other languages,
-- but make them a no-op instead of raising an error in COBOL buffers.
if vim.tbl_contains({ "cobol", "cbl", "cob" }, vim.bo.filetype) then
  return {}
end
```

**Therefore, `iao`, `iaf`, and `iac` do not work in COBOL buffers**—the configuration deliberately disables them to avoid errors. They work in non-COBOL files (Lua, Python, JS).

## 4. Common objects at a glance

| Command | Effect |
|---|---|
| `cia` | Change an argument |
| `ciq` / `caq` | Change inside quotes / including quotes |
| `vii` / `vai` | Select inside / entire indentation block |
| `di(` / `da(` | Delete inside parentheses / including parentheses |
| `yig` / `dag` | Yank entire file / delete entire file |
| `cid` | Change a number |
| `cie` | Change a CamelCase or snake_case word |
| `viu` | Select inside function-call parentheses |

### Special behavior of `ig`

`ig` (inner entire buffer) skips leading and trailing blank lines, while `ag` includes everything. This is useful when processing an entire file:

```text
ggdag    删除整个文件内容
```
⚠️ This is a destructive operation; press `u` first to make sure it can be undone.

## 5. Integration with which-key

The configuration registers 27 text objects with which-key. After pressing `a` or `i`, **pause briefly** to see the available objects:

```text
 a  around
 i  inner
```

Then press the object's letter. If you forget a letter, this is the quickest way to find it.

## 6. Exercises

### Exercise 1: Compare `ciw` and `cia`

```sh
cd ~/development/cobol
nvim lessons/25_using-parameters/lesson.cob
```

1. Put the cursor somewhere inside `AMOUNT-ARGUMENT`.
2. Press `ciw`, type `X`, then `<Esc>` and observe the result.
3. Undo with `u`.
4. Press `cia`, type `X`, then `<Esc>` and observe the result.

**Check**: `ciw` changes only part of the word (it stops at `-`), while `cia` changes the whole word. This comparison is the quickest way to understand the value of mini.ai.

### Exercise 2: Change quoted content with `ciq`

1. Find a line such as `VALUE "C0001042"`.
2. Put the cursor inside the quotes.
3. Use `ciq` and type a new value.

**Check**: The content changes without first checking whether the quotes are single or double.

### Exercise 3: Yank the entire file with `yig`

1. Press `yig`.
2. Open a new buffer with `:new`.
3. Press `p`.

**Check**: The whole file is copied, without extra blank lines at the beginning or end (`ig` skips blank lines).

### Exercise 4: Indentation block

In any indented code block (for example, `IF ... END-IF`):

1. Use `vii` to select the inside.
2. Press `d` to delete it.
3. Undo with `u`.

**Check**: The selection runs from the line after `IF` to the line before `END-IF`.

### Exercise 5: Explore which-key

1. Press `a` and wait 1 second.
2. Look at the list that appears.
3. Press `<Esc>` to exit.

**Check**: You can see the names and descriptions of all 27 text objects.

## 7. Pitfalls

### `iao` does nothing in COBOL

The configuration returns an empty table for the COBOL filetype because there is no COBOL Treesitter parser. **This is intentional, not a bug**; it avoids errors. Use `vii` instead.

### `cia` selects the wrong range

The boundary for `a` (argument) depends on context. In `PIC X(10)`, it may select only `X(10)`. **When in doubt, enter Visual mode with `v` first, inspect the selection, then decide.**

### You panic after `ig` deletes the entire file

You can undo with `u`. Vim's undo tree is reliable as long as you haven't exited Neovim.

### `n_lines = 500` is exceeded

mini.ai searches up and down for only 500 lines. In very large files, a boundary far away may not be found. This is a performance safeguard, not a defect.

## 8. Official documentation

```vim
:h mini.ai
:h mini.ai-examples
```

Repository: <https://github.com/nvim-mini/mini.ai>

Print the current text-object list:

```vim
:lua print(vim.inspect(require("mini.ai").config.custom_textobjects))
```

## 9. Boundaries

- The key mappings in this article come from your configuration (`lua/plugins/mini-ai.lua`): 27 text objects, `n_lines = 500`.
- **The three Treesitter objects `o`, `f`, and `c` are deliberately disabled in COBOL buffers** because there is no COBOL parser; don't expect them to work.
- The boundary for `a` (argument) depends on context and can vary by cursor position; `W` (whitespace-delimited word) is more predictable in COBOL.
- Pair this with [the multicursor article](08-multicursor-batch-editing.md): after selecting with `viq`, add multicursors to change multiple strings in one pass.
