       IDENTIFICATION DIVISION.
       PROGRAM-ID. ESQL-PROBE.
      *> module08 reference: lessons 08.1 + 08.2 probe.
      *>   08.1 host/indicator var, NULL vs empty, SQLCODE/STATE.
      *>   08.2 DECLARE/OPEN/FETCH/CLOSE: no-data 02000 vs error.
      *> fixed format: Area A col8, Area B col12, code within col72.
      *> frozen contract: CUSTOMER v1 = 27B. date via BIZ-DATE.
      *> note: gixsql emits cursor-init after the last user para, so
      *> the last user para must be a tail (9100-FAIL) not PERFORMed.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01 DB-NAME PIC X(128) VALUE
           'pgsql://database:5432/postgres?autocommit=off'.
       01 DB-USER PIC X(30) VALUE 'postgres'.
       01 DB-PASS PIC X(30) VALUE SPACES.
       01 BIZ-DATE PIC X(8) VALUE '20261009'.
       01 HV-CUST-ID PIC X(8).
       01 HV-NAME PIC X(10).
       01 HV-BALANCE PIC X(8).
       01 HV-STATUS PIC X.
       01 HV-NOTE PIC X(20).
       01 HV-NOTE-IND PIC S9(4) COMP.
       01 HV-DUP-TX PIC X(16).
           EXEC SQL END DECLARE SECTION END-EXEC.
           COPY SQLCA.
       01 PROBE-MODE PIC X(16).
       01 ROW-COUNT PIC 9(3) VALUE 0.
       01 NULL-NOTES PIC 9(3) VALUE 0.
       01 EMPTY-NOTES PIC 9(3) VALUE 0.
       01 FAIL-CNT PIC 9(3) VALUE 0.
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
           PERFORM 1100-NULL-VS-EMPTY
           PERFORM 1200-NO-DATA
           PERFORM 1300-ERROR-CLASS
           PERFORM 1400-CURSOR
           PERFORM 1500-UNIQUE
           EXEC SQL DISCONNECT ALL END-EXEC
           PERFORM 9000-CHECK
           IF FAIL-CNT NOT = 0
               DISPLAY 'PROBE-FAIL-CNT=' FAIL-CNT
               PERFORM 9100-FAIL
           END-IF
           DISPLAY 'PROBE=PASS'
           MOVE 0 TO RETURN-CODE
           GOBACK.
      *> NULL indicator is -1; empty string = indicator 0 + SPACES.
       1100-NULL-VS-EMPTY.
           MOVE '00000001' TO HV-CUST-ID
           EXEC SQL
               SELECT contact_note INTO :HV-NOTE:HV-NOTE-IND
                   FROM customer WHERE customer_id = :HV-CUST-ID
           END-EXEC
           PERFORM 9000-CHECK
           IF HV-NOTE-IND = -1
               DISPLAY 'NULL-INDICATOR=YES'
           ELSE
               DISPLAY 'NULL-INDICATOR=NO:' HV-NOTE-IND
               ADD 1 TO FAIL-CNT
           END-IF
           MOVE '00000005' TO HV-CUST-ID
           EXEC SQL
               SELECT contact_note INTO :HV-NOTE:HV-NOTE-IND
                   FROM customer WHERE customer_id = :HV-CUST-ID
           END-EXEC
           PERFORM 9000-CHECK
           IF HV-NOTE-IND = 0 AND HV-NOTE = SPACES
               DISPLAY 'EMPTY-STRING=YES'
           ELSE
               DISPLAY 'EMPTY-STRING=NO:' HV-NOTE-IND
               ADD 1 TO FAIL-CNT
           END-IF.
      *> SELECT INTO with no row = 02000 (no data), not an error.
       1200-NO-DATA.
           MOVE '99999999' TO HV-CUST-ID
           EXEC SQL
               SELECT customer_name INTO :HV-NAME
                   FROM customer WHERE customer_id = :HV-CUST-ID
           END-EXEC
           DISPLAY 'NO-DATA=' SQLSTATE
           IF SQLSTATE = '02000'
               DISPLAY 'NO-DATA-IS-02000=YES'
           ELSE
               DISPLAY 'NO-DATA-IS-02000=NO'
               ADD 1 TO FAIL-CNT
           END-IF.
      *> real error: CHECK constraint violated, SQLSTATE 23514.
       1300-ERROR-CLASS.
           EXEC SQL
               INSERT INTO customer
                   (customer_id, customer_name, balance_demo, status,
                    business_date)
               VALUES ('00000099', 'BAD STATUS', 0, 'X', '20261009')
           END-EXEC
           DISPLAY 'ERROR=' SQLSTATE
           IF SQLSTATE = '23514' AND SQLSTATE NOT = '02000'
               DISPLAY 'ERROR-NOT-NODATA=YES'
           ELSE
               DISPLAY 'ERROR-NOT-NODATA=NO'
               ADD 1 TO FAIL-CNT
           END-IF
           EXEC SQL ROLLBACK WORK END-EXEC
           PERFORM 9000-CHECK.
      *> cursor extract by date; final FETCH = 02000; then reopen.
       1400-CURSOR.
           EXEC SQL
               DECLARE CUSTCUR CURSOR FOR
               SELECT customer_id, customer_name, balance_demo, status,
                      contact_note
                   FROM customer WHERE business_date = :BIZ-DATE
                   ORDER BY customer_id
           END-EXEC.
           EXEC SQL OPEN CUSTCUR END-EXEC
           PERFORM 9000-CHECK
           MOVE 0 TO ROW-COUNT
           MOVE 0 TO NULL-NOTES
           MOVE 0 TO EMPTY-NOTES
           PERFORM UNTIL SQLSTATE = '02000'
               EXEC SQL
                   FETCH CUSTCUR INTO :HV-CUST-ID, :HV-NAME,
                       :HV-BALANCE, :HV-STATUS, :HV-NOTE:HV-NOTE-IND
               END-EXEC
               IF SQLSTATE = '02000' EXIT PERFORM END-IF
               PERFORM 9000-CHECK
               ADD 1 TO ROW-COUNT
               IF HV-NOTE-IND = -1
                   ADD 1 TO NULL-NOTES
               ELSE
                   IF HV-NOTE = SPACES
                       ADD 1 TO EMPTY-NOTES
                   END-IF
               END-IF
           END-PERFORM
           EXEC SQL CLOSE CUSTCUR END-EXEC
           PERFORM 9000-CHECK
           DISPLAY 'CURSOR-ROWS=' ROW-COUNT
           DISPLAY 'CURSOR-NULL-NOTES=' NULL-NOTES
           DISPLAY 'CURSOR-EMPTY-NOTES=' EMPTY-NOTES
           IF ROW-COUNT NOT = 4 OR NULL-NOTES NOT = 2
               OR EMPTY-NOTES NOT = 1
               DISPLAY 'CURSOR-COUNT=NO'
               ADD 1 TO FAIL-CNT
           END-IF
      *> after CLOSE + COMMIT, reopen+FETCH: closed-cursor check.
           EXEC SQL COMMIT WORK END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL OPEN CUSTCUR END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL
               FETCH CUSTCUR INTO :HV-CUST-ID, :HV-NAME, :HV-BALANCE,
                   :HV-STATUS, :HV-NOTE:HV-NOTE-IND
           END-EXEC
           PERFORM 9000-CHECK
           IF HV-CUST-ID = '00000001'
               DISPLAY 'REOPEN=YES'
           ELSE
               DISPLAY 'REOPEN=NO'
               ADD 1 TO FAIL-CNT
           END-IF
           EXEC SQL CLOSE CUSTCUR END-EXEC
           PERFORM 9000-CHECK.
      *> unique constraint: second insert same business key = 23505.
       1500-UNIQUE.
           MOVE 'DUP0000000000001' TO HV-DUP-TX
           EXEC SQL
               INSERT INTO transaction_ledger
                   (transaction_id, account_id, business_date,
                    sequence_no, direction, amount, status,
                    applied_run_id)
               VALUES (:HV-DUP-TX, '0000000001', '20261009',
                    '000001', 'C', 50, 'N', 'PROBE-RUN')
           END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL
               INSERT INTO transaction_ledger
                   (transaction_id, account_id, business_date,
                    sequence_no, direction, amount, status,
                    applied_run_id)
               VALUES (:HV-DUP-TX, '0000000001', '20261009',
                    '000002', 'D', 10, 'N', 'PROBE-RUN')
           END-EXEC
           DISPLAY 'DUPLICATE=' SQLSTATE
           IF SQLSTATE = '23505'
               DISPLAY 'UNIQUE-VIOLATION=YES'
           ELSE
               DISPLAY 'UNIQUE-VIOLATION=NO'
               ADD 1 TO FAIL-CNT
           END-IF
           EXEC SQL ROLLBACK WORK END-EXEC
           PERFORM 9000-CHECK.
       9000-CHECK.
           IF SQLCODE NOT = 0
               DISPLAY 'SQL-FAIL=' SQLCODE ':' SQLSTATE
               DISPLAY SQLERRMC
               PERFORM 9100-FAIL
           END-IF.
       9100-FAIL.
           MOVE 12 TO RETURN-CODE
           STOP RUN.
