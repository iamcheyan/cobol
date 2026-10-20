# Color Editing: ccc.nvim

When you see `#3b82f6` in a CSS file, Lua config, or terminal color scheme, you may want to know what color it is, make it lighter, or convert it to `rgb()`. Editing hex values by hand is painful.

ccc.nvim provides a color picker and format conversion.

---

## 1. What Problem It Solves

| Need | Manual approach | ccc |
|---|---|---|
| See what color `#3b82f6` is | Guess or open an external tool | Preview it directly |
| Make it lighter or darker | Calculate RGB by hand | Drag sliders |
| Convert to `rgb()` / `hsl()` | Calculate by hand or use a website | `<leader>cC` |
| Choose a new color | Remember a color value | Color picker |

## 2. Your Configuration

`lua/plugins/ccc.lua`:

```lua
cmd = { "CccPick", "CccConvert" },
keys = {
  { "<leader>cp", "<cmd>CccPick<cr>", desc = "Color Picker (ccc)" },
  { "<leader>cC", "<cmd>CccConvert<cr>", desc = "Color Convert (ccc)" },
},
opts = {
  highlighter = {
    auto_enable = false, -- 禁用自带的 buffer 高亮
    lsp = false,
  },
},
```

| Key | Command | Action |
|---|---|---|
| `<leader>cp` | `:CccPick` | Open the color picker |
| `<leader>cC` | `:CccConvert` | Convert the color format |

### Key Detail: Automatic Highlighting Is Disabled

```lua
highlighter = {
  auto_enable = false,
  lsp = false,
},
```

The configuration comments explain why:

```lua
-- 禁用自带的 buffer 高亮，避免与极速的 mini.hipatterns 争抢高亮组
```

**ccc can automatically add a background color to color values in the buffer**, but this configuration uses `mini.hipatterns` for that (see [the mini.hipatterns tutorial](29-rainbow-delimiters.md)). Both would compete for the same highlight group, so ccc's automatic highlighting is disabled here.

**Result**: Color previews in the buffer come from mini.hipatterns, not ccc. ccc works only when you explicitly press `<leader>cp` or `<leader>cC`.

## 3. Color Picker (`<leader>cp`)

Place the cursor on a color value (such as `#3b82f6`) and press `<leader>cp`:

```text
┌─────────────────────────────┐
│  #3b82f6                    │
│  R ████████░░  59           │
│  G █████████░░░ 130         │
│  B █████████████ 246        │
│  ─────────────────────────  │
│  [hex] [rgb] [hsl] ...      │
└─────────────────────────────┘
```

### Controls

| Key | Action |
|---|---|
| `h` / `l` | Switch the channel to adjust (R/G/B or H/S/L) |
| `j` / `k` or `↑` `↓` | Decrease or increase the value |
| `0`–`9` | Enter a value directly |
| `<CR>` | Confirm |
| `q` or `<Esc>` | Cancel |

### Switch Color Space

The picker supports several representations; use `Tab` or the arrow keys to switch:

- `hex`: `#3b82f6`
- `rgb`: `rgb(59, 130, 246)`
- `hsl`: `hsl(217, 91%, 60%)`
- And more, depending on the configuration

## 4. Convert a Format (`<leader>cC`)

With the cursor on a color value, press `<leader>cC` and choose the target format:

```text
将 #3b82f6 转换为：
  > rgb
    hsl
    ...
```

After you choose a format, the value is replaced in place.

## 5. COBOL Use Cases

**Color values are rarely used in COBOL source code**. These scenarios are useful, though:

### Scenario 1: Edit Terminal Colors or a Statusline Theme

When defining colors in `~/nvim/colors/` or `lua/config/ui_highlights.lua`, use `<leader>cp` to choose a suitable value.

### Scenario 2: Edit the Course Site's CSS

`site-src/site.css` contains color definitions. To change a theme color:

1. Place the cursor on the color value.
2. Use `<leader>cp` to adjust it.
3. Confirm.

**Note**: The course site's CSS uses design tokens such as `var(--purple)`. Editing a raw color value can break theme switching. Before editing, read the theme notes near [Lesson 32](../../../lessons/32_bank-reconciliation-project/README.md).

### Scenario 3: Inspect a Color Highlighted by mini.hipatterns

Since ccc's automatic highlighting is disabled, color swatches in the buffer come from mini.hipatterns. To inspect the actual value, open the picker with `<leader>cp`.

## 6. Exercises

### Exercise 1: Open the Color Picker

1. Open a file containing color values (for example, `~/nvim/lua/config/ui_highlights.lua`).
2. Place the cursor on a value that starts with `#`.
3. Press `<leader>cp`.

**Check**: The picker opens and shows the current color value.

### Exercise 2: Adjust a Color

1. Press `j` / `k` in the picker to adjust a channel.
2. Observe the color value in the buffer update live.
3. Press `<CR>` to confirm.

**Check**: The color value changes.

### Exercise 3: Cancel

1. Press `<leader>cp`.
2. Adjust the value a few times.
3. Press `q` or `<Esc>`.

**Check**: The color value is unchanged; cancellation worked.

### Exercise 4: Convert a Format

1. Place the cursor on `#3b82f6`.
2. Press `<leader>cC`.
3. Choose `rgb`.

**Check**: It becomes something like `rgb(59, 130, 246)`.

### Exercise 5: Confirm the Highlight Comes from mini.hipatterns

1. Open a CSS file and check whether color swatches appear.
2. Inspect the configuration.

```vim
:lua =require("ccc").config.highlighter
```

**Check**: `auto_enable = false`, confirming that ccc did not create the background swatches.

## 7. Troubleshooting

### `<leader>cp` Does Nothing

The cursor must be **on a color value** (such as `#3b82f6`). If there is no color under the cursor, the picker will report that it could not find one.

### There Are No Color Highlights in the Buffer

ccc's automatic highlighting is disabled (`auto_enable = false`); mini.hipatterns provides the highlights. This is intentional, not a malfunction.

**To let ccc highlight colors too**: Set `auto_enable = true` in the configuration, but this will conflict with mini.hipatterns over highlight groups.

### The Converted Format Is Wrong

`<leader>cC` asks you to choose a target format. If you choose the wrong one, undo with `u` and try again.

### Picker Keys Do Not Work as Expected

The picker has its own keys (`h` / `l` to select a channel, `j` / `k` to adjust its value). It is not a regular Vim mode. Press `?` for help, if available.

### `<leader>cp` Cannot Find a Color in a COBOL File

That is expected: COBOL source code does not contain color values. This plugin has limited value for COBOL development and is mainly useful for configuration and CSS files.

## 8. Official Documentation

```vim
:h ccc
:h ccc-options
```

Repository: <https://github.com/uga-rosa/ccc.nvim>

## 9. Scope

- This page describes `lua/plugins/ccc.lua`: `<leader>cp` (color picker) and `<leader>cC` (conversion).
- **Automatic highlighting is disabled** (`auto_enable = false`); color highlights in the buffer come from mini.hipatterns. This avoids a conflict over highlight groups.
- COBOL source code rarely contains color values; this plugin is mainly for configuration files and CSS.
- The course site's CSS uses design tokens, and directly changing color values may break light/dark theme switching.
