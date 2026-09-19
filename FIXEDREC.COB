       IDENTIFICATION DIVISION.
       PROGRAM-ID. FIXEDREC.
      *================================================================*
      * FIXEDREC.COB: 80-COLUMN FIXED RECORD PROCESSING & REDEFINES    *
      *================================================================*
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TX-IN-FILE ASSIGN TO "tx_input.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-IN-STATUS.
           SELECT TX-RPT-FILE ASSIGN TO "tx_report.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUT-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TX-IN-FILE.
       01  RAW-RECORD                  PIC X(80).

       FD  TX-RPT-FILE.
       01  RPT-RECORD                  PIC X(80).

       WORKING-STORAGE SECTION.
      *    -- INCLUDE COPYBOOK (REDEFINES DEMO) --
           COPY "TX-REC.CPY".

       01  WS-STATUS-FLAGS.
           05  WS-IN-STATUS            PIC X(02) VALUE "00".
           05  WS-OUT-STATUS           PIC X(02) VALUE "00".
           05  WS-EOF-FLAG             PIC X(01) VALUE "N".
               88  EOF-YES             VALUE "Y".
               88  EOF-NO              VALUE "N".

       01  WS-COUNTERS.
           05  WS-CNT-TOTAL            PIC 9(05) VALUE ZERO.
           05  WS-CNT-DEP              PIC 9(05) VALUE ZERO.
           05  WS-CNT-WDR              PIC 9(05) VALUE ZERO.
           05  WS-CNT-XFR              PIC 9(05) VALUE ZERO.

       01  WS-TOTALS.
           05  WS-SUM-DEP              PIC S9(11)V99 COMP-3 VALUE ZERO.
           05  WS-SUM-WDR              PIC S9(11)V99 COMP-3 VALUE ZERO.
           05  WS-SUM-XFR              PIC S9(11)V99 COMP-3 VALUE ZERO.
           05  WS-NET-FLOW             PIC S9(11)V99 COMP-3 VALUE ZERO.

       01  WS-DISPLAY-FIELDS.
           05  FMT-AMOUNT              PIC $$,$$$,$$9.99.
           05  FMT-NET                 PIC $$$,$$$,$$9.99CR.
           05  FMT-CNT                 PIC ZZZZ9.

       01  WS-REPORT-LINES.
           05  RPT-HEADER.
               10  FILLER              PIC X(80) VALUE
                   "==================================================".
           05  RPT-TITLE.
               10  FILLER              PIC X(32) VALUE
                   "BANK TRANSACTION SUMMARY REPORT ".
               10  FILLER              PIC X(48) VALUE SPACES.
           05  RPT-DETAIL.
               10  DET-ID              PIC X(10).
               10  FILLER              PIC X(02) VALUE SPACES.
               10  DET-TYPE            PIC X(05).
               10  FILLER              PIC X(02) VALUE SPACES.
               10  DET-ACCT            PIC X(18).
               10  FILLER              PIC X(02) VALUE SPACES.
               10  DET-AMT             PIC $$,$$$,$$9.99.
               10  FILLER              PIC X(29) VALUE SPACES.

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-TRANSACTIONS
           PERFORM 3000-GENERATE-REPORT
           PERFORM 9000-FINALIZE
           STOP RUN.

       1000-INITIALIZE.
           OPEN INPUT TX-IN-FILE
           IF WS-IN-STATUS NOT = "00"
               DISPLAY "ERROR: Failed to open tx_input.dat, Status="
                       WS-IN-STATUS
               STOP RUN
           END-IF

           OPEN OUTPUT TX-RPT-FILE
           IF WS-OUT-STATUS NOT = "00"
               DISPLAY "ERROR: Failed to open tx_report.txt, Status="
                       WS-OUT-STATUS
               CLOSE TX-IN-FILE
               STOP RUN
           END-IF

           DISPLAY "FIXEDREC: Input files opened successfully.".

       2000-PROCESS-TRANSACTIONS.
           READ TX-IN-FILE INTO TX-RECORD
               AT END SET EOF-YES TO TRUE
           END-READ

           PERFORM UNTIL EOF-YES
               PERFORM 2100-HANDLE-RECORD
               READ TX-IN-FILE INTO TX-RECORD
                   AT END SET EOF-YES TO TRUE
               END-READ
           END-PERFORM.

       2100-HANDLE-RECORD.
           ADD 1 TO WS-CNT-TOTAL

      *    -- USE 88-LEVEL CONDITIONS & REDEFINES FIELDS --
           EVALUATE TRUE
               WHEN TX-DEPOSIT
                   ADD 1 TO WS-CNT-DEP
                   ADD TX-AMOUNT TO WS-SUM-DEP
                   DISPLAY "  [DEP] Acct=" TX-DEP-ACCOUNT
                           " Branch=" TX-DEP-BRANCH
                           " Amt=" TX-AMOUNT

               WHEN TX-WITHDRAW
                   ADD 1 TO WS-CNT-WDR
                   ADD TX-AMOUNT TO WS-SUM-WDR
                   DISPLAY "  [WDR] Acct=" TX-DEP-ACCOUNT
                           " Teller=" TX-DEP-TELLER
                           " Amt=" TX-AMOUNT

               WHEN TX-TRANSFER
                   ADD 1 TO WS-CNT-XFR
                   ADD TX-AMOUNT TO WS-SUM-XFR
                   DISPLAY "  [XFR] From=" TX-XFR-FROM-ACCT
                           " To=" TX-XFR-TO-ACCT
                           " Chan=" TX-XFR-CHANNEL
                           " Amt=" TX-AMOUNT

               WHEN OTHER
                   DISPLAY "  [WARN] Unknown Transaction Type: "
                           TX-TYPE
           END-EVALUATE.

       3000-GENERATE-REPORT.
      *    Calculate net cash flow: Deposits - Withdrawals
           COMPUTE WS-NET-FLOW = WS-SUM-DEP - WS-SUM-WDR

      *    Write Report Header
           WRITE RPT-RECORD FROM RPT-HEADER
           WRITE RPT-RECORD FROM RPT-TITLE
           WRITE RPT-RECORD FROM RPT-HEADER

      *    Write Deposits Summary
           MOVE WS-SUM-DEP TO FMT-AMOUNT
           MOVE WS-CNT-DEP TO FMT-CNT
           MOVE SPACES TO RPT-RECORD
           STRING "Total Deposits    : " DELIMITED BY SIZE
                  FMT-AMOUNT DELIMITED BY SIZE
                  " (Count: " DELIMITED BY SIZE
                  FMT-CNT DELIMITED BY SIZE
                  ")" DELIMITED BY SIZE
                  INTO RPT-RECORD
           WRITE RPT-RECORD

      *    Write Withdrawals Summary
           MOVE WS-SUM-WDR TO FMT-AMOUNT
           MOVE WS-CNT-WDR TO FMT-CNT
           MOVE SPACES TO RPT-RECORD
           STRING "Total Withdrawals : " DELIMITED BY SIZE
                  FMT-AMOUNT DELIMITED BY SIZE
                  " (Count: " DELIMITED BY SIZE
                  FMT-CNT DELIMITED BY SIZE
                  ")" DELIMITED BY SIZE
                  INTO RPT-RECORD
           WRITE RPT-RECORD

      *    Write Transfers Summary
           MOVE WS-SUM-XFR TO FMT-AMOUNT
           MOVE WS-CNT-XFR TO FMT-CNT
           MOVE SPACES TO RPT-RECORD
           STRING "Total Transfers   : " DELIMITED BY SIZE
                  FMT-AMOUNT DELIMITED BY SIZE
                  " (Count: " DELIMITED BY SIZE
                  FMT-CNT DELIMITED BY SIZE
                  ")" DELIMITED BY SIZE
                  INTO RPT-RECORD
           WRITE RPT-RECORD

           WRITE RPT-RECORD FROM RPT-HEADER

      *    Write Net Flow
           MOVE WS-NET-FLOW TO FMT-NET
           MOVE SPACES TO RPT-RECORD
           STRING "Net Cash Inflow   : " DELIMITED BY SIZE
                  FMT-NET DELIMITED BY SIZE
                  INTO RPT-RECORD
           WRITE RPT-RECORD

           WRITE RPT-RECORD FROM RPT-HEADER.

       9000-FINALIZE.
           CLOSE TX-IN-FILE
           CLOSE TX-RPT-FILE
           DISPLAY "FIXEDREC: Summary report written to tx_report.txt"
           DISPLAY "FIXEDREC: Total processed = " WS-CNT-TOTAL.
