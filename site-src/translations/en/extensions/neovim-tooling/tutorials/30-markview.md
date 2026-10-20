# Markdown Rendering: markview.nvim

Markdown files normally show only their source: `# Heading` is a line of text with a `#`, and tables are raw `|` pipes.

markview renders them closer to their final appearance: larger headings, aligned tables, shaded code blocks, and clickable checkboxes.

---

## 1. What Problem It Solves

| Need | Source view | markview |
|---|---|---|
| See heading hierarchy | Count the `#` characters | Distinct sizes and colors |
| Read tables | Align the `|` characters by eye | Rendered as tables |
| Read code blocks | Monospaced text only | Background and language label |
| View task lists | `- [ ]` text | Clickable checkboxes |

## 2. Your Configuration

`lua/plugins/markview.lua`:

| Option | Value | Meaning |
|---|---|---|
| `lazy` | `false` | Load immediately (don't wait for LazyFile) |
| `ft` | 4 types, including `markdown` | Applies only to Markdown-related files |
| `preview.enable` | `true` | Enable rendering |
| `icon_provider` | `internal` | Use built-in icons (no extra icon library needed) |

The configuration comment explains why `lazy = false`:

```lua
-- Markview manages its own preview attachment; keep it available after the
-- colorscheme has initialized so Markdown opens with rendered elements.
```

markview manages when its preview attaches. Keeping it available after the colorscheme initializes lets Markdown open with rendered elements.

### Active Filetypes

```lua
ft = { "markdown", "markdown.mdx", "quarto", "rmd" },
```

### Toggle the Preview

| Key | Action |
|---|---|
| `<leader>um` | Toggle Markdown rendering |

**This works only in Markdown buffers** (the `ft` setting restricts it).

## 3. What It Renders

| Element | Rendered appearance |
|---|---|
| Headings `#` `##` | Different sizes and colors |
| Tables | Aligned table borders |
| Code blocks ``` | Shaded block + language label |
| Blockquotes `>` | Vertical line on the left |
| Lists `-` | Bullet points |
| Task lists `- [ ]` | Clickable checkboxes |
| Links | Distinctive color |
| Bold/italic | Font weight/italic style |

## 4. Practical Value in the COBOL Course

This repository contains a lot of Markdown: the READMEs for 32 lessons, tutorials in `extensions/`, and this tutorial itself.

### Scenario 1: Read Course Documentation

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/README.md
```

After rendering:
- Heading hierarchy is clear
- Tables (such as offset tables) are aligned as actual tables
- Code blocks have a background

**It's much more comfortable than reading the source**, especially in lessons with many tables (such as the 200-byte offset table in Lesson 17).

### Scenario 2: Check Layout While Writing Documentation

Enable rendering while editing a README to spot table alignment and heading hierarchy issues immediately.

After editing, press `<leader>um` to view the source and check for syntax errors.

### Scenario 3: Review a Table

The offset table in Lesson 17 has 14 rows. When rendered as a table, you can immediately spot a row with misaligned columns.

## 5. Exercises

### Exercise 1: Open a Rendered File

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/README.md
```

**Check**: Headings have hierarchy styling, tables render as tables, and code blocks have a background.

### Exercise 2: Toggle Rendering

1. `<leader>um`

**Check**: The buffer returns to source mode (you can see `#` and `|`). Press again to restore rendering.

### Exercise 3: Inspect a Table

1. Find the offset table in the README
2. Observe the alignment in the rendered view

**Check**: The table columns are aligned and easier to read than in source mode.

### Exercise 4: Confirm It Works Only in Markdown

1. Open a `.cob` file
2. Press `<leader>um`

**Check**: **Nothing happens** (the `ft` restriction binds it only in Markdown).

### Exercise 5: View a Task List

1. Open a Markdown file containing `- [ ]` (if one exists in the repository)
2. Observe the rendering

**Check**: It appears as checkboxes (they may be clickable, depending on the configuration).

## 6. Common Issues

### Markdown Opens Without Rendering

Check:
1. Is the filetype `markdown`? Run `set ft?`
2. Is markview loaded? Check its status with `:Lazy`

`lazy = false` is configured, so it should be available after startup.

### `<leader>um` Does Nothing

The mapping exists only in Markdown buffers (restricted by `ft`). It won't work in a `.cob` file.

### Code Is Hard to See After Rendering

Code blocks use a monospaced font, but may look gray with a low-contrast theme. Check:

```vim
:hi MarkviewCode
```

### The Cursor Position Seems Odd While Editing

In rendered mode, the cursor is still on the source characters; only their display is enhanced. **Editing behavior is unchanged**—`x`, `dd`, and insertions work as usual.

### Temporarily View the Source

Toggle with `<leader>um`. You can also use `:set ft=` to remove the filetype (not recommended, because highlighting will be lost).

### Large Files Feel Slow

Rendering can be a little slow for long Markdown files (such as this tutorial). Turn it off if needed.

## 7. How It Relates to Other Plugins

| Need | Tool |
|---|---|
| Render Markdown | markview (`<leader>um`) |
| Edit Markdown structure | Regular Vim operations |
| Navigate the outline | aerial (`<leader>cs`, supports the Markdown backend) |
| Format Markdown | conform (`prettierd`) |

**markview changes only the display, not the file contents.** The file remains unchanged when rendering is off.

## 8. Official Documentation

```vim
:h markview
```

Repository: <https://github.com/OXY2DEV/markview.nvim>

## 9. Boundaries

- This tutorial describes the configuration in `lua/plugins/markview.nvim`: `lazy = false`, four `ft` entries, and `icon_provider = "internal"`.
- `<leader>um` works **only in Markdown buffers**.
- markview changes only the display, not the file contents; turning rendering off leaves the file unchanged.
- COBOL development itself doesn't need it, but **it's useful for reading course documentation**—this repository has more than 30 Markdown files.
