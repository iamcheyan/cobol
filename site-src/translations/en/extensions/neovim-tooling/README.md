# Neovim Editor Tutorials

These tutorials cover **the tools actually in use in your local Neovim configuration** across seven groups, including COBOL-specific tools and general editor skills.

- **COBOL-specific** (01–07): fixed-format rulers, structural navigation, PIC calculation and GnuCOBOL diagnostics from `cobol.nvim`.
- **General editor skills** (08–17, 19–35): search, jumping, batch editing, code understanding, Git and sessions.

The two have distinct roles: COBOL tools handle column positions and copybooks; general tools handle search, code navigation and batch editing.

**Not a prerequisite for the main course.** This is optional tooling material, to consult as needed. Tutorials use real files from `extensions/standalone-examples/` and `lessons/`.

## Requirements

| Dependency | Used for |
|---|---|
| Neovim 0.10+ | Everything |
| `cobol.nvim` | 01–07, plus COBOL structure and diagnostics |
| Tree-sitter parser | Highlighting and folding (**COBOL has none**, see 16) |
| GnuCOBOL (`cobc`) | Syntax diagnostics, compilation |
| Aerial, blink.cmp | Optional; their absence does not break anything else |

## Tutorial index

The 34 current guides are ordered by number across 01–37 (guides 18, 36 and 37 have been withdrawn). Categories group adjacent guides so you can find one quickly.

### 1. COBOL-specific: `cobol.nvim`

| # | Topic | What you learn |
|---|---|---|
| [01](tutorials/01-punchcard-and-ruler.md) | Fixed-format columns and the ruler | What columns 7/8/12/73 mean, overflow warnings |
| [02](tutorials/02-structure-and-navigation.md) | Structure overview, outline, definition jumps | `gd` / `gf` / `K`, Aerial outline |
| [03](tutorials/03-pic-and-memory-calculator.md) | PIC and memory calculation | Estimating bytes with `:CobolCalcRecord` |
| [04](tutorials/04-syntax-check-and-diagnostics.md) | Syntax checking and diagnostics | `cobc` diagnostics inside the editor |
| [05](tutorials/05-compilation-and-workflow.md) | Compilation and workflow | Build, run, locate errors |
| [06](tutorials/06-practical-examples-guide.md) | Practical examples | Four standalone examples with the plugin |
| [07](tutorials/07-cobol-nvim-plugin-lab.md) | Plugin lab | Combined practice |

### 2. Find and change: multi-cursor, search and replace

| # | Topic | What you learn |
|---|---|---|
| [08](tutorials/08-multicursor-batch-editing.md) | Multi-cursor batch editing | `gaip`, `ciW`, `C`, `ci"`, `g<C-a>` |
| [09](tutorials/09-snacks-picker.md) | File and content search (snacks picker) | `ff`/`fg`/`fw`, picker internals, quickfix hand-off |
| [10](tutorials/10-flash-jump.md) | On-screen jumping (flash) | `s`/`S`, combining with operators |
| [11](tutorials/11-grug-far.md) | Cross-file search and replace (grug-far) | `<leader>sr`, match-count safety check, staged replacement |

### 3. Editing helpers

| # | Topic | What you learn |
|---|---|---|
| [12](tutorials/12-mini-ai-textobjects.md) | Text objects (mini.ai) | Semantic boundaries, `cia`/`ciq`/`g` |
| [13](tutorials/13-mini-surround.md) | Surrounds (mini.surround) | `gsa`/`gsd`/`gsr` |
| [14](tutorials/14-smart-paste.md) | Smart paste | Keep relative indent, rebase to the current line |

### 4. Understanding code

| # | Topic | What you learn |
|---|---|---|
| [15](tutorials/15-lsp-code-intelligence.md) | LSP code intelligence | Jump/references/rename, **COBOL has no LSP** |
| [16](tutorials/16-treesitter-and-folding.md) | Treesitter and folding | Treesitter limits, where COBOL folding comes from |
| [17](tutorials/17-aerial-outline.md) | Code outline (aerial) | `<leader>cs`, the COBOL-specific backend |

### 5. Git

| # | Topic | What you learn |
|---|---|---|
| [19](tutorials/19-gitsigns.md) | Line-level Git operations | Stage/reset hunks, blame |
| [20](tutorials/20-diffview.md) | Full diffs and history | Side-by-side diff, file history |

### 6. Sessions and discovery

| # | Topic | What you learn |
|---|---|---|
| [21](tutorials/21-auto-session.md) | Session save and restore | Per-directory layouts |
| [22](tutorials/22-which-key.md) | Key discovery | `<leader>` plus a pause, drill down layer by layer |
| [23](tutorials/23-quicker.md) | quickfix context expansion | `>`/`<` to expand result context |

### 7. Interface and appearance

| # | Topic | What you learn |
|---|---|---|
| [24](tutorials/24-bufferline.md) | Buffer tab line | Tabs at the top, modification markers |
| [25](tutorials/25-noice.md) | Messages and cmdline | Cmdline, yank toast, confirm dialog |
| [26](tutorials/26-dashboard.md) | Start screen | Recent files, shortcuts |
| [27](tutorials/27-ccc-color.md) | Colour editing | Picker, format conversion |
| [28](tutorials/28-satellite.md) | Scrollbar markers | Where changes, diagnostics and matches are |
| [29](tutorials/29-rainbow-delimiters.md) | Rainbow delimiters | Colouring nesting levels |
| [30](tutorials/30-markview.md) | Markdown rendering | Headings, tables, code blocks |

### 8. Helpers and others

| # | Topic | What you learn |
|---|---|---|
| [31](tutorials/31-mini-pairs.md) | Auto-pairs | Auto-close and skip for `(` and `"` |
| [32](tutorials/32-contextline.md) | Breadcrumb dropdown | Structure menu (usually empty for COBOL) |
| [33](tutorials/33-bookmark.md) | Bookmarks | Mark positions, `]b` / `[b` to jump |
| [34](tutorials/34-batch-and-shellcheck.md) | Batch and Shell lint | `.bat` support, `shellcheck` diagnostics |
| [35](tutorials/35-vimquest.md) | English vocabulary drill | Practice English in code (does not affect coding) |

## Suggested order

**If time is short**, these four cover 80% of daily work:

1. **[22 which-key](tutorials/22-which-key.md)** — learn how to find the other keys first
2. **[09 snacks picker](tutorials/09-snacks-picker.md)** — find files, search content
3. **[19 gitsigns](tutorials/19-gitsigns.md)** — see exactly what you changed
4. **[08 multi-cursor](tutorials/08-multicursor-batch-editing.md)** — change many places at once

**Working on COBOL code**, add:

5. [01 column rules](tutorials/01-punchcard-and-ruler.md) — the basis of fixed format
6. [17 aerial](tutorials/17-aerial-outline.md) — COBOL paragraph structure

**Editing course documentation**, add:

7. [11 grug-far](tutorials/11-grug-far.md) — cross-file batch replacement
8. [20 diffview](tutorials/20-diffview.md) — reviewing changes

## How to read these

Every page follows the same shape:

| Section | Content |
|---|---|
| What problem it solves | A comparison table showing the cost of not using it |
| Your actual configuration | Real config pulled from `lua/plugins/*.lua` |
| Key table | Keys that actually work in your setup |
| Measured observations | What a real session showed (marked "measured") |
| Exercises | Concrete steps with **acceptance criteria** |
| Pitfalls | Common failure causes |
| Official documentation | `:help` topics and repository links |
| Limits | Which restrictions come from your config rather than plugin defaults |

**"Measured" only appears where something was actually run.** Unverified steps are explicitly marked as "practise first" or "not verified".

## Relationship to the main course

The 32-lesson course teaches COBOL itself. These tutorials teach **how to write and change COBOL efficiently in an editor**.

- The main course does not depend on these tutorials.
- But these tutorials repeatedly use files from the main course (lesson 17's fixed-length records, lesson 20's matching, lesson 32's capstone).
- Recommendation: **read the relevant course section first, then practise with the tutorial.**

## References

- Neovim documentation: `:help`
- Your config repository: `~/nvim`
- Per-plugin quick reference: `~/nvim/docs/plugins/PLUGINS.md` (47 plugins, five short sections each — shallower but broader than these tutorials)
