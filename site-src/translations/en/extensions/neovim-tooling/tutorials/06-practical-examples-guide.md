# COBOL Examples and Plugin Walkthrough

This guide summarizes four standalone COBOL examples in the repository and suggests `cobol.nvim` features to try with them. The examples complement the plugin tutorials; installing the plugin is not a prerequisite for using the programs.

---

## 1. Overview of the Four Examples

| Example program | Business scenario | Key COBOL concepts | Useful plugin interactions |
|---|---|---|---|
| **1. `INPUTCSV.COB`** | Clean pipe-delimited text and export CSV | • `ORGANIZATION IS LINE SEQUENTIAL`<br>• Split with `UNSTRING ... DELIMITED BY`<br>• Trim with `STRING` and `FUNCTION TRIM`<br>• Include a Copybook (`EMP-REC.CPY`) | `gf` to open the Copybook, `K` to preview it, and `gd` / `<C-o>` to jump to and return from Paragraph definitions |
| **2. `FIXEDREC.COB`** | Process 80-column fixed-length bank transaction records | • Read physical records by position, without delimiters<br>• **Share storage and redefine layouts with `REDEFINES`**<br>• Level-88 transaction status condition names (`EVALUATE TRUE`)<br>• Accumulate precise decimal amounts with `COMP-3` | Use `<leader>cr` to inspect the layout table. Redefinition branches are not merged for offsets or total size; verify with the compiler. |
| **3. `TBLSRCH.COB`** | Currency-rate matrix and binary search | • COBOL in-memory tables (arrays): `OCCURS n TIMES`<br>• Dedicated pointers and subscripts: `INDEXED BY`<br>• **Language-level binary search with `SEARCH ALL`**<br>• Floating-point rate multiplication and rounding | Inspect basic-field OCCURS size estimates; use `gd` to find field definitions (group-level OCCURS counts are not fully applied to child-field totals). |
| **4. `BATCHRPT.COB`** | Classic two-level control-break audit report | • **Two-level control-break algorithm**<br>• Department subtotals and branch totals<br>• Edited currency output (`PIC $$$,$$$,$$9.99`, `ZZ9`)<br>• Structured pagination and double separators | Jump among paragraphs (`gd` / `<C-o>` between Header, Detail, and Break); try the column-72 overflow guard. |

---

## 2. Example 1: `INPUTCSV.COB` — Split and Clean a Text Feed

### Scenario
A data warehouse or external partner sends personnel records in `input.txt`, delimited by `|`. The program trims extra spaces, wraps names in double quotes, and exports a standard comma-separated `output.csv`.

### Key Code Patterns
* **Split a string (`UNSTRING`)**:
  ```cobol
  UNSTRING INPUT-RECORD
      DELIMITED BY "|"
      INTO IN-EMPLOYEE-ID
           IN-FULL-NAME
           IN-AGE
           IN-SALARY
      TALLYING IN WS-FIELD-COUNT
  END-UNSTRING
  ```
* **Join strings and trim spaces (`STRING` + `TRIM`)**:
  ```cobol
  STRING FUNCTION TRIM(IN-EMPLOYEE-ID) DELIMITED BY SIZE
         "," DELIMITED BY SIZE
         QUOTE DELIMITED BY SIZE
         IN-FULL-NAME DELIMITED BY SIZE
         QUOTE DELIMITED BY SIZE
         INTO CSV-LINE
  END-STRING
  ```

### Suggested Hands-on Steps
1. Open the file: `nvim extensions/standalone-examples/INPUTCSV.COB`.
2. On `COPY "EMP-REC.CPY".`, press **`K`** to preview the structure in a floating window; press **`q`** to close it.
3. On `PERFORM 1000-INITIALIZE`, press **`gd`** to jump to its definition, then **`<C-o>`** to return.
4. Verify it with `make -C extensions/standalone-examples run-csv`; inspect the terminal output and generated `output.csv`.

---

## 3. Example 2: `FIXEDREC.COB` — Fixed-Length Records and REDEFINES

### Scenario
A bank’s transaction file, `tx_input.dat`, has exactly 80 characters per line and no delimiters. The transaction type determines which fields are present:
- Deposits use an account, branch, and teller number.
- Transfers use a source account, destination account, and channel code.

The two transaction types contain different data but have the same total length. With **`REDEFINES`**, they can reuse the same 42-byte block of physical memory!

### Core Copybook Structure (`TX-REC.CPY`)
```cobol
       01  TX-RECORD.
           05  TX-HEADER.
               10  TX-DATE             PIC 9(08).
               10  TX-TIME             PIC 9(06).
               10  TX-ID               PIC X(10).
               10  TX-TYPE             PIC X(03).
                   88  TX-DEPOSIT      VALUE "DEP".
                   88  TX-WITHDRAW     VALUE "WDR".
                   88  TX-TRANSFER     VALUE "XFR".
           05  TX-AMOUNT               PIC 9(09)V99.
           05  TX-BODY                 PIC X(42).
      *    -- 重定义分支 1：存款/取款专用 --
           05  TX-DEP-INFO REDEFINES TX-BODY.
               10  TX-DEP-ACCOUNT      PIC X(16).
               10  TX-DEP-BRANCH       PIC X(08).
               10  TX-DEP-TELLER       PIC X(06).
               10  FILLER              PIC X(12).
      *    -- 重定义分支 2：跨行转账专用 --
           05  TX-XFR-INFO REDEFINES TX-BODY.
               10  TX-XFR-FROM-ACCT    PIC X(16).
               10  TX-XFR-TO-ACCT      PIC X(16).
               10  TX-XFR-CHANNEL      PIC X(06).
               10  FILLER              PIC X(04).
```

### Suggested Hands-on Steps
1. Open the Copybook: `nvim extensions/standalone-examples/TX-REC.CPY`.
2. On `01 TX-RECORD`, press **`<leader>cr`** (or run `:CobolCalcRecord`).
3. **Inspect the layout table**: it lists basic items in source order with offsets, for example `TX-BODY` at `+38` and `TX-AMOUNT` at `+27`.
4. **Understand the limits of `REDEFINES` estimates**: the current calculator does not place `TX-DEP-INFO` and `TX-XFR-INFO` at the same offset. Instead, it lays out their child fields in sequence (in a measured output, `TX-DEP-ACCOUNT` is at `+80` and `TX-XFR-FROM-ACCT` at `+122`), so the displayed `Total Size` counts the overlaid memory more than once.
   - In other words, **do not treat this total as the actual length of `TX-RECORD`**. Use the compiler or interface specification to determine the real shared offsets of `REDEFINES` branches.
5. Open the main program: `nvim extensions/standalone-examples/FIXEDREC.COB`.
6. On `TX-DEPOSIT`, press **`gd`** to jump to its level-88 definition in `TX-REC.CPY`, then **`<C-o>`** to return.
7. Verify it with `make -C extensions/standalone-examples run-fixed`; inspect the generated settlement report `tx_report.txt`.

---

## 4. Example 3: `TBLSRCH.COB` — In-memory Tables and Binary Search (`SEARCH ALL`)

### Scenario
A bank’s live foreign-exchange clearing center keeps reference rates for multiple currencies against USD in memory. As batch transactions arrive, the system must quickly find the requested currency’s rate and convert the amount.

### Key Concepts
* **Define a table with a binary-search key**:
  ```cobol
  01  WS-CURRENCY-TABLE REDEFINES WS-CURRENCY-TABLE-DATA.
      05  CURR-ENTRY OCCURS 10 TIMES
                     ASCENDING KEY IS CURR-CODE
                     INDEXED BY CURR-IDX.
          10  CURR-CODE           PIC X(03).
          10  CURR-RATE-TO-USD    PIC 9(06)V9(06).
  ```
* **Search with `SEARCH ALL`**:
  ```cobol
  SEARCH ALL CURR-ENTRY
      AT END
          DISPLAY "  [FAIL] Currency not supported: " REQ-CURR (REQ-IDX)
      WHEN CURR-CODE (CURR-IDX) = REQ-CURR (REQ-IDX)
          PERFORM 1100-CALCULATE-USD
  END-SEARCH
  ```
  *(Note: the COBOL compiler implements an $O(\log N)$ binary search using the `ASCENDING KEY`; there is no need to write the binary-search loop yourself.)*

### Suggested Hands-on Steps
1. Open the file: `nvim extensions/standalone-examples/TBLSRCH.COB`.
2. Inspect PIC estimates near the declarations and run `:CobolCalcRecord` to check recognized field sizes. The calculator does not fully multiply group-level OCCURS counts across members.
3. On `SEARCH ALL CURR-ENTRY`, take a moment to appreciate the concise native COBOL syntax for binary search.
4. Verify it with `make -C extensions/standalone-examples run-table`. Check the successful conversions for EUR, JPY, CNY, and GBP, and that unsupported currency `XYZ` takes the `AT END` branch.

---

## 5. Example 4: `BATCHRPT.COB` — A Classic Two-Level Control-Break Report

### Scenario
Generate a company sales report from input data sorted by branch and department. The program must:
1. Print each sales detail row and add it to department, branch, and company totals.
2. When the department changes, print **the department subtotal (`* DEPT TOTAL`)** and reset the department accumulator.
3. When the branch changes, first settle the last department subtotal, then print **the branch subtotal (`** BRANCH TOTAL`)** and a separator, and reset the branch accumulator.
4. At end-of-file, settle the final control break and print **the company grand total (`*** COMPANY GRAND TOTAL`)**.

### Control-Break Algorithm
```cobol
    IF IN-BRANCH NOT = PREV-BRANCH
        PERFORM 2200-DEPT-BREAK
        PERFORM 2300-BRANCH-BREAK
        MOVE IN-BRANCH TO PREV-BRANCH
        MOVE IN-DEPT TO PREV-DEPT
    ELSE
        IF IN-DEPT NOT = PREV-DEPT
            PERFORM 2200-DEPT-BREAK
            MOVE IN-DEPT TO PREV-DEPT
        END-IF
    END-IF
```

### Currency-Editing Picture (`PIC $$$,$$$,$$9.99`)
* `$$$,$$$,$$9.99`: the dollar sign floats next to the first nonzero digit. For example, `12500` is formatted as `   $12,500.00`; thousands separators are added automatically and leading zeroes are suppressed to spaces.

### Suggested Hands-on Steps
1. Open the file: `nvim extensions/standalone-examples/BATCHRPT.COB`.
2. Inspect `FMT-AMOUNT PIC $$,$$$,$$9.99.`.
3. After installing and configuring Aerial, run `:AerialToggle` to browse program symbols. You can also use `gd` on a Paragraph name to inspect its definition.
4. Verify it with `make -C extensions/standalone-examples run-report`; inspect the formatted `sales_report.txt`.

---

![COBOL hierarchy in the Aerial outline](images/aerial-outline.png)

Aerial displays COBOL structural symbols for search and source navigation. It is optional; the other core features remain available without it.

## 6. Run All Examples

From the repository root, run the examples’ Makefile:

```bash
make -C extensions/standalone-examples check
make -C extensions/standalone-examples run
```
