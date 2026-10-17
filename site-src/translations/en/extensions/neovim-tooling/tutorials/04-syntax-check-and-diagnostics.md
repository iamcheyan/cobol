# GnuCOBOL Syntax Checking and Neovim Diagnostics

COBOL source has fixed-format, punctuation, and declaration rules. `cobol.nvim` can run GnuCOBOL syntax checks on the current buffer and show recognized problems as Neovim diagnostics.

## How Checks Run

- By default, checks run asynchronously on save, after a 600 ms debounce on text changes, and when leaving Insert mode.
- `<leader>cl` / `:CobolLint` checks the current buffer immediately.
- `<leader>cq` / `:CobolQuickfix` puts current diagnostics in Neovim’s Quickfix list.
- `:CobolDiagnosticsToggle` enables or disables automatic diagnostics.
- When possible, unsaved buffer contents are sent to `cobc` through standard input.
- Copybook diagnostics are associated with the Copybook buffer and the source program’s `COPY` line where possible.

![GnuCOBOL compiler diagnostics in Neovim](images/compiler-diagnostics.png)

The screenshot shows a compiler error for an undefined field beside the source. Diagnostics depend on the output from GnuCOBOL and the plugin’s parser; compiler checks cannot run if `cobc` is missing.

## Quick Walkthrough

Create this small program in a temporary copy, then run `:CobolLint`:

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CHECK-DEMO.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
           DISPLAY WS-COUNT.
           STOP RUN.
```

Temporarily change the reference to `WS-COUNT` to `WS-MISSING`, then wait for the automatic check or run `:CobolLint` again. If the compiler reports the error in a recognized format, Neovim displays a diagnostic. Run `:CobolQuickfix` to view the list and press `<CR>` to jump to an entry. Restore the name and check again to confirm that the diagnostic is gone.

## Configuration

```lua
{
  "iamcheyan/cobol.nvim",
  opts = {
    diagnostics = {
      enable = true,
      on_save = true,
      on_change = true,
      debounce_ms = 600,
      warnings = { "all", "no-obsolete" },
    },
  },
}
```

Set `cobc_command` to choose the compiler and use `cobc_extra_args` to add arguments. A project profile can also set `compiler`, `compiler_args`, `dialect`, and `copybook_paths`. See the plugin help at `:help cobol-projects`.
