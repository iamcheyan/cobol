       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON32.
      * This program coordinates the complete reconciliation batch.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * The worker modules share these exact record and counter layouts.
       COPY "BATCH-INTERFACE.CPY".
       01 WS-CHECK-COUNT PIC 999 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
      * Reset the account table, counters and worker error flag.
           INITIALIZE WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           MOVE "N" TO WS-FAILED
      * Read the account master and apply the transaction stream.
      * The posting module owns both input files and business rules.
           CALL "LOADPOST32" USING BY REFERENCE
               WS-ACCOUNT-TABLE WS-BATCH-COUNTS
      * Do not sync a partial account table after a file failure.
           IF WS-FAILED NOT = "Y"
      * The sync module owns SQLite, the report and database status.
               CALL "SYNCDB32" USING BY REFERENCE
                   WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           END-IF
      * Validate batch arithmetic before reporting final counters.
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
      * The shell receives a nonzero status only for a system failure.
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
      * A successful sync classifies every loaded account exactly once.
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
      * The worker keeps at most twenty accounts in the shared table.
      * Duplicate account keys fail before posting begins.
      * Deposits and permitted withdrawals update the table.
      * Overdrafts and unknown types or accounts are business rejects.
      * Business rejects do not change the final account balance.
      * Accepted and rejected records use separate sequential files.
      * The batch log records each transaction decision.
      * SYNCDB32 looks up the final account by its primary key.
      * A matching database balance is reported as UNCHANGED.
      * A different balance is updated to the computed file result.
      * A missing database key is inserted from the account master.
      * The report states the decision made for every loaded account.
      * On rerun with identical inputs, the final balances converge.
      * Replaying the input starts from its declared opening balances.
      * It therefore does not apply a deposit twice to database state.
      * Outputs and database changes do not share an atomic transaction.
      * The run script seeds a reproducible SQLite starting database.
      * The run-existing action checks deterministic restart behavior.
      * A production batch would add a durable batch identifier.
      * It would also define a transaction commit and recovery protocol.
      * Those boundaries are documented instead of being simulated here.
      * Module calls use the shared Copybook layout by reference.
      * This driver owns the final summary and process return status.
      * The posting and sync modules own their own files and SQL work.
      * Additional design notes for this integrated batch.
      * The driver converts worker status to the process return code.
      * Workers receive these tables by reference.
      * They update the caller-owned shared state.
      * Each counter has a role in the batch arithmetic checks above.
      * Posted and rejected counts partition the transaction input.
      * Sync counts classify every account after successful SQL work.
      * Amount text represents integer cents, not localized decimals.
      * The account lookup costs one scan for each input transaction.
      * Larger masters need a deliberate table or indexed lookup design.
      * This sample caps master rows to keep memory use predictable.
      * Rebuilds seed a clean database; reruns preserve database rows.
      * Checks use temporary data so the lesson fixtures stay unchanged.
       END PROGRAM LESSON32.
