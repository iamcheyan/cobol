# Bookmarks: bookmark.nvim

Aerial shows structure and grep finds content, **but how do you mark “that place I was halfway through yesterday”?**

bookmark lets you set a bookmark on any line and jump back to it with one keystroke later.

---

## 1. What Problem It Solves

| Need | Without bookmarks | With bookmark |
|---|---|---|
| Remember a location | Rely on memory or `:marks` | Set a bookmark |
| Move between locations | `Ctrl-o` / `Ctrl-i` history | `]b` / `[b` |
| List all marked locations | No built-in list | `<leader>mm` |
| Save by project | No | Yes (project-level) |

## 2. Your Configuration

`lua/plugins/bookmark.lua`:

```lua
opts = {
  sign = " ",
  sign_color = "#e0af68",
  mouse = true,
},
```

| Option | Value | Meaning |
|---|---|---|
| `sign` | ``  `` | Bookmark icon in the sign column |
| `sign_color` | `#e0af68` | Yellow |
| `mouse` | `true` | Enable mouse clicks |

### Keybindings

| Key | Command | Action |
|---|---|---|
| `<leader>mt` | `:BookmarkToggle` | Toggle a bookmark on the current line |
| `<leader>mm` | `:BookmarkList` | List all bookmarks |
| `]b` | `:BookmarkNext` | Next bookmark |
| `[b` | `:BookmarkPrev` | Previous bookmark |
| `<leader>mc` | `:BookmarkClear!` | Clear bookmarks in the **current buffer** |
| `<leader>mC` | `:BookmarkClear` | Clear bookmarks for the **entire project** |

### Note the `<leader>m` Group

In the which-key configuration, `<leader>m` is the **bookmarks** group; `mh`, `mH`, `mt`, `m0`, `ma` and `mA` are all used by this plugin.

## 3. Use Cases

### Scenario 1: Resume Work the Next Day

You got halfway through editing Lesson 27 and want to continue tomorrow:

1. Move the cursor to that line
2. Press `<leader>mt` to set a bookmark
3. Open the file the next day
4. Use `<leader>mm` to list bookmarks or jump directly with `]b`

### Scenario 2: Mark Several Locations in a Long File

Lesson 32 is several hundred lines long, and you want to track three places:

1. Press `<leader>mt` at each place
2. Use `]b` / `[b` to move among them

This is more reliable than remembering line numbers (such as `:120`)—line numbers change, and bookmarks move with their lines.

### Scenario 3: Mark Suspect Code During a Review

You find three suspicious spots while reading someone else's code:

1. Set a bookmark at each one
2. Review them with `<leader>mm` when you finish reading
3. Clear them with `<leader>mc` when done

## 4. Exercises

### Exercise 1: Set a Bookmark

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/lesson.cob
```

1. Move the cursor to a paragraph (such as `1000-INIT`)
2. Press `<leader>mt`
3. Look at the left side

**Check**: A `` icon appears in the sign column.

### Exercise 2: Jump

1. Move somewhere else in the file
2. Press `]b`

**Check**: You return to the bookmarked location. Press `[b` to move back as well.

### Exercise 3: List Bookmarks

1. Set bookmarks in two places
2. Press `<leader>mm`
3. Inspect the list

**Check**: Both bookmarks are listed, and you can select one to jump to it.

### Exercise 4: Clear the Current Buffer

1. Press `<leader>mc`

**Check**: Bookmarks in the current file are cleared; bookmarks in other files remain.

### Exercise 5: Clear the Project

1. Press `<leader>mC`

**Check**: Bookmarks for the **entire project** are cleared. **This affects a wider scope**, so take care.

### Exercise 6: Mouse

1. Click a bookmark icon in the sign column (`mouse = true`)

**Check**: It jumps or triggers the related action.

## 5. Common Issues

### Do Bookmarks Persist After Closing a File?

This depends on how the plugin stores them (project-level persistence). They usually remain when you reopen the file. **Confirm by testing**—set a bookmark, restart Neovim, and see whether it is still there.

### `<leader>mC` Clears Too Much

`BookmarkClear` applies to the **entire project**. To clear only the current file, use `<leader>mc` (`BookmarkClear!`).

### The Icon Is a Box

`sign = " "` requires an icon font. If your terminal doesn't support it, the icon appears as a box.

### Do Bookmarks Move with Their Lines?

A bookmark records a line. After inserting or deleting lines, it moves with the line (as most implementations do). **If the line itself is deleted, the bookmark may disappear.**

### Conflict with Vim's Built-in `m` Marks

Vim's built-in `ma` sets a mark. The plugin uses `<leader>m*`, so they don't conflict (the prefixes are different).

## 6. How It Relates to Other Plugins

| Need | Tool |
|---|---|
| Remember “the place I was halfway through editing” | bookmark (`<leader>mt`) |
| View file structure | aerial (`<leader>cs`) |
| Jump to a definition | `gd` (`cobol.nvim` / LSP) |
| Search for content | `<leader>fw` (snacks) |
| Return to the previous edit location | `Ctrl-o` / `gi` |

**bookmark is for manual marking; the others locate things automatically.**

## 7. Official Documentation

Repository: <https://github.com/iamcheyan/bookmark.nvim>

## 8. Boundaries

- This tutorial describes `lua/plugins/bookmark.lua`: `<leader>mt`/`mm`/`mc`/`mC`, `]b`/`[b`, and `mouse = true`.
- `<leader>mC` clears bookmarks for the **entire project**, a much wider scope than `<leader>mc` (the current buffer).
- Confirm bookmark persistence by testing; this is a plugin you develop (`iamcheyan/`).
