# Fixed-Format Columns and the Ruler

Before writing business logic, learn COBOL’s distinctive **Fixed Reference Format (80 columns)**.

---

## 1. The Basics: Why 80 Columns?

Modern programmers are used to free indentation, but standard COBOL (ANSI 68/74/85) dates back to the era of **80-column Hollerith punch cards**. Code was punched onto cards, each exactly 80 columns wide, so every COBOL column has a strictly defined role:

```text
列号: 1----6  7   8---11  12---------------------------------------------72  73----80
区域: SEQ    IND  Area A  Area B (语句主体)                                  IDENT
标尺:        │   │       │                                                │
代码: 000100      0000-MAIN-LOGIC SECTION.
```

### Quick Reference: The Five Areas

| Columns | Area | Syntax rules and purpose |
|---|---|---|
| **1–6** | **Sequence Number** | Historically used to number cards, so a dropped deck could be put back in order. Modern projects usually leave this blank or use a six-digit line number; the compiler ignores it by default. |
| **7** | **Indicator** | **Controls the line type**:<br>• `*`: comment line (must be in column 7);<br>• `/`: page eject when printing;<br>• `-`: continuation of a string across lines. |
| **8–11** | **Area A** | **Structure definitions** (start in column 8):<br>• The four Division declarations (such as `IDENTIFICATION DIVISION.`);<br>• Section and Paragraph names;<br>• Root-level record variables `01` and standalone variables `77`;<br>• File descriptors `FD` / `SD`. |
| **12–72** | **Area B** | **Executable statements** (start in column 12 or later):<br>• Business instructions such as `MOVE`, `PERFORM`, `IF`, `OPEN`, and `DISPLAY`;<br>• subordinate data items (`05`, `10`, `15`, etc.);<br>• condition names at level `88`. |
| **73–80** | **Identification** | Historically used for a punched program identifier. **Warning: modern GnuCOBOL and IBM compilers ignore all code characters after column 72!** Anything beyond the limit is truncated, a subtle but serious pitfall for COBOL beginners. |

---

## 2. Helpful Tools in the Plugin

With `cobol.nvim`, there is no need to count spaces by hand:
1. **Fine-line ruler (`│`)**: precisely marks columns 7, 8, 12, and 73, with no heavy background blocks; it moves aside where text is present.
2. **Winbar structural breadcrumbs**: the top of the window shows the current Division / Section / Paragraph path (for example, `[ DATA DIVISION ]` or `[ PROCEDURE DIVISION > 2000-PROCESS-SECTION > 2100-PROCESS-RECORD ]`).
3. **Column-72 overflow warning**: code beyond column 72 is highlighted with a red wavy underline.
4. **Column-jump shortcuts**: jump straight to important columns.
5. **Smart Tab stops**: at the start of a line, Tab moves through columns 7, 8, and 12.
6. **Smart comments in column 7**: toggle `*` in the correct column without changing the code’s indentation.

![COBOL column ruler and Winbar in Neovim](images/fixed-format-ruler.png)

The ruler in the screenshot marks columns 7, 8, 12, and 73. The Winbar shows the `[ DATA DIVISION ]` breadcrumb, and content past column 72 is highlighted. This screenshot shows the plugin running in Neovim.

---

## 3. Hands-on Exercises

Open the sample file in a terminal:

```bash
cd <仓库根目录>
nvim extensions/standalone-examples/INPUTCSV.COB
```

### Exercise 1.1: Check the Ruler and Breadcrumb Alignment
1. Look at the Winbar breadcrumb at the top; it changes with the cursor position, for example:
   ```text
   [ PROCEDURE DIVISION > 2000-PROCESS-SECTION > 2100-PROCESS-RECORD ]
   ```
2. Find the four fine steel-blue vertical lines `│` in the editor. They mark column 7 (Indicator), column 8 (Area A), column 12 (Area B), and column 73 (past Area B).
3. Watch how the rulers move aside where text appears and run through blank or short lines.

### Exercise 1.2: Practice the Column-Jump Shortcuts
In Normal mode, leave the cursor on any line:
1. Press **`g8`** to place the cursor in **column 8**, the start of Area A.
2. Press **`g12`** to place it in **column 12**, the start of Area B.
3. Press **`g7`** to place it in **column 7**, the Indicator column.
4. Press **`g73`** to jump to **column 73**, the start of Identification.

> 💡 **Practice tip**: Repeat `g8` → `g12` → `g7` a few times to build muscle memory.

### Exercise 1.3: Toggle the Ruler and Winbar
Run `:CobolGuideToggle` to hide the visual guides, then run it again to restore them. You can also use `:CobolGuideDisable` and `:CobolGuideEnable`.

### Exercise 1.4: Try Smart Tab Indentation
COBOL convention places Paragraph names in Area A (column 8) and statements in Area B (column 12). Instead of tapping the spacebar repeatedly, use Tab:
1. Find a blank line and press `o` to enter Insert mode.
2. The cursor starts in column 1. Press **`<Tab>`** once.
3. **Notice**: the leading whitespace moves to column 7 (the Indicator column).
4. Press `<Tab>` again to reach column 8 (Area A), ready for a Paragraph name such as `3100-MY-LOGIC.`.
5. Press `<Tab>` again to reach column 12 (Area B), ready for a statement such as `DISPLAY "HELLO".`. Further Tabs indent by `shiftwidth`.
6. Press `<Esc>` to leave Insert mode.

### Exercise 1.5: Toggle Comments in Column 7
A full-line comment in fixed-format COBOL must have its marker in column 7. Many ordinary comment plugins insert `*` at the start of the line, which misaligns the code.
1. Leave the cursor on the line you just entered.
2. Press **`<leader>c*`** (or run `:CobolToggleComment`).
3. **Notice**: `*` is inserted in column 7, making the line a valid COBOL comment while preserving the code’s indentation.
4. Press **`<leader>c*`** again to remove the marker and restore the executable line.
5. **Toggle comments on multiple lines**: press `V` for Visual line mode, use `j` to select three lines, then press **`<leader>c*`** to toggle comments in column 7 on all of them.

### Exercise 1.6: Trigger the Column-72 Overflow Guard
1. Move to the end of any line, such as a `MOVE ... TO OUTPUT-RECORD` statement.
2. Enter Insert mode and type a long string of characters until the cursor passes column 72.
3. **Observe**: text from column 73 onward immediately receives a conspicuous **dark red background and bright red wavy underline**.
4. **Think about it**: the compiler discards these characters, so code after column 72 can disappear and cause confusing errors. Press `u` to undo the overflow input.

---

## 4. Quick Reference

| Key / command | Mode | Effect |
|---|---|---|
| `g7` | Normal | Jump to column 7 (Indicator) |
| `g8` | Normal | Jump to column 8 (start of Area A) |
| `g12` | Normal | Jump to column 12 (start of Area B) |
| `g73` | Normal | Jump to column 73 (start of Identification) |
| `:CobolGuideToggle` | Command line | Toggle visual guides and diagnostic attachment |
| `<leader>c*` | Normal / Visual | Toggle the `*` comment marker in column 7, on one or multiple lines |
| `<Tab>` | Insert | At the start of a line or in leading whitespace: columns 1–6 → 7, 7 → 8, 8–11 → 12; from column 12 onward, indent by `shiftwidth` |
