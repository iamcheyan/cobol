      *> CUSTOMER v1 contract: 27 bytes, ASCII, LF-terminated.
      *> 1-based: 1-8 customer_id, 9-18 customer_name(10),
      *> 19-26 balance_demo(8, minor units, unsigned), 27 status.
      *> Layout frozen; business_date/schema version live in DESIGN.md.
       01 CUSTOMER-RECORD.
          05 CUST-ID          PIC X(8).
          05 CUST-NAME        PIC X(10).
          05 CUST-BALANCE     PIC X(8).
          05 CUST-STATUS      PIC X.
