      * CUSTOMER v1 -- canonical frozen interface, 27 bytes, ASCII.
      * One record is followed by LF; the LF is not counted in the 27.
      * 1-8   customer_id     8 digits, leading zeros kept
      * 9-18  customer_name   10 chars, left justified, space padded
      * 19-26 balance_demo    8 digits, minor unit, unsigned demo
      * 27    status          1 char: A active, D dormant; else reject
      *
      * Byte 27 is the record STATUS, never a customer distinction.
      * The customer DISTINCTION/CLASSIFICATION for the module 11/12
      * maintenance exercise is a DIFFERENT field and lives in the
      * independent, versioned CAP-CUSTOMER-FEED layout -- see
      * CAP-CUSTOMER-FEED-V1.CPY / CUSTOMER-DAY-V1.CPY and
      * docs/curriculum/BANK-SYSTEM.md section 2.
       01 CUSTOMER-V1-RECORD.
          05 CV1-CUSTOMER-ID    PIC X(8).
          05 CV1-CUSTOMER-NAME  PIC X(10).
          05 CV1-BALANCE-DEMO   PIC X(8).
          05 CV1-CUSTOMER-STATUS PIC X(1).
