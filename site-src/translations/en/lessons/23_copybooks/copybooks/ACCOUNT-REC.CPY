      * 27-byte account record (10+8+9), matching Lessons 17, 20, 22.
      * Consumers: lesson.cob, account_report_23.cob; Lesson 28 copy.
      * Width changes alter record length; rebuild all and check bytes.
       01 WS-ACCOUNT-RECORD.
          05 WS-ACCOUNT-NUMBER PIC X(10).
          05 WS-CUSTOMER-ID PIC X(8).
          05 WS-ACCOUNT-BALANCE PIC 9(7)V99.
