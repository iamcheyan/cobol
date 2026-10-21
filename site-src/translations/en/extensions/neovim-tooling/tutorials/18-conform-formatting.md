# Code Formatting: conform.nvim

The goal of formatting is not to “make things look nice”; it is **to keep diffs focused on real changes**. If every save rearranges whitespace, code review becomes noise.

conform.nvim calls the appropriate formatter for each file type and respects a global toggle.

---

## 1. What Problem It Solves

| Need | Without conform | With conform |
|---|---|---|
| Format automatically on save | Configure a different plugin for each language | One configuration handles all languages |
| Format manually | Remember commands like `:!stylua %` | `<leader>F` |
| Temporarily disable formatting | Edit the configuration | Toggle with `<leader>uf` |
| Find an available formatter | Look it up yourself | `:ConformInfo` |

![The save path: `autoformat` defaults to `false`, so saving never formats. Either run `<leader>F` manually or flip the toggle first.](images/18-conform-decision.png)

The save path: `autoformat` defaults to `false`, so saving never formats. Either run `<leader>F` manually or flip the toggle first.

## 2. Your Configuration

`lua/plugins/conform.lua`:

```lua
keys = {
  {
    "<leader>F",
    function()
      require("conform").format({ async = true, lsp_fallback = true })
    end,
    mode = { "n", "x" },
    desc = "Format (conform)",
  },
},
```

### Formatters by Language

| File type | Tool |
|---|---|
| `lua` | `stylua` |
| `sh` / `bash` / `zsh` | `shfmt` |
| `python` | `ruff_fix` → `ruff_format` |
| `javascript` / `typescript` / `tsx` | `prettierd` → `prettier` (`stop_after_first`) |
| `css` / `html` / `json` / `yaml` / `markdown` | `prettierd` → `prettier` |
| `rust` | `rustfmt` |
| `go` | `gofumpt` → `goimports` |
| `c` / `cpp` | `clang_format` |

**Note: `cobol` is not in the list.**

### Automatic Formatting on Save: Disabled by Default

```lua
format_on_save = function(bufnr)
  if vim.g.autoformat == false then
    return nil
  end
  return { timeout_ms = 500, lsp_fallback = true }
end,
```

```lua
init = function()
  vim.g.autoformat = false
end,
```

**`autoformat = false` by default**, so files are not automatically formatted on save. This is intentional—COBOL is sensitive to column positions, so automatic formatting is too risky.

A comment in the configuration explains why the function form is used:

```lua
-- The function form is evaluated on each save, so toggling takes effect
-- immediately instead of being frozen at startup.
```

The function is evaluated on every save, so changes to the toggle take effect immediately.

## 3. Usage

### Format Manually

| Key | Action |
|---|---|
| `<leader>F` | Format the current buffer (in `n` / `x` mode) |

In visual mode, only the selected range is formatted.

### See Which Formatters Are Available

```vim
:ConformInfo
```

Shows which formatter the current buffer uses, whether it is installed, and its path.

### Toggle Automatic Formatting

| Key | Action |
|---|---|
| `<leader>uf` | Toggle automatic formatting globally |
| `<leader>uF` | Toggle it for the current buffer |

(These two keys come from LazyVim-style UI toggles; the configuration notes that conform respects them.)

## 4. COBOL

**There is no COBOL formatter.** Reasons:

1. There is no standard COBOL formatter (unlike `gofmt` for Go).
2. COBOL fixed format imposes strict column requirements, which automatic reflow can easily break.
3. `cobol.nvim` provides `:CobolFormatCase` (capitalizes reserved words only); it does not reflow code.

### Alternatives for COBOL

| What you want to do | Tool |
|---|---|
| Capitalize reserved words consistently | `:CobolFormatCase` (`cobol.nvim`) |
| Align indentation | Manually, or use smart Tab in `cobol.nvim` |
| Check column positions | Overflow highlighting from `cobol.nvim` + an `awk` check |
| Validate syntax | `cobc -fsyntax-only` |

“Formatting” COBOL code is **essentially a manual task**. That is the reality of the language.

### Check Column Positions (An Alternative to Formatting)

Lesson 17 provides three `awk` commands that you can turn into shortcuts:

```sh
LC_ALL=C awk '/^      \*/ {next} {if (length($0)>72) print "over72", NR, length($0)}' lesson.cob
LC_ALL=C awk '/^      \*/ {next} {i=match($0,/[^ ]/); if (i>0 && i<12 && i!=8 && i!=11) print "bad column", NR, i}' lesson.cob
```

## 5. Exercises

### Exercise 1: See Which Formatter the Current File Uses

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. Run `:ConformInfo`.
2. Inspect the output.

**Acceptance criteria**: The COBOL buffer shows that no formatter is available.

### Exercise 2: Compare with a Language That Has a Formatter

1. Open any `.lua` file.
2. Run `:ConformInfo`.

**Acceptance criteria**: It shows `stylua` and its path.

### Exercise 3: Format Manually

In a Lua file:

1. Intentionally mess up the indentation.
2. Press `<leader>F`.
3. Observe the indentation being corrected.

**Acceptance criteria**: The file returns to standard indentation.

### Exercise 4: Verify That Automatic Formatting Is Disabled by Default

1. Open a `.lua` file.
2. Change the indentation on one line.
3. Run `:w`.
4. Check whether the indentation was automatically corrected.

**Acceptance criteria**: **It was not corrected**, because `autoformat = false`.

### Exercise 5: Toggle Automatic Formatting

1. Press `<leader>uf` to enable automatic formatting.
2. Change the indentation on another line.
3. Run `:w`.

**Acceptance criteria**: This time the file is automatically formatted on save. Press `<leader>uf` again to turn it back off.

### Exercise 6: Try the COBOL Formatting Alternative

1. Open a COBOL file.
2. Run `:CobolFormatCase`.
3. Check whether the reserved words became uppercase.

**Acceptance criteria**: `move`, `display`, and similar words become `MOVE`, `DISPLAY`, while indentation and column positions remain unchanged.

## 6. Pitfalls

### `<leader>F` Does Nothing

Check `ConformInfo` to see whether a formatter is available. If not, formatting is silently skipped (a configuration comment notes that conform itself will warn `Formatter 'stylua' unavailable`).

### The File Is Not Formatted on Save

It is disabled by default (`vim.g.autoformat = false`). Enable it with `<leader>uf`, or format manually with `<leader>F`.

### `<leader>F` Does Nothing in a COBOL Buffer

There is no COBOL formatter. This is expected; nothing is broken.

### The Diff Is Huge After Formatting

The formatter may not match the existing style. **Inspect the changes with `git diff` first**; if you do not want them, restore them with `git checkout --`.

**This is the value of `autoformat = false`**: it prevents accidental large-scale reformatting.

### `prettierd` Cannot Be Found

`prettierd` is the daemon version of prettier. If it is not installed, conform falls back to `prettier` (`stop_after_first = true` in the configuration ensures this).

## 7. Official Documentation

```vim
:h conform
:h conform-options
```

Repository: <https://github.com/stevearc/conform.nvim>

## 8. Boundaries

- The configuration comes from `lua/plugins/conform.lua`: it supports 12 file types and **does not include COBOL**.
- **Automatic formatting is disabled by default** (`vim.g.autoformat = false`). This is intentional because COBOL is sensitive to column positions.
- COBOL “formatting” is limited to `:CobolFormatCase` (capitalizing reserved words), manual indentation, and `awk` column checks.
- `format_on_save` uses the function form, so the `<leader>uf` toggle takes effect immediately without a restart.
