       IDENTIFICATION DIVISION.
       PROGRAM-ID. M11CUST2.
      *> Reference implementation for module 11 maintenance 11.5:
      *> enterprise-CLASS v2 classification extract.
      *>
      *> The customer distinction is NOT the canonical CUSTOMER v1 byte
      *> 27 (that byte is the record STATUS A/D).  It lives in the
      *> independent, versioned enterprise-class lab layout (a distinct
      *> name from canonical module 07 L4 ENTERPRISE-CUSTOMER-V1): v1
      *> (23 bytes, layout 001) carries CUSTOMER-CLASSIFICATION X(1) =
      *> A/B/C/D; v2 (24 bytes, layout 002) widens it to X(2) =
      *> A1/B1/C1/D1.  This program reads the frozen v2 snapshot and
      *> writes the downstream extract.  v1 files are migrated by
      *> migrate-customer.py, never rewritten in place; a v1 file (or
      *> 27-byte CUSTOMER v1 record) is rejected by width/version.
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
       01 WS-CUST PIC X(24).
       01 WS-VER PIC X(3).
       01 WS-ID PIC X(8).
       01 WS-CLASS PIC X(2).
       01 WS-LEN PIC 9(4) COMP.
       01 WS-EOF PIC X VALUE 'N'.
       01 WS-STRUCT PIC X VALUE 'N'.
       01 WS-EXTR.
          05 FILLER PIC X(6) VALUE 'CLASS|'.
          05 WS-E-ID PIC X(8).
          05 FILLER PIC X VALUE '|'.
          05 WS-E-CLASS PIC X(2).
          05 FILLER PIC X(40) VALUE SPACES.
       01 C-COUNT PIC 9(9) COMP.
       01 C-KNOWN PIC 9(9) COMP.
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
               DISPLAY 'M11CUST2: missing environment' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN INPUT CUST-IN
           IF CUST-STAT NOT = '00'
               DISPLAY 'M11CUST2: cannot open enterprise snapshot '
                       CUST-STAT UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN OUTPUT EXTR-OUT
           OPEN OUTPUT RPT-OUT
           IF EXTR-STAT NOT = '00' OR RPT-STAT NOT = '00'
               DISPLAY 'M11CUST2: cannot open output' UPON STDERR
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
                       MOVE WS-CUST(1:3) TO WS-VER
                       IF WS-LEN NOT = 24 OR WS-VER NOT = '002'
                           DISPLAY 'M11CUST2: expected v2 24-byte '
                                   'layout (got ' WS-LEN ' ver '
                                   WS-VER ')'
                             UPON STDERR
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
               DISPLAY 'M11CUST2: structural error' UPON STDERR
               MOVE 8 TO RETURN-CODE
               GOBACK
           END-IF
           MOVE 0 TO RETURN-CODE
           GOBACK.
       2000-EXTRACT.
           ADD 1 TO C-COUNT
           MOVE WS-CUST(4:8) TO WS-ID
           MOVE WS-CUST(23:2) TO WS-CLASS
           MOVE WS-ID TO WS-E-ID
           MOVE WS-CLASS TO WS-E-CLASS
           MOVE WS-EXTR TO EXTR-LINE
           WRITE EXTR-LINE
           EVALUATE WS-CLASS
               WHEN 'A1' WHEN 'B1' WHEN 'C1' WHEN 'D1'
                   ADD 1 TO C-KNOWN
               WHEN OTHER
                   ADD 1 TO C-UNK
                   DISPLAY 'M11CUST2: unknown class code' UPON STDERR
           END-EVALUATE.
       3000-REPORT.
           MOVE SPACES TO RPT-LINE
           MOVE 1 TO WS-PTR
           STRING 'CUST2|TOTAL=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE C-COUNT TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           STRING '|KNOWN=' DELIMITED BY SIZE
               INTO RPT-LINE WITH POINTER WS-PTR
           MOVE C-KNOWN TO WS-NUM
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
