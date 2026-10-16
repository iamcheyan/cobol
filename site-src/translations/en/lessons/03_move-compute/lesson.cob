      * Lesson 03: MOVE/COMPUTE monetary example.
      * Data are in-program demo constants, not real accounts.
      * No ROUNDED means truncate; ROUNDED rounds to dest.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE03.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 250.55.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
       01 WS-SERVICE-FEE PIC 9(5)V99 VALUE 5.25.
      * Demo rate: no day-count rule; multiply once.
       01 WS-PERIOD-RATE PIC 9(1)V9(4) VALUE 0.0125.
       01 WS-PRE-INTEREST-BALANCE PIC 9(7)V99 VALUE ZERO.
      * Intermediate keeps 4 decimals for compare.
       01 WS-INTEREST-RAW PIC 9(5)V9999 VALUE ZERO.
       01 WS-INTEREST-MOVE PIC 9(5)V99 VALUE ZERO.
       01 WS-INTEREST-TRUNC PIC 9(5)V99 VALUE ZERO.
      * ROUNDED rounds to dest; default away from zero.
       01 WS-INTEREST-ROUNDED PIC 9(5)V99 VALUE ZERO.
      * Posting rule: this lesson credits rounded interest.
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
       PROCEDURE DIVISION.
           COMPUTE WS-PRE-INTEREST-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT
                   - WS-WITHDRAWAL - WS-SERVICE-FEE.
           COMPUTE WS-INTEREST-RAW =
               WS-PRE-INTEREST-BALANCE * WS-PERIOD-RATE.
           MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE.
           COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW.
           COMPUTE WS-INTEREST-ROUNDED ROUNDED =
               WS-INTEREST-RAW.
           COMPUTE WS-CLOSING-BALANCE =
               WS-PRE-INTEREST-BALANCE + WS-INTEREST-ROUNDED.
           DISPLAY "期首残高=" WS-OPENING-BALANCE
           DISPLAY "預入額=" WS-DEPOSIT
           DISPLAY "払戻額=" WS-WITHDRAWAL
           DISPLAY "手数料=" WS-SERVICE-FEE
           DISPLAY "期間利率=" WS-PERIOD-RATE
           DISPLAY "利息加算前残高="
               WS-PRE-INTEREST-BALANCE
           DISPLAY "利息（4桁）=" WS-INTEREST-RAW
           DISPLAY "MOVE後利息（2桁）=" WS-INTEREST-MOVE
           DISPLAY "COMPUTE切捨て利息=" WS-INTEREST-TRUNC
           DISPLAY "COMPUTE四捨五入利息="
               WS-INTEREST-ROUNDED
           DISPLAY "期末残高=" WS-CLOSING-BALANCE
      * Overflow silently drops high digits; no runtime error.
      * Overflow must be checked explicitly (lesson 26).
           STOP RUN.
