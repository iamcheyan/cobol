       IDENTIFICATION DIVISION.
       PROGRAM-ID. M11CUST.
      *> Snapshot job JOB007C: customer STATUS extract for the
      *> downstream feed.  Reads the frozen CUSTOMER v1 snapshot
      *> (27 bytes: id 8, name 10, demo balance 8, status 1) and writes
      *> one extract line per customer plus per-status counts.
      *> Byte 27 is the record status (A active / D dormant), NOT a
      *> customer classification; the 11.5 maintenance task works on a
      *> separate, versioned enterprise layout and never edits this
      *> byte.  The offsets here are the frozen v1 contract, not a
      *> guess.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUST-IN ASSIGN TO DYNAMIC CUST-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS CUST-STAT.
           SELECT EXTR-OUT ASSIGN TO DYNAMIC EXTR-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS EXTR-STAT.
           SELECT RPT-OUT ASSIGN TO DYNAMIC RPT-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS RPT-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD CUST-IN.
       01 CUST-LINE PIC X(400).
       FD EXTR-OUT.
       01 EXTR-LINE PIC X(57).
       FD RPT-OUT.
       01 RPT-LINE PIC X(120).
       WORKING-STORAGE SECTION.
       01 CUST-PATH PIC X(4096).
       01 EXTR-PATH PIC X(4096).
       01 RPT-PATH PIC X(4096).
       01 CUST-STAT PIC XX.
       01 EXTR-STAT PIC XX.
       01 RPT-STAT PIC XX.
       01 WS-CUST PIC X(27).
       01 WS-ID PIC X(8).
       01 WS-STATUS PIC X.
       01 WS-LEN PIC 9(4) COMP.
       01 WS-EOF PIC X VALUE 'N'.
       01 WS-STRUCT PIC X VALUE 'N'.
       01 WS-EXTR.
          05 FILLER PIC X(7) VALUE 'STATUS|'.
          05 WS-E-ID PIC X(8).
          05 FILLER PIC X VALUE '|'.
          05 WS-E-STATUS PIC X.
          05 FILLER PIC X(40) VALUE SPACES.
       01 C-COUNT PIC 9(9) COMP.
       01 C-A PIC 9(9) COMP.
       01 C-D PIC 9(9) COMP.
       01 C-UNK PIC 9(9) COMP.
       01 WS-NUM PIC 9(9).
       01 WS-NUMX PIC X(9).
       01 WS-PTR PIC 9(4) COMP.
       PROCEDURE DIVISION.
           ACCEPT CUST-PATH FROM ENVIRONMENT 'M11CUST_INPUT'
           ACCEPT EXTR-PATH FROM ENVIRONMENT 'M11CUST_EXTRACT'
           ACCEPT RPT-PATH FROM ENVIRONMENT 'M11CUST_REPORT'
           IF CUST-PATH = SPACES OR EXTR-PATH = SPACES OR
              RPT-PATH = SPACES
               DISPLAY 'M11CUST: missing environment' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN INPUT CUST-IN
           IF CUST-STAT NOT = '00'
               DISPLAY 'M11CUST: cannot open customer snapshot '
                       CUST-STAT UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN OUTPUT EXTR-OUT
           OPEN OUTPUT RPT-OUT
           IF EXTR-STAT NOT = '00' OR RPT-STAT NOT = '00'
               DISPLAY 'M11CUST: cannot open output' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           PERFORM UNTIL WS-EOF = 'Y'
               READ CUST-IN
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       MOVE CUST-LINE TO WS-CUST
                       COMPUTE WS-LEN =
                           FUNCTION LENGTH(FUNCTION TRIM(WS-CUST))
                       IF WS-LEN NOT = 27
                           DISPLAY 'M11CUST: customer record length '
                                   WS-LEN ' is not 27' UPON STDERR
                           MOVE 'Y' TO WS-STRUCT
                           MOVE 'Y' TO WS-EOF
                       ELSE
                           PERFORM 2000-EXTRACT
                       END-IF
               END-READ
           END-PERFORM
           IF WS-STRUCT = 'N'
               PERFORM 3000-REPORT
           END-IF
           CLOSE CUST-IN EXTR-OUT RPT-OUT
           IF WS-STRUCT = 'Y'
               DISPLAY 'M11CUST: structural error' UPON STDERR
               MOVE 8 TO RETURN-CODE
               GOBACK
           END-IF
           MOVE 0 TO RETURN-CODE
           GOBACK.
       2000-EXTRACT.
           ADD 1 TO C-COUNT
           MOVE WS-CUST(1:8) TO WS-ID
           MOVE WS-CUST(27:1) TO WS-STATUS
           MOVE WS-ID TO WS-E-ID
           MOVE WS-STATUS TO WS-E-STATUS
           MOVE WS-EXTR TO EXTR-LINE
           WRITE EXTR-LINE
           EVALUATE WS-STATUS
               WHEN 'A'
                   ADD 1 TO C-A
               WHEN 'D'
                   ADD 1 TO C-D
               WHEN OTHER
                   ADD 1 TO C-UNK
                   DISPLAY 'M11CUST: unknown status code' UPON STDERR
           END-EVALUATE.
       3000-REPORT.
           MOVE SPACES TO RPT-LINE
           MOVE 1 TO WS-PTR
           STRING 'CUST|TOTAL=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE C-COUNT TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           STRING '|A=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE C-A TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           STRING '|D=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE C-D TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           STRING '|UNKNOWN=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE C-UNK TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           WRITE RPT-LINE.
