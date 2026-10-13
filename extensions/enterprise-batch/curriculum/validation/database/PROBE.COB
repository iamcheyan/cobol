       IDENTIFICATION DIVISION.
       PROGRAM-ID. SQL-PROBE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01 DB-NAME PIC X(128) VALUE
           'pgsql://database:5432/postgres?autocommit=off'.
       01 DB-USER PIC X(30) VALUE 'postgres'.
       01 DB-PASS PIC X(30) VALUE SPACES.
       01 ACCOUNT-ID PIC 9(4).
       01 ACCOUNT-AMOUNT PIC 9(4).
       01 ACCOUNT-MEMO PIC X(20).
       01 MEMO-NULL PIC S9(4) COMP.
           EXEC SQL END DECLARE SECTION END-EXEC.
           EXEC SQL INCLUDE SQLCA END-EXEC.
       01 ROW-COUNT PIC 9 VALUE 0.
       01 PROBE-MODE PIC X(20).
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT PROBE-MODE FROM COMMAND-LINE
           IF PROBE-MODE = 'fail-connect'
               MOVE 'pgsql://database:1/postgres?connect_timeout=2'
                   TO DB-NAME
           END-IF
           EXEC SQL
               CONNECT :DB-USER IDENTIFIED BY :DB-PASS
                   USING :DB-NAME
           END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL
               SELECT memo INTO :ACCOUNT-MEMO:MEMO-NULL
                   FROM p1_account WHERE id=1
           END-EXEC
           PERFORM 9000-CHECK
           IF MEMO-NULL NOT = -1
               PERFORM 9100-FAIL
           END-IF
           DISPLAY 'SINGLE-NULL=YES'
           EXEC SQL
               SELECT amount INTO :ACCOUNT-AMOUNT
                   FROM p1_account WHERE id=999
           END-EXEC
           DISPLAY 'EMPTY=' SQLSTATE
           IF SQLSTATE NOT = '02000'
               PERFORM 9100-FAIL
           END-IF
           EXEC SQL
               DECLARE C1 CURSOR FOR
               SELECT id, amount, memo FROM p1_account ORDER BY id
           END-EXEC.
           EXEC SQL OPEN C1 END-EXEC
           PERFORM 9000-CHECK
           PERFORM UNTIL ROW-COUNT = 2
               EXEC SQL
                   FETCH C1 INTO :ACCOUNT-ID, :ACCOUNT-AMOUNT,
                       :ACCOUNT-MEMO:MEMO-NULL
               END-EXEC
               PERFORM 9000-CHECK
               ADD 1 TO ROW-COUNT
               IF ACCOUNT-ID = 1 AND MEMO-NULL = -1
                   DISPLAY 'NULL=YES'
               ELSE
                   IF ACCOUNT-ID NOT = 2 OR MEMO-NULL NOT = 0 OR
                       ACCOUNT-MEMO NOT = 'ready'
                       PERFORM 9100-FAIL
                   END-IF
               END-IF
           END-PERFORM
           DISPLAY 'ROWS=' ROW-COUNT
           EXEC SQL
               FETCH C1 INTO :ACCOUNT-ID, :ACCOUNT-AMOUNT,
                   :ACCOUNT-MEMO:MEMO-NULL
           END-EXEC
           DISPLAY 'EOF=' SQLSTATE
           IF SQLSTATE NOT = '02000'
               PERFORM 9100-FAIL
           END-IF
           EXEC SQL CLOSE C1 END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL COMMIT WORK END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL
               UPDATE p1_account SET amount=999 WHERE id=1
           END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL
               INSERT INTO p1_account (id, amount) VALUES (1, 500)
           END-EXEC
           DISPLAY 'DUPLICATE=' SQLSTATE
           IF SQLSTATE NOT = '23505'
               PERFORM 9100-FAIL
           END-IF
           EXEC SQL ROLLBACK WORK END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL
               SELECT amount INTO :ACCOUNT-AMOUNT
                   FROM p1_account WHERE id=1
           END-EXEC
           PERFORM 9000-CHECK
           IF ACCOUNT-AMOUNT NOT = 100
               PERFORM 9100-FAIL
           END-IF
           DISPLAY 'ROLLBACK=100'
           EXEC SQL
               UPDATE p1_account SET amount=101 WHERE id=1
           END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL COMMIT WORK END-EXEC
           PERFORM 9000-CHECK
           DISPLAY 'COMMIT=101'
           EXEC SQL OPEN C1 END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL COMMIT WORK END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL OPEN C1 END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL
               FETCH C1 INTO :ACCOUNT-ID, :ACCOUNT-AMOUNT,
                   :ACCOUNT-MEMO:MEMO-NULL
           END-EXEC
           PERFORM 9000-CHECK
           IF ACCOUNT-ID NOT = 1 OR ACCOUNT-AMOUNT NOT = 101 OR
               MEMO-NULL NOT = -1
               PERFORM 9100-FAIL
           END-IF
           EXEC SQL CLOSE C1 END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL COMMIT WORK END-EXEC
           PERFORM 9000-CHECK
           DISPLAY 'REOPEN=YES'
           EXEC SQL DISCONNECT ALL END-EXEC
           PERFORM 9000-CHECK
           MOVE 0 TO RETURN-CODE
           GOBACK.
       9000-CHECK.
           IF SQLCODE NOT = 0
               PERFORM 9100-FAIL
           END-IF.
       9100-FAIL.
           DISPLAY 'SQL-FAIL=' SQLCODE ':' SQLSTATE
           DISPLAY SQLERRMC
           MOVE 12 TO RETURN-CODE
           STOP RUN.
