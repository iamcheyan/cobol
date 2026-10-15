       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON32.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "BATCH-INTERFACE.CPY".
       01 WS-CHECK-COUNT PIC 999 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           INITIALIZE WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           MOVE "N" TO WS-FAILED
           CALL "LOADPOST32" USING BY REFERENCE
               WS-ACCOUNT-TABLE WS-BATCH-COUNTS
      * Do not sync a partial account table after a file failure.
           IF WS-FAILED NOT = "Y"
               CALL "SYNCDB32" USING BY REFERENCE
                   WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           END-IF
           PERFORM 3000-CHECK-COUNTS
           PERFORM 1000-REPORT-SUMMARY
           PERFORM 2000-RETURN-STATUS
           GOBACK.
       1000-REPORT-SUMMARY.
      * Business rejects count as rejects, not system failures.
           DISPLAY "SUMMARY ACCOUNTS=" WS-ACCOUNT-COUNT
                   " TX=" WS-TRANSACTION-COUNT
                   " POSTED=" WS-POSTED-COUNT
                   " REJECTED=" WS-REJECTED-COUNT
                   " UPDATED=" WS-UPDATED-COUNT
                   " UNCHANGED=" WS-UNCHANGED-COUNT
                   " INSERTED=" WS-INSERTED-COUNT.
       2000-RETURN-STATUS.
           IF WS-FAILED = "Y"
               MOVE 1 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
       3000-CHECK-COUNTS.
      * Every read transaction must be either posted or rejected.
           COMPUTE WS-CHECK-COUNT =
               WS-POSTED-COUNT + WS-REJECTED-COUNT
           IF WS-CHECK-COUNT NOT = WS-TRANSACTION-COUNT
               DISPLAY "ERROR=TRANSACTION COUNT MISMATCH"
               MOVE "Y" TO WS-FAILED
           END-IF
           IF WS-FAILED NOT = "Y"
               COMPUTE WS-CHECK-COUNT =
                   WS-UPDATED-COUNT + WS-UNCHANGED-COUNT
                   + WS-INSERTED-COUNT
               IF WS-CHECK-COUNT NOT = WS-ACCOUNT-COUNT
                   DISPLAY "ERROR=SYNC COUNT MISMATCH"
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
      * LOADPOST32 reads fixed 27- and 20-character records.
      * Amount fields contain integer cents with an implied decimal.
      * Duplicate account keys fail before posting begins.
      * Overdrafts and unknown types or accounts are business rejects.
      * Business rejects do not change the final account balance.
      * It therefore does not apply a deposit twice to database state.
      * Outputs and database changes do not share an atomic transaction.
      * It would also define a transaction commit and recovery protocol.
      * Amount text represents integer cents, not localized decimals.
       END PROGRAM LESSON32.
