# Automatic Pairing: mini.pairs

Type `(` and it automatically inserts `)`. Type `"` and it inserts the closing `"`. That's basic editor courtesy. mini.pairs does this, with some **checks to avoid annoying behavior**.

---

## 1. What Problem It Solves

| Situation | Without automatic pairing | With mini.pairs |
|---|---|---|
| Writing `(IF ...)` | You still have to type `)` after `(` | Type only `(` |
| Writing a string | Easy to leave off one quote | The closing quote is inserted automatically |
| Cursor is already before `)` | Typing `)` again produces `))` | **Skip over it** (`skip_unbalanced`) |

## 2. Your Configuration

`lua/plugins/mini-pairs.lua`:

| Option | Value | Meaning |
|---|---|---|
| `modes.insert` | `true` | Enabled in Insert mode |
| `modes.command` | `true` | Enabled in Command-line mode |
| `modes.terminal` | `false` | Disabled in Terminal mode |
| `skip_next` | `%w%%%'%[%"%.%`%$` | **Don't auto-pair** when the next character is one of these |
| `skip_ts` | `{ "string" }` | Don't pair inside string nodes |
| `skip_unbalanced` | `true` | Skip when there are more closing brackets |
| `markdown` | `true` | Optimize pairing in Markdown code blocks |

### `skip_next` Is the Key

```lua
skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
```

Meaning: if one of the following characters is **immediately after the cursor**, don't automatically insert the closing character:

| Character | Example | Why skip pairing |
|---|---|---|
| `%w` | `a` `1` | You may want to write `a)` instead of `(a)` |
| `%'` | `'` | A quote is already there |
| `%[` | `[` | An opening square bracket is already there |
| `%"` | `"` | A double quote is already there |
| `%.` | `.` | This may be `obj.method(` |
| `` %` `` | Backtick | A backtick is already there |
| `%$` | `$` | A variable marker |

**This avoids the awkward case where a `)` is already there and the plugin inserts another one.**

### `skip_unbalanced = true`

When there are **more** closing brackets on the right than opening brackets, typing an opening bracket skips automatic pairing.

For example, in `(a + b))`, if you type `(` before the second `)`, it won't insert another `)` because the brackets are already unbalanced.

### Toggle

The configuration registers a Snacks toggle. Check its status with:

```vim
:lua =vim.g.minipairs_disable
```

`nil` or `false` = enabled.

## 3. Usage

### Basics

| Input | Result |
|---|---|
| `(` | `()` with the cursor in the middle |
| `[` | `[]` |
| `{` | `{}` |
| `"` | `""` |
| `'` | `''` |
| `` ` `` | ` `` ` |

### Skip Over the Closing Character

After a pair is inserted, typing the closing character (or pressing `→`) moves the cursor **past** the existing one instead of inserting another.

```text
输入 (  →  ()
输入 )  →  ()|    光标跳到 ) 之后，不是 ())
```

### Delete

Press Backspace between `()` to delete both characters (if configured).

## 4. COBOL Scenarios

### Scenario 1: Write `PIC X(10)`

1. Type `PIC X(`
2. It automatically becomes `PIC X()`
3. Type `10`
4. Type `)` → the cursor skips over it

**Result**: `PIC X(10)`, with no extra closing bracket.

### Scenario 2: Write a String Literal

```cobol
DISPLAY "HELLO".
```

1. Type `DISPLAY "`
2. It automatically becomes `DISPLAY ""`
3. Type `HELLO`
4. Type `"` → it skips over the existing quote
5. Type `.`

### Scenario 3: A `VALUE` Clause

```cobol
01 WS-FLAG PIC X(1) VALUE "A".
```

This uses both parentheses and quotes. You don't have to type either closing character manually.

### Scenario 4: Avoid Distractions

When writing in a COBOL comment line (with `*` in column 7), `skip_next` helps avoid unwanted pairs.

## 5. Exercises

### Exercise 1: Basic Pairing

```sh
cd ~/development/cobol
nvim lessons/01_hello-cobol/lesson.cob
```

1. Enter Insert mode
2. Type `(`
3. Observe

**Check**: It becomes `()` with the cursor in the middle.

### Exercise 2: Skip Over an Existing Closing Character

1. Type `(`
2. Then type `)`
3. Observe

**Check**: The cursor moves past `)`, **not** to `())`.

### Exercise 3: Verify `skip_next`

1. Type `(` where the next character is already `)` at the end of a line
2. Observe

**Check**: It does not automatically insert another `)` (because the next character is a letter or an existing symbol).

### Exercise 4: Write a `PIC` Clause

1. Find a line with `PIC X(10)`
2. Delete it and type it again

**Check**: Typing `(` inserts `()`, and typing `)` after the contents skips over the existing closer.

### Exercise 5: Command-line Mode

1. Press `:` to enter Command-line mode
2. Type an opening `(`

**Check**: It is paired automatically too (`modes.command = true`).

### Exercise 6: Confirm Terminal Mode Is Disabled

1. Open a terminal (`:terminal`)
2. Type `(`

**Check**: **No pairing** (`modes.terminal = false`).

## 6. Common Issues

### Typing `(` Doesn't Insert `)`

Check `skip_next`: is there a letter, quote, `.`, or other listed character after the cursor? This is intentional behavior.

### No Pairing Inside Strings

`skip_ts = { "string" }` disables pairing inside string nodes recognized by Treesitter. **COBOL has no parser**, so this rule has no effect for COBOL—but `skip_next` covers most cases for quotes too.

### Behavior Differs in Markdown

`markdown = true` handles code blocks specially. Pairing is optimized when you type ``` `code` ``` in Markdown.

### Turn Pairing Off Completely

```vim
:lua vim.g.minipairs_disable = true
```

Or remove the plugin configuration.

### Conflict with blink.cmp

When the completion menu is open, typing `(` may be handled by completion. **Check the actual behavior**—both plugins listen for Insert mode keypresses.

## 7. Official Documentation

```vim
:h mini.pairs
```

Repository: <https://github.com/nvim-mini/mini.pairs>

## 8. Boundaries

- This tutorial describes `lua/plugins/mini-pairs.lua`: enabled in Insert and Command-line modes, disabled in Terminal mode, with 7 `skip_next` character classes.
- **`skip_next` is intentional behavior**: when a letter, quote, `.`, `$`, and so on follows the cursor, the closing character is not inserted automatically. This is not a bug.
- `skip_ts = { "string" }` depends on Treesitter, so **it has no effect without a COBOL parser**.
- Which mapping handles a key when mini.pairs and blink.cmp coexist should be confirmed by testing.
