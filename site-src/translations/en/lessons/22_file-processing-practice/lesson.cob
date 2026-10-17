      * Transactions: 20 chars; master: 27, unique/sorted; unchecked.
      * Require matching accounts, D/C type, and numeric amount.
      * OPEN OUTPUT truncates results; errors can leave partial output.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCH22.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-INPUT
               ASSIGN TO "transactions-unsorted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
           SELECT ACCOUNT-MASTER
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-M-STATUS.
           SELECT ACCEPTED-FILE
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCEPTED-STATUS.
           SELECT REJECTED-FILE
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REJECTED-STATUS.
           SELECT SORT-WORK ASSIGN TO DISK.
       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-INPUT.
       01 FD-TRANSACTION-RAW PIC X(100).
       FD ACCOUNT-MASTER.
       01 FD-MASTER-RAW PIC X(100).
       FD ACCEPTED-FILE.
       01 FD-ACCEPTED-RECORD PIC X(28).
       FD REJECTED-FILE.
       01 FD-REJECTED-RECORD PIC X(30).
       SD SORT-WORK.
       01 SD-TRANSACTION-RECORD.
          05 SD-TRANSACTION-ACCOUNT PIC X(10).
          05 SD-TRANSACTION-TYPE PIC X.
          05 SD-TRANSACTION-AMOUNT PIC X(9).
       WORKING-STORAGE SECTION.
       01 WS-INPUT-STATUS PIC XX VALUE SPACES.
       01 WS-M-STATUS PIC XX VALUE SPACES.
       01 WS-ACCEPTED-STATUS PIC XX VALUE SPACES.
       01 WS-REJECTED-STATUS PIC XX VALUE SPACES.
       01 WS-INPUT-EOF PIC X VALUE "N".
       01 WS-MASTER-EOF PIC X VALUE "N".
       01 WS-SORT-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-MASTER-OPEN PIC X VALUE "N".
       01 WS-ACCEPTED-OPEN PIC X VALUE "N".
       01 WS-REJECTED-OPEN PIC X VALUE "N".
       01 WS-INPUT-LENGTH PIC 9(3) VALUE ZERO.
       01 WS-MASTER-LENGTH PIC 9(3) VALUE ZERO.
       01 WS-MASTER-ACCOUNT PIC X(10) VALUE SPACES.
       01 WS-MASTER-CUSTOMER PIC X(8) VALUE SPACES.
       01 WS-MASTER-BALANCE PIC X(9) VALUE SPACES.
       01 WS-REJECT-REASON PIC X(10) VALUE SPACES.
       01 WS-ACCEPTED-RECORD PIC X(28) VALUE SPACES.
       01 WS-REJECTED-RECORD PIC X(30) VALUE SPACES.
       01 WS-INPUT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-SORTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCEPTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-MASTER-ONLY-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           SORT SORT-WORK ON ASCENDING KEY SD-TRANSACTION-ACCOUNT
               INPUT PROCEDURE 1000-LOAD-TRANSACTIONS
               OUTPUT PROCEDURE 2000-RECONCILE-TRANSACTIONS.
           IF SORT-RETURN NOT = ZERO
               DISPLAY "SORT=FAILED STATUS=" SORT-RETURN
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "输入记录数=" WS-INPUT-COUNT
               " 排序记录数=" WS-SORTED-COUNT
           DISPLAY "接受记录数=" WS-ACCEPTED-COUNT
           DISPLAY "拒绝记录数=" WS-REJECTED-COUNT
               " MASTER_ONLY账户记录数=" WS-MASTER-ONLY-COUNT
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       1000-LOAD-TRANSACTIONS.
           OPEN INPUT TRANSACTION-INPUT
           IF WS-INPUT-STATUS NOT = "00"
               DISPLAY "OPEN=TXN STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           ELSE
               PERFORM UNTIL WS-INPUT-EOF = "Y"
                   OR WS-IO-ERROR = "Y"
                   PERFORM 1100-READ-AND-RELEASE
               END-PERFORM
               CLOSE TRANSACTION-INPUT
               IF WS-INPUT-STATUS NOT = "00"
                   DISPLAY "CLOSE=TXN STATUS=" WS-INPUT-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
       1100-READ-AND-RELEASE.
           READ TRANSACTION-INPUT
               AT END
                   MOVE "Y" TO WS-INPUT-EOF
               NOT AT END
                   IF WS-INPUT-STATUS = "00"
                       PERFORM 1110-VALIDATE-TRANSACTION-WIDTH
                   END-IF
           END-READ
           IF WS-INPUT-STATUS NOT = "00" AND WS-INPUT-STATUS NOT = "10"
               DISPLAY "READ=TXN STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       1110-VALIDATE-TRANSACTION-WIDTH.
           COMPUTE WS-INPUT-LENGTH = FUNCTION LENGTH(
               FUNCTION TRIM(FD-TRANSACTION-RAW TRAILING))
           IF WS-INPUT-LENGTH NOT = 20
               DISPLAY "TRANSACTION=REJECTED REASON=BAD_WIDTH"
               MOVE "Y" TO WS-IO-ERROR
           ELSE
               MOVE FD-TRANSACTION-RAW(1:20) TO SD-TRANSACTION-RECORD
               RELEASE SD-TRANSACTION-RECORD
               IF SORT-RETURN = ZERO
                   ADD 1 TO WS-INPUT-COUNT
               ELSE
                   DISPLAY "RELEASE=FAILED STATUS=" SORT-RETURN
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
       2000-RECONCILE-TRANSACTIONS.
           IF WS-IO-ERROR = "N"
               PERFORM 2100-OPEN-OUTPUTS
           END-IF
           IF WS-IO-ERROR = "N"
               PERFORM 3000-READ-MASTER
               PERFORM UNTIL WS-SORT-EOF = "Y"
                   OR WS-IO-ERROR = "Y"
                   PERFORM 4000-RETURN-ONE-TRANSACTION
               END-PERFORM
           END-IF
           IF WS-IO-ERROR = "N"
               PERFORM UNTIL WS-MASTER-EOF = "Y"
                   OR WS-IO-ERROR = "Y"
                   PERFORM 5000-REPORT-MASTER-ONLY
               END-PERFORM
           END-IF
           PERFORM 9000-CLOSE-OUTPUTS.
       2100-OPEN-OUTPUTS.
           OPEN INPUT ACCOUNT-MASTER
           IF WS-M-STATUS = "00"
               MOVE "Y" TO WS-MASTER-OPEN
           ELSE
               DISPLAY "OPEN=MASTER STATUS=" WS-M-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           IF WS-IO-ERROR = "N"
               OPEN OUTPUT ACCEPTED-FILE
               IF WS-ACCEPTED-STATUS = "00"
                   MOVE "Y" TO WS-ACCEPTED-OPEN
               ELSE
                   DISPLAY "OPEN=ACCEPTED STATUS=" WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF
           IF WS-IO-ERROR = "N"
               OPEN OUTPUT REJECTED-FILE
               IF WS-REJECTED-STATUS = "00"
                   MOVE "Y" TO WS-REJECTED-OPEN
               ELSE
                   DISPLAY "OPEN=REJECTED STATUS=" WS-REJECTED-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
       4000-RETURN-ONE-TRANSACTION.
           RETURN SORT-WORK
               AT END
                   MOVE "Y" TO WS-SORT-EOF
               NOT AT END
                   IF SORT-RETURN = ZERO
                       ADD 1 TO WS-SORTED-COUNT
                       PERFORM 4100-MATCH-TRANSACTION
                   ELSE
                       DISPLAY "RETURN=FAILED STATUS=" SORT-RETURN
                       MOVE "Y" TO WS-IO-ERROR
                   END-IF
           END-RETURN.
       4100-MATCH-TRANSACTION.
           PERFORM UNTIL WS-MASTER-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               IF WS-MASTER-ACCOUNT < SD-TRANSACTION-ACCOUNT
                   PERFORM 5000-REPORT-MASTER-ONLY
               ELSE
                   EXIT PERFORM
               END-IF
           END-PERFORM
           IF WS-IO-ERROR = "N"
               IF WS-MASTER-EOF = "Y"
                   OR WS-MASTER-ACCOUNT NOT =
                       SD-TRANSACTION-ACCOUNT
                   MOVE "NO_ACCOUNT" TO WS-REJECT-REASON
                   PERFORM 6100-WRITE-REJECTED
               ELSE
                   PERFORM 6000-VALIDATE-MATCHED-TRANSACTION
                   IF WS-IO-ERROR = "N"
                       PERFORM 3000-READ-MASTER
                   END-IF
               END-IF
           END-IF.
       6000-VALIDATE-MATCHED-TRANSACTION.
           EVALUATE TRUE
               WHEN SD-TRANSACTION-TYPE NOT = "D"
                   AND SD-TRANSACTION-TYPE NOT = "C"
                   MOVE "BAD_TYPE__" TO WS-REJECT-REASON
                   PERFORM 6100-WRITE-REJECTED
               WHEN SD-TRANSACTION-AMOUNT IS NOT NUMERIC
                   MOVE "BAD_AMOUNT" TO WS-REJECT-REASON
                   PERFORM 6100-WRITE-REJECTED
               WHEN OTHER
                   PERFORM 6200-WRITE-ACCEPTED
           END-EVALUATE.
       6100-WRITE-REJECTED.
           MOVE SD-TRANSACTION-ACCOUNT TO WS-REJECTED-RECORD(1:10)
           MOVE WS-REJECT-REASON TO WS-REJECTED-RECORD(11:10)
           MOVE SD-TRANSACTION-TYPE TO WS-REJECTED-RECORD(21:1)
           MOVE SD-TRANSACTION-AMOUNT TO WS-REJECTED-RECORD(22:9)
           WRITE FD-REJECTED-RECORD FROM WS-REJECTED-RECORD
           IF WS-REJECTED-STATUS = "00"
               ADD 1 TO WS-REJECTED-COUNT
               DISPLAY "被拒绝 账号=" SD-TRANSACTION-ACCOUNT
                   " REASON=" WS-REJECT-REASON
           ELSE
               DISPLAY "WRITE=REJECT STATUS=" WS-REJECTED-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       6200-WRITE-ACCEPTED.
           MOVE SD-TRANSACTION-ACCOUNT TO WS-ACCEPTED-RECORD(1:10)
           MOVE WS-MASTER-CUSTOMER TO WS-ACCEPTED-RECORD(11:8)
           MOVE SD-TRANSACTION-TYPE TO WS-ACCEPTED-RECORD(19:1)
           MOVE SD-TRANSACTION-AMOUNT TO WS-ACCEPTED-RECORD(20:9)
           WRITE FD-ACCEPTED-RECORD FROM WS-ACCEPTED-RECORD
           IF WS-ACCEPTED-STATUS = "00"
               ADD 1 TO WS-ACCEPTED-COUNT
               DISPLAY "ACCEPTED 账号=" SD-TRANSACTION-ACCOUNT
           ELSE
               DISPLAY "WRITE=ACCEPT STATUS=" WS-ACCEPTED-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       3000-READ-MASTER.
           READ ACCOUNT-MASTER
               AT END
                   MOVE "Y" TO WS-MASTER-EOF
               NOT AT END
                   IF WS-M-STATUS = "00"
                       PERFORM 3100-VALIDATE-MASTER
                   END-IF
           END-READ
           IF WS-M-STATUS NOT = "00" AND WS-M-STATUS NOT = "10"
               DISPLAY "READ=MASTER STATUS=" WS-M-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       3100-VALIDATE-MASTER.
           COMPUTE WS-MASTER-LENGTH = FUNCTION LENGTH(
               FUNCTION TRIM(FD-MASTER-RAW TRAILING))
           IF WS-MASTER-LENGTH NOT = 27
               DISPLAY "MASTER=FAILED REASON=BAD_WIDTH"
               MOVE "Y" TO WS-IO-ERROR
           ELSE
               MOVE FD-MASTER-RAW(1:10) TO WS-MASTER-ACCOUNT
               MOVE FD-MASTER-RAW(11:8) TO WS-MASTER-CUSTOMER
               MOVE FD-MASTER-RAW(19:9) TO WS-MASTER-BALANCE
               IF WS-MASTER-BALANCE IS NOT NUMERIC
                   DISPLAY "MASTER=FAILED REASON=BAD_BALANCE"
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
       5000-REPORT-MASTER-ONLY.
           ADD 1 TO WS-MASTER-ONLY-COUNT
           DISPLAY "MASTER_ONLY账户 账号=" WS-MASTER-ACCOUNT
           PERFORM 3000-READ-MASTER.
       9000-CLOSE-OUTPUTS.
           IF WS-MASTER-OPEN = "Y"
               CLOSE ACCOUNT-MASTER
               IF WS-M-STATUS NOT = "00"
                   DISPLAY "CLOSE=MASTER STATUS=" WS-M-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
               MOVE "N" TO WS-MASTER-OPEN
           END-IF
           IF WS-ACCEPTED-OPEN = "Y"
               CLOSE ACCEPTED-FILE
               IF WS-ACCEPTED-STATUS NOT = "00"
                   DISPLAY "CLOSE=ACCEPTED STATUS=" WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
               MOVE "N" TO WS-ACCEPTED-OPEN
           END-IF
           IF WS-REJECTED-OPEN = "Y"
               CLOSE REJECTED-FILE
               IF WS-REJECTED-STATUS NOT = "00"
                   DISPLAY "CLOSE=REJECTED STATUS=" WS-REJECTED-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
               MOVE "N" TO WS-REJECTED-OPEN
           END-IF.
