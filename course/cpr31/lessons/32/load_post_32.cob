       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOADPOST32.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT TRANSACTION-FILE ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
           SELECT ACCEPTED-FILE ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCEPTED-STATUS.
           SELECT REJECTED-FILE ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REJECTED-STATUS.
           SELECT LOG-FILE ASSIGN TO "batch.log"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-LOG-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-FILE.
       01 ACCOUNT-INPUT PIC X(27).
       FD TRANSACTION-FILE.
       01 TRANSACTION-INPUT PIC X(20).
       FD ACCEPTED-FILE.
       01 ACCEPTED-RECORD PIC X(80).
       FD REJECTED-FILE.
       01 REJECTED-RECORD PIC X(80).
       FD LOG-FILE.
       01 LOG-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       COPY "TRANSACTION.CPY".
       01 WS-ACCOUNT-STATUS PIC XX.
       01 WS-TRANSACTION-STATUS PIC XX.
       01 WS-ACCEPTED-STATUS PIC XX.
       01 WS-REJECTED-STATUS PIC XX.
       01 WS-LOG-STATUS PIC XX.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-ACCOUNT-OPEN PIC X VALUE "N".
       01 WS-TRANSACTION-OPEN PIC X VALUE "N".
       01 WS-ACCEPTED-OPEN PIC X VALUE "N".
       01 WS-REJECTED-OPEN PIC X VALUE "N".
       01 WS-LOG-OPEN PIC X VALUE "N".
       01 WS-FOUND PIC X VALUE "N".
       01 WS-INDEX PIC 99 VALUE ZERO.
       01 WS-SEARCH-INDEX PIC 99 VALUE ZERO.
       01 WS-REASON PIC X(16).
       01 WS-AMOUNT PIC S9(7)V99 COMP-3.
       01 WS-EDITED-BALANCE PIC 9(7).99.
       01 WS-OUTPUT-LINE PIC X(80).
       01 WS-LOG-LINE PIC X(100).
       LINKAGE SECTION.
       COPY "BATCH-INTERFACE.CPY".
       PROCEDURE DIVISION USING WS-ACCOUNT-TABLE WS-BATCH-COUNTS.
       MAIN-LOAD.
           PERFORM 1000-OPEN-FILES
           IF WS-FAILED NOT = "Y"
               PERFORM 1100-LOAD-ACCOUNTS
           END-IF
           IF WS-FAILED NOT = "Y"
               PERFORM 2000-POST-TRANSACTIONS
           END-IF
           PERFORM 8000-CLOSE-FILES
           GOBACK.
       1000-OPEN-FILES.
           OPEN INPUT ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS = "00"
               MOVE "Y" TO WS-ACCOUNT-OPEN
           ELSE
               DISPLAY "ERROR=OPEN ACCOUNTS " WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF
           IF WS-FAILED NOT = "Y"
               OPEN INPUT TRANSACTION-FILE
               IF WS-TRANSACTION-STATUS = "00"
                   MOVE "Y" TO WS-TRANSACTION-OPEN
               ELSE
                   DISPLAY "ERROR=OPEN TX " WS-TRANSACTION-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-FAILED NOT = "Y"
               OPEN OUTPUT ACCEPTED-FILE
               IF WS-ACCEPTED-STATUS = "00"
                   MOVE "Y" TO WS-ACCEPTED-OPEN
               ELSE
                   DISPLAY "ERROR=OPEN ACCEPTED " WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-FAILED NOT = "Y"
               OPEN OUTPUT REJECTED-FILE
               IF WS-REJECTED-STATUS = "00"
                   MOVE "Y" TO WS-REJECTED-OPEN
               ELSE
                   DISPLAY "ERROR=OPEN REJECTED " WS-REJECTED-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-FAILED NOT = "Y"
               OPEN OUTPUT LOG-FILE
               IF WS-LOG-STATUS = "00"
                   MOVE "Y" TO WS-LOG-OPEN
                   MOVE "EVENT=BATCH_START" TO WS-LOG-LINE
                   PERFORM 8200-WRITE-LOG
               ELSE
                   DISPLAY "ERROR=OPEN LOG STATUS=" WS-LOG-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
       1100-LOAD-ACCOUNTS.
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y" OR WS-FAILED = "Y"
               READ ACCOUNT-FILE
                   AT END
                       MOVE "Y" TO WS-ACCOUNT-EOF
                   NOT AT END
                       IF WS-ACCOUNT-STATUS = "00"
                           PERFORM 1110-STORE-ACCOUNT
                       ELSE
                           DISPLAY "ERR=READ ACCTS " WS-ACCOUNT-STATUS
                           MOVE "Y" TO WS-FAILED
                       END-IF
               END-READ
           END-PERFORM.
       1110-STORE-ACCOUNT.
           IF WS-ACCOUNT-COUNT = 20
               DISPLAY "ERROR=ACCOUNT CAPACITY EXCEEDED"
               MOVE "Y" TO WS-FAILED
           ELSE
               ADD 1 TO WS-ACCOUNT-COUNT
               MOVE ACCOUNT-INPUT(1:10)
                 TO WS-ACCOUNT-NO(WS-ACCOUNT-COUNT)
               MOVE ACCOUNT-INPUT(11:8)
                 TO WS-CUSTOMER-ID(WS-ACCOUNT-COUNT)
               IF ACCOUNT-INPUT(19:9) IS NUMERIC
                   COMPUTE WS-ACCOUNT-BALANCE(WS-ACCOUNT-COUNT) =
                       FUNCTION NUMVAL(ACCOUNT-INPUT(19:9)) / 100
               ELSE
                   DISPLAY "ERROR=BAD ACCOUNT BALANCE"
                   MOVE "Y" TO WS-FAILED
               END-IF
               PERFORM VARYING WS-SEARCH-INDEX FROM 1 BY 1
                 UNTIL WS-SEARCH-INDEX >= WS-ACCOUNT-COUNT
                   IF WS-ACCOUNT-NO(WS-SEARCH-INDEX) =
                      WS-ACCOUNT-NO(WS-ACCOUNT-COUNT)
                       DISPLAY "ERROR=DUPLICATE ACCOUNT="
                               WS-ACCOUNT-NO(WS-ACCOUNT-COUNT)
                       MOVE "Y" TO WS-FAILED
                   END-IF
               END-PERFORM
           END-IF.
       2000-POST-TRANSACTIONS.
           PERFORM UNTIL WS-TRANSACTION-EOF = "Y" OR WS-FAILED = "Y"
               READ TRANSACTION-FILE
                   AT END
                       MOVE "Y" TO WS-TRANSACTION-EOF
                   NOT AT END
                       IF WS-TRANSACTION-STATUS = "00"
                           PERFORM 2100-POST-ONE
                       ELSE
                           DISPLAY "ERR=READ TX " WS-TRANSACTION-STATUS
                           MOVE "Y" TO WS-FAILED
                       END-IF
               END-READ
           END-PERFORM.
       2100-POST-ONE.
           ADD 1 TO WS-TRANSACTION-COUNT
           MOVE TRANSACTION-INPUT(1:10)
             TO WS-TRANSACTION-ACCOUNT
           MOVE TRANSACTION-INPUT(11:1)
             TO WS-TRANSACTION-TYPE
           MOVE TRANSACTION-INPUT(12:9)
             TO WS-TRANSACTION-AMOUNT-TEXT
           MOVE "N" TO WS-FOUND
           MOVE ZERO TO WS-INDEX
           PERFORM VARYING WS-SEARCH-INDEX FROM 1 BY 1
             UNTIL WS-SEARCH-INDEX > WS-ACCOUNT-COUNT OR
                   WS-FOUND = "Y"
               IF WS-ACCOUNT-NO(WS-SEARCH-INDEX) =
                  WS-TRANSACTION-ACCOUNT
                   MOVE WS-SEARCH-INDEX TO WS-INDEX
                   MOVE "Y" TO WS-FOUND
               END-IF
           END-PERFORM
           MOVE SPACES TO WS-REASON
           IF WS-TRANSACTION-AMOUNT-TEXT IS NOT NUMERIC
               MOVE "BAD_AMOUNT" TO WS-REASON
           ELSE
               COMPUTE WS-AMOUNT =
                   FUNCTION NUMVAL(WS-TRANSACTION-AMOUNT-TEXT) / 100
               IF WS-FOUND NOT = "Y"
                   MOVE "NO_ACCOUNT" TO WS-REASON
               ELSE
                   PERFORM 2200-APPLY-TRANSACTION
               END-IF
           END-IF
           IF WS-REASON = SPACES
               PERFORM 2300-WRITE-POSTED
           ELSE
               PERFORM 2400-WRITE-REJECTED
           END-IF
           MOVE WS-OUTPUT-LINE TO WS-LOG-LINE
           PERFORM 8200-WRITE-LOG.
       2200-APPLY-TRANSACTION.
           EVALUATE WS-TRANSACTION-TYPE
             WHEN "D"
               ADD WS-AMOUNT TO WS-ACCOUNT-BALANCE(WS-INDEX)
             WHEN "C"
               IF WS-AMOUNT > WS-ACCOUNT-BALANCE(WS-INDEX)
                   MOVE "INSUFFICIENT" TO WS-REASON
               ELSE
                   SUBTRACT WS-AMOUNT
                     FROM WS-ACCOUNT-BALANCE(WS-INDEX)
               END-IF
             WHEN OTHER
               MOVE "BAD_TYPE" TO WS-REASON
           END-EVALUATE.
       2300-WRITE-POSTED.
           ADD 1 TO WS-POSTED-COUNT
           MOVE WS-ACCOUNT-BALANCE(WS-INDEX)
             TO WS-EDITED-BALANCE
           MOVE SPACES TO WS-OUTPUT-LINE
           STRING "POSTED TX=" WS-TRANSACTION-COUNT
                  " ACCOUNT=" WS-TRANSACTION-ACCOUNT
                  " TYPE=" WS-TRANSACTION-TYPE
                  " BALANCE=" WS-EDITED-BALANCE
               INTO WS-OUTPUT-LINE
           END-STRING
           DISPLAY FUNCTION TRIM(WS-OUTPUT-LINE)
           WRITE ACCEPTED-RECORD FROM WS-OUTPUT-LINE
           IF WS-ACCEPTED-STATUS NOT = "00"
               DISPLAY "ERROR=WRITE ACCEPTED " WS-ACCEPTED-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
       2400-WRITE-REJECTED.
           ADD 1 TO WS-REJECTED-COUNT
           MOVE SPACES TO WS-OUTPUT-LINE
           STRING "REJECTED TX=" WS-TRANSACTION-COUNT
                  " ACCOUNT=" WS-TRANSACTION-ACCOUNT
                  " REASON=" FUNCTION TRIM(WS-REASON)
               INTO WS-OUTPUT-LINE
           END-STRING
           DISPLAY FUNCTION TRIM(WS-OUTPUT-LINE)
           WRITE REJECTED-RECORD FROM WS-OUTPUT-LINE
           IF WS-REJECTED-STATUS NOT = "00"
               DISPLAY "ERROR=WRITE REJECTED " WS-REJECTED-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
       8000-CLOSE-FILES.
           IF WS-ACCOUNT-OPEN = "Y"
               CLOSE ACCOUNT-FILE
               IF WS-ACCOUNT-STATUS NOT = "00"
                   DISPLAY "ERROR=CLOSE ACCOUNTS "
                           WS-ACCOUNT-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-TRANSACTION-OPEN = "Y"
               CLOSE TRANSACTION-FILE
               IF WS-TRANSACTION-STATUS NOT = "00"
                   DISPLAY "ERROR=CLOSE TRANSACTIONS "
                           WS-TRANSACTION-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-ACCEPTED-OPEN = "Y"
               CLOSE ACCEPTED-FILE
               IF WS-ACCEPTED-STATUS NOT = "00"
                   DISPLAY "ERROR=CLOSE ACCEPTED "
                           WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-REJECTED-OPEN = "Y"
               CLOSE REJECTED-FILE
               IF WS-REJECTED-STATUS NOT = "00"
                   DISPLAY "ERROR=CLOSE REJECTED "
                           WS-REJECTED-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-LOG-OPEN = "Y"
               MOVE "EVENT=POSTING_COMPLETE" TO WS-LOG-LINE
               PERFORM 8200-WRITE-LOG
               CLOSE LOG-FILE
               IF WS-LOG-STATUS NOT = "00"
                   DISPLAY "ERROR=CLOSE LOG STATUS=" WS-LOG-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
       8200-WRITE-LOG.
           MOVE WS-LOG-LINE TO LOG-RECORD
           WRITE LOG-RECORD
           IF WS-LOG-STATUS NOT = "00"
               DISPLAY "ERROR=WRITE LOG STATUS=" WS-LOG-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
