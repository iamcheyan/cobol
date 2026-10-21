# Add Cursors by Line: multicursor-line.nvim

`multicursor-line.nvim` is a Neovim plugin we developed. It turns Vim's selected lines or rectangular area into a set of cursors at consistent positions: before each line's first non-blank character, at absolute column zero, at each line's end, or alternating between line ends and starts. Select a range, press one mapping, then edit at all those positions together.

This is a standalone guide to the plugin, separate from `multicursor.nvim`. It follows the local `lua/plugins/multicursor-line.lua` configuration and the plugin implementation.

## 1. Select a Range, Then Add Cursors

The basic workflow:

1. Select the lines with native Vim motions: `Vj` for two lines, `vip` for the current paragraph, or `ggVG` for the whole file.
2. In Visual mode, press a layout mapping such as `<leader>mh`.
3. The plugin places a cursor at the corresponding position on each selected line.
4. Press `i` or `a` to type at all cursors; backspace is synchronized too.
5. Press `<Esc>` to finish the multi-cursor edit.

The key idea is “select first, apply second”: the plugin only processes the selected lines. It does not guess which lines you intend to change.

![multicursor-line.nvim places three cursors before the first character of three COBOL declarations; the status line reads “head (3 lines)”.](images/37-multicursor-line.png)

This real capture uses the native backend: it skips the indentation spaces and places each cursor before `01`. Press `i` to begin synchronized input.

## 2. Five Cursor Layouts

| Layout | Position | Common mappings |
|---|---|---|
| Smart head (`head`) | Before the first non-blank character on each line, skipping indentation | Visual mode `<leader>h`; Normal mode `<leader>mh` |
| Absolute beginning of line (`bol`) | Column 0, before indentation | Visual mode `<leader>H` / `<leader>0`; Normal mode `<leader>mH` / `<leader>m0` |
| Tail (`tail`) | After the last character on each line | Visual mode `<leader>t`; Normal mode `<leader>mt` |
| Alternating head and tail | Alternates between line end and first non-blank character | Visual mode `<leader>a`; Normal mode `<leader>ma` |
| Alternating absolute BOL and tail | Alternates between line end and column 0 | Visual mode `<leader>A`; Normal mode `<leader>mA` |

Visual-mode mappings are useful when you want to mark the range precisely. The `<leader>m…` mnemonic mappings are also registered in Normal mode and use the current line plus an optional count to determine the range. Visual block mode (`<C-v>`) can also define a rectangular selection.

## 3. Batch Insert at COBOL Line Starts

For example, suppose you want to add the same prefix to several COBOL declarations:

```cobol
       01 WS-ACCT-ID     PIC X(10).
       01 WS-ACCT-NAME   PIC X(30).
       01 WS-ACCT-BAL    PIC 9(9)V99.
```

1. Move to the first line, press `V`, then use `j` to select the declarations.
2. Press `<leader>mh` to place a cursor before the first non-blank character on each line.
3. Press `i` and type the text; all cursors receive the same input.
4. Press `<Esc>` to finish.

To insert before Area A while including the indentation, choose `<leader>m0` (absolute beginning of line). In Normal mode, `2<leader>mh` adds cursors on the current line and the next line. Start with a small range and verify it before typing.

## 4. Commands and Ranges

The plugin also provides Ex commands that accept a line range:

| Command | Layout |
|---|---|
| `:[range]McLineHead` | Before the first non-blank character on each line |
| `:[range]McLineBol` | Column 0 on each line |
| `:[range]McLineTail` | End of each line |
| `:[range]McLineAlt` | Alternates between line end and first non-blank character |
| `:[range]McLineAltBol` | Alternates between line end and column 0 |
| `:McLineClear` | Clear the current multi-cursor session |

For example, `:10,15McLineTail` places tail cursors on lines 10 through 15. Before committing an edit, check that every cursor is in the intended column. Different line lengths and blank lines produce different tail positions by design.

## 5. Backend and Implementation Boundaries

The local configuration uses `backend = "native"`. The native backend computes positions per line and updates the buffer in a batch, without maintaining a search highlight for every cursor. The plugin also supports `vm` and `multicursor` backends for workflows that need features from those backends.

Smart head skips each line's indentation; absolute BOL places the cursor at column 0. The starting direction for alternating mode is controlled by `alternate_start`; the local setting is `tail`. A Visual block selection uses the corresponding rectangular edges to calculate positions.

The plugin computes cursor positions. Synchronized typing and backspace in multi-cursor mode are provided by the selected backend. Press `<Esc>` to leave the mode before continuing ordinary editing. For large edits, practice on a few lines first and inspect the result.

## 6. How It Differs from the Existing Multi-Cursor Plugins

| Tool | Best suited for |
|---|---|
| `multicursor-line.nvim` | Adding cursors at line heads, beginnings, tails, or alternating positions in a known range |
| `multicursor.nvim` | Adding cursors progressively by motion, paragraph, or match, such as `gaip` |
| `vim-visual-multi` | Interactively selecting repeated words, skipping matches, and moving or adjusting a cursor set |

They can be used together, but solve different problems. When the line layout is known, `multicursor-line.nvim` is direct; for content-based matching, `multicursor.nvim` or `vim-visual-multi` is more suitable.

### Local Key Conflict

Both `lua/plugins/bookmark.lua` and `multicursor-line.nvim` register Normal-mode `<leader>mt`. Load order determines which mapping is active; run `:verbose nmap <leader>mt` to see its source. The Visual-mode `<leader>mt` mapping for `multicursor-line` is registered separately. To avoid ambiguity, use `:McLineTail` or adjust the local mappings.

## 7. Exercises

### Exercise 1: Smart Head

1. Select three COBOL data declarations.
2. Press `<leader>mh` and confirm that each cursor is before `01`, not before the indentation.
3. Type a short prefix, then press `<Esc>`.

**Check**: all three lines have the same prefix and their indentation was not replaced.

### Exercise 2: Alternate Positions

Select four lines and press `<leader>ma`. Confirm that cursors alternate between line ends and the first non-blank character. Press `<Esc>` to clear them, then use `<leader>mA` to see how absolute BOL differs.

### Exercise 3: Command Range

Run `:10,12McLineTail`, confirm that tail cursors appear only on lines 10–12, then clear them with `:McLineClear`.

## 8. Troubleshooting

- **A mapping does nothing**: Confirm that Visual mode is active and the selection is non-empty; inspect `:verbose xmap <leader>mh`.
- **Normal-mode `<leader>mt` triggers a bookmark**: Run `:verbose nmap <leader>mt` to inspect the mapping source, or use `:McLineTail`.
- **Cursors land in unexpected positions**: Check the selected range and layout. `head` skips indentation; `bol` uses column 0 before indentation.
- **You want to stop batch editing**: Press `<Esc>`; run `:McLineClear` for explicit cleanup.

## 9. Project and Documentation

- Local configuration: `lua/plugins/multicursor-line.lua`
- Plugin source and documentation: <https://github.com/iamcheyan/multicursor-line.nvim>
- Neovim help: `:help multicursor-line`

This guide is based on the local configuration and plugin documentation. The performance figures come from the plugin README and were not independently re-benchmarked for this guide.
