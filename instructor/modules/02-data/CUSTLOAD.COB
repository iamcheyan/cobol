       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTLOAD.
      *> Customer Record v1 (27 bytes) loader and validator (module 02
      *> reference). Validates raw byte length, key charset/order, the
      *> required name, the unsigned balance_demo digits and the status
      *> letter, then re-emits accepted rows and a control report.
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
       01 PASS-REC PIC X(27).
       FD REJECT-OUT RECORD IS VARYING IN SIZE FROM 29 TO 48
           CHARACTERS DEPENDING ON REJECT-LENGTH.
       01 REJECT-REC PIC X(48).
       WORKING-STORAGE SECTION.
       01 IN-PATH PIC X(4096).
       01 PASS-PATH PIC X(4096).
       01 REJECT-PATH PIC X(4096).
       01 IN-STATUS PIC XX.
       01 PASS-STAT PIC XX.
       01 REJECT-STAT PIC XX.
       01 REJECT-LENGTH BINARY-LONG.
       01 IN-SIZE BINARY-LONG.
       01 IN-DONE PIC 9 VALUE 0.
       01 IN-EOF PIC 9 VALUE 0.
       01 IN-RAW PIC X(27).
       01 PREV-ID PIC X(8) VALUE LOW-VALUES.
       01 REASON PIC X(14).
       01 BALANCE-VALUE PIC 9(8) VALUE 0.
       01 READ-COUNT PIC 9(12) VALUE 0.
       01 ACCEPT-COUNT PIC 9(12) VALUE 0.
       01 REJECT-COUNT PIC 9(12) VALUE 0.
       01 BALANCE-TOTAL PIC 9(18) VALUE 0.
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT IN-PATH FROM ENVIRONMENT 'INPUT_FILE'
           ACCEPT PASS-PATH FROM ENVIRONMENT 'PASS_OUTPUT_FILE'
           ACCEPT REJECT-PATH FROM ENVIRONMENT 'REJECT_OUTPUT_FILE'
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
               DISPLAY 'CONTROL:CONSERVATION' UPON STDERR
               PERFORM 9100-FAIL
           END-IF
           DISPLAY 'JOB|CUSTLOAD|V1'
           DISPLAY 'CONTROL|READ=' READ-COUNT
               '|ACCEPTED=' ACCEPT-COUNT '|REJECTED=' REJECT-COUNT
               '|BALANCE-TOTAL=' BALANCE-TOTAL
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
                           IF IN-SIZE = 27 PERFORM 9200-DATA-FAIL
                           END-IF
                           ADD 1 TO IN-SIZE
                           MOVE IN-BYTE TO IN-RAW(IN-SIZE:1)
                       END-IF
                   WHEN OTHER
                       PERFORM 9100-FAIL
               END-EVALUATE
           END-PERFORM
           IF IN-EOF = 0
               IF IN-SIZE NOT = 27 PERFORM 9200-DATA-FAIL END-IF
               PERFORM 2200-VALIDATE-ROW
           END-IF.
       2200-VALIDATE-ROW.
           IF IN-RAW(1:8) IS NOT NUMERIC PERFORM 9200-DATA-FAIL
           END-IF
           IF IN-RAW(1:8) NOT > PREV-ID PERFORM 9200-DATA-FAIL
           END-IF
           MOVE IN-RAW(1:8) TO PREV-ID
           ADD 1 TO READ-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
           END-ADD
           MOVE SPACES TO REASON
           IF IN-RAW(9:10) = SPACES
               MOVE 'NAME-MISSING' TO REASON
           ELSE
               IF IN-RAW(19:8) IS NOT NUMERIC
                   MOVE 'BAD-AMOUNT' TO REASON
               ELSE
                   IF IN-RAW(27:1) NOT = 'A' AND IN-RAW(27:1) NOT = 'D'
                       MOVE 'UNKNOWN-STATUS' TO REASON
                   END-IF
               END-IF
           END-IF
           IF REASON = SPACES
               PERFORM 2300-ACCEPT
           ELSE
               PERFORM 2400-REJECT
           END-IF.
       2300-ACCEPT.
           MOVE IN-RAW TO PASS-REC
           WRITE PASS-REC
           IF PASS-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           MOVE IN-RAW(19:8) TO BALANCE-VALUE
           ADD BALANCE-VALUE TO BALANCE-TOTAL
               ON SIZE ERROR PERFORM 9100-FAIL
           END-ADD
           ADD 1 TO ACCEPT-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
           END-ADD.
       2400-REJECT.
           MOVE SPACES TO REJECT-REC
           MOVE IN-RAW TO REJECT-REC(1:27)
           MOVE '|' TO REJECT-REC(28:1)
           MOVE REASON TO REJECT-REC(29:14)
           MOVE 42 TO REJECT-LENGTH
           WRITE REJECT-REC
           IF REJECT-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           ADD 1 TO REJECT-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
           END-ADD.
       9100-FAIL.
           DISPLAY 'FILE-STATUS=' IN-STATUS '/' PASS-STAT '/'
               REJECT-STAT UPON STDERR
           MOVE 12 TO RETURN-CODE
           STOP RUN.
       9200-DATA-FAIL.
           DISPLAY 'INVALID-CUSTOMER-RECORD' UPON STDERR
           MOVE 8 TO RETURN-CODE
           STOP RUN.
