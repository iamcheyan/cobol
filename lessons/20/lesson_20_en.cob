      * Lesson 20: match two sorted account files by account number.
      * Master rows are 27 characters; transaction rows are 20.
      * Each input is sorted ascending by its ten-character key.
      * The merge classifies matches and records present on one side.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MATCH20.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-MASTER
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT DAILY-TRANSACTIONS
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-MASTER.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
       FD DAILY-TRANSACTIONS.
       01 FD-TRANSACTION-RECORD.
          05 FD-TRANSACTION-ACCOUNT PIC X(10).
          05 FD-TRANSACTION-TYPE PIC X.
          05 FD-TRANSACTION-AMOUNT PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-TRANSACTION-STATUS PIC XX VALUE SPACES.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-MATCH-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT-ONLY-COUNT PIC 9(3) VALUE ZERO.
       01 WS-TRANSACTION-ONLY-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Open both sorted inputs before positioning either stream.
       0000-MAIN.
           OPEN INPUT ACCOUNT-MASTER
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN INPUT DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "OPEN=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               CLOSE ACCOUNT-MASTER
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=ACCOUNT OK OPEN=TRANSACTION OK"
           PERFORM 1000-READ-ACCOUNT
           PERFORM 2000-READ-TRANSACTION
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y"
               AND WS-TRANSACTION-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 3000-MATCH-CURRENT-RECORDS
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Compare current keys and advance the lower or equal stream.
       3000-MATCH-CURRENT-RECORDS.
           EVALUATE TRUE
               WHEN WS-ACCOUNT-EOF = "Y"
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN WS-TRANSACTION-EOF = "Y"
                   PERFORM 4000-REPORT-ACCOUNT-ONLY
                   PERFORM 1000-READ-ACCOUNT
               WHEN FD-ACCOUNT-NUMBER < FD-TRANSACTION-ACCOUNT
                   PERFORM 4000-REPORT-ACCOUNT-ONLY
                   PERFORM 1000-READ-ACCOUNT
               WHEN FD-ACCOUNT-NUMBER > FD-TRANSACTION-ACCOUNT
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN OTHER
                   PERFORM 4200-REPORT-MATCH
                   PERFORM 1000-READ-ACCOUNT
                   IF WS-IO-ERROR = "N"
                       PERFORM 2000-READ-TRANSACTION
                   END-IF
           END-EVALUATE.
      * Read the next master row or mark only this stream at EOF.
       1000-READ-ACCOUNT.
           READ ACCOUNT-MASTER
               AT END
                   MOVE "Y" TO WS-ACCOUNT-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-ACCOUNT-STATUS NOT = "00"
               AND WS-ACCOUNT-STATUS NOT = "10"
               DISPLAY "READ=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * Read the next transaction row or mark only this stream at EOF.
       2000-READ-TRANSACTION.
           READ DAILY-TRANSACTIONS
               AT END
                   MOVE "Y" TO WS-TRANSACTION-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-TRANSACTION-STATUS NOT = "00"
               AND WS-TRANSACTION-STATUS NOT = "10"
               DISPLAY "READ=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * The master key sorts before the current transaction key.
       4000-REPORT-ACCOUNT-ONLY.
           ADD 1 TO WS-ACCOUNT-ONLY-COUNT
           DISPLAY "ACCOUNT_ONLY ACCOUNT=" FD-ACCOUNT-NUMBER
               " CUSTOMER=" FD-CUSTOMER-ID
               " BALANCE=" FD-ACCOUNT-BALANCE.
      * The transaction key sorts before the current master key.
       4100-REPORT-TRANSACTION-ONLY.
           ADD 1 TO WS-TRANSACTION-ONLY-COUNT
           DISPLAY "TRANSACTION_ONLY ACCOUNT="
               FD-TRANSACTION-ACCOUNT
               " TYPE=" FD-TRANSACTION-TYPE
               " AMOUNT=" FD-TRANSACTION-AMOUNT.
      * Equal keys identify one account and its daily transaction.
       4200-REPORT-MATCH.
           ADD 1 TO WS-MATCH-COUNT
           DISPLAY "MATCH ACCOUNT=" FD-ACCOUNT-NUMBER
               " CUSTOMER=" FD-CUSTOMER-ID
               " BALANCE=" FD-ACCOUNT-BALANCE
               " TYPE=" FD-TRANSACTION-TYPE
               " AMOUNT=" FD-TRANSACTION-AMOUNT.
      * Close both inputs and report all three classification counts.
       9000-CLOSE-FILES.
           CLOSE ACCOUNT-MASTER
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "CLOSE=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "CLOSE=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "SUMMARY MATCHED=" WS-MATCH-COUNT
               " ACCOUNT_ONLY=" WS-ACCOUNT-ONLY-COUNT
               " TRANSACTION_ONLY=" WS-TRANSACTION-ONLY-COUNT.
      * Both fixture files are sorted in ascending account-key order.
      * The master key is the ten-character account number.
      * The transaction key is the same ten-character account number.
      * A smaller master key means no transaction key matches it.
      * A smaller transaction key means no master key matches it.
      * Equal keys classify one matched pair of records.
      * After a match, both input streams advance once.
      * After a one-sided row, only that side advances.
      * When one side reaches EOF, remaining rows are orphans.
      * Each stream has its own status and EOF state.
      * Status 10 is normal EOF; other read errors stop the merge.
      * AT END handles EOF for the READ it follows.
      * FILE STATUS is checked to distinguish other read failures.
      * The account balance and transaction amount use implied cents.
      * This example reports values but calculates no new balance.
      * Duplicate keys are outside this lesson's one-row-per-key rule.
      * Unsorted input invalidates the forward comparison algorithm.
      * Sort both files by the same account-key collation first.
      * The key fields have equal length and are compared as text.
      * Leading zeroes are significant parts of these account keys.
      * Master and transaction record layouts are fixed-width text rows.
      * Each physical line contains one record with no delimiter fields.
      * The FD record lengths match the fixture row lengths.
      * Both files are required and must open successfully.
      * If the second OPEN fails, the first input is closed.
      * A successful READ advances only the file named in that READ.
      * The merge uses constant working storage regardless of row count.
      * No OCCURS table stores the complete input files in memory.
      * This is a sequential merge, not a nested search of both files.
      * Its run time grows with the total number of input records.
      * The output labels distinguish match and both orphan directions.
      * Each input contributes at most one row to a matched pair.
      * EOF is tested before referencing a current key for comparison.
      * Empty files produce zero rows on their respective side.
      * The summary counts classifications, not read attempts.
      * The program does not write or alter either input fixture.
      * Later lessons add sorting and complete batch output files.
      * Run here so both ASSIGN paths find their fixtures.
      * The program returns a nonzero status after an I/O failure.
      * The sample contains matches, a master-only row, and orphans.
      * One transaction-only row sorts between two master keys.
      * Another transaction-only row remains after master EOF.
      * The fixtures exercise both key directions and EOF handling.
      * STOP RUN returns the batch status code to the operating system.
