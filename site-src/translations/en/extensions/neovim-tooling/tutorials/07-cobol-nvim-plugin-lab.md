# cobol.nvim Plugin Lab

This tutorial uses the COBOL examples in `extensions/standalone-examples/` to show how the plugin can support everyday source browsing. The plugin does not replace GnuCOBOL; syntax checks and project builds are still performed by `cobc` or project commands.

## Setup

Open a sample in Neovim:

```sh
nvim extensions/standalone-examples/INPUTCSV.COB
```

The plugin supports the `cobol`, `cbl`, and `cob` filetypes. For fixed-format examples, start with the column ruler. Tree-sitter pairing markers, breadcrumbs, and text objects are unavailable if the parser is missing. Aerial and blink.cmp are optional dependencies.

## Column Ruler and Editing

1. Use `g7`, `g8`, `g12`, and `g73` to jump to important fixed-format columns.
2. Enter Insert mode in leading whitespace and try `<Tab>` / `<S-Tab>` to move among columns 7, 8, and 12.
3. `:CobolGuideToggle` toggles the column ruler and Winbar. Use `:CobolGuideEnable` / `:CobolGuideDisable` to explicitly enable or disable the guides and diagnostic attachment.
4. Toggle comments with `gcc`, Visual `gc`, or `<leader>c*`; format reserved words with `:CobolFormatCase`. With no range, the command processes the whole buffer; with a range, it processes only that range.

![Fixed-format column ruler and Winbar](images/fixed-format-ruler.png)

The screenshot shows rulers at columns 7, 8, 12, and 73, along with the current-position breadcrumb. Use `:CobolGuideToggle` to toggle the guides. `:CobolGuideDisable` also clears current diagnostics while keeping loaded mappings and folding settings.

## Structural Navigation, Outlines, and Copybooks

1. On the Paragraph name in `PERFORM 1000-INITIALIZE`, press `gd`, then `<C-o>` to return. `<C-i>` moves forward through the jumplist.
2. On `COPY "EMP-REC.CPY".`, press `gf` to open the Copybook or `K` to preview it.
3. If the parser is available, place the cursor inside an IF block to see colored markers for the innermost structure, connecting lines, and ELSE/WHEN markers. Press `%` to move between structural keywords; use `vaf` / `vif` to select outside or inside an IF block.
4. Aerial must be installed separately and enabled with the COBOL backend supplied by this plugin. Run `:AerialToggle` to open it; this plugin does not bind `<leader>cs` by default.

![IF/ELSE/END-IF scope and Syms outline](images/structure-scope.png)

This real screenshot shows the Syms outline and paired IF-scope markers. Syms is an external UI configured by the user; this plugin supplies the Aerial backend.

![Aerial COBOL outline](images/aerial-outline.png)

![Copybook preview floating window](images/copybook-preview.png)

## PIC Estimates, Diagnostics, and Folding

1. On a level-01 record, run `<leader>cr` / `:CobolCalcRecord` to view field offsets and size estimates. Group-level `OCCURS` counts are not multiplied across child fields, and large `REDEFINES` overlays do not increase the total, so do not treat the result as an ABI guarantee.
2. Run `<leader>cl` / `:CobolLint` for an immediate GnuCOBOL check; use `<leader>cq` / `:CobolQuickfix` to open Quickfix. Diagnostics can also run automatically on save, after a debounced edit, and when leaving Insert mode.
3. Use `za`, `zc`, and `zo` to operate folds for Divisions, Sections, Paragraphs, and data items. Native folding does not create IF/EVALUATE folds; if another fold provider creates control-block folds, the plugin can provide structural summaries.

![PIC and record layout estimates](images/record-layout.png)

![GnuCOBOL compiler diagnostics](images/compiler-diagnostics.png)

![COBOL structural folding](images/folding.png)

## Keys and Commands

| Action | Function |
|---|---|
| `g7` / `g8` / `g12` / `g73` | Jump to fixed-format columns |
| `gd` / `gf` / `K` | Go to definition / open Copybook / preview |
| `%`, `af`/`if`, `ae`/`ie`, `ap`/`ip` | Tree-sitter pairing motions and structural text objects |
| `<leader>cr` / `<leader>cl` / `<leader>cq` | Record estimate / immediate diagnostics / Quickfix |
| `:CobolGuideToggle` | Toggle column ruler and Winbar |
| `:CobolLint` / `:CobolBuild` / `:CobolRun` / `:CobolTest` | Check, build, run, and test the project |

For full configuration and command details, see the plugin repository README and Neovim help at `:help cobol.nvim`.
