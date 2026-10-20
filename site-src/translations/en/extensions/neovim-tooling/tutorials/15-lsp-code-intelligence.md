# Language Servers: LSP and Code Intelligence

`cobol.nvim` provides COBOL-specific features (rulers, structure, PIC calculations). **LSP provides general code intelligence**: go to definition, find references, rename, diagnostics, and code actions.

They complement each other. COBOL has no official LSP server, but your configuration fills part of that gap with GnuCOBOL compiler diagnostics—this is the diagnostics module in `cobol.nvim`.

---

## 1. What problem does it solve?

| Need | Without LSP | With LSP |
|---|---|---|
| Go to definition | Search globally or use `ctags` | Jump with `gd` |
| Find all references | Run grep and inspect the results yourself | List with `gr` |
| Rename | Manually change every occurrence | Change all at once with `<leader>cr` |
| See a function signature | Look it up in the docs | Floating window with `gK` |
| Fix lint issues | Look them up manually | Code action with `<leader>ca` |
| See errors | Read compiler output afterward | Live inline marks |

## 2. Your configuration

`lua/plugins/lsp.lua`. Key mappings are registered dynamically based on **server capabilities**—a key isn't mapped for a feature that a given server doesn't support.

### Navigation

| Key | Effect | Requirement |
|---|---|---|
| `gd` | Go to definition | `definitionProvider` available |
| `gr` | Show references | `referencesProvider` available |
| `gy` | Go to type definition | `typeDefinitionProvider` available |
| `gI` | Go to implementation | `implementationProvider` available |
| `K` | Hover documentation | `hoverProvider` available |
| `gK` | Signature help | `signatureHelpProvider` available |
| `<C-k>` | Signature help (Insert mode) | Same |

### Editing

| Key | Effect | Requirement |
|---|---|---|
| `<leader>ca` | Code action (`n` / `x` mode) | `codeActionProvider` available |
| `<leader>cr` | Rename symbol | `renameProvider` available |
| `<leader>cR` | Rename file | Snacks |
| `<leader>co` | Organize imports | — |

### Information

| Key | Effect |
|---|---|
| `<leader>cl` | LSP configuration for the current buffer (which server is running) |
| `<leader>cm` | Open Mason (manage servers and tools) |

### Reference navigation

| Key | Effect |
|---|---|
| `]]` | Next reference |
| `[[` | Previous reference |
| `<a-n>` | Next reference (momentary highlight) |
| `<a-p>` | Previous reference |

These four use `Snacks.words`. They're lighter-weight than LSP references and are useful for quickly scanning occurrences of a symbol with the same name.

## 3. The situation with COBOL

**COBOL has no LSP server.** So:

| Feature | What to use in COBOL |
|---|---|
| Go to definition | `cobol.nvim`'s `gd` / `:CobolGotoDef` |
| Go to Copybook | `cobol.nvim`'s `gf` / `:CobolGotoCopybook` |
| Preview definition | `cobol.nvim`'s `K` / `:CobolPreview` |
| Syntax diagnostics | `cobol.nvim` invokes `cobc -fsyntax-only` |
| Structure outline | `cobol.nvim` provides an Aerial backend |
| Rename | **Unavailable**; use grug-far or grep + multicursor |

**So COBOL's `gd` and `K` are implemented by `cobol.nvim`, not LSP.** This is easy to confuse because two plugins map the same keys.

See which handler is active in the current buffer:

```vim
:lua =vim.lsp.get_clients({ bufnr = 0 })
```

An empty table in a COBOL buffer means no LSP is running; `gd` is handled by `cobol.nvim`.

## 4. Which languages have LSP?

The configuration uses `mason-lspconfig` to install servers automatically. See what's installed with:

```vim
:Mason
```

Common servers include Lua, Python, TypeScript, Bash, JSON, YAML, and others. **COBOL isn't on the list** because no server is available.

### Check whether a filetype has an LSP

```vim
:lua =vim.lsp.get_clients({ bufnr = 0 })
```

An empty table means none is running.

### Install a new server

```vim
:Mason
```

Search in the interface and press `i` to install. Restart Neovim when it's done.

## 5. Diagnostics

LSP diagnostics and GnuCOBOL diagnostics are separate mechanisms, though they appear the same way (inline marks):

| Source | Trigger | Content |
|---|---|---|
| LSP server | Live | Type errors, undefined symbols |
| `cobol.nvim` diagnostics | Save, debounced edits, leaving Insert mode | `cobc` syntax errors and warnings |

### Diagnostic keys

| Key | Effect |
|---|---|
| `]d` / `[d` | Next / previous diagnostic |
| `<leader>cd` | Show diagnostic for the current line (floating window) |
| `<leader>xq` | Send diagnostics to quickfix |

In COBOL, diagnostics come from `cobc`. Run this to see them:

```vim
:CobolLint
```

## 6. Exercises

### Exercise 1: Confirm that COBOL has no LSP

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. Run `:lua =vim.lsp.get_clients({ bufnr = 0 })`.
2. Look at the return value.

**Check**: It returns an empty table `{}`, confirming that COBOL has no LSP.

### Exercise 2: Compare with a language that has an LSP

1. Open any `.lua` file (for example, `~/.config/nvim/lua/plugins/flash.lua`).
2. Run `:lua =vim.lsp.get_clients({ bufnr = 0 })`.
3. Look at the return value.

**Check**: You should see server information such as `lua_ls`. Compare it with Exercise 1 to understand the difference.

### Exercise 3: LSP navigation

In a Lua file:

1. Put the cursor on a function call.
2. Press `gd`.

**Check**: It jumps to the function definition, and `<C-o>` returns to the previous location.

### Exercise 4: Rename

In a Lua file:

1. Put the cursor on a variable.
2. Press `<leader>cr`.
3. Enter a new name and press Enter.

**Check**: All references are changed. **This key isn't available in COBOL** because there is no `renameProvider`.

### Exercise 5: View COBOL diagnostics

1. Open a COBOL file.
2. Deliberately remove a period.
3. Save (`:w`).
4. Check for a diagnostic mark.

**Check**: An error mark appears, and `<leader>cd` shows the `cobc` error message. Undo with `u`.

## 7. Pitfalls

### `gd` in COBOL looks like LSP navigation, but isn't

It's `cobol.nvim`'s `:CobolGotoDef`. The behavior is similar, but the implementation is different. **If navigation fails, first check which plugin is handling the key**:

```vim
:verbose nmap gd
```

The output shows where the mapping came from.

### `<leader>cr` does nothing in COBOL

There is no `renameProvider`, so the key isn't registered by LSP. Use grug-far (`<leader>sr`) or grep + multicursor instead.

**Note**: In `cobol.nvim`, `<leader>cr` means “calculate record layout” (`:CobolCalcRecord`), which collides with LSP rename. In a COBOL buffer, the `cobol.nvim` mapping is the one that runs.

### Mason can't install a server

This may be due to a network issue or a missing system dependency. Press `?` in the `:Mason` interface for help, or check `:MasonLog`.

### Diagnostics don't update

LSP diagnostics are asynchronous, so wait a moment after editing. COBOL diagnostics are triggered by `cobol.nvim` on save or after a debounce, with `on_change = true` and `debounce_ms = 600`.

## 8. Official documentation

```vim
:h lsp
:h lsp-config
:h vim.lsp.buf
```

- `nvim-lspconfig`: <https://github.com/neovim/nvim-lspconfig>
- `mason.nvim`: <https://github.com/mason-org/mason.nvim>

## 9. Boundaries

- The mappings in this article come from your configuration (`lua/plugins/lsp.lua`) and are **registered dynamically based on server capabilities**—a key isn't mapped for features a server doesn't support.
- **COBOL has no LSP server.** COBOL's `gd`, `K`, `gf`, and diagnostics come from `cobol.nvim`, not LSP.
- `<leader>cr` is used by `cobol.nvim` in COBOL buffers for record layout calculations; it is a different function from LSP rename.
- LSP diagnostics and `cobc` diagnostics are separate mechanisms; COBOL uses only the latter.
