       IDENTIFICATION DIVISION.
       PROGRAM-ID. L28.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-STATUS PIC XX.
       01 WS-READ-COUNT PIC 9(7) VALUE ZERO.
       01 WS-ERROR-COUNT PIC 9(7) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY "Design the batch flow before coding."
           DISPLAY "See README."
           STOP RUN.
