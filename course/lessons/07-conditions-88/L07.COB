       IDENTIFICATION DIVISION.
       PROGRAM-ID. L07.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-STATUS PIC X VALUE "N".
           88 WS-READY VALUE "Y".
           88 WS-NOT-READY VALUE "N".
       PROCEDURE DIVISION.
       0000-MAIN.
           IF WS-NOT-READY
               DISPLAY "Not ready yet."
           END-IF
           SET WS-READY TO TRUE
           IF WS-READY
               DISPLAY "Ready."
           END-IF
           STOP RUN.
