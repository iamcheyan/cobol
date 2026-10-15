      * 27 字节账户记录（10+8+9），与第 17、20、22 课的定长文件接口同宽。
      * 消费者：lesson.cob、account_report_23.cob；第 28 课持有同宽度的独立副本。
      * 改任一字段宽度都会改变物理记录长度，须重编译全部消费者并逐字节复核。
       01 WS-ACCOUNT-RECORD.
          05 WS-ACCOUNT-NUMBER PIC X(10).
          05 WS-CUSTOMER-ID PIC X(8).
          05 WS-ACCOUNT-BALANCE PIC 9(7)V99.
