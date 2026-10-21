# Editing Surrounding Delimiters: mini.surround

Adding quotes to a column of numbers, changing `(` to `[`, or removing one layer of parentheses—doing it manually means “move to the start, insert, move to the end, insert.”

mini.surround turns this into **three letters followed by a target delimiter**.

---

## 1. What problem does it solve?

| Task | Manual approach | mini.surround |
|---|---|---|
| Quote a word | `i"` `<Esc>` `a"` `"` | `gsa"` |
| Change `(` to `[` | Find and change each parenthesis | `gsr([` |
| Remove surrounding quotes | Find and delete both | `gsd"` |
| Put parentheses around an entire line | Do both ends manually | `gsa(` (after selecting in Visual mode) |

## 2. Your configuration

`lua/plugins/mini-surround.lua`:

```lua
mappings = {
  add = "gsa",
  delete = "gsd",
  replace = "gsr",
  find = "gsf",
  find_left = "gsF",
  highlight = "gsh",
  update_n_lines = "gsn",
}
```

| Key | Effect |
|---|---|
| `gsa` | **add**: add surrounding delimiters |
| `gsd` | **delete**: delete surrounding delimiters |
| `gsr` | **replace**: replace surrounding delimiters |
| `gsf` | **find**: find the next surrounding delimiter |
| `gsF` | **find_left**: search backward |
| `gsh` | **highlight**: highlight the surrounding pair at the cursor |
| `gsn` | Update the search range (20 lines by default) |

The `gs` prefix is fixed. Follow it with the operation letter and then the **target delimiter**.

## 3. Add: `gsa`

### Basic usage

With the cursor on a word, follow `gsa` with a delimiter:

```text
gsa"      给当前词加双引号
gsa'      加单引号
gsa)      加圆括号（自动匹配成 ( )）
gsa(      同上
gsa]      加方括号
gsa}      加花括号
gsa<      加尖括号
```

### Add to entire lines

```text
gsa<CR>   给当前行加换行包围？不——需要先选中
```

The correct approach: first select multiple lines in **Visual mode**, then use `gsa)`. This adds parentheses to each line.

A tested approach (COBOL scenario):

```text
V 选中 3 行
gsa"      每行都加上了双引号
```

### Custom delimiters

You can enter any string as a delimiter:

```text
gsa<space>   加一个空格
gsa DIVISION.
```

mini.surround supports “enter custom text as a delimiter.” The README describes entering `f` (find right) and other special keys after `gsa`. **In practice, single-character delimiters are the most common.**

## 4. Delete: `gsd`

```text
gsd"      删掉最近的引号对
gsd)      删掉最近的括号对
gsdb      删除最近的一对，任意类型
```

`gsdb` (`b` = bracket) deletes the **nearest** surrounding pair, regardless of type. Use it when you don't know what kind of delimiter is on the outside.

## 5. Replace: `gsr`

```text
gsr("     把 ( ) 换成 " "
gsr)'     把 ( ) 换成 ' '
gsr*}     把 { } 换成 * *
```

**Enter the old delimiter first, then the new one.** Type the two characters consecutively.

## 6. Find and highlight

| Command | Effect |
|---|---|
| `gsf"` | Find the next `"` forward |
| `gsF"` | Find the previous one backward |
| `gsh` | Highlight the pair surrounding the cursor |

`gsh` is especially useful when you're inside several nested parentheses: press it once to see which level you're on.

## 7. Useful COBOL scenarios

### Scenario 1: Add quotes to several fields

```cobol
01  WS-FLAG-A  PIC X(1) VALUE A.
01  WS-FLAG-B  PIC X(1) VALUE B.
```

Turn `A` and `B` into `"A"` and `"B"`:

1. Put the cursor on `A`.
2. Use `gsa"`.

A more efficient approach: add multicursors (match each occurrence with `<leader>n`) and then use `gsa"` once.

### Scenario 2: Change the parentheses in `PIC X(10)`

```text
光标在 (10) 内
gsr(]    括号从 ( ) 变成 [ ]  ← 语法上 demo 用，实际 COBOL 不用方括号
```

**Note**: COBOL's `PIC` syntax only accepts parentheses. This example demonstrates the replacement operation itself.

### Scenario 3: Quote a `COPY` filename

```cobol
COPY ACCOUNT-REC.CPY.
```

Becomes:

```cobol
COPY "ACCOUNT-REC.CPY".
```

1. Put the cursor on `ACCOUNT-REC.CPY`.
2. Use `gsa"`.

### Scenario 4: Remove an extra layer of parentheses

```cobol
COMPUTE X = ((A + B)).
```

With the cursor inside, `gsd)` removes one layer, resulting in `COMPUTE X = (A + B).`.

## 8. Exercises

### Exercise 1: Add quotes

```sh
cd ~/development/cobol
nvim lessons/23_copybooks/lesson.cob
```

1. Find a `COPY filename.` statement.
2. Put the cursor on the filename.
3. Use `gsa"`.

**Check**: The filename is surrounded by quotes.

### Exercise 2: Change delimiter type

On any line containing `( )`:

1. Put the cursor inside the parentheses.
2. Use `gsr("[`.

**Check**: `(` and `)` become `[` and `]`.

### Exercise 3: Remove one layer

1. Find an arithmetic expression with two layers of parentheses.
2. Put the cursor inside the inner pair.
3. Use `gsd)`.
4. Undo with `u`.

**Check**: Only the nearest layer was removed; the outer layer remains.

### Exercise 4: Locate with `gsh`

1. Find a `COMPUTE` statement with nested parentheses.
2. Put the cursor in the middle.
3. Press `gsh`.

**Check**: The pair of parentheses around the cursor is highlighted.

### Exercise 5: Add delimiters to multiple lines

1. Use `V` to select 3 lines of `DISPLAY` statements.
2. Use `gsa(`.

**Check**: Each of the three lines is surrounded by parentheses (rather than the whole selection being surrounded once).

### Exercise 6: Combine with text objects

1. Use `viq` to select the quoted content.
2. Use `gsa'` to surround it with single quotes.

**Check**: You can combine text objects and surround.

## 9. Pitfalls

### `gsa` does nothing

Make sure you pressed `gsa`, not `gsA`. Also, you must **follow it with a delimiter**: use `gsa"`, not just `gsa`.

### The replacement delimiters don't match

The order for `gsr("[` is “old delimiter → new delimiter.” Entering `gsr["(` tries to replace `[` with `(`; if it can't find one, nothing happens.

### The target delimiter isn't found

By default, the search range is 20 lines up and down. For deeply nested delimiters, increase it with `gsn`:

```text
gsn100
```

### `gsd` removes the wrong layer

It removes the **nearest** layer. Cursor position matters—use `gsh` first to confirm the highlighted pair is the one you want to remove.

### Parentheses in COBOL comment lines

Parentheses in comment lines (where column 7 is `*`) are also recognized. Before operating, make sure the cursor isn't in a comment.

## 10. Official documentation

```vim
:h mini.surround
:h mini.surround-mappings
```

Repository: <https://github.com/nvim-mini/mini.surround>

## 11. Boundaries

- The mappings in this article come from your configuration (`lua/plugins/mini-surround.lua`); the default prefix is `gs`.
- The default search range is 20 lines and can be adjusted with `gsn`.
- COBOL's `PIC` syntax only accepts parentheses. Replacements such as `gsr("[` are suitable only for demonstrating the operation, not for actual `PIC` clauses.
- To add delimiters to multiple lines, select them in Visual mode first, then use `gsa`; it adds delimiters to **each line** individually rather than surrounding the whole selection.
