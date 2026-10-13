       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-ENTRY.
      *> Minimal bank nightly batch entry (module 01 reference).
      *> Reads a posted ACCOUNT v1 (47 bytes) file for one business
      *> date, validates the interface, counts accepted/rejected rows
      *> and re-emits validated rows. No balance arithmetic here; the
      *> account model is introduced from module 02 onward.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO DYNAMIC IN-PATH
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS IN-STATUS.
           SELECT PASS-OUT ASSIGN TO DYNAMIC PASS-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS PASS-STAT.
           SELECT REJECT-OUT ASSIGN TO DYNAMIC REJECT-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS REJECT-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD IN-FILE.
       01 IN-BYTE PIC X.
       FD PASS-OUT.
       01 PASS-REC PIC X(47).
       FD REJECT-OUT RECORD IS VARYING IN SIZE FROM 49 TO 80
           CHARACTERS DEPENDING ON REJECT-LENGTH.
       01 REJECT-REC PIC X(80).
       WORKING-STORAGE SECTION.
       01 IN-PATH PIC X(4096).
       01 PASS-PATH PIC X(4096).
       01 REJECT-PATH PIC X(4096).
       01 RUN-DATE PIC X(8).
       01 IN-STATUS PIC XX.
       01 PASS-STAT PIC XX.
       01 REJECT-STAT PIC XX.
       01 REJECT-LENGTH BINARY-LONG.
       01 IN-SIZE BINARY-LONG.
       01 IN-DONE PIC 9 VALUE 0.
       01 IN-EOF PIC 9 VALUE 0.
       01 IN-RAW PIC X(47).
       01 PREV-ID PIC X(10) VALUE LOW-VALUES.
       01 READ-COUNT PIC 9(12) VALUE 0.
       01 ACCEPT-COUNT PIC 9(12) VALUE 0.
       01 REJECT-COUNT PIC 9(12) VALUE 0.
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT IN-PATH FROM ENVIRONMENT 'INPUT_FILE'
           ACCEPT PASS-PATH FROM ENVIRONMENT 'PASS_OUTPUT_FILE'
           ACCEPT REJECT-PATH FROM ENVIRONMENT 'REJECT_OUTPUT_FILE'
           ACCEPT RUN-DATE FROM ENVIRONMENT 'BUSINESS_DATE'
           IF RUN-DATE IS NOT NUMERIC OR
              FUNCTION TEST-DATE-YYYYMMDD(
                FUNCTION NUMVAL(RUN-DATE)) NOT = 0
               PERFORM 9000-DATA-FAIL
           END-IF
           OPEN INPUT IN-FILE
           IF IN-STATUS NOT = '00' PERFORM 9100-FAIL END-IF
           OPEN OUTPUT PASS-OUT REJECT-OUT
           IF PASS-STAT NOT = '00' OR REJECT-STAT NOT = '00'
               PERFORM 9100-FAIL
           END-IF
           PERFORM 2100-READ-INPUT
           PERFORM UNTIL IN-EOF = 1
               PERFORM 2100-READ-INPUT
           END-PERFORM
           CLOSE IN-FILE PASS-OUT REJECT-OUT
           IF (IN-STATUS NOT = '00' AND IN-STATUS NOT = '10') OR
              PASS-STAT NOT = '00' OR REJECT-STAT NOT = '00'
               PERFORM 9100-FAIL
           END-IF
           IF READ-COUNT NOT = ACCEPT-COUNT + REJECT-COUNT
               DISPLAY 'CONTROL:CONSERVATION|' READ-COUNT '|'
                   ACCEPT-COUNT '|' REJECT-COUNT UPON STDERR
               PERFORM 9100-FAIL
           END-IF
           DISPLAY 'JOB|BANK-ENTRY|V1'
           DISPLAY 'BUSINESS-DATE|' RUN-DATE
           DISPLAY 'CONTROL|READ=' READ-COUNT
               '|ACCEPTED=' ACCEPT-COUNT '|REJECTED=' REJECT-COUNT
           MOVE 0 TO RETURN-CODE
           IF REJECT-COUNT > 0 MOVE 4 TO RETURN-CODE END-IF
           GOBACK.
       2100-READ-INPUT.
           MOVE 0 TO IN-DONE IN-SIZE
           MOVE SPACES TO IN-RAW
           PERFORM UNTIL IN-DONE = 1
               READ IN-FILE
               EVALUATE IN-STATUS
                   WHEN '10'
                       IF IN-SIZE NOT = 0 PERFORM 9200-DATA-FAIL
                       END-IF
                       MOVE 1 TO IN-EOF IN-DONE
                   WHEN '00'
                       IF IN-BYTE = X'0A'
                           MOVE 1 TO IN-DONE
                       ELSE
                           IF IN-SIZE = 47 PERFORM 9200-DATA-FAIL
                           END-IF
                           ADD 1 TO IN-SIZE
                           MOVE IN-BYTE TO IN-RAW(IN-SIZE:1)
                       END-IF
                   WHEN OTHER
                       PERFORM 9100-FAIL
               END-EVALUATE
           END-PERFORM
           IF IN-EOF = 0
               IF IN-SIZE NOT = 47 PERFORM 9200-DATA-FAIL END-IF
               PERFORM 2200-VALIDATE-ROW
           END-IF.
       2200-VALIDATE-ROW.
           IF IN-RAW(1:10) IS NOT NUMERIC OR
              IN-RAW(45:3) NOT = '001' OR
              IN-RAW(37:8) NOT = RUN-DATE OR
              (IN-RAW(22:1) NOT = '+' AND IN-RAW(22:1) NOT = '-') OR
              IN-RAW(23:13) IS NOT NUMERIC OR
              IN-RAW(19:3) NOT = 'JPY'
               PERFORM 9200-DATA-FAIL
           END-IF
           IF IN-RAW(1:10) NOT > PREV-ID PERFORM 9200-DATA-FAIL
           END-IF
           MOVE IN-RAW(1:10) TO PREV-ID
           ADD 1 TO READ-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
           END-ADD
           IF IN-RAW(36:1) = 'A' OR 'F' OR 'C'
               PERFORM 2300-ACCEPT
           ELSE
               PERFORM 2400-REJECT
           END-IF.
       2300-ACCEPT.
           MOVE IN-RAW TO PASS-REC
           WRITE PASS-REC
           IF PASS-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           ADD 1 TO ACCEPT-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
           END-ADD.
       2400-REJECT.
           MOVE SPACES TO REJECT-REC
           MOVE IN-RAW TO REJECT-REC(1:47)
           MOVE '|' TO REJECT-REC(48:1)
           MOVE 'UNKNOWN-STATUS' TO REJECT-REC(49:14)
           MOVE 62 TO REJECT-LENGTH
           WRITE REJECT-REC
           IF REJECT-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           ADD 1 TO REJECT-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
           END-ADD.
       9000-DATA-FAIL.
           DISPLAY 'INVALID-BUSINESS-DATE' UPON STDERR
           MOVE 8 TO RETURN-CODE
           STOP RUN.
       9100-FAIL.
           DISPLAY 'FILE-STATUS=' IN-STATUS '/' PASS-STAT '/'
               REJECT-STAT UPON STDERR
           MOVE 12 TO RETURN-CODE
           STOP RUN.
       9200-DATA-FAIL.
           DISPLAY 'INVALID-ACCOUNT-RECORD' UPON STDERR
           MOVE 8 TO RETURN-CODE
           STOP RUN.
