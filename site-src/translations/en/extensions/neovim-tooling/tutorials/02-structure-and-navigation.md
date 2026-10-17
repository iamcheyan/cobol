# Structure Overview, Outlines, and Go to Definition

Large mainframe COBOL programs combine many `PERFORM` paragraphs and Copybooks (`.CPY`). Reading them means tracing the relationships between business flow and data definitions.

Without modern IDE support, developers have to search for paragraph names with `/` and switch between files manually, which breaks their train of thought. This tutorial shows how `cobol.nvim` provides outlines, go-to-definition, return navigation, and inline previews in Neovim.

---

## 1. COBOL’s Hierarchical Structure

COBOL programs have four Divisions, in a fixed top-to-bottom order:

```text
IDENTIFICATION DIVISION.       <-- 程序的身份证：程序名、作者、编写日期
ENVIRONMENT DIVISION.          <-- 运行环境与外部实体文件映射（SELECT ... ASSIGN TO）
DATA DIVISION.                 <-- 全局数据字典：文件记录结构（FILE SECTION）、工作变量（WORKING-STORAGE）
PROCEDURE DIVISION.            <-- 执行逻辑区：各种节（SECTION）与过程段落（PARAGRAPH）
```

Within `PROCEDURE DIVISION`:
- A **SECTION** groups related Paragraphs.
- A **PARAGRAPH** is the smallest named execution unit (similar to a function, but without arguments or local variables; data is shared through global fields).
- Control flow uses `PERFORM <paragraph-name>` (similar to a subroutine call) or `GO TO <paragraph-name>` (an unconditional jump).

---

## 2. Navigation Tools in the Plugin

1. **Dynamic Winbar breadcrumbs**: the top of the window continuously shows the current Division / Section / Paragraph path.
2. **Aerial structural outline**: Aerial is an optional Neovim outline plugin. This plugin’s Aerial backend exposes Divisions, Sections, Paragraphs, FD/SD entries, and level-01 records. Run `:AerialToggle` to open it; this plugin does not bind `<leader>cs` by default.
3. **Jump to paragraph or data definitions (`gd`)**: place the cursor on `PERFORM 1000-INITIALIZE` or a variable name and press `gd` to jump to its definition.
4. **Return navigation (`<C-o>` / `<C-i>`)**: use Neovim’s built-in jumplist to move back and forward.
5. **Copybook preview (`K`)**: on `COPY "EMP-REC.CPY".`, press `K` to preview the contents in a floating window; press `q` or `<Esc>` to close it.
6. **Open a Copybook (`gf`)**: press `gf` to open the `.CPY` file referenced by the current `COPY` statement.
7. **Data-parent hints**: show a field’s parent name beside deeply nested data items.
8. **Tree-sitter structural scopes**: when a parser is available, highlight the surrounding keywords of the innermost paired structure and draw connecting lines. `ELSE` / `WHEN` branches can also be marked.
9. **Structural motions and text objects**: `%` moves between opening and closing keywords; `af`/`if`, `ae`/`ie`, and `ap`/`ip` select around or inside IF, EVALUATE, and PERFORM blocks.

![IF, ELSE, and END-IF scope markers with a structural outline](images/structure-scope.png)

This real Neovim screenshot shows the Syms outline, Winbar breadcrumbs, and markers and a connecting line for the current IF block. Syms is an external outline UI shown in the screenshot; the plugin’s built-in Aerial backend is shown separately below.

![Aerial COBOL structural outline](images/aerial-outline.png)

Aerial is optional. The image shows the outline linked to COBOL source. This plugin does not bind `<leader>cs` by default; use `:AerialToggle` to open the outline, or configure your own shortcut.

---

## 3. Hands-on Exercises

Open the sample source:

```bash
cd <仓库根目录>
nvim extensions/standalone-examples/INPUTCSV.COB
```

### Exercise 2.1: Dynamic Winbar Breadcrumbs
1. Watch the breadcrumb at the top of the window update as you move the cursor.
2. Move to `IDENTIFICATION DIVISION`; the Winbar shows `[ IDENTIFICATION DIVISION ]`.
3. Move to a data item under `WORKING-STORAGE SECTION`; it shows `[ DATA DIVISION ]`.
4. Move to `2100-PROCESS-RECORD`; it shows `[ PROCEDURE DIVISION > 2000-PROCESS-SECTION > 2100-PROCESS-RECORD ]`.
5. **Takeaway**: even while scrolling quickly, you can tell at a glance where the current code sits in the program hierarchy.

### Exercise 2.2: The Aerial Three-Level Outline

Aerial is an optional Neovim outline plugin. After installing and configuring it, run `:AerialToggle` to open the outline. This plugin supplies the COBOL symbol backend, but does not bind `<leader>cs` by default.
1. Run `:AerialToggle` to open Aerial.
2. **Inspect the sidebar**:
   - Top-level nodes: the four Divisions (with module icons).
   - Second-level nodes: items such as `WORKING-STORAGE SECTION` and `1000-INIT-SECTION`.
   - Leaf nodes: Paragraphs such as `0000-MAIN`, `1000-INITIALIZE`, and `2100-PROCESS-RECORD`, plus level-01 root records.
3. Use `j` / `k` to move to `3000-PARSE-RECORD` in the sidebar and press **`<CR>`**.
4. **Notice**: the main editor jumps smoothly to `3000-PARSE-RECORD.`.
5. Move through the code with `j` / `k` and watch the corresponding outline node highlight in sync.
6. Run `:AerialToggle` again to close the outline.

### Exercise 2.3: Jump to a Paragraph or Variable (`gd` / `<C-o>`)
This is one of the most useful everyday combinations:
1. Move to `PERFORM 1000-INITIALIZE`.
2. Place the cursor on `1000-INITIALIZE` and press **`gd`** (Go to Definition).
3. **Notice**: the cursor jumps to the `1000-INITIALIZE.` Paragraph definition.
4. After inspecting it, press **`<C-o>`**.
5. **Notice**: the cursor returns to the `PERFORM` call.
6. Move to `INITIALIZE WS-FLAGS WS-COUNTERS.`.
7. Place the cursor on `WS-FLAGS` and press **`gd`**.
8. **Notice**: the cursor jumps to the `01 WS-FLAGS` declaration.
9. Press **`<C-o>`** again to return.

> 💡 **Tip**: `gd` and `<C-o>` make a smooth go-forward-and-back workflow, eliminating repeated searches among definitions.

### Exercise 2.4: Preview (`K`) and Open (`gf`) a Copybook
COBOL programs often use Copybooks to reuse data structures, much like C’s `#include`.
1. Move to `COPY "EMP-REC.CPY".`.
2. Press **`K`** (the hover-preview shortcut).
3. **Notice**: a floating window appears in the center with the contents of `EMP-REC.CPY`:
   ```cobol
          01  EMP-RECORD.
              05  EMP-ID                   PIC X(05).
              05  EMP-NAME.
                  10  EMP-FIRST-NAME       PIC X(10).
                  10  EMP-LAST-NAME        PIC X(10).
              05  EMP-DEPT                 PIC X(02).
                  88  DEPT-SALES           VALUE "01".
                  88  DEPT-DEV             VALUE "02".
                  88  DEPT-HR              VALUE "03".
              05  EMP-SALARY               PIC S9(7) COMP-3.
              05  EMP-STATUS               PIC X(01).
   ```
4. Press **`q`** or **`<Esc>`** to close it; the editor remains at the same position.
5. Press **`gf`** on the same line (Go to File). Neovim searches for and opens the `.CPY` file for editing. Run `:bd` or `:b INPUTCSV.COB` to return to the main file.
6. Place the cursor on `PERFORM 2000-PROCESS-FILE` and press **`K`** to preview that Paragraph’s code; press `q` to close it.

### Exercise 2.5: Inspect Parent Hints for Nested Fields
1. Move to `10  IN-FULL-NAME         PIC X(80).`.
2. **Check the end of the line**: if hierarchy hints are enabled, you may see something like `← 05 IN-NAME-GROUP (01 WS-INPUT-FIELDS)`.
3. Move to `88  CONVERT-SUCCESS      VALUE "S".`.
4. **Check the line end** for its parent field hint as well.
5. **Think about it**: with deeply nested COBOL records, there is no need to count indentation levels to find a parent field.

---

![Copybook preview floating window](images/copybook-preview.png)

Press `K` on a `COPY` statement to preview the Copybook without leaving the current editing position.

## 4. Quick Reference

| Key / command | Mode | Effect |
|---|---|---|
| `:AerialToggle` | Command line | Open or close the optional Aerial outline (requires installation and configuration) |
| `gd` | Normal | Jump from a Paragraph name, variable, or Copybook to its definition |
| `<C-o>` | Normal | Use Neovim’s built-in jump list to return to the previous position |
| `K` | Normal | Preview a Copybook or target Paragraph in a floating window; press `q` to close |
| `gf` | Normal | Open the referenced Copybook for editing |
