      *> CUSTOMER v1 契約：27 bytes、ASCII、LF終端。
      *> 1始まり：1-8 customer_id、9-18 customer_name(10)、
      *19-26 balance_demo 8桁・最小通貨単位、27 status。
      *> 配置固定。business_date/schema は DESIGN.md 参照。
       01 CUSTOMER-RECORD.
          05 CUST-ID          PIC X(8).
          05 CUST-NAME        PIC X(10).
          05 CUST-BALANCE     PIC X(8).
          05 CUST-STATUS      PIC X.
