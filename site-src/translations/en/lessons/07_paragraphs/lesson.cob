       IDENTIFICATION DIVISION.
       PROGRAM-ID. PARAGRAPH07.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 125.50.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
       PROCEDURE DIVISION.
      * All four items are shared; all paragraphs access the same data.
      * Initialize first; otherwise it clears processing results.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 9000-FINALIZE
           DISPLAY "バッチ=COMPLETE"
           STOP RUN.
       1000-INITIALIZE.
           DISPLAY "段階=INITIALIZE"
           MOVE ZERO TO WS-CLOSING-BALANCE.
       2000-PROCESS.
           DISPLAY "段階=PROCESS"
           COMPUTE WS-CLOSING-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT - WS-WITHDRAWAL
           DISPLAY "期末残高=" WS-CLOSING-BALANCE.
       9000-FINALIZE.
           DISPLAY "段階=FINALIZE"
           DISPLAY "最終残高=" WS-CLOSING-BALANCE.
