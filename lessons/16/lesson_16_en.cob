      *Accepted and rejected records go to separate destinations.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRITE16.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCEPTED-FILE
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCEPTED-STATUS.
           SELECT REJECTED-FILE
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REJECTED-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCEPTED-FILE.
       01 FD-ACCEPTED-RECORD PIC X(35).
       FD REJECTED-FILE.
       01 FD-REJECTED-RECORD PIC X(35).
       WORKING-STORAGE SECTION.
       01 WS-RESULT-TABLE.
          05 WS-RESULT-ENTRY OCCURS 4 TIMES.
             10 WS-RESULT-DESTINATION PIC X.
             10 WS-RESULT-TEXT PIC X(35).
       01 WS-RESULT-NUMBER PIC 9 VALUE ZERO.
       01 WS-ACCEPTED-STATUS PIC XX VALUE SPACES.
       01 WS-REJECTED-STATUS PIC XX VALUE SPACES.
       01 WS-ACCEPTED-COUNT PIC 9(2) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(2) VALUE ZERO.
       01 WS-WRITE-ERROR PIC X VALUE "N".
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT ACCEPTED-FILE
           IF WS-ACCEPTED-STATUS NOT = "00"
               DISPLAY "OPEN=ACCEPTED FAILED STATUS="
                   WS-ACCEPTED-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=ACCEPTED OK"
           OPEN OUTPUT REJECTED-FILE
           IF WS-REJECTED-STATUS NOT = "00"
               DISPLAY "OPEN=REJECTED FAILED STATUS="
                   WS-REJECTED-STATUS
               CLOSE ACCEPTED-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=REJECTED OK"
           PERFORM 1000-LOAD-RESULTS
           PERFORM VARYING WS-RESULT-NUMBER FROM 1 BY 1
               UNTIL WS-RESULT-NUMBER > 4
                   OR WS-WRITE-ERROR = "Y"
               PERFORM 2000-WRITE-ONE-RESULT
           END-PERFORM
           PERFORM 9000-CLOSE-OUTPUTS
           IF WS-WRITE-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       1000-LOAD-RESULTS.
           MOVE "A" TO WS-RESULT-DESTINATION(1)
           MOVE "TXN-000001|0001234567|D|000125.50|A"
               TO WS-RESULT-TEXT(1)
           MOVE "A" TO WS-RESULT-DESTINATION(2)
           MOVE "TXN-000002|0007654321|T|000040.00|A"
               TO WS-RESULT-TEXT(2)
           MOVE "R" TO WS-RESULT-DESTINATION(3)
           MOVE "TXN-000003|0002468101|X|000000.00|R"
               TO WS-RESULT-TEXT(3)
           MOVE "R" TO WS-RESULT-DESTINATION(4)
           MOVE "TXN-000004|0009999999|T|000020.00|R"
               TO WS-RESULT-TEXT(4).
       2000-WRITE-ONE-RESULT.
           EVALUATE WS-RESULT-DESTINATION(WS-RESULT-NUMBER)
               WHEN "A"
                   WRITE FD-ACCEPTED-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-ACCEPTED-STATUS = "00"
                       ADD 1 TO WS-ACCEPTED-COUNT
                       DISPLAY "WRITE=ACCEPTED"
                           " TXN=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "WRITE=ACCEPTED FAILED STATUS="
                           WS-ACCEPTED-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN "R"
                   WRITE FD-REJECTED-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-REJECTED-STATUS = "00"
                       ADD 1 TO WS-REJECTED-COUNT
                       DISPLAY "WRITE=REJECTED"
                           " TXN=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "WRITE=REJECTED FAILED STATUS="
                           WS-REJECTED-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN OTHER
                   DISPLAY "WRITE=FAILED REASON=UNKNOWN_DESTINATION"
                   MOVE "Y" TO WS-WRITE-ERROR
           END-EVALUATE.
       9000-CLOSE-OUTPUTS.
           CLOSE ACCEPTED-FILE
           IF WS-ACCEPTED-STATUS = "00"
               DISPLAY "CLOSE=ACCEPTED OK"
           ELSE
               DISPLAY "CLOSE=ACCEPTED FAILED STATUS="
                   WS-ACCEPTED-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           CLOSE REJECTED-FILE
           IF WS-REJECTED-STATUS = "00"
               DISPLAY "CLOSE=REJECTED OK"
           ELSE
               DISPLAY "CLOSE=REJECTED FAILED STATUS="
                   WS-REJECTED-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           DISPLAY "SUMMARY ACCEPTED=" WS-ACCEPTED-COUNT
               " REJECTED=" WS-REJECTED-COUNT.
      *Each successful WRITE sets its file status to 00.
      *Counts increase only after a successful WRITE.
      *A failed OPEN stops before the corresponding file is written.
      *A failed WRITE sets an error flag and stops later writes.
