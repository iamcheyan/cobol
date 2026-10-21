# Batch Scripts and Shell Checking: batch.nvim / nvim-lint

The COBOL course includes many `.sh` scripts (`build.sh`, `check.sh`, `install-toolchain.sh`). They are code that you may need to read too.

This configuration provides language support and linting for batch scripts (`.bat`/`.cmd`) and Shell scripts.

---

## 1. What Problem They Solve

| Need | Without support | With support |
|---|---|---|
| Syntax highlighting for `.bat` files | Plain text | Provided by `batch.nvim` |
| Outline for `.bat` files | None | Provided by `batch.nvim` |
| Find errors in Shell scripts | Discover them only at runtime | Live feedback from `shellcheck` |

## 2. batch.nvim (Windows Batch Files)

`lua/plugins/batch.lua`:

| Option | Value | Meaning |
|---|---|---|
| `enable_diagnostics` | `true` | Enable diagnostics |
| `enable_folding` | `true` | Enable folding |
| `enable_statusline` | `true` | Show information in the statusline |
| `map_keys` | `false` | **Don't map any keys** |

`ft = { "dosbatch" }` — only active for the dosbatch filetype.

`map_keys = false` is an important choice: **it doesn't take over your keys**. Access all features through commands or Aerial.

### Working with Aerial

In the configuration, `batch.nvim` is a dependency of `contextline.nvim`, and Aerial's backend configuration includes:

```lua
dosbatch = { "batch" },
batch = { "batch" },
```

So you can view the structure of `.bat` files in Aerial (`<leader>cs`).

### Where It Fits in the COBOL Course

The course is mainly about Linux and Shell, but it also covers batch-related topics. `extensions/enterprise-batch/` is a course on enterprise batch processing (COBOL batch processing, not Windows `.bat` files).

## 3. nvim-lint + shellcheck (Shell Scripts)

`lua/plugins/shellcheck.lua`:

```lua
lint.linters_by_ft = {
  sh = { "shellcheck" },
  bash = { "shellcheck" },
}
```

When linting runs:

```lua
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  callback = function(args)
    if vim.tbl_contains({ "sh", "bash" }, vim.bo[args.buf].filetype) then
      lint.try_lint("shellcheck")
    end
  end,
})
```

| Event | Action |
|---|---|
| `BufEnter` | Check when entering a buffer |
| `BufWritePost` | Check after saving |
| `InsertLeave` | Check after leaving Insert mode |

### Requirement: `shellcheck` Must Be Installed

```sh
which shellcheck
```

If it isn't installed, linting silently skips it (no error or notification).

Install it with:

```sh
sudo apt install shellcheck
```

### How Diagnostics Appear

`shellcheck` warnings appear as diagnostics (inline marks), like `cobc` diagnostics:

- Word splitting caused by missing quotes
- Unused variables
- Portability issues
- Common typos

## 4. Practical Value in the COBOL Course

### Scenario 1: Check Course Scripts

The course includes:

```sh
lessons/32_bank-reconciliation-project/build.sh
lessons/32_bank-reconciliation-project/check.sh
lessons/29_embedded-sql/install-toolchain.sh
extensions/standalone-examples/ 里的 Makefile 相关脚本
```

Open a `.sh` file and `shellcheck` will flag potential issues.

### Scenario 2: Write a Build Script

When editing `build.sh`, saving triggers a check, so you don't have to run it to discover syntax issues.

### Scenario 3: Learn Shell Best Practices

`shellcheck`'s feedback is itself a Shell tutorial—it explains why a particular construct can be risky.

## 5. Exercises

### Exercise 1: Check Whether shellcheck Is Installed

```sh
which shellcheck || echo "not installed"
```

**Check**: If installed, it prints the path; otherwise, it prints a message.

### Exercise 2: Open a Script and Inspect Diagnostics

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/build.sh
```

1. Check whether there are diagnostic marks
2. Save once (`:w`) to make sure linting runs

**Check**: Diagnostic marks appear if the script has issues. No marks means no issues (both results are normal).

### Exercise 3: Intentionally Introduce an Issue

1. Add `echo $UNQUOTED_VAR` to the script (without quotes)
2. Run `:w`
3. Observe

**Check**: `shellcheck` says the variable should be quoted. Remove the change and the mark disappears.

### Exercise 4: Confirm It Applies Only to sh/bash

1. Open a `.cob` file
2. Intentionally type something
3. Run `:w`

**Check**: There are **no** shellcheck diagnostics (it applies only to sh/bash).

### Exercise 5: Confirm batch.nvim Doesn't Take Over Keys

```vim
:verbose nmap <buffer>
```

In a `.bat` file (if one is available), confirm that batch.nvim has no mappings (`map_keys = false`).

## 6. Common Issues

### shellcheck Doesn't Run

Check:

1. Is `shellcheck` installed? Run `which shellcheck`
2. Is the filetype `sh` or `bash`? Run `set ft?`

If it isn't installed, linting silently skips it.

### There Are Too Many Diagnostics

By default, `shellcheck` checks rigorously. You can disable an individual check in the script with a comment:

```sh
# shellcheck disable=SC2086
```

Or configure the `-e` option for `shellcheck`.

### `.bat` Files Don't Have Highlighting

`batch.nvim` is restricted by `ft = { "dosbatch" }`. Check the filetype:

```vim
:set ft?
```

### batch.nvim Doesn't Add Mappings

**This is intentional** (`map_keys = false`). Use Aerial or commands to access its features.

### Linting a Large Script Is Slow

`shellcheck` is an external process. Very large scripts may pause briefly. That's normal.

## 7. Official Documentation

- `nvim-lint`: <https://github.com/mfussenegger/nvim-lint>
- `batch.nvim`: <https://github.com/iamcheyan/batch.nvim>
- `shellcheck`: <https://www.shellcheck.net/>

## 8. Boundaries

- `shellcheck` must be installed externally; if it isn't, linting **silently skips it** (no error).
- nvim-lint applies only to `sh` / `bash`, independently of other filetypes.
- `map_keys = false` in `batch.nvim` is an intentional choice to avoid taking over keys.
- The course is mainly about COBOL, with Shell scripts as supporting material; these two tools provide useful extra support.
