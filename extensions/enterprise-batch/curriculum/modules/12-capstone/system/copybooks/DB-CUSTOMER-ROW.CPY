      * Logical table 1 customer -> db/customer.table (31 or 32 B).
      * Physical row is CAP-CUSTOMER-FEED-V1-RECORD (31) or
      * CAP-CUSTOMER-FEED-V2-RECORD (32); reader stores v2.
       01 DB-CUSTOMER-ROW.
          05 DBC-ROW-DATA         PIC X(32).
