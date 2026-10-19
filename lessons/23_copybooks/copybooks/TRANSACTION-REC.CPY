      * 取引20バイト（10+1+9）。第22課と同じ行幅。
      * 内部定数を格納。外部ファイルは読まない。
       01 WS-TRANSACTION-RECORD.
          05 WS-TRANSACTION-ACCOUNT PIC X(10).
          05 WS-TRANSACTION-TYPE PIC X.
          05 WS-TRANSACTION-AMOUNT PIC 9(7)V99.
