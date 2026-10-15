       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON29.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Database connection values stay outside the compiled program.
      * GixSQL receives the database path and credentials at run time.
       01 WS-DATASRC PIC X(255).
       01 WS-DBUSER PIC X(64).
       01 WS-DBPASS PIC X(64).
       01 WS-LOOKUP-ACCOUNT PIC X(10).
       01 WS-ACCOUNT PIC X(10).
       01 WS-CUSTOMER PIC X(8).
       01 WS-BALANCE PIC S9(7)V99 COMP-3.
       01 WS-EDITED-BALANCE PIC 9(5).99.
       01 WS-DB-OPEN PIC X VALUE "N".
       01 WS-FAILED PIC X VALUE "N".
      * SQLCODE zero means success; 100 means a query returned no row.
       EXEC SQL INCLUDE SQLCA END-EXEC.
       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           PERFORM 1000-CONNECT-DATABASE
           IF WS-DB-OPEN = "Y"
               MOVE "A000000001" TO WS-LOOKUP-ACCOUNT
               PERFORM 2000-LOOKUP-ACCOUNT
               MOVE "A99999999X" TO WS-LOOKUP-ACCOUNT
               PERFORM 2000-LOOKUP-ACCOUNT
               PERFORM 9000-DISCONNECT-DATABASE
           END-IF
           IF WS-FAILED = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           GOBACK.
       1000-CONNECT-DATABASE.
      * Read connection data from the environment, not source literals.
           DISPLAY "DATASRC" UPON ENVIRONMENT-NAME
           ACCEPT WS-DATASRC FROM ENVIRONMENT-VALUE
           DISPLAY "DATASRC_USR" UPON ENVIRONMENT-NAME
           ACCEPT WS-DBUSER FROM ENVIRONMENT-VALUE
           DISPLAY "DATASRC_PWD" UPON ENVIRONMENT-NAME
           ACCEPT WS-DBPASS FROM ENVIRONMENT-VALUE
           EXEC SQL
               CONNECT TO :WS-DATASRC USER :WS-DBUSER
                           USING :WS-DBPASS
           END-EXEC
           IF SQLCODE = 0
               MOVE "Y" TO WS-DB-OPEN
               DISPLAY "CONNECT=OK"
           ELSE
               DISPLAY "CONNECT=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
       2000-LOOKUP-ACCOUNT.
      * The primary-key predicate can return at most one account row.
           MOVE SPACES TO WS-ACCOUNT WS-CUSTOMER
           MOVE ZERO TO WS-BALANCE
           EXEC SQL
               SELECT ACCOUNT_NO, CUSTOMER_ID, BALANCE
                 INTO :WS-ACCOUNT, :WS-CUSTOMER, :WS-BALANCE
                 FROM ACCOUNT_SNAPSHOT
                WHERE ACCOUNT_NO = :WS-LOOKUP-ACCOUNT
           END-EXEC
      * SQLCODE 100 is a normal no-match result, not a database failure.
           EVALUATE SQLCODE
             WHEN 0
               MOVE WS-BALANCE TO WS-EDITED-BALANCE
               DISPLAY "LOOKUP=" WS-LOOKUP-ACCOUNT
                       " STATUS=FOUND CUSTOMER=" WS-CUSTOMER
                       " BALANCE=" WS-EDITED-BALANCE
             WHEN 100
               DISPLAY "LOOKUP=" WS-LOOKUP-ACCOUNT
                       " STATUS=NOT_FOUND"
             WHEN OTHER
               DISPLAY "LOOKUP=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-EVALUATE.
       9000-DISCONNECT-DATABASE.
           EXEC SQL CONNECT RESET END-EXEC
           IF SQLCODE = 0
               DISPLAY "DISCONNECT=OK"
           ELSE
               DISPLAY "DISCONNECT=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
