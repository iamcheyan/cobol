      * 20-byte transaction record (10+1+9), matching Lesson 22 fixture.
      * Used only for in-program constants; no external file is read.
       01 WS-TRANSACTION-RECORD.
          05 WS-TRANSACTION-ACCOUNT PIC X(10).
          05 WS-TRANSACTION-TYPE PIC X.
          05 WS-TRANSACTION-AMOUNT PIC 9(7)V99.
