      *> CUSTOMER v1 -- frozen interface, 27 bytes (layout 001), ASCII.
      *> 1-8   customer_id    8 digits, leading zeros kept, unique
      *> 9-18  customer_name  10 chars, left justified, space padded
      *> 19-26 balance_demo   8 digits, unsigned demo amount
      *> 27    status         1 char: A active, D dormant; else reject
      *>
      *> Byte 27 is the record STATUS, NOT a customer distinction or
      *> classification.  The 11.5 maintenance task widens the
      *> distinction field of the independent, versioned enterprise
      *> layout (maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY); it
      *> must never be moved onto this byte.  See BANK-SYSTEM.md.
       01 CUSTOMER-RECORD.
          05 CUSTOMER-ID PIC X(8).
          05 CUSTOMER-NAME PIC X(10).
          05 CUSTOMER-BALANCE-DEMO PIC X(8).
          05 CUSTOMER-STATUS PIC X(1).
