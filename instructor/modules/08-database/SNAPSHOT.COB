       IDENTIFICATION DIVISION.
       PROGRAM-ID. SNAPSHOT.
      *> module08 ref: 08.2 cursor extract + 08.3 reconcile vs upstream.
      *>   1) cursor-extract customers by date to 27B CUSTOMER v1.
      *>   2) write metadata: date, schema/layout version, cutoff.
      *>   3) bounded two-pointer reconcile vs upstream 27B, emit
      *>      MATCH / FIELD-DIFF / DB-ONLY / FILE-ONLY diffs.
      *> RC: 0 none; 4 business diff; 8 structural; 12 system.
      *> paths via env: M08_BIZ_DATE/M08_SNAPSHOT/M08_META/
      *>   M08_UPSTREAM/M08_DIFF/M08_CONTROL.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SNAP-FILE ASSIGN TO WS-SNAP-PATH
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT META-FILE ASSIGN TO WS-META-PATH
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT UP-FILE ASSIGN TO WS-UP-PATH
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT DIFF-FILE ASSIGN TO WS-DIFF-PATH
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT CTL-FILE ASSIGN TO WS-CTL-PATH
               ORGANIZATION IS LINE SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD  SNAP-FILE.
       01 SNAP-REC PIC X(27).
       FD  META-FILE.
       01 META-REC PIC X(80).
       FD  UP-FILE.
       01 UP-REC PIC X(27).
       FD  DIFF-FILE.
       01 DIFF-REC PIC X(120).
       FD  CTL-FILE.
       01 CTL-REC PIC X(100).
       WORKING-STORAGE SECTION.
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01 DB-NAME PIC X(128) VALUE
           'pgsql://database:5432/postgres?autocommit=off'.
       01 DB-USER PIC X(30) VALUE 'postgres'.
       01 DB-PASS PIC X(30) VALUE SPACES.
       01 BIZ-DATE PIC X(8).
       01 HV-CUST-ID PIC X(8).
       01 HV-NAME PIC X(10).
       01 HV-BAL-NUM PIC 9(8).
       01 HV-STATUS PIC X(1).
       01 HV-NOTE PIC X(20).
       01 HV-NOTE-IND PIC S9(4) COMP.
       01 HV-SCHEMA PIC X(3).
       01 HV-CUTOFF PIC X(30).
           EXEC SQL END DECLARE SECTION END-EXEC.
           COPY SQLCA.
           COPY CUSTOMER-V1.
       01 WS-SNAP-PATH PIC X(200).
       01 WS-META-PATH PIC X(200).
       01 WS-UP-PATH PIC X(200).
       01 WS-DIFF-PATH PIC X(200).
       01 WS-CTL-PATH PIC X(200).
       01 WS-EOF-S PIC X VALUE 'N'.
       01 WS-EOF-U PIC X VALUE 'N'.
       01 WS-END-FILE PIC X VALUE 'N'.
       01 WS-CTRL PIC X(200).
       01 WS-MSG PIC X(120).
       01 WS-META-TEXT PIC X(80).
       01 WS-BAL-TEXT PIC 9(9).
       01 WS-RC PIC 9(2) VALUE 0.
       01 DB-ROWS PIC 9(6) VALUE 0.
       01 FILE-ROWS PIC 9(6) VALUE 0.
       01 NULL-NOTES PIC 9(6) VALUE 0.
       01 EMPTY-NOTES PIC 9(6) VALUE 0.
       01 MATCH-CNT PIC 9(6) VALUE 0.
       01 FDIFF-CNT PIC 9(6) VALUE 0.
       01 DBONLY-CNT PIC 9(6) VALUE 0.
       01 FILEONLY-CNT PIC 9(6) VALUE 0.
       01 DIFF-CNT PIC 9(6) VALUE 0.
       01 SNAP-BYTES PIC 9(9) VALUE 0.
       01 WS-KEY-S PIC X(8).
       01 WS-KEY-U PIC X(8).
       01 WS-FIELD PIC X(13).
       01 WS-OFF PIC X(5).
       01 WS-OLD PIC X(13).
       01 WS-NEW PIC X(13).
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT BIZ-DATE FROM ENVIRONMENT 'M08_BIZ_DATE'
           ACCEPT WS-SNAP-PATH FROM ENVIRONMENT 'M08_SNAPSHOT'
           ACCEPT WS-META-PATH FROM ENVIRONMENT 'M08_META'
           ACCEPT WS-UP-PATH FROM ENVIRONMENT 'M08_UPSTREAM'
           ACCEPT WS-DIFF-PATH FROM ENVIRONMENT 'M08_DIFF'
           ACCEPT WS-CTL-PATH FROM ENVIRONMENT 'M08_CONTROL'
           EXEC SQL
               CONNECT :DB-USER IDENTIFIED BY :DB-PASS
                   USING :DB-NAME
           END-EXEC
           PERFORM 9000-CHECK
           OPEN OUTPUT SNAP-FILE
           OPEN OUTPUT META-FILE
           PERFORM 1100-EXTRACT
           PERFORM 1200-METADATA
           CLOSE SNAP-FILE META-FILE
           OPEN INPUT SNAP-FILE
           OPEN INPUT UP-FILE
           PERFORM 1250-COUNT-UPSTREAM
           CLOSE UP-FILE
           OPEN INPUT UP-FILE
           OPEN OUTPUT DIFF-FILE
           MOVE 'N' TO WS-END-FILE
           PERFORM 1300-RECONCILE
           CLOSE UP-FILE DIFF-FILE SNAP-FILE
           OPEN OUTPUT CTL-FILE
           PERFORM 1400-CONTROL
           CLOSE CTL-FILE
           EXEC SQL DISCONNECT ALL END-EXEC
           PERFORM 9000-CHECK
           IF DIFF-CNT > 0 MOVE 4 TO RETURN-CODE
           ELSE MOVE 0 TO RETURN-CODE
           END-IF
           GOBACK.
      *> cursor extract to 27B; count NULL/empty notes via indicator.
       1100-EXTRACT.
           EXEC SQL
               DECLARE CUSTCUR CURSOR FOR
               SELECT customer_id, customer_name, balance_demo,
                      status, contact_note
                   FROM customer WHERE business_date = :BIZ-DATE
                   ORDER BY customer_id
           END-EXEC.
           EXEC SQL OPEN CUSTCUR END-EXEC
           PERFORM 9000-CHECK
           PERFORM UNTIL SQLSTATE = '02000'
               EXEC SQL
                   FETCH CUSTCUR INTO :HV-CUST-ID, :HV-NAME,
                       :HV-BAL-NUM, :HV-STATUS, :HV-NOTE:HV-NOTE-IND
               END-EXEC
               IF SQLSTATE = '02000' EXIT PERFORM END-IF
               PERFORM 9000-CHECK
               ADD 1 TO DB-ROWS
               IF HV-NOTE-IND = -1
                   ADD 1 TO NULL-NOTES
               ELSE
                   IF HV-NOTE = SPACES
                       ADD 1 TO EMPTY-NOTES
                   END-IF
               END-IF
               MOVE HV-CUST-ID TO CUST-ID
               MOVE HV-NAME TO CUST-NAME
               MOVE HV-BAL-NUM TO CUST-BALANCE
               MOVE HV-STATUS TO CUST-STATUS
               WRITE SNAP-REC FROM CUSTOMER-RECORD
               ADD 27 TO SNAP-BYTES
           END-PERFORM
           EXEC SQL CLOSE CUSTCUR END-EXEC
           PERFORM 9000-CHECK.
      *> metadata: date, schema/layout version, cutoff, counters.
       1200-METADATA.
           EXEC SQL
               SELECT schema_version INTO :HV-SCHEMA
                   FROM schema_version ORDER BY applied_at DESC LIMIT 1
           END-EXEC
           PERFORM 9000-CHECK
           EXEC SQL
               SELECT to_char(now(),
                   'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') INTO :HV-CUTOFF
           END-EXEC
           PERFORM 9000-CHECK
           MOVE SPACES TO WS-META-TEXT
           STRING 'BUSINESS_DATE=' BIZ-DATE INTO WS-META-TEXT
           WRITE META-REC FROM WS-META-TEXT
           MOVE SPACES TO WS-META-TEXT
           STRING 'SCHEMA_VERSION=' HV-SCHEMA INTO WS-META-TEXT
           WRITE META-REC FROM WS-META-TEXT
           MOVE SPACES TO WS-META-TEXT
           MOVE 'LAYOUT_VERSION=001' TO WS-META-TEXT
           WRITE META-REC FROM WS-META-TEXT
           MOVE SPACES TO WS-META-TEXT
           STRING 'CUTOFF=' HV-CUTOFF INTO WS-META-TEXT
           WRITE META-REC FROM WS-META-TEXT
           MOVE DB-ROWS TO WS-BAL-TEXT
           MOVE SPACES TO WS-META-TEXT
           STRING 'SNAPSHOT_ROWS=' WS-BAL-TEXT INTO WS-META-TEXT
           WRITE META-REC FROM WS-META-TEXT
           MOVE NULL-NOTES TO WS-BAL-TEXT
           MOVE SPACES TO WS-META-TEXT
           STRING 'NULL_NOTES=' WS-BAL-TEXT INTO WS-META-TEXT
           WRITE META-REC FROM WS-META-TEXT
           MOVE EMPTY-NOTES TO WS-BAL-TEXT
           MOVE SPACES TO WS-META-TEXT
           STRING 'EMPTY_NOTES=' WS-BAL-TEXT INTO WS-META-TEXT
           WRITE META-REC FROM WS-META-TEXT
           MOVE SNAP-BYTES TO WS-BAL-TEXT
           MOVE SPACES TO WS-META-TEXT
           STRING 'SNAPSHOT_BYTES=' WS-BAL-TEXT INTO WS-META-TEXT
           WRITE META-REC FROM WS-META-TEXT.
      *> count upstream rows (FILE-ROWS) first, then reopen to merge.
       1250-COUNT-UPSTREAM.
           MOVE 0 TO FILE-ROWS
           PERFORM UNTIL WS-EOF-U = 'Y'
               READ UP-FILE AT END MOVE 'Y' TO WS-EOF-U
               END-READ
               IF WS-EOF-U = 'N' ADD 1 TO FILE-ROWS END-IF
           END-PERFORM
           MOVE 'N' TO WS-EOF-U.
      *> bounded two-pointer merge: two cursors and current keys only.
       1300-RECONCILE.
           IF WS-END-FILE = 'N'
               READ SNAP-FILE AT END MOVE 'Y' TO WS-EOF-S
               END-READ
               READ UP-FILE AT END MOVE 'Y' TO WS-EOF-U
               END-READ
               MOVE 'Y' TO WS-END-FILE
           END-IF
           PERFORM UNTIL WS-EOF-S = 'Y' AND WS-EOF-U = 'Y'
               IF WS-EOF-S = 'Y'
                   PERFORM 1360-FILE-ONLY
               ELSE
                   IF WS-EOF-U = 'Y'
                       PERFORM 1350-DB-ONLY
                   ELSE
                       MOVE SNAP-REC(1:8) TO WS-KEY-S
                       MOVE UP-REC(1:8) TO WS-KEY-U
                       EVALUATE TRUE
                           WHEN WS-KEY-S < WS-KEY-U
                               PERFORM 1350-DB-ONLY
                           WHEN WS-KEY-S > WS-KEY-U
                               PERFORM 1360-FILE-ONLY
                           WHEN OTHER
                               PERFORM 1370-COMPARE
                       END-EVALUATE
                   END-IF
               END-IF
           END-PERFORM.
       1350-DB-ONLY.
           MOVE SNAP-REC TO WS-MSG
           MOVE SPACES TO DIFF-REC
           STRING 'DB-ONLY|' WS-MSG(1:8) '|' SNAP-REC
               DELIMITED BY SIZE INTO DIFF-REC
           WRITE DIFF-REC
           ADD 1 TO DBONLY-CNT
           ADD 1 TO DIFF-CNT
           READ SNAP-FILE AT END MOVE 'Y' TO WS-EOF-S END-READ.
       1360-FILE-ONLY.
           MOVE SPACES TO DIFF-REC
           STRING 'FILE-ONLY|' UP-REC(1:8) '|' UP-REC
               DELIMITED BY SIZE INTO DIFF-REC
           WRITE DIFF-REC
           ADD 1 TO FILEONLY-CNT
           ADD 1 TO DIFF-CNT
           READ UP-FILE AT END MOVE 'Y' TO WS-EOF-U END-READ.
       1370-COMPARE.
           IF SNAP-REC = UP-REC
               ADD 1 TO MATCH-CNT
           ELSE
               PERFORM 1380-FIELD-DIFF
               ADD 1 TO FDIFF-CNT
               ADD 1 TO DIFF-CNT
           END-IF
           READ SNAP-FILE AT END MOVE 'Y' TO WS-EOF-S END-READ
           READ UP-FILE AT END MOVE 'Y' TO WS-EOF-U END-READ.
       1380-FIELD-DIFF.
           MOVE SPACES TO WS-FIELD WS-OFF WS-OLD WS-NEW
           IF SNAP-REC(1:8) NOT = UP-REC(1:8)
               MOVE 'customer_id' TO WS-FIELD
               MOVE '1-8' TO WS-OFF
               MOVE SNAP-REC(1:8) TO WS-OLD
               MOVE UP-REC(1:8) TO WS-NEW
           ELSE
               IF SNAP-REC(9:10) NOT = UP-REC(9:10)
                   MOVE 'customer_name' TO WS-FIELD
                   MOVE '9-18' TO WS-OFF
                   MOVE SNAP-REC(9:10) TO WS-OLD
                   MOVE UP-REC(9:10) TO WS-NEW
               ELSE
                   IF SNAP-REC(19:8) NOT = UP-REC(19:8)
                       MOVE 'balance_demo' TO WS-FIELD
                       MOVE '19-26' TO WS-OFF
                       MOVE SNAP-REC(19:8) TO WS-OLD
                       MOVE UP-REC(19:8) TO WS-NEW
                   ELSE
                       MOVE 'status' TO WS-FIELD
                       MOVE '27' TO WS-OFF
                       MOVE SNAP-REC(27:1) TO WS-OLD
                       MOVE UP-REC(27:1) TO WS-NEW
                   END-IF
               END-IF
           END-IF
           MOVE SPACES TO DIFF-REC
           STRING 'FIELD-DIFF|' SNAP-REC(1:8) '|' WS-FIELD '|'
               WS-OFF '|' WS-OLD '|' WS-NEW
               DELIMITED BY SIZE INTO DIFF-REC
           WRITE DIFF-REC.
       1400-CONTROL.
           MOVE SPACES TO WS-CTRL
           MOVE DB-ROWS TO WS-BAL-TEXT
           STRING 'DATABASE-ROWS|' WS-BAL-TEXT '|' INTO WS-CTRL
           WRITE CTL-REC FROM WS-CTRL
           MOVE FILE-ROWS TO WS-BAL-TEXT
           MOVE SPACES TO WS-CTRL
           STRING 'FILE-ROWS|' WS-BAL-TEXT '|' INTO WS-CTRL
           WRITE CTL-REC FROM WS-CTRL
           MOVE MATCH-CNT TO WS-BAL-TEXT
           MOVE SPACES TO WS-CTRL
           STRING 'MATCH|' WS-BAL-TEXT '|' INTO WS-CTRL
           WRITE CTL-REC FROM WS-CTRL
           MOVE FDIFF-CNT TO WS-BAL-TEXT
           MOVE SPACES TO WS-CTRL
           STRING 'FIELD-DIFF|' WS-BAL-TEXT '|' INTO WS-CTRL
           WRITE CTL-REC FROM WS-CTRL
           MOVE DBONLY-CNT TO WS-BAL-TEXT
           MOVE SPACES TO WS-CTRL
           STRING 'DB-ONLY|' WS-BAL-TEXT '|' INTO WS-CTRL
           WRITE CTL-REC FROM WS-CTRL
           MOVE FILEONLY-CNT TO WS-BAL-TEXT
           MOVE SPACES TO WS-CTRL
           STRING 'FILE-ONLY|' WS-BAL-TEXT '|' INTO WS-CTRL
           WRITE CTL-REC FROM WS-CTRL
           MOVE DIFF-CNT TO WS-BAL-TEXT
           MOVE SPACES TO WS-CTRL
           STRING 'DIFFS|' WS-BAL-TEXT '|' INTO WS-CTRL
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
