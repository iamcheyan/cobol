      * ACCOUNT v1 -- FROZEN interface, 47 bytes, ASCII, LF terminated.
      * 1-10  account_id      10 digits, unique
      * 11-18 customer_id     8 digits, references CUSTOMER
      * 19-21 currency        3 chars, JPY only in this course
      * 22    balance_sign    '+' or '-', explicit in the text interface
      * 23-35 opening_balance 13 digits, minor unit
      * 36    account_status  A active, F frozen, C closed
      * 37-44 business_date   YYYYMMDD
      * 45-47 layout_version  001
       01 ACCOUNT-V1-RECORD.
          05 AC1-ACCOUNT-ID      PIC X(10).
          05 AC1-CUSTOMER-ID     PIC X(8).
          05 AC1-CURRENCY        PIC X(3).
          05 AC1-BALANCE-SIGN    PIC X(1).
          05 AC1-OPENING-BALANCE PIC X(13).
          05 AC1-ACCOUNT-STATUS  PIC X(1).
          05 AC1-BUSINESS-DATE   PIC X(8).
          05 AC1-LAYOUT-VERSION  PIC X(3).
