       IDENTIFICATION DIVISION.
       PROGRAM-ID. TBLSRCH.
      *================================================================*
      * TBLSRCH.COB: IN-MEMORY TABLES, OCCURS & BINARY SEARCH ALL      *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *================================================================*
      * 1. SORTED CURRENCY EXCHANGE TABLE (BINARY SEARCH TARGET)       *
      *================================================================*
       01  WS-CURRENCY-TABLE-DATA.
           05  FILLER          PIC X(15) VALUE "AUD000000006520".
           05  FILLER          PIC X(15) VALUE "CAD000000007350".
           05  FILLER          PIC X(15) VALUE "CHF000000011420".
           05  FILLER          PIC X(15) VALUE "CNY000000001395".
           05  FILLER          PIC X(15) VALUE "EUR000000010850".
           05  FILLER          PIC X(15) VALUE "GBP000000012730".
           05  FILLER          PIC X(15) VALUE "HKD000000001280".
           05  FILLER          PIC X(15) VALUE "JPY000000000067".
           05  FILLER          PIC X(15) VALUE "SGD000000007560".
           05  FILLER          PIC X(15) VALUE "USD000000010000".

      *    REDEFINE AS STRUCTURED ARRAY (TABLE)
       01  WS-CURRENCY-TABLE REDEFINES WS-CURRENCY-TABLE-DATA.
           05  CURR-ENTRY OCCURS 10 TIMES
                          ASCENDING KEY IS CURR-CODE
                          INDEXED BY CURR-IDX.
               10  CURR-CODE           PIC X(03).
               10  CURR-RATE-TO-USD    PIC 9(06)V9(06).

      *================================================================*
      * 2. SAMPLE CONVERSION REQUESTS                                  *
      *================================================================*
       01  WS-REQUEST-TABLE-DATA.
           05  FILLER                  PIC X(14) VALUE "EUR0000150000".
           05  FILLER                  PIC X(14) VALUE "JPY0050000000".
           05  FILLER                  PIC X(14) VALUE "CNY0000880000".
           05  FILLER                  PIC X(14) VALUE "GBP0000075000".
           05  FILLER                  PIC X(14) VALUE "XYZ0000010000".

       01  WS-REQUEST-TABLE REDEFINES WS-REQUEST-TABLE-DATA.
           05  REQ-ENTRY OCCURS 5 TIMES INDEXED BY REQ-IDX.
               10  REQ-CURR            PIC X(03).
               10  REQ-AMT             PIC 9(09)V99.

      *================================================================*
      * 3. WORKING FIELDS & ACCUMULATORS                               *
      *================================================================*
       01  WS-WORK-VARS.
           05  WS-USD-EQUIV            PIC 9(11)V99 COMP-3 VALUE ZERO.
           05  WS-TOTAL-USD            PIC 9(11)V99 COMP-3 VALUE ZERO.
           05  WS-FOUND-FLAG           PIC X(01) VALUE "N".
               88  CURR-FOUND          VALUE "Y".
               88  CURR-NOT-FOUND      VALUE "N".

       01  WS-DISPLAY-FIELDS.
           05  DISP-FOREIGN-AMT        PIC ZZZ,ZZZ,ZZ9.99.
           05  DISP-USD-AMT            PIC $$,$$$,$$9.99.
           05  DISP-RATE               PIC Z9.999999.
           05  DISP-TOTAL-USD          PIC $$$,$$$,$$9.99.

       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY "=================================================="
           DISPLAY "COBOL TBLSRCH: Tables & Binary Search (SEARCH ALL)"
           DISPLAY "=================================================="
           PERFORM 1000-PROCESS-CONVERSIONS
           PERFORM 2000-DISPLAY-SUMMARY
           STOP RUN.

       1000-PROCESS-CONVERSIONS.
           PERFORM VARYING REQ-IDX FROM 1 BY 1 UNTIL REQ-IDX > 5
               SET CURR-NOT-FOUND TO TRUE

      *        -- HIGH SPEED BINARY SEARCH IN SORTED TABLE --
               SEARCH ALL CURR-ENTRY
                   AT END
                       DISPLAY "  [FAIL] Currency not supported: "
                               REQ-CURR (REQ-IDX)
                   WHEN CURR-CODE (CURR-IDX) = REQ-CURR (REQ-IDX)
                       SET CURR-FOUND TO TRUE
                       PERFORM 1100-CALCULATE-USD
               END-SEARCH
           END-PERFORM.

       1100-CALCULATE-USD.
           COMPUTE WS-USD-EQUIV ROUNDED =
               REQ-AMT (REQ-IDX) * CURR-RATE-TO-USD (CURR-IDX)

           ADD WS-USD-EQUIV TO WS-TOTAL-USD

           MOVE REQ-AMT (REQ-IDX) TO DISP-FOREIGN-AMT
           MOVE CURR-RATE-TO-USD (CURR-IDX) TO DISP-RATE
           MOVE WS-USD-EQUIV TO DISP-USD-AMT

           DISPLAY "  [OK] " REQ-CURR (REQ-IDX) " "
                   DISP-FOREIGN-AMT " @ " DISP-RATE
                   " -> " DISP-USD-AMT.

       2000-DISPLAY-SUMMARY.
           DISPLAY "=================================================="
           MOVE WS-TOTAL-USD TO DISP-TOTAL-USD
           DISPLAY "Grand Total Portfolio in USD Base: " DISP-TOTAL-USD
           DISPLAY "==================================================".
