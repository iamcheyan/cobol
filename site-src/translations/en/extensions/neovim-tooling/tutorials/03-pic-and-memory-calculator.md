# Estimating PIC and Record Layouts

A COBOL `PIC` clause describes a field’s format. Fixed-length files and Copybook interfaces often require checking field widths and offsets; `cobol.nvim` can turn common declarations into readable size estimates.

## What the Plugin Provides

- On a data declaration, show the current field’s PIC and estimated size in bytes.
- On a level-01 record line, show a summary estimate for recognized fields.
- `<leader>cr` / `:CobolCalcRecord` opens a layout table with field hierarchy, offsets, PIC/usage, and estimated sizes.

![COBOL PIC field and record layout estimates](images/record-layout.png)

The layout table shows offsets and estimated sizes for fields under `WS-TRANSACTION-RECORD`. This image was captured from `:CobolCalcRecord` running in Neovim.

## A Simple Example

```cobol
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-RECORD.
          10 WS-CUSTOMER-ID PIC X(8).
          10 WS-AMOUNT PIC 9(5)V99.
          10 WS-STATUS PIC X.
```

Place the cursor on `WS-TRANSACTION-RECORD` and run `:CobolCalcRecord`. The table lists recognized fields in source order with estimated byte offsets; field lines also show local size hints.

For a rough mental estimate, `PIC X(n)` and display `PIC 9(n)` usually use one byte per character; the implied decimal point `V` takes no storage; and `COMP-3` is commonly estimated from the digit nibbles plus a sign nibble. The size of binary `COMP` depends on precision, compiler, and target ABI.

## Limits of the Estimate

The layout is useful for reading and initial checks, but does not replace the target compiler. Alignment, sign representation, dialect, compiler options, and platform can all change the actual layout. The current calculator does not multiply every child field by the number of occurrences in a group-level `OCCURS`; larger `REDEFINES` overlays also do not increase the accumulated total. For these declarations, rely on the target compiler and interface specification.

## Quick Actions

| Action | Effect |
| --- | --- |
| `<leader>cr` / `:CobolCalcRecord` | Show a layout estimate for the current field or level-01 record |
| Cursor on a data declaration | Show a field PIC / byte estimate hint |
| `q` / `<Esc>` | Close the layout floating window |
