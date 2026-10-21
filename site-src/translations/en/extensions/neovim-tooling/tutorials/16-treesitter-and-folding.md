# Syntax Parsing and Folding: nvim-treesitter

Regex highlighting only recognizes “there is an `IF` on this line.” Treesitter recognizes “where this `IF` ends.” That difference determines whether folding, text objects, and structural navigation work correctly.

---

## 1. What Problem It Solves

| Need | Regex approach | Treesitter |
|---|---|---|
| Syntax highlighting | Keyword matching; nesting can be wrong | Accurate, based on the syntax tree |
| Folding | Guesses based on indentation | Uses the actual `IF ... END-IF` range |
| Text objects | Limited to character boundaries | Based on syntax nodes |
| Structural navigation | Search for keywords | Traverse the syntax tree |

A COBOL `IF` / `END-IF` block can span dozens of lines and be nested several levels deep. Regex-based folding is completely unreliable here.

## 2. Your Configuration

`lua/plugins/treesitter.lua`; the `ensure_installed` list contains 28 languages:

```text
bash c diff go html javascript java jsdoc json lua luadoc luap
markdown markdown_inline printf python query regex ruby sql
toml tsx typescript vim vimdoc xml yaml
```

**Note: `cobol` is not in the list.**

### The Reality for COBOL

| Capability | Available for COBOL? |
|---|---|
| Syntax highlighting | Partial (using regex highlighting from `cobol.nvim`) |
| Folding | **Available** (`cobol.nvim` implements Division/Section/Paragraph folding itself) |
| Treesitter text objects | **Unavailable** (`mini.ai` configuration explicitly returns empty) |
| Flash `S` key | Available; currently performs a regular character jump, not node selection |

`cobol.nvim` documents this in its configuration:

```lua
function M.attach(bufnr)
  setup_comment_syntax(bufnr)
  setup_folding(bufnr)
  ...
```

Folding is provided by the plugin's own `folding.lua`; it does not depend on Treesitter.

### What Happens If You Install the COBOL Parser

The plugin repository includes a `tree-sitter-cobol` subdirectory that you can compile yourself:

```sh
cd ~/development/cobol.nvim/tree-sitter-cobol
make
```

After installation, the parser is available to Treesitter consumers; Flash `S` currently performs a regular character jump, while some mini.ai Treesitter objects remain guarded for COBOL.

## 3. Folding (nvim-ufo)

In `lua/plugins/ufo.lua`, the provider is `{ "treesitter", "indent" }`:

1. It prefers folding ranges from Treesitter.
2. If Treesitter is unavailable, it falls back to indentation-based folding.

For COBOL, `cobol.nvim` takes over folding first and sets `foldtext` to `"auto"`: when n-ufo manages the buffer, it renders the fold text itself; otherwise, the plugin's summary format is used.

### Folding Keys

| Key | Action |
|---|---|
| `za` | Toggle the current fold |
| `zc` | Close |
| `zo` | Open |
| `zR` | Open all |
| `zM` | Close all |
| `zr` / `zm` | Expand/collapse one level at a time |

### Fold Display

n-ufo's custom summary looks like this:

```text
+-- 12 lines 󰁂
```

It shows the number of folded lines.

## 4. Syntax Highlighting

### Enable/Disable

```vim
:TSBufEnable highlight
:TSBufDisable highlight
```

You generally do not need to manage this manually; it is enabled automatically when a file is opened.

### Check the Parser Status for the Current Buffer

```vim
:InspectTree
```

Displays the syntax tree. If the COBOL buffer has no parser, you will be notified.

### Install a New Parser

```vim
:TSInstall python
:TSUpdate
```

Parsers in the `ensure_installed` list are installed automatically; install other parsers manually.

## 5. The Actual COBOL Experience

### What Works

- **Folding** (the three levels Division/Section/Paragraph from `cobol.nvim`)
- **Syntax highlighting** (keyword highlighting + hierarchy highlighting from `cobol.nvim`)
- **Warnings when code exceeds column 72**

### What Does Not Work

- Treesitter text objects (`iao`, `iaf`, `iac`)
- Flash Treesitter node selection (the current `S` mapping uses regular character jump instead)
- Syntax matching with `%` (`cobol.nvim` has its own `%` implementation for jumping between `IF`/`END-IF`)

**COBOL's structural features come from `cobol.nvim`, not Treesitter.** Understanding this avoids a lot of confusion about “why it doesn't work for me when the documentation says it should.”

## 6. Exercises

### Exercise 1: Compare Folding Quality

```sh
cd ~/development/cobol
nvim lessons/26_error-handling/lesson.cob
```

1. Find an `IF ... END-IF` block.
2. Press `zc` to close it.
3. Check whether the fold range is exactly from `IF` to `END-IF`.

**Acceptance criteria**: The fold boundary aligns with `END-IF`; it is not guessed from indentation.

### Exercise 2: Check Whether COBOL Has a Parser

1. Run `:InspectTree`.
2. Observe the output.

**Acceptance criteria**: You are told that no cobol parser was found (because it is not in `ensure_installed`), or an incomplete tree is displayed.

### Exercise 3: Compare with a Language That Has a Parser

1. Open any `.lua` file.
2. Run `:InspectTree`.

**Acceptance criteria**: A complete syntax tree appears, and you can expand its nodes.

### Exercise 4: Try Installing a Parser

```vim
:TSInstall python
```

Then use `:InspectTree` to view the syntax tree for a Python file.

**Acceptance criteria**: You can see the complete syntax structure. This helps illustrate the difference between having a parser and not having one.

### Exercise 5: Fold Everything

1. Open a long COBOL file.
2. Press `zM` to fold everything.
3. Inspect each fold's summary line.

**Acceptance criteria**: The summary shows the line count (`⋯ N lines`), making the file structure easy to scan.

## 7. Pitfalls

### Flash Keys in COBOL

Both `S` and `s` invoke Flash character jump. `S` no longer selects Treesitter nodes, so it will not behave like a large structural selection.

### Syntax Highlighting Is Wrong

COBOL highlighting comes from the regex implementation in `cobol.nvim`, not Treesitter. Some structures may not be highlighted completely. This is a known limitation.

### `:TSInstall` Fails

You need a build toolchain (`tree-sitter-cli` or a C compiler). Check with:

```sh
cc --version
```

### ufo and cobol.nvim Are Competing Over Folding

`foldtext = "auto"` in `cobol.nvim` detects whether ufo is managing the fold. If the fold display looks wrong, check:

```vim
:set foldmethod?
```

In a COBOL buffer, it should be `expr` (set by the plugin).

### Restart After Installing a Parser

A newly installed parser takes effect after you reopen the buffer. Alternatively, run:

```vim
:edit
```

## 8. Official Documentation

```vim
:h treesitter
:h nvim-ufo
```

- `nvim-treesitter`: <https://github.com/nvim-treesitter/nvim-treesitter>
- `nvim-ufo`: <https://github.com/kevinhwang91/nvim-ufo>

## 9. Boundaries

- The `ensure_installed` list (`lua/plugins/treesitter.lua`) does not include `cobol`; the local parser is installed by the `cobol.nvim` build script. COBOL folding and most highlighting come from `cobol.nvim`.
- mini.ai Treesitter text objects still return no objects for COBOL; Flash `S` is a regular character jump and does not rely on that parser.
- This tutorial does not cover the full process of compiling the parser manually; that falls under plugin development. See `scripts/build_parser.sh` in the `cobol.nvim` repository.
