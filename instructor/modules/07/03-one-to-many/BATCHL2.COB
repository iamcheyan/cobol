       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-MATCH-L2.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT M-FILE ASSIGN TO DYNAMIC M-PATH
               ORGANIZATION IS SEQUENTIAL FILE STATUS IS M-STAT.
           SELECT T-FILE ASSIGN TO DYNAMIC T-PATH
               ORGANIZATION IS SEQUENTIAL FILE STATUS IS T-STAT.
           SELECT R-FILE ASSIGN TO DYNAMIC R-PATH
               ORGANIZATION IS SEQUENTIAL FILE STATUS IS R-STAT.
           SELECT LEDGER ASSIGN TO DYNAMIC L-PATH
               ORGANIZATION IS INDEXED ACCESS MODE IS DYNAMIC
               RECORD KEY IS L-ID FILE STATUS IS L-STAT.
           SELECT LINKS ASSIGN TO DYNAMIC K-PATH
               ORGANIZATION IS INDEXED ACCESS MODE IS DYNAMIC
               RECORD KEY IS K-ID FILE STATUS IS K-STAT.
           SELECT MASTER-OUT ASSIGN TO DYNAMIC O-PATH
               ORGANIZATION IS LINE SEQUENTIAL FILE STATUS IS O-STAT.
           SELECT ACCEPT-OUT ASSIGN TO DYNAMIC A-PATH
               ORGANIZATION IS LINE SEQUENTIAL FILE STATUS IS A-STAT.
           SELECT REJECT-OUT ASSIGN TO DYNAMIC J-PATH
               ORGANIZATION IS LINE SEQUENTIAL FILE STATUS IS J-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD M-FILE.
       01 M-BYTE PIC X.
       FD T-FILE.
       01 T-BYTE PIC X.
       FD R-FILE.
       01 R-BYTE PIC X.
       FD LEDGER.
       01 L-REC.
          05 L-ID PIC X(16).
          05 L-ACCOUNT PIC X(10).
          05 L-SEQUENCE PIC X(6).
          05 L-AMOUNT PIC 9(13).
          05 L-DIRECTION PIC X.
          05 L-STATE PIC X.
          05 L-KIND PIC X.
       FD LINKS.
       01 K-REC.
          05 K-ID PIC X(16).
          05 K-ACCOUNT PIC X(10).
          05 K-SEQUENCE PIC X(6).
          05 K-ORIGINAL PIC X(16).
          05 K-USED PIC X.
       FD MASTER-OUT.
       01 O-REC PIC X(47).
       FD ACCEPT-OUT.
       01 A-REC PIC X(55).
       FD REJECT-OUT RECORD IS VARYING IN SIZE FROM 57 TO 80
           CHARACTERS DEPENDING ON J-LENGTH.
       01 J-REC PIC X(80).
       WORKING-STORAGE SECTION.
       01 M-PATH PIC X(4096).
       01 T-PATH PIC X(4096).
       01 R-PATH PIC X(4096).
       01 L-PATH PIC X(4096).
       01 K-PATH PIC X(4096).
       01 O-PATH PIC X(4096).
       01 A-PATH PIC X(4096).
       01 J-PATH PIC X(4096).
       01 RUN-DATE PIC X(8).
       01 CURRENT-ACCOUNT-ID PIC X(10).
       01 CURRENT-TX-ACCOUNT-ID PIC X(10).
       01 CURRENT-ACCOUNT-STATUS PIC X.
           COPY "ACCOUNT-V1.CPY".
           COPY "TRANSACTION-V1.CPY".
       01 M-STAT PIC XX.
       01 T-STAT PIC XX.
       01 R-STAT PIC XX.
       01 L-STAT PIC XX.
       01 K-STAT PIC XX.
       01 O-STAT PIC XX.
       01 A-STAT PIC XX.
       01 J-STAT PIC XX.
       01 J-LENGTH BINARY-LONG.
       01 J-POINTER BINARY-LONG.
       01 M-RAW PIC X(47).
       01 T-RAW PIC X(55).
       01 R-RAW PIC X(48).
       01 M-SIZE BINARY-LONG.
       01 T-SIZE BINARY-LONG.
       01 R-SIZE BINARY-LONG.
       01 M-EOF PIC 9 VALUE 0.
       01 T-EOF PIC 9 VALUE 0.
       01 R-EOF PIC 9 VALUE 0.
       01 M-PREV PIC X(10) VALUE LOW-VALUES.
       01 T-PREV-ACCT PIC X(10) VALUE LOW-VALUES.
       01 T-PREV-SEQ PIC X(6) VALUE LOW-VALUES.
       01 T-PREV-ID PIC X(16) VALUE LOW-VALUES.
       01 R-PREV PIC X(48) VALUE LOW-VALUES.
       01 M-DONE PIC 9.
       01 T-DONE PIC 9.
       01 R-DONE PIC 9.
       01 ACCT-COUNT PIC 9(12) VALUE 0.
       01 NO-TX-COUNT PIC 9(12) VALUE 0.
       01 TX-COUNT PIC 9(12) VALUE 0.
       01 ACCEPT-COUNT PIC 9(12) VALUE 0.
       01 REJECT-COUNT PIC 9(12) VALUE 0.
       01 A-TX-COUNT PIC 9(12) VALUE 0.
       01 A-ACCEPT-COUNT PIC 9(12) VALUE 0.
       01 A-REJECT-COUNT PIC 9(12) VALUE 0.
       01 A-CREDIT PIC 9(18) VALUE 0.
       01 A-DEBIT PIC 9(18) VALUE 0.
       01 CREDIT-TOTAL PIC 9(18) VALUE 0.
       01 DEBIT-TOTAL PIC 9(18) VALUE 0.
       01 OPENING-TOTAL PIC S9(18) COMP-3 VALUE 0.
       01 CLOSING-TOTAL PIC S9(18) COMP-3 VALUE 0.
       01 CHECK-BALANCE PIC S9(18) COMP-3 VALUE 0.
       01 TX-ACCOUNT-COUNT PIC 9(12) VALUE 0.
       01 BALANCE PIC S9(13) COMP-3 VALUE 0.
       01 OPENING PIC S9(13) COMP-3 VALUE 0.
       01 AMOUNT PIC 9(13) COMP-3 VALUE 0.
       01 AMOUNT-EDIT PIC 9(13).
       01 BALANCE-EDIT PIC 9(13).
       01 RESULT-SIGN PIC X.
       01 IN-ACCOUNT PIC X(10).
       01 IN-TX-ID PIC X(16).
       01 IN-DATE PIC X(8).
       01 IN-SEQ PIC X(6).
       01 IN-DIR PIC X.
       01 IN-AMOUNT PIC X(13).
       01 IN-STATUS PIC X.
       01 REASON PIC X(24).
       01 REVERSAL-FLAG PIC 9.
       01 SAVED-ACCOUNT PIC X(10).
       01 SAVED-ID PIC X(16).
       01 SAVED-DIR PIC X.
       01 SAVED-AMOUNT PIC 9(13).
       01 INDEX-OPEN PIC 9 VALUE 0.
       01 LINK-OPEN PIC 9 VALUE 0.
       01 I BINARY-LONG.
       01 LINK-COUNT PIC 9(12) VALUE 0.
       01 USED-LINK-COUNT PIC 9(12) VALUE 0.
       01 ACCOUNT-HAD-TX PIC 9 VALUE 0.
       01 INDEX-PASS PIC 9 VALUE 1.
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT M-PATH FROM ENVIRONMENT 'ACCOUNT_FILE'
           ACCEPT T-PATH FROM ENVIRONMENT 'TRANSACTION_FILE'
           ACCEPT R-PATH FROM ENVIRONMENT 'REVERSAL_FILE'
           ACCEPT L-PATH FROM ENVIRONMENT 'LEDGER_FILE'
           ACCEPT K-PATH FROM ENVIRONMENT 'LINKS_FILE'
           ACCEPT O-PATH FROM ENVIRONMENT 'MASTER_OUTPUT_FILE'
           ACCEPT A-PATH FROM ENVIRONMENT 'ACCEPT_OUTPUT_FILE'
           ACCEPT J-PATH FROM ENVIRONMENT 'REJECT_OUTPUT_FILE'
           ACCEPT RUN-DATE FROM ENVIRONMENT 'BUSINESS_DATE'
           IF RUN-DATE IS NOT NUMERIC OR
             FUNCTION TEST-DATE-YYYYMMDD(
               FUNCTION NUMVAL(RUN-DATE)) NOT = 0
               PERFORM 9000-DATA-FAIL
           END-IF
           OPEN INPUT M-FILE
           IF M-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           OPEN INPUT T-FILE
           IF T-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           OPEN INPUT R-FILE
           IF R-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           OPEN OUTPUT MASTER-OUT ACCEPT-OUT REJECT-OUT
           IF O-STAT NOT = '00' OR A-STAT NOT = '00' OR
              J-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           OPEN OUTPUT LEDGER
           IF L-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           CLOSE LEDGER
           IF L-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           OPEN I-O LEDGER
           IF L-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           MOVE 1 TO INDEX-OPEN
           OPEN OUTPUT LINKS
           IF K-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           MOVE 1 TO LINK-OPEN
           PERFORM 1500-LOAD-LINKS
           PERFORM 1700-INDEX-TRANSACTIONS
           PERFORM 2000-READ-MASTER
           PERFORM UNTIL M-EOF = 1 AND T-EOF = 1
               EVALUATE TRUE
                 WHEN M-EOF = 1
                   PERFORM 5000-ORPHAN-TX
                 WHEN T-EOF = 1
                   PERFORM 4000-CLOSE-ACCOUNT
                 WHEN CURRENT-ACCOUNT-ID < CURRENT-TX-ACCOUNT-ID
                   PERFORM 4000-CLOSE-ACCOUNT
                 WHEN CURRENT-ACCOUNT-ID > CURRENT-TX-ACCOUNT-ID
                   PERFORM 5000-ORPHAN-TX
                 WHEN OTHER
                   PERFORM 6000-POST-TX
               END-EVALUATE
           END-PERFORM
           PERFORM 4000-CLOSE-ACCOUNT
           IF R-EOF NOT = 1 PERFORM 9200-DATA-FAIL END-IF
           CLOSE M-FILE T-FILE R-FILE LEDGER LINKS
             MASTER-OUT ACCEPT-OUT REJECT-OUT
           IF (M-STAT NOT = '00' AND M-STAT NOT = '10') OR
              (T-STAT NOT = '00' AND T-STAT NOT = '10') OR
              (R-STAT NOT = '00' AND R-STAT NOT = '10') OR
              L-STAT NOT = '00' OR
              K-STAT NOT = '00' OR O-STAT NOT = '00' OR
              A-STAT NOT = '00' OR J-STAT NOT = '00'
               PERFORM 9100-FAIL
           END-IF
           IF TX-COUNT NOT = ACCEPT-COUNT + REJECT-COUNT
               DISPLAY 'CONTROL:TX-CONSERVATION|' TX-COUNT '|'
                 ACCEPT-COUNT '|' REJECT-COUNT UPON STDERR
               PERFORM 9100-FAIL
           END-IF
           IF LINK-COUNT NOT = USED-LINK-COUNT
               DISPLAY 'CONTROL:LINK-CONSERVATION' UPON STDERR
               PERFORM 9200-DATA-FAIL
           END-IF
           IF ACCT-COUNT NOT = NO-TX-COUNT + TX-ACCOUNT-COUNT
               DISPLAY 'CONTROL:ACCOUNT-CONSERVATION' UPON STDERR
               PERFORM 9100-FAIL
           END-IF
           COMPUTE CHECK-BALANCE = OPENING-TOTAL + CREDIT-TOTAL -
             DEBIT-TOTAL ON SIZE ERROR PERFORM 9100-FAIL
           END-COMPUTE
           IF CHECK-BALANCE NOT = CLOSING-TOTAL
               DISPLAY 'CONTROL:GLOBAL-AMOUNT' UPON STDERR
               PERFORM 9100-FAIL
           END-IF
           DISPLAY 'CONTROL|ACCOUNTS=' ACCT-COUNT
             '|NO-TX=' NO-TX-COUNT '|TX=' TX-COUNT
             '|ACCEPT=' ACCEPT-COUNT '|REJECT=' REJECT-COUNT
             '|OPENING=' OPENING-TOTAL '|CLOSING=' CLOSING-TOTAL
             '|CREDIT=' CREDIT-TOTAL '|DEBIT=' DEBIT-TOTAL
           MOVE 0 TO RETURN-CODE
           IF REJECT-COUNT > 0 MOVE 4 TO RETURN-CODE END-IF
           GOBACK.
       1500-LOAD-LINKS.
           PERFORM 3100-READ-LINK
           PERFORM UNTIL R-EOF = 1
               MOVE R-RAW(17:16) TO K-ID
               MOVE R-RAW(1:10) TO K-ACCOUNT
               MOVE R-RAW(11:6) TO K-SEQUENCE
               MOVE R-RAW(33:16) TO K-ORIGINAL
               MOVE 'N' TO K-USED
               WRITE K-REC
               IF K-STAT = '22' PERFORM 9200-DATA-FAIL END-IF
               IF K-STAT NOT = '00' PERFORM 9100-FAIL END-IF
               ADD 1 TO LINK-COUNT
                 ON SIZE ERROR PERFORM 9100-FAIL
               END-ADD
               PERFORM 3100-READ-LINK
           END-PERFORM
           CLOSE LINKS
           IF K-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           OPEN I-O LINKS
           IF K-STAT NOT = '00' PERFORM 9100-FAIL END-IF.
       1700-INDEX-TRANSACTIONS.
           PERFORM 3000-READ-TX
           PERFORM UNTIL T-EOF = 1
               PERFORM 3000-READ-TX
           END-PERFORM
           CLOSE T-FILE
           IF T-STAT NOT = '00' AND T-STAT NOT = '10'
               PERFORM 9100-FAIL
           END-IF
           OPEN INPUT T-FILE
           IF T-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           MOVE 0 TO T-EOF INDEX-PASS
           MOVE LOW-VALUES TO T-PREV-ACCT T-PREV-SEQ T-PREV-ID
           PERFORM 3000-READ-TX.
       2000-READ-MASTER.
           MOVE 0 TO M-SIZE M-DONE
           MOVE SPACES TO M-RAW
           PERFORM UNTIL M-DONE = 1
             READ M-FILE
             EVALUATE M-STAT
               WHEN '10'
                 IF M-SIZE NOT = 0 PERFORM 9200-DATA-FAIL END-IF
                 MOVE 1 TO M-EOF M-DONE
               WHEN '00'
                 IF M-BYTE = X'0A'
                   MOVE 1 TO M-DONE
                 ELSE
                   IF M-SIZE = 47 PERFORM 9200-DATA-FAIL END-IF
                   ADD 1 TO M-SIZE
                   MOVE M-BYTE TO M-RAW(M-SIZE:1)
                 END-IF
               WHEN OTHER PERFORM 9100-FAIL
             END-EVALUATE
           END-PERFORM
           IF M-EOF = 0
             IF M-SIZE NOT = 47 PERFORM 9200-DATA-FAIL END-IF
             IF M-RAW(1:18) IS NOT NUMERIC OR
                M-RAW(19:3) NOT = 'JPY' OR
                (M-RAW(22:1) NOT = '+' AND '-') OR
                M-RAW(23:13) IS NOT NUMERIC OR
                (M-RAW(36:1) NOT = 'A' AND 'F' AND 'C') OR
                M-RAW(37:8) NOT = RUN-DATE OR
                M-RAW(45:3) NOT = '001'
                  PERFORM 9200-DATA-FAIL
             END-IF
             IF M-RAW(1:10) NOT > M-PREV
                  PERFORM 9200-DATA-FAIL
             END-IF
             MOVE M-RAW(1:10) TO CURRENT-ACCOUNT-ID M-PREV
             MOVE 0 TO ACCOUNT-HAD-TX
             MOVE M-RAW(36:1) TO CURRENT-ACCOUNT-STATUS
             COMPUTE OPENING = FUNCTION NUMVAL(M-RAW(23:13))
             IF M-RAW(22:1) = '-' COMPUTE OPENING = 0 - OPENING
             END-IF
             MOVE OPENING TO BALANCE
             ADD 1 TO ACCT-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
             END-ADD
             MOVE 0 TO A-TX-COUNT A-ACCEPT-COUNT
               A-REJECT-COUNT A-CREDIT A-DEBIT
           END-IF.
       3000-READ-TX.
           MOVE 0 TO T-SIZE T-DONE
           MOVE SPACES TO T-RAW
           PERFORM UNTIL T-DONE = 1
             READ T-FILE
             EVALUATE T-STAT
               WHEN '10'
                 IF T-SIZE NOT = 0 PERFORM 9200-DATA-FAIL END-IF
                 MOVE 1 TO T-EOF T-DONE
               WHEN '00'
                 IF T-BYTE = X'0A'
                   MOVE 1 TO T-DONE
                 ELSE
                   IF T-SIZE = 55 PERFORM 9200-DATA-FAIL END-IF
                   ADD 1 TO T-SIZE
                   MOVE T-BYTE TO T-RAW(T-SIZE:1)
                 END-IF
               WHEN OTHER PERFORM 9100-FAIL
             END-EVALUATE
           END-PERFORM
           IF T-EOF = 0
             IF T-SIZE NOT = 55 PERFORM 9200-DATA-FAIL END-IF
             IF T-RAW(1:10) IS NOT NUMERIC OR
                T-RAW(11:16) = SPACES OR
                T-RAW(27:8) NOT = RUN-DATE OR
                T-RAW(35:6) IS NOT NUMERIC OR
                (T-RAW(41:1) NOT = 'C' AND 'D') OR
                T-RAW(42:13) IS NOT NUMERIC OR
                T-RAW(55:1) NOT = 'N'
                  PERFORM 9200-DATA-FAIL
             END-IF
             PERFORM VARYING I FROM 11 BY 1 UNTIL I > 26
               IF (T-RAW(I:1) < 'A' OR > 'Z') AND
                  (T-RAW(I:1) < '0' OR > '9')
                 PERFORM 9200-DATA-FAIL
               END-IF
             END-PERFORM
             MOVE T-RAW(1:10) TO IN-ACCOUNT
             MOVE T-RAW(1:10) TO CURRENT-TX-ACCOUNT-ID
             MOVE T-RAW(11:16) TO IN-TX-ID
             MOVE T-RAW(35:6) TO IN-SEQ
             IF IN-ACCOUNT < T-PREV-ACCT OR
               (IN-ACCOUNT = T-PREV-ACCT AND
                (IN-SEQ < T-PREV-SEQ OR
                 (IN-SEQ = T-PREV-SEQ AND
                  IN-TX-ID NOT > T-PREV-ID)))
                  PERFORM 9200-DATA-FAIL
             END-IF
             MOVE IN-ACCOUNT TO T-PREV-ACCT
             MOVE IN-SEQ TO T-PREV-SEQ
             MOVE IN-TX-ID TO T-PREV-ID
             IF INDEX-PASS = 1
               MOVE T-RAW(11:16) TO L-ID
               MOVE T-RAW(1:10) TO L-ACCOUNT
               MOVE T-RAW(35:6) TO L-SEQUENCE
               MOVE T-RAW(42:13) TO L-AMOUNT
               MOVE T-RAW(41:1) TO L-DIRECTION
               MOVE 'P' TO L-STATE
               MOVE 'N' TO L-KIND
               WRITE L-REC
               IF L-STAT = '22' PERFORM 9200-DATA-FAIL END-IF
               IF L-STAT NOT = '00' PERFORM 9100-FAIL END-IF
               ADD 1 TO TX-COUNT
                 ON SIZE ERROR PERFORM 9100-FAIL
               END-ADD
             END-IF
           END-IF.
       3100-READ-LINK.
           MOVE 0 TO R-SIZE R-DONE
           MOVE SPACES TO R-RAW
           PERFORM UNTIL R-DONE = 1
             READ R-FILE
             EVALUATE R-STAT
               WHEN '10'
                 IF R-SIZE NOT = 0 PERFORM 9200-DATA-FAIL END-IF
                 MOVE 1 TO R-EOF R-DONE
               WHEN '00'
                 IF R-BYTE = X'0A'
                   MOVE 1 TO R-DONE
                 ELSE
                   IF R-SIZE = 48 PERFORM 9200-DATA-FAIL END-IF
                   ADD 1 TO R-SIZE
                   MOVE R-BYTE TO R-RAW(R-SIZE:1)
                 END-IF
               WHEN OTHER PERFORM 9100-FAIL
             END-EVALUATE
           END-PERFORM
           IF R-EOF = 0
             IF R-SIZE NOT = 48 OR R-RAW(1:16) IS NOT NUMERIC
                  PERFORM 9200-DATA-FAIL
             END-IF
             PERFORM VARYING I FROM 17 BY 1 UNTIL I > 32
               IF (R-RAW(I:1) < 'A' OR > 'Z') AND
                  (R-RAW(I:1) < '0' OR > '9')
                 PERFORM 9200-DATA-FAIL
               END-IF
             END-PERFORM
             PERFORM VARYING I FROM 33 BY 1 UNTIL I > 48
               IF (R-RAW(I:1) < 'A' OR > 'Z') AND
                  (R-RAW(I:1) < '0' OR > '9')
                 PERFORM 9200-DATA-FAIL
               END-IF
             END-PERFORM
             IF R-RAW NOT > R-PREV PERFORM 9200-DATA-FAIL END-IF
             MOVE R-RAW TO R-PREV
           END-IF.
       4000-CLOSE-ACCOUNT.
           IF M-EOF = 0
             IF A-TX-COUNT NOT = A-ACCEPT-COUNT + A-REJECT-COUNT
               PERFORM 9100-FAIL
             END-IF
             IF ACCOUNT-HAD-TX = 0
               ADD 1 TO NO-TX-COUNT
                 ON SIZE ERROR PERFORM 9100-FAIL
               END-ADD
             END-IF
             IF ACCOUNT-HAD-TX = 1
               ADD 1 TO TX-ACCOUNT-COUNT
                 ON SIZE ERROR PERFORM 9100-FAIL
               END-ADD
             END-IF
             COMPUTE CHECK-BALANCE = OPENING + A-CREDIT - A-DEBIT
               ON SIZE ERROR PERFORM 9100-FAIL
             END-COMPUTE
             IF CHECK-BALANCE NOT = BALANCE PERFORM 9100-FAIL
             END-IF
             ADD OPENING TO OPENING-TOTAL
               ON SIZE ERROR PERFORM 9100-FAIL
             END-ADD
             ADD BALANCE TO CLOSING-TOTAL
               ON SIZE ERROR PERFORM 9100-FAIL
             END-ADD
             MOVE BALANCE TO BALANCE-EDIT
             MOVE '+' TO RESULT-SIGN
             IF BALANCE < 0
               MOVE '-' TO RESULT-SIGN
               COMPUTE BALANCE-EDIT = 0 - BALANCE
             END-IF
             DISPLAY 'ACCOUNT|' CURRENT-ACCOUNT-ID '|' RESULT-SIGN
               BALANCE-EDIT
             MOVE M-RAW TO O-REC
             MOVE RESULT-SIGN TO O-REC(22:1)
             MOVE BALANCE-EDIT TO O-REC(23:13)
             WRITE O-REC
             IF O-STAT NOT = '00' PERFORM 9100-FAIL END-IF
             DISPLAY 'ACCT-CONTROL|' CURRENT-ACCOUNT-ID '|TX='
               A-TX-COUNT
               '|ACCEPT=' A-ACCEPT-COUNT '|REJECT=' A-REJECT-COUNT
               '|OPENING=' M-RAW(22:1) M-RAW(23:13)
               '|CLOSING=' RESULT-SIGN BALANCE-EDIT
               '|CREDIT=' A-CREDIT '|DEBIT=' A-DEBIT
             PERFORM 2000-READ-MASTER
           END-IF.
       5000-ORPHAN-TX.
           MOVE T-RAW(11:16) TO IN-TX-ID
           MOVE IN-TX-ID TO K-ID
           READ LINKS KEY IS K-ID
           IF K-STAT = '00'
             IF K-ACCOUNT NOT = T-RAW(1:10) OR
                K-SEQUENCE NOT = T-RAW(35:6)
               PERFORM 9200-DATA-FAIL
             END-IF
             MOVE 'Y' TO K-USED
             REWRITE K-REC
             IF K-STAT NOT = '00' PERFORM 9100-FAIL END-IF
             ADD 1 TO USED-LINK-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
             END-ADD
           ELSE
             IF K-STAT NOT = '23' PERFORM 9100-FAIL END-IF
           END-IF
           DISPLAY 'TX|' IN-TX-ID '|REJECT|NO-ACCOUNT'
           MOVE SPACES TO J-REC
           MOVE 1 TO J-POINTER
           STRING T-RAW DELIMITED BY SIZE '|NO-ACCOUNT'
             DELIMITED BY SIZE INTO J-REC WITH POINTER J-POINTER
           END-STRING
           COMPUTE J-LENGTH = J-POINTER - 1
           WRITE J-REC
           IF J-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           ADD 1 TO REJECT-COUNT
             ON SIZE ERROR PERFORM 9100-FAIL
           END-ADD
           PERFORM 3000-READ-TX.
       6000-POST-TX.
           MOVE 1 TO ACCOUNT-HAD-TX
           ADD 1 TO A-TX-COUNT
             ON SIZE ERROR PERFORM 9100-FAIL
           END-ADD
           MOVE T-RAW(11:16) TO IN-TX-ID
           MOVE T-RAW(41:1) TO IN-DIR
           MOVE T-RAW(42:13) TO IN-AMOUNT
           COMPUTE AMOUNT = FUNCTION NUMVAL(IN-AMOUNT)
           MOVE SPACES TO REASON
           MOVE 0 TO REVERSAL-FLAG
           MOVE IN-TX-ID TO K-ID
           READ LINKS KEY IS K-ID
           IF K-STAT = '00'
             MOVE 1 TO REVERSAL-FLAG
             IF K-ACCOUNT NOT = CURRENT-ACCOUNT-ID OR
                K-SEQUENCE NOT = T-RAW(35:6)
               PERFORM 9200-DATA-FAIL
             END-IF
             MOVE 'Y' TO K-USED
             REWRITE K-REC
             IF K-STAT NOT = '00' PERFORM 9100-FAIL END-IF
             ADD 1 TO USED-LINK-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
             END-ADD
           ELSE
             IF K-STAT NOT = '23' PERFORM 9100-FAIL END-IF
           END-IF
           IF CURRENT-ACCOUNT-STATUS = 'F'
             MOVE 'FROZEN' TO REASON
           END-IF
           IF CURRENT-ACCOUNT-STATUS = 'C'
             MOVE 'CLOSED' TO REASON
           END-IF
           IF REASON = SPACES AND AMOUNT = 0
             MOVE 'ZERO-AMOUNT' TO REASON
           END-IF
           IF REVERSAL-FLAG = 1 AND REASON = SPACES
             MOVE K-ACCOUNT TO SAVED-ACCOUNT
             MOVE K-ORIGINAL TO L-ID
             READ LEDGER KEY IS L-ID
             EVALUATE L-STAT
               WHEN '23' MOVE 'ORIGINAL-MISSING' TO REASON
               WHEN '00'
                 IF L-ACCOUNT NOT = CURRENT-ACCOUNT-ID OR
                    SAVED-ACCOUNT NOT = CURRENT-ACCOUNT-ID
                   MOVE 'CROSS-ACCOUNT' TO REASON
                 ELSE
                   IF L-SEQUENCE NOT < IN-SEQ
                     MOVE 'REFERENCE-NOT-PRIOR' TO REASON
                   ELSE
                     IF L-STATE NOT = 'A' AND L-STATE NOT = 'V'
                       MOVE 'ORIGINAL-NOT-ACCEPTED' TO REASON
                     ELSE
                       IF L-KIND = 'R'
                         MOVE 'ORIGINAL-IS-REVERSAL' TO REASON
                       ELSE
                         IF L-STATE = 'V'
                           MOVE 'ALREADY-REVERSED' TO REASON
                         ELSE
                           IF L-DIRECTION = IN-DIR OR
                              L-AMOUNT NOT = IN-AMOUNT
                             MOVE 'REVERSAL-MISMATCH' TO REASON
                           END-IF
                         END-IF
                       END-IF
                     END-IF
                   END-IF
                 END-IF
               WHEN OTHER PERFORM 9100-FAIL
             END-EVALUATE
           END-IF
           IF CURRENT-ACCOUNT-STATUS NOT = 'A' CONTINUE
           ELSE
             IF REASON = SPACES
               IF IN-DIR = 'C'
                 IF BALANCE + AMOUNT > 9999999999999
                   MOVE 'OVERFLOW' TO REASON
                 END-IF
               ELSE
                 IF BALANCE - AMOUNT < 0
                   MOVE 'OVERDRAFT' TO REASON
                 END-IF
               END-IF
             END-IF
           END-IF
           IF REASON = SPACES
             IF IN-DIR = 'C'
               ADD AMOUNT TO BALANCE
                 ON SIZE ERROR PERFORM 9100-FAIL
               END-ADD
               ADD AMOUNT TO CREDIT-TOTAL A-CREDIT
                 ON SIZE ERROR PERFORM 9100-FAIL
               END-ADD
             ELSE
               SUBTRACT AMOUNT FROM BALANCE
                 ON SIZE ERROR PERFORM 9100-FAIL
               END-SUBTRACT
               ADD AMOUNT TO DEBIT-TOTAL A-DEBIT
                 ON SIZE ERROR PERFORM 9100-FAIL
               END-ADD
             END-IF
             ADD 1 TO ACCEPT-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
             END-ADD
             ADD 1 TO A-ACCEPT-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
             END-ADD
             MOVE BALANCE TO BALANCE-EDIT
             MOVE '+' TO RESULT-SIGN
             IF BALANCE < 0
               MOVE '-' TO RESULT-SIGN
               COMPUTE BALANCE-EDIT = 0 - BALANCE
             END-IF
             DISPLAY 'TX|' IN-TX-ID '|ACCEPT|'
               RESULT-SIGN BALANCE-EDIT
             MOVE T-RAW TO A-REC
             WRITE A-REC
             IF A-STAT NOT = '00' PERFORM 9100-FAIL END-IF
             MOVE IN-TX-ID TO L-ID
             READ LEDGER KEY IS L-ID
             IF L-STAT NOT = '00' PERFORM 9100-FAIL END-IF
             MOVE 'A' TO L-STATE
             IF REVERSAL-FLAG = 1 MOVE 'R' TO L-KIND END-IF
             REWRITE L-REC
             IF L-STAT NOT = '00' PERFORM 9100-FAIL END-IF
             IF REVERSAL-FLAG = 1
               MOVE K-ORIGINAL TO L-ID
               READ LEDGER KEY IS L-ID
               IF L-STAT NOT = '00' PERFORM 9100-FAIL END-IF
               MOVE 'V' TO L-STATE
               REWRITE L-REC
               IF L-STAT NOT = '00' PERFORM 9100-FAIL END-IF
             END-IF
           ELSE
             ADD 1 TO REJECT-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
             END-ADD
             ADD 1 TO A-REJECT-COUNT
               ON SIZE ERROR PERFORM 9100-FAIL
             END-ADD
             DISPLAY 'TX|' IN-TX-ID '|REJECT|'
               FUNCTION TRIM(REASON)
             MOVE SPACES TO J-REC
             MOVE 1 TO J-POINTER
             STRING T-RAW DELIMITED BY SIZE '|'
               DELIMITED BY SIZE FUNCTION TRIM(REASON)
               DELIMITED BY SIZE INTO J-REC WITH POINTER J-POINTER
             END-STRING
             COMPUTE J-LENGTH = J-POINTER - 1
             WRITE J-REC
             IF J-STAT NOT = '00' PERFORM 9100-FAIL END-IF
           END-IF
           PERFORM 3000-READ-TX.
       9000-DATA-FAIL.
           DISPLAY 'INVALID-DATA' UPON STDERR
           MOVE 8 TO RETURN-CODE
           STOP RUN.
       9100-FAIL.
           DISPLAY 'FILE-STATUS=' M-STAT '/' T-STAT '/' R-STAT
             '/' L-STAT '/' K-STAT UPON STDERR
           MOVE 12 TO RETURN-CODE
           STOP RUN.
       9200-DATA-FAIL.
           DISPLAY 'INVALID-RECORD' UPON STDERR
           MOVE 8 TO RETURN-CODE
           STOP RUN.
