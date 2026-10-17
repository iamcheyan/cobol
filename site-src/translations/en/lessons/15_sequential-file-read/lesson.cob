       IDENTIFICATION DIVISION.
       PROGRAM-ID. READ15.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *Line input: upstream sends one record per line.
      *Long lines split into records; upstream sets max length.
           SELECT TRANSACTION-FILE
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-FILE.
      *FD record area is 100 chars; short lines pad right.
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
      *The two-digit count wraps after 99 records.
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT TRANSACTION-FILE
      *Missing file gives status 35; no READ; exit code 1.
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "オープン=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "オープン=OK"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               PERFORM 1000-READ-ONE-RECORD
           END-PERFORM
           DISPLAY "EOF=はい レコード数=" WS-RECORD-COUNT
           CLOSE TRANSACTION-FILE
           IF WS-FILE-STATUS = "00"
               DISPLAY "クローズ=OK"
           ELSE
               DISPLAY "クローズ=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       1000-READ-ONE-RECORD.
           READ TRANSACTION-FILE
               AT END
      *EOF is normal, not an error; set flag only, do not count.
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   ADD 1 TO WS-RECORD-COUNT
      *TRIM affects display only; record area stays 100 chars.
                   DISPLAY "レコード="
                       FUNCTION TRIM(FD-TRANSACTION-RECORD TRAILING)
           END-READ.
