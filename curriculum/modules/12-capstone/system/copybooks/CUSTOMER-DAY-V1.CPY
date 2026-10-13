      * CUSTOMER-DAY v1 -- JOB007 downstream deliverable, 30 bytes, LF.
      * One row per customer for the business date.
      * 1-8   customer_id      8 digits
      * 9-10  classification   2 chars: A1/B1/C1/D1 (enterprise v2
      *                         form; a v1 A/B/C/D code becomes A1..)
      * 11-16 account_count    6 digits
      * 17    total_sign       '+' or '-'
      * 18-30 total_balance    13 digits, minor unit
      * The classification comes from the CAP-CUSTOMER-FEED layout,
      * never from the canonical CUSTOMER v1 status byte (byte 27).
       01 CUSTOMER-DAY-V1-RECORD.
          05 CD1-CUSTOMER-ID     PIC X(8).
          05 CD1-CLASSIFICATION  PIC X(2).
          05 CD1-ACCOUNT-COUNT   PIC X(6).
          05 CD1-TOTAL-SIGN      PIC X(1).
          05 CD1-TOTAL-BALANCE   PIC X(13).
