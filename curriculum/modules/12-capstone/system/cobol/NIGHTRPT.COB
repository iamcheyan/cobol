       IDENTIFICATION DIVISION.
       PROGRAM-ID. NIGHTRPT.
      *> Module 12 capstone JOB007: build the customer-day downstream
      *> file and the human daily report from the published closing
      *> master (ACCOUNT v1, 47 bytes) joined to the enterprise customer
      *> view.
      *>
      *> The customer view is the independent CAP-CUSTOMER-FEED
      *> layout: v1 (31 bytes) or v2 (32 bytes).  Byte 27 is the record
      *> STATUS (A/D); the CLASSIFICATION is a separate field: byte 28
      *> in v1, bytes 28-29 in v2. The declared layout (NIGHTRPT_LAYOUT)
      *> must match the physical record width of every row; a mismatch
      *> is a structural error (RC8) and nothing is published.  This
      *> guard stops a wrong-layout run from silently mis-joining rows.
      *>
      *> Memory is bounded by MAX-CUST customers, not by the number of
      *> accounts: the closing master is streamed one record at a time.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-IN ASSIGN TO DYNAMIC A-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS A-STAT.
           SELECT CUST-IN ASSIGN TO DYNAMIC C-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS C-STAT.
           SELECT DAY-OUT ASSIGN TO DYNAMIC D-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS D-STAT.
           SELECT RPT-OUT ASSIGN TO DYNAMIC R-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS R-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD ACCT-IN.
       01 A-LINE PIC X(400).
       FD CUST-IN.
       01 C-LINE PIC X(400).
       FD DAY-OUT.
       01 D-LINE PIC X(30).
       FD RPT-OUT.
       01 R-LINE PIC X(120).
       WORKING-STORAGE SECTION.
       01 A-PATH PIC X(4096).
       01 C-PATH PIC X(4096).
       01 D-PATH PIC X(4096).
       01 R-PATH PIC X(4096).
       01 WS-LAYOUT PIC X(2).
       01 WS-DATE PIC X(8).
       01 A-STAT PIC XX.
       01 C-STAT PIC XX.
       01 D-STAT PIC XX.
       01 R-STAT PIC XX.
       01 WS-REC PIC X(400).
       01 WS-LEN PIC 9(4) COMP.
       01 WS-WANT PIC 9(4) COMP.
       01 WS-EOF PIC X VALUE 'N'.
       01 WS-I PIC 9(4) COMP.
       01 WS-FOUND PIC X.
       01 WS-COUNT PIC 9(9) COMP.
       01 WS-ACCT-N PIC 9(9) COMP.
       01 WS-ACCT-TOTAL PIC S9(15) COMP-3.
       01 WS-CUST-TOTAL PIC S9(15) COMP-3.
       01 WS-ED PIC -(13)9.
       01 WS-ED2 PIC -(15)9.
       01 WS-ED3 PIC -(15)9.
       01 WS-DISP-CUST PIC 9(4).
       01 WS-DISP-CNT PIC 9(9).
       01 WS-DISP-ACCT PIC 9(9).
       01 WS-OUT.
          05 WS-OUT-ID PIC X(8).
          05 WS-OUT-CLASS PIC X(2).
          05 WS-OUT-CNT PIC 9(6).
          05 WS-OUT-SIGN PIC X.
          05 WS-OUT-TOT PIC 9(13).
       01 MAX-CUST PIC 9(4) COMP VALUE 500.
       01 CUST-N PIC 9(4) COMP VALUE 0.
       01 WS-SIGN PIC S9(13) COMP-3.
       01 CUST-TBL.
          05 CUST-ROW OCCURS 500 TIMES.
             10 CT-ID PIC X(8).
             10 CT-CLASS PIC X(2).
             10 CT-COUNT PIC 9(9) COMP.
             10 CT-TOTAL PIC S9(15) COMP-3.
             10 CT-USED PIC X.
       PROCEDURE DIVISION.
           ACCEPT A-PATH FROM ENVIRONMENT 'NIGHTRPT_ACCOUNT'
           ACCEPT C-PATH FROM ENVIRONMENT 'NIGHTRPT_CUSTOMER'
           ACCEPT D-PATH FROM ENVIRONMENT 'NIGHTRPT_DAY'
           ACCEPT R-PATH FROM ENVIRONMENT 'NIGHTRPT_REPORT'
           ACCEPT WS-LAYOUT FROM ENVIRONMENT 'NIGHTRPT_LAYOUT'
           ACCEPT WS-DATE FROM ENVIRONMENT 'NIGHTRPT_DATE'
           IF A-PATH = SPACES OR C-PATH = SPACES OR D-PATH = SPACES OR
              R-PATH = SPACES OR WS-LAYOUT = SPACES
               DISPLAY 'NIGHTRPT: missing environment' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           IF WS-LAYOUT = 'v1'
               MOVE 31 TO WS-WANT
           ELSE
               IF WS-LAYOUT = 'v2'
                   MOVE 32 TO WS-WANT
               ELSE
                   DISPLAY 'NIGHTRPT: bad layout ' WS-LAYOUT UPON STDERR
                   MOVE 8 TO RETURN-CODE
                   GOBACK
               END-IF
           END-IF
           PERFORM 1000-LOAD-CUSTOMERS
           IF WS-EOF = 'Y'
               CONTINUE
           END-IF
           PERFORM 2000-ACCUMULATE
           IF RETURN-CODE = 8
               GOBACK
           END-IF
           PERFORM 3000-WRITE-DAY
           PERFORM 4000-WRITE-REPORT
           DISPLAY 'NIGHTRPT customers=' CUST-N
                   ' accounts=' WS-ACCT-N
                   ' layout=' WS-LAYOUT
           MOVE 0 TO RETURN-CODE
           GOBACK.
       1000-LOAD-CUSTOMERS.
           OPEN INPUT CUST-IN
           IF C-STAT NOT = '00'
               DISPLAY 'NIGHTRPT: cannot open customer ' C-STAT
                 UPON STDERR
               MOVE 12 TO RETURN-CODE
               MOVE 'Y' TO WS-EOF
               EXIT PARAGRAPH
           END-IF
           MOVE 'N' TO WS-EOF
           PERFORM UNTIL WS-EOF = 'Y'
               READ CUST-IN
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       MOVE C-LINE TO WS-REC
                       COMPUTE WS-LEN =
                           FUNCTION LENGTH(FUNCTION TRIM(WS-REC))
                       IF WS-LEN NOT = WS-WANT
                           DISPLAY 'NIGHTRPT: customer width ' WS-LEN
                                   ' != layout ' WS-LAYOUT UPON STDERR
                           MOVE 8 TO RETURN-CODE
                           MOVE 'Y' TO WS-EOF
                           EXIT PERFORM
                       END-IF
                       IF CUST-N >= MAX-CUST
                           DISPLAY 'NIGHTRPT: too many customers'
                             UPON STDERR
                           MOVE 8 TO RETURN-CODE
                           MOVE 'Y' TO WS-EOF
                           EXIT PERFORM
                       END-IF
                       ADD 1 TO CUST-N
                       MOVE WS-REC(1:8) TO CT-ID(CUST-N)
                       IF WS-LAYOUT = 'v1'
                           MOVE WS-REC(28:1) TO CT-CLASS(CUST-N)(1:1)
                           MOVE '1' TO CT-CLASS(CUST-N)(2:1)
                       ELSE
                           MOVE WS-REC(28:2) TO CT-CLASS(CUST-N)
                       END-IF
                       MOVE 0 TO CT-COUNT(CUST-N)
                       MOVE 0 TO CT-TOTAL(CUST-N)
                       MOVE 'Y' TO CT-USED(CUST-N)
               END-READ
           END-PERFORM
           CLOSE CUST-IN
           .
       2000-ACCUMULATE.
           OPEN INPUT ACCT-IN
           IF A-STAT NOT = '00'
               DISPLAY 'NIGHTRPT: cannot open closing master ' A-STAT
                 UPON STDERR
               MOVE 12 TO RETURN-CODE
               EXIT PARAGRAPH
           END-IF
           MOVE 'N' TO WS-EOF
           MOVE 0 TO WS-ACCT-N
           MOVE 0 TO WS-ACCT-TOTAL
           PERFORM UNTIL WS-EOF = 'Y'
               READ ACCT-IN
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       MOVE A-LINE TO WS-REC
                       COMPUTE WS-LEN =
                           FUNCTION LENGTH(FUNCTION TRIM(WS-REC))
                       IF WS-LEN NOT = 47
                           DISPLAY 'NIGHTRPT: closing width ' WS-LEN
                             UPON STDERR
                           MOVE 8 TO RETURN-CODE
                           MOVE 'Y' TO WS-EOF
                           EXIT PERFORM
                       END-IF
                       ADD 1 TO WS-ACCT-N
                       PERFORM 2100-APPLY-ONE
               END-READ
           END-PERFORM
           CLOSE ACCT-IN
           .
       2100-APPLY-ONE.
           MOVE 'N' TO WS-FOUND
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > CUST-N
               IF CT-ID(WS-I) = WS-REC(11:8)
                   MOVE 'Y' TO WS-FOUND
                       ADD 1 TO CT-COUNT(WS-I)
                       IF WS-REC(22:1) = '-'
                           COMPUTE WS-SIGN = -1 *
                               FUNCTION NUMVAL(WS-REC(23:13))
                       ELSE
                           COMPUTE WS-SIGN =
                               FUNCTION NUMVAL(WS-REC(23:13))
                       END-IF
                       ADD WS-SIGN TO CT-TOTAL(WS-I)
                       ADD WS-SIGN TO WS-ACCT-TOTAL
               END-IF
           END-PERFORM
           IF WS-FOUND = 'N'
               DISPLAY 'NIGHTRPT: account customer ' WS-REC(11:8)
                       ' has no customer row' UPON STDERR
               MOVE 8 TO RETURN-CODE
           END-IF
           .
       3000-WRITE-DAY.
           OPEN OUTPUT DAY-OUT
           IF D-STAT NOT = '00'
               DISPLAY 'NIGHTRPT: cannot open day output' UPON STDERR
               MOVE 12 TO RETURN-CODE
               EXIT PARAGRAPH
           END-IF
           MOVE 0 TO WS-COUNT
           MOVE 0 TO WS-CUST-TOTAL
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > CUST-N
               MOVE CT-ID(WS-I) TO WS-OUT-ID
               MOVE CT-CLASS(WS-I) TO WS-OUT-CLASS
               MOVE CT-COUNT(WS-I) TO WS-OUT-CNT
               IF CT-TOTAL(WS-I) < 0
                   MOVE '-' TO WS-OUT-SIGN
                   COMPUTE WS-OUT-TOT = -1 * CT-TOTAL(WS-I)
               ELSE
                   MOVE '+' TO WS-OUT-SIGN
                   MOVE CT-TOTAL(WS-I) TO WS-OUT-TOT
               END-IF
               MOVE WS-OUT TO D-LINE
               WRITE D-LINE
               ADD 1 TO WS-COUNT
               ADD CT-TOTAL(WS-I) TO WS-CUST-TOTAL
           END-PERFORM
           CLOSE DAY-OUT
           IF WS-CUST-TOTAL NOT = WS-ACCT-TOTAL
               DISPLAY 'NIGHTRPT: customer total ' WS-CUST-TOTAL
                       ' != account total ' WS-ACCT-TOTAL UPON STDERR
               MOVE 8 TO RETURN-CODE
           END-IF
           .
       4000-WRITE-REPORT.
           OPEN OUTPUT RPT-OUT
           IF R-STAT NOT = '00'
               DISPLAY 'NIGHTRPT: cannot open report' UPON STDERR
               MOVE 12 TO RETURN-CODE
               EXIT PARAGRAPH
           END-IF
           MOVE SPACES TO R-LINE
           STRING 'CUSTOMER-DAY REPORT business_date=' WS-DATE
                  DELIMITED BY SIZE INTO R-LINE
           WRITE R-LINE
           MOVE CUST-N TO WS-DISP-CUST
           MOVE SPACES TO R-LINE
           STRING 'layout=' WS-LAYOUT ' customers=' WS-DISP-CUST
                  DELIMITED BY SIZE INTO R-LINE
           WRITE R-LINE
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > CUST-N
               MOVE CT-TOTAL(WS-I) TO WS-ED
               MOVE CT-COUNT(WS-I) TO WS-DISP-CNT
               MOVE SPACES TO R-LINE
               STRING 'CUST|' CT-ID(WS-I) '|' CT-CLASS(WS-I)
                      '|ACCOUNTS=' WS-DISP-CNT '|TOTAL=' WS-ED
                      DELIMITED BY SIZE INTO R-LINE
               WRITE R-LINE
           END-PERFORM
           MOVE SPACES TO R-LINE
           MOVE WS-ACCT-TOTAL TO WS-ED2
           MOVE WS-CUST-TOTAL TO WS-ED3
           MOVE WS-ACCT-N TO WS-DISP-ACCT
           STRING 'CONTROL|ACCOUNTS=' WS-DISP-ACCT '|ACCOUNT_TOTAL='
                  WS-ED2 '|CUSTOMER_TOTAL=' WS-ED3 DELIMITED BY SIZE
                  INTO R-LINE
           WRITE R-LINE
           CLOSE RPT-OUT
           .
