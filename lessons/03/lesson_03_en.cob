      * Without ROUNDED, excess fractional digits are truncated.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE03.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 250.55.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
       01 WS-SERVICE-FEE PIC 9(5)V99 VALUE 5.25.
      * The sample applies 0.0125 once, without a day-count adjustment.
       01 WS-PERIOD-RATE PIC 9(1)V9(4) VALUE 0.0125.
       01 WS-PRE-INTEREST-BALANCE PIC 9(7)V99 VALUE ZERO.
       01 WS-INTEREST-RAW PIC 9(5)V9999 VALUE ZERO.
       01 WS-INTEREST-MOVE PIC 9(5)V99 VALUE ZERO.
       01 WS-INTEREST-TRUNC PIC 9(5)V99 VALUE ZERO.
      * ROUNDED requests arithmetic rounding to the receiver's scale.
       01 WS-INTEREST-ROUNDED PIC 9(5)V99 VALUE ZERO.
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
       PROCEDURE DIVISION.
           COMPUTE WS-PRE-INTEREST-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT
                   - WS-WITHDRAWAL - WS-SERVICE-FEE.
           COMPUTE WS-INTEREST-RAW =
               WS-PRE-INTEREST-BALANCE * WS-PERIOD-RATE.
           MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE.
      * Without ROUNDED, extra fractional digits are truncated.
           COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW.
           COMPUTE WS-INTEREST-ROUNDED ROUNDED =
               WS-INTEREST-RAW.
           COMPUTE WS-CLOSING-BALANCE =
               WS-PRE-INTEREST-BALANCE + WS-INTEREST-ROUNDED.
           DISPLAY "Opening balance=" WS-OPENING-BALANCE
           DISPLAY "Deposit=" WS-DEPOSIT
           DISPLAY "Withdrawal=" WS-WITHDRAWAL
           DISPLAY "Service fee=" WS-SERVICE-FEE
           DISPLAY "Period rate=" WS-PERIOD-RATE
           DISPLAY "Pre-interest balance="
               WS-PRE-INTEREST-BALANCE
           DISPLAY "Raw interest (4dp)=" WS-INTEREST-RAW
           DISPLAY "Interest after MOVE (2dp)=" WS-INTEREST-MOVE
           DISPLAY "Truncated interest=" WS-INTEREST-TRUNC
           DISPLAY "Interest after rounded COMPUTE="
               WS-INTEREST-ROUNDED
           DISPLAY "Closing balance=" WS-CLOSING-BALANCE
      * A too-small receiving item can raise a size-error condition.
      * Real batches require documented rounding and posting rules.
           STOP RUN.
