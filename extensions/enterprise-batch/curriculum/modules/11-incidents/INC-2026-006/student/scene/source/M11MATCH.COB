       IDENTIFICATION DIVISION.
       PROGRAM-ID. M11MATCH.
      *
      *
      *
      *
      *
      *
      *
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-IN ASSIGN TO DYNAMIC ACCT-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS ACCT-STAT.
           SELECT TX-IN ASSIGN TO DYNAMIC TX-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS TX-STAT.
           SELECT MAST-OUT ASSIGN TO DYNAMIC MAST-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS MAST-STAT.
           SELECT ACC-OUT ASSIGN TO DYNAMIC ACC-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS ACC-STAT.
           SELECT REJ-OUT ASSIGN TO DYNAMIC REJ-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS REJ-STAT.
           SELECT RPT-OUT ASSIGN TO DYNAMIC RPT-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS RPT-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD ACCT-IN.
       01 ACCT-LINE PIC X(400).
       FD TX-IN.
       01 TX-LINE PIC X(400).
       FD MAST-OUT.
       01 MAST-LINE PIC X(47).
       FD ACC-OUT.
       01 ACC-LINE PIC X(55).
       FD REJ-OUT.
       01 REJ-LINE PIC X(66).
       FD RPT-OUT.
       01 RPT-LINE PIC X(120).
       WORKING-STORAGE SECTION.
       01 ACCT-PATH PIC X(4096).
       01 TX-PATH PIC X(4096).
       01 MAST-PATH PIC X(4096).
       01 ACC-PATH PIC X(4096).
       01 REJ-PATH PIC X(4096).
       01 RPT-PATH PIC X(4096).
       01 ACCT-STAT PIC XX.
       01 TX-STAT PIC XX.
       01 MAST-STAT PIC XX.
       01 ACC-STAT PIC XX.
       01 REJ-STAT PIC XX.
       01 RPT-STAT PIC XX.
       01 WS-MAIN-ROW PIC X(47).
       01 WS-M-ACCT PIC X(10).
       01 WS-M-SIGN PIC X.
       01 WS-M-DIGITS PIC 9(13).
       01 WS-M-VALUE PIC S9(15) COMP-3.
       01 WS-C-VALUE PIC S9(15) COMP-3.
       01 WS-C-DIGITS PIC 9(13).
       01 WS-C-ROW PIC X(47).
       01 WS-PREV-ACCT PIC X(10).
       01 WS-T-ROW PIC X(55).
       01 WS-T-ACCT PIC X(10).
       01 WS-T-KEY PIC X(32).
       01 WS-T-PREV PIC X(32).
       01 WS-T-DIR PIC X.
       01 WS-T-AMOUNT PIC 9(13).
       01 WS-EOF-M PIC X VALUE 'N'.
       01 WS-EOF-T PIC X VALUE 'N'.
       01 WS-STRUCT PIC X VALUE 'N'.
       01 WS-REASON PIC X(10).
       01 WS-LEN PIC 9(4) COMP.
       01 WS-GOT-M PIC X VALUE 'N'.
       01 WS-GOT-T PIC X VALUE 'N'.
       01 WS-REJ-REC.
          05 WS-REJ-DATA PIC X(55).
          05 FILLER PIC X.
          05 WS-REJ-CODE PIC X(10).
       01 M-COUNT PIC 9(9) COMP.
       01 T-COUNT PIC 9(9) COMP.
       01 A-COUNT PIC 9(9) COMP.
       01 R-COUNT PIC 9(9) COMP.
       01 REJ-ORPHAN PIC 9(9) COMP.
       01 REJ-OVER PIC 9(9) COMP.
       01 WS-NUM PIC 9(9).
       01 WS-NUMX PIC X(9).
       01 WS-PTR PIC 9(4) COMP.
       PROCEDURE DIVISION.
           ACCEPT ACCT-PATH FROM ENVIRONMENT 'M11MATCH_ACCOUNT'
           ACCEPT TX-PATH FROM ENVIRONMENT 'M11MATCH_TRANSACTION'
           ACCEPT MAST-PATH FROM ENVIRONMENT 'M11MATCH_MASTER_OUT'
           ACCEPT ACC-PATH FROM ENVIRONMENT 'M11MATCH_ACCEPTED'
           ACCEPT REJ-PATH FROM ENVIRONMENT 'M11MATCH_REJECTED'
           ACCEPT RPT-PATH FROM ENVIRONMENT 'M11MATCH_REPORT'
           IF ACCT-PATH = SPACES OR TX-PATH = SPACES OR
              MAST-PATH = SPACES OR ACC-PATH = SPACES OR
              REJ-PATH = SPACES OR RPT-PATH = SPACES
               DISPLAY 'M11MATCH: missing environment' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN INPUT ACCT-IN
           IF ACCT-STAT NOT = '00'
               DISPLAY 'M11MATCH: cannot open account master '
                       ACCT-STAT UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN INPUT TX-IN
           IF TX-STAT NOT = '00'
               DISPLAY 'M11MATCH: cannot open transaction ' TX-STAT
                 UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN OUTPUT MAST-OUT
           OPEN OUTPUT ACC-OUT
           OPEN OUTPUT REJ-OUT
           OPEN OUTPUT RPT-OUT
           IF MAST-STAT NOT = '00' OR ACC-STAT NOT = '00' OR
              REJ-STAT NOT = '00' OR RPT-STAT NOT = '00'
               DISPLAY 'M11MATCH: cannot open output' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           PERFORM 1000-READ-ACCOUNT
           PERFORM 2000-READ-TX
           PERFORM UNTIL WS-EOF-T = 'Y' OR WS-STRUCT = 'Y'
               PERFORM UNTIL WS-EOF-M = 'Y' OR WS-STRUCT = 'Y'
                   OR WS-M-ACCT >= WS-T-ACCT
                   PERFORM 4000-FINALIZE-ACCOUNT
                   PERFORM 1000-READ-ACCOUNT
               END-PERFORM
               IF WS-STRUCT = 'N'
                   IF WS-EOF-M = 'Y' OR WS-M-ACCT > WS-T-ACCT
                       MOVE 'ORPHAN' TO WS-REASON
                       PERFORM 5000-REJECT-TX
                   ELSE
                       PERFORM 3000-APPLY-TX
                   END-IF
               END-IF
               IF WS-STRUCT = 'N'
                   PERFORM 2000-READ-TX
               END-IF
           END-PERFORM
           PERFORM UNTIL WS-EOF-M = 'Y' OR WS-STRUCT = 'Y'
               PERFORM 4000-FINALIZE-ACCOUNT
               PERFORM 1000-READ-ACCOUNT
           END-PERFORM
           IF WS-STRUCT = 'N'
               PERFORM 6000-REPORT
           END-IF
           CLOSE ACCT-IN TX-IN MAST-OUT ACC-OUT REJ-OUT RPT-OUT
           IF WS-STRUCT = 'Y'
               DISPLAY 'M11MATCH: structural error, batch failed'
                 UPON STDERR
               MOVE 8 TO RETURN-CODE
               GOBACK
           END-IF
           IF R-COUNT > 0
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF
           GOBACK.
       1000-READ-ACCOUNT.
           READ ACCT-IN
               AT END MOVE 'Y' TO WS-EOF-M
               NOT AT END
                   MOVE ACCT-LINE TO WS-MAIN-ROW
                   COMPUTE WS-LEN =
                       FUNCTION LENGTH(FUNCTION TRIM(WS-MAIN-ROW))
                   IF WS-LEN NOT = 47
                       DISPLAY 'M11MATCH: master record length ' WS-LEN
                               ' is not 47' UPON STDERR
                       MOVE 'Y' TO WS-STRUCT
                       MOVE 'Y' TO WS-EOF-M
                   ELSE
                       MOVE WS-MAIN-ROW(1:10) TO WS-M-ACCT
                       IF WS-GOT-M = 'Y' AND WS-M-ACCT < WS-PREV-ACCT
                           DISPLAY 'M11MATCH: account master out of '
                                   'order at ' WS-M-ACCT UPON STDERR
                           MOVE 'Y' TO WS-STRUCT
                           MOVE 'Y' TO WS-EOF-M
                       ELSE
                           MOVE WS-M-ACCT TO WS-PREV-ACCT
                           MOVE 'Y' TO WS-GOT-M
                           ADD 1 TO M-COUNT
                           MOVE WS-MAIN-ROW TO WS-C-ROW
                           MOVE WS-MAIN-ROW(22:1) TO WS-M-SIGN
                           MOVE WS-MAIN-ROW(23:13) TO WS-M-DIGITS
                           MOVE WS-M-DIGITS TO WS-M-VALUE
                           IF WS-M-SIGN = '-'
                               MULTIPLY -1 BY WS-M-VALUE
                           END-IF
                           MOVE WS-M-VALUE TO WS-C-VALUE
                       END-IF
                   END-IF
           END-READ.
       2000-READ-TX.
           READ TX-IN
               AT END MOVE 'Y' TO WS-EOF-T
               NOT AT END
                   MOVE TX-LINE TO WS-T-ROW
                   COMPUTE WS-LEN =
                       FUNCTION LENGTH(FUNCTION TRIM(WS-T-ROW))
                   IF WS-LEN NOT = 55
                       DISPLAY 'M11MATCH: transaction length ' WS-LEN
                               ' is not 55' UPON STDERR
                       MOVE 'Y' TO WS-STRUCT
                       MOVE 'Y' TO WS-EOF-T
                   ELSE
                       MOVE WS-T-ROW(1:10) TO WS-T-ACCT
                       STRING WS-T-ROW(1:10) WS-T-ROW(35:6)
                              WS-T-ROW(11:16)
                              DELIMITED BY SIZE INTO WS-T-KEY
                       IF WS-GOT-T = 'Y' AND WS-T-KEY < WS-T-PREV
                           DISPLAY 'M11MATCH: transaction out of order '
                                   'at ' WS-T-ACCT UPON STDERR
                           MOVE 'Y' TO WS-STRUCT
                           MOVE 'Y' TO WS-EOF-T
                       ELSE
                           MOVE WS-T-KEY TO WS-T-PREV
                           MOVE 'Y' TO WS-GOT-T
                           ADD 1 TO T-COUNT
                           MOVE WS-T-ROW(41:1) TO WS-T-DIR
                           MOVE WS-T-ROW(42:13) TO WS-T-AMOUNT
                       END-IF
                   END-IF
           END-READ.
       3000-APPLY-TX.
           IF WS-T-DIR = 'C'
               ADD WS-T-AMOUNT TO WS-C-VALUE
               PERFORM 3500-CHECK-OVERFLOW
               IF WS-STRUCT = 'N'
                   PERFORM 5100-WRITE-ACCEPTED
               END-IF
           ELSE
               IF WS-C-VALUE - WS-T-AMOUNT < 0
                   MOVE 'OVERDRAFT' TO WS-REASON
                   PERFORM 5000-REJECT-TX
               ELSE
                   SUBTRACT WS-T-AMOUNT FROM WS-C-VALUE
                   PERFORM 3500-CHECK-OVERFLOW
                   IF WS-STRUCT = 'N'
                       PERFORM 5100-WRITE-ACCEPTED
                   END-IF
               END-IF
           END-IF.
       3500-CHECK-OVERFLOW.
           IF WS-C-VALUE > 9999999999999 OR
              WS-C-VALUE < -9999999999999
               DISPLAY 'M11MATCH: closing balance overflow for '
                       WS-M-ACCT UPON STDERR
               MOVE 'Y' TO WS-STRUCT
           END-IF.
       4000-FINALIZE-ACCOUNT.
           IF WS-GOT-M = 'N'
               EXIT PARAGRAPH
           END-IF
           MOVE FUNCTION ABS(WS-C-VALUE) TO WS-C-DIGITS
           MOVE WS-C-DIGITS TO WS-C-ROW(23:13)
           IF WS-C-VALUE < 0
               MOVE '-' TO WS-C-ROW(22:1)
           ELSE
               MOVE '+' TO WS-C-ROW(22:1)
           END-IF
           MOVE WS-C-ROW TO MAST-LINE
           WRITE MAST-LINE.
       5000-REJECT-TX.
           MOVE WS-T-ROW TO WS-REJ-DATA
           MOVE WS-REASON TO WS-REJ-CODE
           MOVE WS-REJ-REC TO REJ-LINE
           WRITE REJ-LINE
           ADD 1 TO R-COUNT
           EVALUATE WS-REASON
               WHEN 'ORPHAN'
                   ADD 1 TO REJ-ORPHAN
               WHEN 'OVERDRAFT'
                   ADD 1 TO REJ-OVER
               WHEN OTHER
                   CONTINUE
           END-EVALUATE.
       5100-WRITE-ACCEPTED.
           MOVE WS-T-ROW TO ACC-LINE
           WRITE ACC-LINE
           ADD 1 TO A-COUNT.
       6000-REPORT.
           MOVE SPACES TO RPT-LINE
           MOVE 1 TO WS-PTR
           STRING 'MATCH|ACCOUNTS=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE M-COUNT TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           STRING '|TRANSACTIONS=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE T-COUNT TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           STRING '|ACCEPTED=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE A-COUNT TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           STRING '|REJECTED=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE R-COUNT TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           WRITE RPT-LINE
           MOVE SPACES TO RPT-LINE
           MOVE 1 TO WS-PTR
           STRING 'REJ|ORPHAN=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE REJ-ORPHAN TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           STRING '|OVERDRAFT=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE REJ-OVER TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           WRITE RPT-LINE.
