      * 20 字节交易记录（10+1+9），与第 22 课交易夹具的行宽同宽。
      * 本课只用它保存程序内常量样例，不读外部文件。
       01 WS-TRANSACTION-RECORD.
          05 WS-TRANSACTION-ACCOUNT PIC X(10).
          05 WS-TRANSACTION-TYPE PIC X.
          05 WS-TRANSACTION-AMOUNT PIC 9(7)V99.
