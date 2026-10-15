       IDENTIFICATION DIVISION.
       PROGRAM-ID. PARAGRAPH07.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 125.50.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 9000-FINALIZE
           DISPLAY "Batch=COMPLETE"
           STOP RUN.
       1000-INITIALIZE.
           DISPLAY "Stage=INITIALIZE"
           MOVE ZERO TO WS-CLOSING-BALANCE.
       2000-PROCESS.
           DISPLAY "Stage=PROCESS"
           COMPUTE WS-CLOSING-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT - WS-WITHDRAWAL
           DISPLAY "Closing balance=" WS-CLOSING-BALANCE.
       9000-FINALIZE.
           DISPLAY "Stage=FINALIZE"
           DISPLAY "Final balance=" WS-CLOSING-BALANCE.
      * Initialization precedes the arithmetic processing stage.
      * Reordering calls changes the visible stage order.
