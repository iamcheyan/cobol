      * Lesson 11: store a small batch in an OCCURS table.
      * OCCURS creates a fixed number of repeated data entries.
      * A group entry repeats all of its subordinate elementary items.
      * Numeric subscripts in parentheses select one table occurrence.
      * This lesson uses an ordinary numeric subscript, not an index.
      * Table bound is four; the loop visits entries 1 through 4.
      * Credits increase the sample balance and debits reduce it.
      * An unknown code is displayed and leaves the balance unchanged.
      * Table data is loaded with MOVE before it is processed.
      * No file, external input, or dynamic table is used here.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. OCCURS11.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Each 05 entry repeats a code and a two-decimal amount.
       01 WS-TRANSACTION-TABLE.
          05 WS-TRANSACTION-ENTRY OCCURS 4 TIMES.
             10 WS-TXN-CODE PIC X.
             10 WS-TXN-AMOUNT PIC 9(5)V99.
      * The numeric field is a subscript for the table references.
       01 WS-SAMPLE-INDEX PIC 9(2) VALUE ZERO.
       01 WS-LAST-SAMPLE PIC 9 VALUE 4.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT-BALANCE PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
      * Load the table, process its populated range, then report.
       0000-MAIN.
           PERFORM 1000-LOAD-TABLE
           PERFORM 2000-PROCESS-TABLE
           PERFORM 9000-REPORT
           STOP RUN.
      * Initialize all four occurrences using numeric subscripts.
       1000-LOAD-TABLE.
           MOVE "C" TO WS-TXN-CODE(1)
           MOVE 125.50 TO WS-TXN-AMOUNT(1)
           MOVE "D" TO WS-TXN-CODE(2)
           MOVE 40.10 TO WS-TXN-AMOUNT(2)
           MOVE "X" TO WS-TXN-CODE(3)
           MOVE 25.00 TO WS-TXN-AMOUNT(3)
           MOVE "C" TO WS-TXN-CODE(4)
           MOVE 20.00 TO WS-TXN-AMOUNT(4).
      * Process populated entries through the configured last index.
       2000-PROCESS-TABLE.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               PERFORM 2100-PROCESS-ENTRY
           END-PERFORM.
      * Read the code and amount from the current occurrence.
       2100-PROCESS-ENTRY.
           DISPLAY "ENTRY=" WS-SAMPLE-INDEX
               " CODE=" WS-TXN-CODE(WS-SAMPLE-INDEX)
               " AMOUNT=" WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
           EVALUATE WS-TXN-CODE(WS-SAMPLE-INDEX)
               WHEN "C"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           + WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "ACTION=CREDIT"
               WHEN "D"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           - WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "ACTION=DEBIT"
               WHEN OTHER
                   DISPLAY "ACTION=IGNORED_UNKNOWN_CODE"
           END-EVALUATE
           COMPUTE WS-PROCESSED-COUNT =
               WS-PROCESSED-COUNT + 1.
      * Report entries processed and the resulting account balance.
       9000-REPORT.
           DISPLAY "PROCESSED=" WS-PROCESSED-COUNT
           DISPLAY "FINAL-BALANCE=" WS-ACCOUNT-BALANCE.
      * WS-TRANSACTION-TABLE is the parent group for all table entries.
      * OCCURS 4 TIMES allocates four occurrences in this fixed table.
      * Each occurrence includes both WS-TXN-CODE and WS-TXN-AMOUNT.
      * A group-level OCCURS repeats its entire subordinate structure.
      * Both elementary fields use the same numeric subscript per entry.
      * Subscripts are written in parentheses after the data name.
      * The first occurrence is addressed with subscript 1.
      * The fourth and final occurrence is addressed with subscript 4.
      * WS-LAST-SAMPLE must never exceed the declared table upper bound.
      * The loop checks its end condition before each processing pass.
      * Index 4 is processed because the exit test uses greater-than.
      * After index 4, index 5 meets the exit test.
      * The performed entry paragraph returns to the loop body.
      * The loop increments the processed count once per table entry.
      * A numeric subscript is an ordinary numeric data item.
      * Lesson 12 introduces INDEXED BY and table index data items.
      * This table has fixed capacity even when fewer entries are used.
      * This sample fills every allocated occurrence before the loop.
      * OCCURS does not load values or check transaction business rules.
      * EVALUATE keeps the already learned code classification explicit.
      * The unknown code branch leaves the running balance unchanged.
      * Entries are processed in the order selected by the subscript.
      * No implicit sorting or lookup happens when a table is declared.
      * Later lessons will search tables using account identifiers.
      * The four sample amounts are 125.50, 40.10, 25.00, and 20.00.
      * The accepted credit and debit sequence ends at balance 1105.40.
      * The ignored unknown-code amount is not added to the balance.
      * The table is stored in WORKING-STORAGE for this program run.
      * Fixed OCCURS bounds simplify storage planning and table review.
      * Keep table bound and loop range consistent.
      * Avoid using a subscript outside the declared occurrence range.
      * This program displays fields, not the whole group record.
      * STOP RUN ends this fixed-table demonstration.
