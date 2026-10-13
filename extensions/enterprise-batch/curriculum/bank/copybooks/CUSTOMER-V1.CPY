      *> CUSTOMER v1 -- canonical frozen interface, 27 bytes, ASCII.
      *> One record is followed by LF; LF is not counted in the width.
      *> 1-8   customer_id    8 digits, leading zeros kept, unique
      *> 9-18  customer_name  10 chars, left justified, space padded
      *> 19-26 balance_demo   8 digits, minor unit, unsigned demo
      *> 27    status         1 char: A active, D dormant; else reject
      *>
      *> Byte 27 is the record STATUS, not a distinction.  The customer
      *> DISTINCTION for the module 11/12 maintenance exercise is a
      *> DIFFERENT field and must live in an independent, versioned
      *> enterprise layout -- never in this byte.  See BANK-SYSTEM.md
      *> section 2 and module 07 L4 ENTERPRISE-CUSTOMER-V1, whose
      *> CUSTOMER-CLASSIFICATION is X(1) in v1 and X(2) in v2.
       01 CUSTOMER-RECORD.
          05 CUSTOMER-ID          PIC X(8).
          05 CUSTOMER-NAME        PIC X(10).
          05 CUSTOMER-BALANCE-DEMO PIC X(8).
          05 CUSTOMER-STATUS      PIC X(1).
