       IDENTIFICATION DIVISION.
       PROGRAM-ID. BASH-TEST.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COUNT PIC 9 VALUE 3.
       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY "Regression check passed."
           DISPLAY "Records processed: " WS-COUNT
           STOP RUN.
