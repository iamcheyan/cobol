      * CAP-CUSTOMER-FEED v2 -- independent, versioned enterprise
      * customer layout (layout version 002), 32 bytes, ASCII, LF.
      * Same as v1 except the classification is widened to 2 chars
      * (map A -> A1, B -> B1, C -> C1, D -> D1) at bytes 28-29 and
      * layout_version becomes "002".  Every field before the
      * classification keeps its offset; the widened field shifts
      * layout_version by one byte, so the record is 32 bytes.
      *   1-8   customer_id      8 digits, leading zeros kept
      *   9-18  customer_name    10 chars, space padded
      *   19-26 balance_demo     8 digits, minor unit
      *   27    record_status    1 char: A active, D dormant
      *   28-29 classification   2 chars: A1/B1/C1/D1 sub-coded
      *   30-32 layout_version   "002"
      * The 27 byte CUSTOMER v1 (byte 27 = status) is unchanged and
      * embedded at bytes 1-27; the classification is separate.
       01 CAP-CUSTOMER-FEED-V2-RECORD.
          05 EC2-CUSTOMER-ID            PIC X(8).
          05 EC2-CUSTOMER-NAME          PIC X(10).
          05 EC2-BALANCE-DEMO           PIC X(8).
          05 EC2-RECORD-STATUS          PIC X(1).
          05 EC2-CUSTOMER-CLASSIFICATION PIC X(2).
          05 EC2-LAYOUT-VERSION         PIC X(3).
