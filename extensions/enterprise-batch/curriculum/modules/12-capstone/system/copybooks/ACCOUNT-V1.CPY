      *ACCOUNT v1：固定形式、47B、ASCII、LF終端。
      *1-10 account_id：10桁、一意。
      *11-18 customer_id：8桁、CUSTOMER参照。
      *19-21 currency：3文字。本コースはJPYのみ。
      *22 balance_sign：テキスト記号+または-。
      *23-35 opening_balance：13桁、最小通貨単位。
      *36 account_status：A有効、F凍結、C閉鎖。
      *37-44 business_date：YYYYMMDD。
      *45-47 layout_version：001。
       01 ACCOUNT-V1-RECORD.
          05 AC1-ACCOUNT-ID      PIC X(10).
          05 AC1-CUSTOMER-ID     PIC X(8).
          05 AC1-CURRENCY        PIC X(3).
          05 AC1-BALANCE-SIGN    PIC X(1).
          05 AC1-OPENING-BALANCE PIC X(13).
          05 AC1-ACCOUNT-STATUS  PIC X(1).
          05 AC1-BUSINESS-DATE   PIC X(8).
          05 AC1-LAYOUT-VERSION  PIC X(3).
