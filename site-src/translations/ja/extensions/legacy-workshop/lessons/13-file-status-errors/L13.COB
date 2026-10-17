       IDENTIFICATION DIVISION.
       PROGRAM-ID. L13.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX.
       01 WS-ERROR-COUNT PIC 9(4) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           IF WS-FILE-STATUS = "00"
               DISPLAY "File operation succeeded."
           ELSE
               ADD 1 TO WS-ERROR-COUNT
               DISPLAY "FILE STATUS=" WS-FILE-STATUS
           END-IF
           STOP RUN.
