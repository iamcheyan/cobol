       IDENTIFICATION DIVISION.
       PROGRAM-ID. APPLY.
      *> module08 ref: 08.4 update, unique constraint, COMMIT/ROLLBACK.
      *>   read TRANSACTION v1 55B; idempotent apply by business day:
      *>     new -> INSERT transaction_ledger + UPDATE balance;
      *>     dup transaction_id in run -> 23505 -> RC8 rollback;
      *>     applied by prior run -> 23505 -> SKIP (no re-post).
      *>   batch_commit marks day; dup insert -> 23505 -> DAY-DUP.
      *> mode: M08_MODE=apply (COMMIT) or rollback (demo).
      *> env: M08_BIZ_DATE/M08_TX_FILE/M08_RUN_ID/M08_CONTROL/M08_MODE.
      *> RC: 0 ok; 8 dup-in-run/structural; 12 system/connection.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TX-FILE ASSIGN TO WS-TX-PATH
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT CTL-FILE ASSIGN TO WS-CTL-PATH
               ORGANIZATION IS LINE SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD  TX-FILE.
       01 TX-REC PIC X(55).
       FD  CTL-FILE.
       01 CTL-REC PIC X(100).
       WORKING-STORAGE SECTION.
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01 DB-NAME PIC X(128) VALUE
           'pgsql://database:5432/postgres?autocommit=off'.
       01 DB-USER PIC X(30) VALUE 'postgres'.
       01 DB-PASS PIC X(30) VALUE SPACES.
       01 BIZ-DATE PIC X(8).
       01 RUN-ID PIC X(32).
       01 HV-ACC PIC X(10).
       01 HV-TX PIC X(16).
       01 HV-DATE PIC X(8).
       01 HV-SEQ PIC X(6).
       01 HV-DIR PIC X(1).
       01 HV-AMT PIC 9(13).
       01 HV-ST PIC X(1).
       01 HV-PREV-RUN PIC X(32).
           EXEC SQL END DECLARE SECTION END-EXEC.
           COPY SQLCA.
       01 WS-TX-PATH PIC X(200).
       01 WS-CTL-PATH PIC X(200).
       01 WS-MODE PIC X(16) VALUE 'apply'.
       01 WS-RC PIC 9(2) VALUE 0.
       01 WS-ENV PIC X(16).
       01 WS-EOF PIC X VALUE 'N'.
       01 WS-CTRL PIC X(100).
       01 WS-TXT PIC X(32).
       01 READ-CNT PIC 9(6) VALUE 0.
       01 APPLIED-CNT PIC 9(6) VALUE 0.
       01 SKIPPED-CNT PIC 9(6) VALUE 0.
       01 DUPINRUN-CNT PIC 9(6) VALUE 0.
       01 DAY-DUP PIC 9(1) VALUE 0.
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT BIZ-DATE FROM ENVIRONMENT 'M08_BIZ_DATE'
           ACCEPT WS-TX-PATH FROM ENVIRONMENT 'M08_TX_FILE'
           ACCEPT RUN-ID FROM ENVIRONMENT 'M08_RUN_ID'
           ACCEPT WS-CTL-PATH FROM ENVIRONMENT 'M08_CONTROL'
           ACCEPT WS-ENV FROM ENVIRONMENT 'M08_MODE'
           IF WS-ENV NOT = SPACES MOVE WS-ENV TO WS-MODE END-IF
           EXEC SQL
               CONNECT :DB-USER IDENTIFIED BY :DB-PASS
                   USING :DB-NAME
           END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL
               INSERT INTO batch_run (run_id, business_date, status)
                   VALUES (:RUN-ID, :BIZ-DATE, 'RUNNING')
           END-EXEC
           PERFORM 9000-CHECK
           OPEN INPUT TX-FILE
           PERFORM 1100-LOAD
           CLOSE TX-FILE
           PERFORM 1200-DAY-COMMIT
           IF DUPINRUN-CNT > 0
               EXEC SQL ROLLBACK WORK END-EXEC
               PERFORM 9000-CHECK
               MOVE 8 TO WS-RC
           ELSE
               IF WS-MODE = 'rollback'
                   EXEC SQL ROLLBACK WORK END-EXEC
                   PERFORM 9000-CHECK
                   DISPLAY 'ROLLED-BACK=YES'
                   MOVE 0 TO WS-RC
               ELSE
                   EXEC SQL COMMIT WORK END-EXEC
                   PERFORM 9000-CHECK
                   DISPLAY 'COMMITTED=YES'
                   MOVE 0 TO WS-RC
               END-IF
           END-IF
           OPEN OUTPUT CTL-FILE
           PERFORM 1300-CONTROL
           CLOSE CTL-FILE
           EXEC SQL DISCONNECT ALL END-EXEC
           MOVE WS-RC TO RETURN-CODE
           GOBACK.
      *> read 55B transactions; idempotent apply per business key.
       1100-LOAD.
           PERFORM UNTIL WS-EOF = 'Y'
               READ TX-FILE AT END MOVE 'Y' TO WS-EOF
               END-READ
               IF WS-EOF = 'N'
                   ADD 1 TO READ-CNT
                   PERFORM 1150-ONE
               END-IF
           END-PERFORM.
       1150-ONE.
           MOVE TX-REC(1:10) TO HV-ACC
           MOVE TX-REC(11:16) TO HV-TX
           MOVE TX-REC(27:8) TO HV-DATE
           MOVE TX-REC(35:6) TO HV-SEQ
           MOVE TX-REC(41:1) TO HV-DIR
           MOVE TX-REC(42:13) TO HV-AMT
           MOVE TX-REC(55:1) TO HV-ST
           EXEC SQL SAVEPOINT SP1 END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL
               INSERT INTO transaction_ledger
                   (transaction_id, account_id, business_date,
                    sequence_no, direction, amount, status,
                    applied_run_id)
               VALUES (:HV-TX, :HV-ACC, :HV-DATE, :HV-SEQ,
                    :HV-DIR, :HV-AMT, :HV-ST, :RUN-ID)
           END-EXEC
           EVALUATE SQLSTATE
               WHEN '00000'
                   PERFORM 1160-UPDATE-BALANCE
                   ADD 1 TO APPLIED-CNT
               WHEN '23505'
                   EXEC SQL ROLLBACK TO SAVEPOINT SP1 END-EXEC
                   PERFORM 9000-CHECK
                   PERFORM 1170-DUPLICATE
               WHEN OTHER
                   DISPLAY 'LOAD-FAIL=' SQLCODE ':' SQLSTATE
                   DISPLAY SQLERRMC
                   PERFORM 9100-FAIL
           END-EVALUATE.
      *> applied: update closing and account balance by direction.
       1160-UPDATE-BALANCE.
           IF HV-DIR = 'C'
               EXEC SQL
                   UPDATE account SET closing_balance =
                       closing_balance + :HV-AMT
                       WHERE account_id = :HV-ACC
               END-EXEC
               PERFORM 9000-CHECK
               EXEC SQL
                   UPDATE account_balance SET balance =
                       balance + :HV-AMT
                       WHERE account_id = :HV-ACC
               END-EXEC
               PERFORM 9000-CHECK
           ELSE
               EXEC SQL
                   UPDATE account SET closing_balance =
                       closing_balance - :HV-AMT
                       WHERE account_id = :HV-ACC
               END-EXEC
               PERFORM 9000-CHECK
               EXEC SQL
                   UPDATE account_balance SET balance =
                       balance - :HV-AMT
                       WHERE account_id = :HV-ACC
               END-EXEC
               PERFORM 9000-CHECK
           END-IF.
      *> 23505: read applied_run_id to tell in-run dup vs retry.
       1170-DUPLICATE.
           EXEC SQL
               SELECT applied_run_id INTO :HV-PREV-RUN
                   FROM transaction_ledger
                   WHERE business_date = :HV-DATE
                     AND transaction_id = :HV-TX
           END-EXEC
           PERFORM 9000-CHECK
           IF HV-PREV-RUN = RUN-ID
               ADD 1 TO DUPINRUN-CNT
               DISPLAY 'DUP-IN-RUN=' HV-TX
           ELSE
               ADD 1 TO SKIPPED-CNT
               DISPLAY 'ALREADY-APPLIED=' HV-TX
           END-IF.
      *> day commit marker; dup insert 23505 = already committed.
       1200-DAY-COMMIT.
           EXEC SQL SAVEPOINT SP2 END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL
               INSERT INTO batch_commit
                   (business_date, run_id, applied_count)
                   VALUES (:BIZ-DATE, :RUN-ID, :APPLIED-CNT)
           END-EXEC
           IF SQLSTATE = '23505'
               EXEC SQL ROLLBACK TO SAVEPOINT SP2 END-EXEC
               PERFORM 9000-CHECK
               MOVE 1 TO DAY-DUP
               DISPLAY 'DAY-ALREADY-COMMITTED=YES'
           ELSE
               PERFORM 9000-CHECK
           END-IF.
       1300-CONTROL.
           MOVE READ-CNT TO WS-TXT
           STRING 'MODE|' WS-MODE '|READ|' WS-TXT '|'
               DELIMITED BY SIZE INTO WS-CTRL
           WRITE CTL-REC FROM WS-CTRL
           MOVE APPLIED-CNT TO WS-TXT
           MOVE SPACES TO WS-CTRL
           STRING 'APPLIED|' WS-TXT '|' DELIMITED BY SIZE
               INTO WS-CTRL
           WRITE CTL-REC FROM WS-CTRL
           MOVE SKIPPED-CNT TO WS-TXT
           MOVE SPACES TO WS-CTRL
           STRING 'SKIPPED|' WS-TXT '|' DELIMITED BY SIZE
               INTO WS-CTRL
           WRITE CTL-REC FROM WS-CTRL
           MOVE DUPINRUN-CNT TO WS-TXT
           MOVE SPACES TO WS-CTRL
           STRING 'DUP-IN-RUN|' WS-TXT '|' DELIMITED BY SIZE
               INTO WS-CTRL
           WRITE CTL-REC FROM WS-CTRL
           MOVE DAY-DUP TO WS-TXT
           MOVE SPACES TO WS-CTRL
           STRING 'DAY-ALREADY|' WS-TXT '|' DELIMITED BY SIZE
               INTO WS-CTRL
           WRITE CTL-REC FROM WS-CTRL.
       9000-CHECK.
           IF SQLCODE NOT = 0
               DISPLAY 'SQL-FAIL=' SQLCODE ':' SQLSTATE
               DISPLAY SQLERRMC
               PERFORM 9100-FAIL
           END-IF.
       9100-FAIL.
           MOVE 12 TO RETURN-CODE
           STOP RUN.
