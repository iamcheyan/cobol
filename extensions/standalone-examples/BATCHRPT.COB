       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCHRPT.
      *================================================================*
      * BATCHRPT.COB: TWO-LEVEL CONTROL BREAK AUDIT REPORT             *
      *================================================================*
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SALES-FILE ASSIGN TO "sales_data.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT RPT-FILE ASSIGN TO "sales_report.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  SALES-FILE.
       01  SALES-RECORD.
           05  IN-BRANCH               PIC X(04).
           05  IN-DEPT                 PIC X(04).
           05  IN-NAME                 PIC X(15).
           05  IN-AMOUNT               PIC 9(07)V99.

       FD  RPT-FILE.
       01  PRINT-LINE                  PIC X(80).

       WORKING-STORAGE SECTION.
       01  WS-CONTROL-KEYS.
           05  PREV-BRANCH             PIC X(04) VALUE SPACES.
           05  PREV-DEPT               PIC X(04) VALUE SPACES.

       01  WS-FLAGS.
           05  WS-EOF                  PIC X(01) VALUE "N".
               88  EOF-YES             VALUE "Y".
               88  EOF-NO              VALUE "N".
           05  FIRST-REC               PIC X(01) VALUE "Y".
               88  IS-FIRST-REC        VALUE "Y".
               88  NOT-FIRST-REC       VALUE "N".

       01  WS-TOTALS.
           05  DEPT-TOTAL              PIC 9(09)V99 COMP-3 VALUE ZERO.
           05  BRANCH-TOTAL            PIC 9(09)V99 COMP-3 VALUE ZERO.
           05  GRAND-TOTAL             PIC 9(11)V99 COMP-3 VALUE ZERO.
           05  PAGE-NUM                PIC 9(03) VALUE ZERO.

       01  WS-FORMATTED-VARS.
           05  FMT-AMOUNT              PIC $$,$$$,$$9.99.
           05  FMT-PAGE                PIC ZZ9.

       01  RPT-HEADER-1.
           05  FILLER                  PIC X(32) VALUE
               "CORPORATE SALES AUDIT REPORT    ".
           05  FILLER                  PIC X(10) VALUE "PAGE:     ".
           05  HDR-PAGE                PIC ZZ9.
           05  FILLER                  PIC X(35) VALUE SPACES.

       01  RPT-HEADER-2.
           05  FILLER                  PIC X(80) VALUE
               "BRANCH  DEPT  REPRESENTATIVE   SALES AMOUNT".

       01  RPT-DIVIDER.
           05  FILLER                  PIC X(80) VALUE
               "--------------------------------------------------".

       01  RPT-DOUBLE-DIVIDER.
           05  FILLER                  PIC X(80) VALUE
               "==================================================".

       01  RPT-DETAIL.
           05  DET-BRANCH              PIC X(04).
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  DET-DEPT                PIC X(04).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  DET-NAME                PIC X(15).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  DET-AMT                 PIC $$,$$$,$$9.99.
           05  FILLER                  PIC X(36) VALUE SPACES.

       01  RPT-DEPT-SUBTOTAL.
           05  FILLER                  PIC X(10) VALUE "  * DEPT  ".
           05  SUB-DEPT                PIC X(04).
           05  FILLER                  PIC X(11) VALUE " TOTAL:    ".
           05  SUB-DEPT-AMT            PIC $$,$$$,$$9.99.
           05  FILLER                  PIC X(42) VALUE SPACES.

       01  RPT-BRANCH-SUBTOTAL.
           05  FILLER                  PIC X(10) VALUE " ** BRANCH".
           05  FILLER                  PIC X(02) VALUE "  ".
           05  SUB-BRANCH              PIC X(04).
           05  FILLER                  PIC X(09) VALUE " TOTAL:  ".
           05  SUB-BRANCH-AMT          PIC $$,$$$,$$9.99.
           05  FILLER                  PIC X(42) VALUE SPACES.

       01  RPT-GRAND-TOTAL.
           05  FILLER                  PIC X(25) VALUE
               "*** COMPANY GRAND TOTAL: ".
           05  GRAND-AMT               PIC $$$,$$$,$$9.99.
           05  FILLER                  PIC X(41) VALUE SPACES.

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 2000-PROCESS-DATA
           PERFORM 3000-CLOSE-OUT
           PERFORM 9000-TERMINATE
           STOP RUN.

       1000-INIT.
           OPEN INPUT SALES-FILE
           OPEN OUTPUT RPT-FILE
           PERFORM 1100-PRINT-PAGE-HEADER.

       1100-PRINT-PAGE-HEADER.
           ADD 1 TO PAGE-NUM
           MOVE PAGE-NUM TO HDR-PAGE
           WRITE PRINT-LINE FROM RPT-DOUBLE-DIVIDER
           WRITE PRINT-LINE FROM RPT-HEADER-1
           WRITE PRINT-LINE FROM RPT-DIVIDER
           WRITE PRINT-LINE FROM RPT-HEADER-2
           WRITE PRINT-LINE FROM RPT-DIVIDER.

       2000-PROCESS-DATA.
           READ SALES-FILE
               AT END SET EOF-YES TO TRUE
           END-READ

           PERFORM UNTIL EOF-YES
               IF IS-FIRST-REC
                   MOVE IN-BRANCH TO PREV-BRANCH
                   MOVE IN-DEPT TO PREV-DEPT
                   SET NOT-FIRST-REC TO TRUE
               END-IF

      *        -- CHECK CONTROL BREAKS --
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

               PERFORM 2100-PROCESS-RECORD

               READ SALES-FILE
                   AT END SET EOF-YES TO TRUE
               END-READ
           END-PERFORM.

       2100-PROCESS-RECORD.
           MOVE IN-BRANCH TO DET-BRANCH
           MOVE IN-DEPT TO DET-DEPT
           MOVE IN-NAME TO DET-NAME
           MOVE IN-AMOUNT TO DET-AMT

           WRITE PRINT-LINE FROM RPT-DETAIL

           ADD IN-AMOUNT TO DEPT-TOTAL
           ADD IN-AMOUNT TO BRANCH-TOTAL
           ADD IN-AMOUNT TO GRAND-TOTAL.

       2200-DEPT-BREAK.
           MOVE PREV-DEPT TO SUB-DEPT
           MOVE DEPT-TOTAL TO SUB-DEPT-AMT
           WRITE PRINT-LINE FROM RPT-DEPT-SUBTOTAL
           MOVE ZERO TO DEPT-TOTAL.

       2300-BRANCH-BREAK.
           MOVE PREV-BRANCH TO SUB-BRANCH
           MOVE BRANCH-TOTAL TO SUB-BRANCH-AMT
           WRITE PRINT-LINE FROM RPT-BRANCH-SUBTOTAL
           WRITE PRINT-LINE FROM RPT-DIVIDER
           MOVE ZERO TO BRANCH-TOTAL.

       3000-CLOSE-OUT.
      *    FLUSH FINAL CONTROL BREAKS AT END OF FILE
           PERFORM 2200-DEPT-BREAK
           PERFORM 2300-BRANCH-BREAK

           WRITE PRINT-LINE FROM RPT-DOUBLE-DIVIDER
           MOVE GRAND-TOTAL TO GRAND-AMT
           WRITE PRINT-LINE FROM RPT-GRAND-TOTAL
           WRITE PRINT-LINE FROM RPT-DOUBLE-DIVIDER.

       9000-TERMINATE.
           CLOSE SALES-FILE
           CLOSE RPT-FILE
           DISPLAY "BATCHRPT: Control break report written to "
                   "sales_report.txt".
