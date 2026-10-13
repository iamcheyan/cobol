      * CAP-CUSTOMER-FEED v2 -- maintenance deliverable (the target
      * of "customer classification 1 -> 2").  32 bytes, ASCII, LF.
      * This is an INDEPENDENT, versioned enterprise customer layout;
      * it is NOT the 27 byte CUSTOMER v1 (whose byte 27 is the record
      * status).  v2 = v1 with CUSTOMER-CLASSIFICATION widened from
      * PIC X(1) to PIC X(2) and LAYOUT-VERSION 001 -> 002:
      *   1-8   customer_id      8 digits, leading zeros kept
      *   9-18  customer_name    10 chars, space padded
      *   19-26 balance_demo     8 digits, minor unit
      *   27    record_status    1 char: A active, D dormant
      *   28-29 classification   2 chars: A1/B1/C1/D1 (v1 maps A->A1)
      *   30-32 layout_version   "002"
      * The v1 file is never overwritten in place; migrate to a new
      * file and keep the original for parallel comparison/rollback.
       01 CAP-CUSTOMER-FEED-V2-RECORD.
          05 EC2-CUSTOMER-ID            PIC X(8).
          05 EC2-CUSTOMER-NAME          PIC X(10).
          05 EC2-BALANCE-DEMO           PIC X(8).
          05 EC2-RECORD-STATUS          PIC X(1).
          05 EC2-CUSTOMER-CLASSIFICATION PIC X(2).
          05 EC2-LAYOUT-VERSION         PIC X(3).
