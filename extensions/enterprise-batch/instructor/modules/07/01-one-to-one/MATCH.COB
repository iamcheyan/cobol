       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-MATCH-L1.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MASTER-FILE ASSIGN TO DYNAMIC M-PATH
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS M-STATUS.
           SELECT TX-FILE ASSIGN TO DYNAMIC T-PATH
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS T-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD MASTER-FILE.
       01 M-BYTE PIC X.
       FD TX-FILE.
       01 T-BYTE PIC X.
       WORKING-STORAGE SECTION.
       01 M-PATH PIC X(4096).
       01 T-PATH PIC X(4096).
       01 RUN-DATE PIC X(8).
       01 BYTE-INDEX BINARY-LONG.
           COPY "ACCOUNT-V1.CPY".
           COPY "TRANSACTION-V1.CPY".
       01 M-SIZE BINARY-LONG.
       01 T-SIZE BINARY-LONG.
       01 M-DONE PIC 9.
       01 T-DONE PIC 9.
       01 M-STATUS PIC XX.
       01 T-STATUS PIC XX.
       01 M-EOF PIC 9 VALUE 0.
       01 T-EOF PIC 9 VALUE 0.
       01 M-PREV PIC X(10) VALUE LOW-VALUES.
       01 T-PREV PIC X(10) VALUE LOW-VALUES.
       01 M-COUNT PIC 9(12) VALUE 0.
       01 T-COUNT PIC 9(12) VALUE 0.
       01 MATCH-COUNT PIC 9(12) VALUE 0.
       01 M-ONLY-COUNT PIC 9(12) VALUE 0.
       01 T-ONLY-COUNT PIC 9(12) VALUE 0.
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT M-PATH FROM ENVIRONMENT 'ACCOUNT_FILE'
           ACCEPT T-PATH FROM ENVIRONMENT 'TRANSACTION_FILE'
           ACCEPT RUN-DATE FROM ENVIRONMENT 'BUSINESS_DATE'
           IF RUN-DATE IS NOT NUMERIC
               PERFORM 9000-DATA-FAIL
           END-IF
           IF FUNCTION TEST-DATE-YYYYMMDD(
               FUNCTION NUMVAL(RUN-DATE)) NOT = 0
               PERFORM 9000-DATA-FAIL
           END-IF
           OPEN INPUT MASTER-FILE
           IF M-STATUS NOT = '00'
               PERFORM 9100-SYSTEM-FAIL
           END-IF
           OPEN INPUT TX-FILE
           IF T-STATUS NOT = '00'
               PERFORM 9100-SYSTEM-FAIL
           END-IF
           PERFORM 2000-READ-MASTER
           PERFORM 3000-READ-TX
           PERFORM UNTIL M-EOF = 1 AND T-EOF = 1
               EVALUATE TRUE
                   WHEN M-EOF = 1
                       PERFORM 5000-TX-ONLY
                   WHEN T-EOF = 1
                       PERFORM 4000-MASTER-ONLY
                   WHEN ACCOUNT-ID = TX-ACCOUNT-ID
                       DISPLAY 'MATCH|' ACCOUNT-ID
                       ADD 1 TO MATCH-COUNT
                       PERFORM 2000-READ-MASTER
                       PERFORM 3000-READ-TX
                   WHEN ACCOUNT-ID < TX-ACCOUNT-ID
                       PERFORM 4000-MASTER-ONLY
                   WHEN OTHER
                       PERFORM 5000-TX-ONLY
               END-EVALUATE
           END-PERFORM
           CLOSE MASTER-FILE TX-FILE
           IF M-STATUS NOT = '00' OR T-STATUS NOT = '00'
               PERFORM 9100-SYSTEM-FAIL
           END-IF
           IF M-COUNT NOT = MATCH-COUNT + M-ONLY-COUNT OR
               T-COUNT NOT = MATCH-COUNT + T-ONLY-COUNT
               PERFORM 9100-SYSTEM-FAIL
           END-IF
           DISPLAY 'COUNTS|' M-COUNT '|' T-COUNT '|'
               MATCH-COUNT '|' M-ONLY-COUNT '|' T-ONLY-COUNT
           MOVE 0 TO RETURN-CODE
           GOBACK.
       2000-READ-MASTER.
           MOVE 0 TO M-SIZE M-DONE
           MOVE SPACES TO ACCOUNT-RECORD
           PERFORM UNTIL M-DONE = 1
               READ MASTER-FILE
               EVALUATE M-STATUS
                   WHEN '10'
                       IF M-SIZE NOT = 0
                           DISPLAY 'MASTER:MISSING-LF' UPON STDERR
                           PERFORM 9000-DATA-FAIL
                       END-IF
                       MOVE 1 TO M-EOF M-DONE
                   WHEN '00'
                       IF M-BYTE = X'0A'
                           MOVE 1 TO M-DONE
                       ELSE
                           IF M-SIZE = 47
                               DISPLAY 'MASTER:LONG' UPON STDERR
                               PERFORM 9000-DATA-FAIL
                           END-IF
                           ADD 1 TO M-SIZE
                           MOVE M-BYTE TO ACCOUNT-RECORD(M-SIZE:1)
                       END-IF
                   WHEN OTHER
                       PERFORM 9100-SYSTEM-FAIL
               END-EVALUATE
           END-PERFORM
           IF M-EOF = 0
               IF M-SIZE NOT = 47
                   DISPLAY 'MASTER:SHORT' UPON STDERR
                   PERFORM 9000-DATA-FAIL
               END-IF
               PERFORM 2100-VALIDATE-MASTER
               IF ACCOUNT-ID NOT > M-PREV
                   DISPLAY 'MASTER:ORDER-OR-DUPLICATE'
                       UPON STDERR
                   PERFORM 9000-DATA-FAIL
               END-IF
               MOVE ACCOUNT-ID TO M-PREV
               ADD 1 TO M-COUNT
           END-IF.
       3000-READ-TX.
           MOVE 0 TO T-SIZE T-DONE
           MOVE SPACES TO TRANSACTION-RECORD
           PERFORM UNTIL T-DONE = 1
               READ TX-FILE
               EVALUATE T-STATUS
                   WHEN '10'
                       IF T-SIZE NOT = 0
                           DISPLAY 'TX:MISSING-LF' UPON STDERR
                           PERFORM 9000-DATA-FAIL
                       END-IF
                       MOVE 1 TO T-EOF T-DONE
                   WHEN '00'
                       IF T-BYTE = X'0A'
                           MOVE 1 TO T-DONE
                       ELSE
                           IF T-SIZE = 55
                               DISPLAY 'TX:LONG' UPON STDERR
                               PERFORM 9000-DATA-FAIL
                           END-IF
                           ADD 1 TO T-SIZE
                           MOVE T-BYTE TO TRANSACTION-RECORD(T-SIZE:1)
                       END-IF
                   WHEN OTHER
                       PERFORM 9100-SYSTEM-FAIL
               END-EVALUATE
           END-PERFORM
           IF T-EOF = 0
               IF T-SIZE NOT = 55
                   DISPLAY 'TX:SHORT' UPON STDERR
                   PERFORM 9000-DATA-FAIL
               END-IF
               PERFORM 3100-VALIDATE-TX
               IF TX-ACCOUNT-ID NOT > T-PREV
                   DISPLAY 'TX:ORDER-OR-DUPLICATE'
                       UPON STDERR
                   PERFORM 9000-DATA-FAIL
               END-IF
               MOVE TX-ACCOUNT-ID TO T-PREV
               ADD 1 TO T-COUNT
           END-IF.
       2100-VALIDATE-MASTER.
           IF ACCOUNT-RECORD(1:18) IS NOT NUMERIC OR
               ACCOUNT-RECORD(19:3) NOT = 'JPY' OR
               (ACCOUNT-RECORD(22:1) NOT = '+' AND '-') OR
               ACCOUNT-RECORD(23:13) IS NOT NUMERIC OR
               (ACCOUNT-RECORD(36:1) NOT = 'A' AND 'F' AND 'C') OR
               ACCOUNT-RECORD(37:8) NOT = RUN-DATE OR
               ACCOUNT-RECORD(45:3) NOT = '001'
               DISPLAY 'MASTER:FIELD' UPON STDERR
               PERFORM 9000-DATA-FAIL
           END-IF.
       3100-VALIDATE-TX.
           PERFORM VARYING BYTE-INDEX FROM 11 BY 1
               UNTIL BYTE-INDEX > 26
               IF (TRANSACTION-RECORD(BYTE-INDEX:1)
                   < 'A' OR > 'Z') AND
                   (TRANSACTION-RECORD(BYTE-INDEX:1)
                   < '0' OR > '9')
                   DISPLAY 'TX:ID-CHARACTER' UPON STDERR
                   PERFORM 9000-DATA-FAIL
               END-IF
           END-PERFORM
           IF TX-ACCOUNT-ID IS NOT NUMERIC OR
               TRANSACTION-RECORD(11:16) = SPACES OR
               TRANSACTION-RECORD(27:8) NOT = RUN-DATE OR
               TRANSACTION-RECORD(35:6) IS NOT NUMERIC OR
               (TRANSACTION-RECORD(41:1) NOT = 'C' AND 'D') OR
               TRANSACTION-RECORD(42:13) IS NOT NUMERIC OR
               TRANSACTION-RECORD(55:1) NOT = 'N'
               DISPLAY 'TX:FIELD' UPON STDERR
               PERFORM 9000-DATA-FAIL
           END-IF.
       4000-MASTER-ONLY.
           DISPLAY 'MASTER-ONLY|' ACCOUNT-ID
           ADD 1 TO M-ONLY-COUNT
           PERFORM 2000-READ-MASTER.
       5000-TX-ONLY.
           DISPLAY 'TX-ONLY|' TX-ACCOUNT-ID
           ADD 1 TO T-ONLY-COUNT
           PERFORM 3000-READ-TX.
       9000-DATA-FAIL.
           MOVE 8 TO RETURN-CODE
           STOP RUN.
       9100-SYSTEM-FAIL.
           DISPLAY 'FILE-STATUS=' M-STATUS '/' T-STATUS
               UPON STDERR
           MOVE 12 TO RETURN-CODE
           STOP RUN.
