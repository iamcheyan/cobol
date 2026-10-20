# Rainbow Delimiters: rainbow-delimiters.nvim

When an `IF ... END-IF` contains a nested `EVALUATE`, indentation alone can make it hard to see which block matches which.

rainbow-delimiters colors **each nesting level of delimiters or keywords differently**, making the nesting easy to see.

---

## 1. What Problem It Solves

| Need | Single-color delimiters | Rainbow delimiters |
|---|---|---|
| See nesting levels | Count spaces | Distinguish by color |
| Find the end of a block | Try `%` one at a time | Matching colors pair up |
| Tell whether delimiters match | Rely on an LSP error | A color change makes it easy to spot |

## 2. Your Configuration

`lua/plugins/rainbow-delimiters.lua`:

```lua
vim.g.rainbow_delimiters = {
  strategy = {
    [""] = rainbow.strategy["global"],
    vim = rainbow.strategy["local"],
  },
  query = {
    [""] = "rainbow-delimiters",
    lua = "rainbow-blocks",
  },
  highlight = {
    "RainbowDelimiterYellow",
    "RainbowDelimiterCyan",
    "RainbowDelimiterBlue",
    "RainbowDelimiterOrange",
    "RainbowDelimiterGreen",
    "RainbowDelimiterViolet",
    "RainbowDelimiterRed",
  },
}
```

| Option | Meaning |
|---|---|
| `strategy[""]` | `global`: calculate nesting consistently across the whole buffer |
| `strategy.vim` | Use `local` for vim files (based on local scope) |
| `query[""]` | Use the `rainbow-delimiters` query by default |
| `query.lua` | Use `rainbow-blocks` for Lua (color blocks rather than delimiters) |
| `highlight` | Cycle through seven colors |

### Seven-Color Cycle

```
Yellow → Cyan → Blue → Orange → Green → Violet → Red → (回到 Yellow)
```

Level 8 has the same color as level 1, though code nested eight levels deep probably needs refactoring anyway.

## 3. What to Expect in COBOL

**Important**: rainbow-delimiters depends on Treesitter queries. COBOL has no parser (see [the Treesitter tutorial](16-treesitter-and-folding.md)), so:

| Language | Rainbow delimiters |
|---|---|
| Lua, Python, JS, and others | **Works** |
| COBOL | **Does not work** |

Structure matching in COBOL is provided by `cobol.nvim` (the `%` jump and structural markers covered in Lesson 02), not by rainbow-delimiters.

**It is expected that you will not see colored delimiters in a COBOL buffer**; this does not mean the configuration is broken.

### Verify

```vim
:InspectTree
```

In a COBOL buffer, Neovim will report that there is no parser.

## 4. Where to See It in Action

Open any Lua file (for example, `~/nvim/lua/plugins/flash.lua`):

```lua
return {
  {                                    ← 第 1 层（Yellow）
    "folke/flash.nvim",
    keys = {
      { "s", function()                 ← 第 2 层（Cyan）
        require("flash").jump()          ← 第 3 层（Blue）
      end, desc = "Flash" },
    },
  },
}
```

Each level's `{` and `}` has a different color.

## 5. Exercises

### Exercise 1: Confirm It Does Not Work in COBOL

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/lesson.cob
```

1. Observe the colors of `IF ... END-IF`.

**Check**: Delimiters and keywords are **not** rainbow-colored because there is no COBOL parser. This is expected.

### Exercise 2: See It in Lua

1. Open `~/nvim/lua/plugins/flash.lua`.
2. Observe the nested `{` and `}`.

**Check**: Different nesting levels have different delimiter colors, cycling through seven colors.

### Exercise 3: Count the Levels

1. Find a four-level nesting in a Lua file.
2. Check whether four colors appear in sequence.

**Check**: You can count the nesting levels by color.

### Exercise 4: Compare with a vim File

1. Open a `.vim` file, if one is available.

**Check**: It uses the `local` strategy, calculating levels by local scope (unlike Lua's `rainbow-blocks`).

### Exercise 5: Confirm the Query Configuration

```vim
:lua =vim.g.rainbow_delimiters.query
```

**Check**: ` [""] = "rainbow-delimiters"` and `lua = "rainbow-blocks"`.

## 6. Troubleshooting

### Nothing Works in COBOL

That is expected. There is no Treesitter COBOL parser. Use `cobol.nvim`'s `%` and the Aerial outline for structure matching.

### There Are Not Enough Colors (More Than Seven Levels)

The seven colors cycle, so level 8 repeats the color of level 1. Consider refactoring code nested more than seven levels deep.

### Conflict with Treesitter Highlighting

Both plugins affect delimiter colors. If the colors look wrong, check whether the theme overrides the `RainbowDelimiter*` groups:

```vim
:hi RainbowDelimiterYellow
```

### Disable It

Remove or comment out the loading of `lua/plugins/rainbow-delimiters.lua`, or add `enabled = false`.

### Lua Is Colored by Block, Not by Delimiter

The configuration has `query.lua = "rainbow-blocks"`, so Lua `function ... end` blocks are colored by block, not just `{}`.

## 7. Official Documentation

```vim
:h rainbow-delimiters
```

Repository: <https://github.com/HiPhish/rainbow-delimiters.nvim>

## 8. Scope

- This page describes `lua/plugins/rainbow-delimiters.lua`: a seven-color cycle, `rainbow-blocks` for Lua, and the `local` strategy for vim.
- **It depends on Treesitter**. COBOL has no parser, so it **does not work in COBOL buffers**.
- COBOL structure matching uses `cobol.nvim` (`%` jumps, the Aerial outline, and structural markers), not this plugin.
- Colors repeat after seven nesting levels.
