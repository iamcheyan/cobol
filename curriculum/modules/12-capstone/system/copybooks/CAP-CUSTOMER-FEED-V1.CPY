      * CAP-CUSTOMER-FEED v1 -- capstone-specific, independent,
      * versioned customer feed layout (layout version 001), 31 bytes,
      * ASCII, LF.
      *
      * NAMING: this 31 byte feed is NOT the canonical 1778 byte
      * ENTERPRISE-CUSTOMER v1 of modules 04/07 (the 175 field large
      * record) and NOT the module 11 incident lab layout.  Reusing one
      * name for three incompatible widths would let a version label
      * hide a physical layout change, so the capstone uses the distinct
      * name CAP-CUSTOMER-FEED and states the relationship explicitly:
      *   - it EMBEDS the canonical 27 byte CUSTOMER v1 (bytes 1-27,
      *     byte 27 = record status A/D) unchanged;
      *   - it appends its own classification + layout_version.
      * The classification is NOT the status byte.
      *
      *   1-8   customer_id      8 digits, leading zeros kept
      *   9-18  customer_name    10 chars, space padded
      *   19-26 balance_demo     8 digits, minor unit
      *   27    record_status    1 char: A active, D dormant
      *   28    classification   1 char: A/B/C/D retail/business/
      *                          private/public-sector
      *   29-31 layout_version   "001"
      * v2 widens only the classification (A -> A1 .. D -> D1) at
      * bytes 28-29 and bumps layout_version to 002 (32 bytes).
       01 CAP-CUSTOMER-FEED-V1-RECORD.
          05 EC1-CUSTOMER-ID            PIC X(8).
          05 EC1-CUSTOMER-NAME          PIC X(10).
          05 EC1-BALANCE-DEMO           PIC X(8).
          05 EC1-RECORD-STATUS          PIC X(1).
          05 EC1-CUSTOMER-CLASSIFICATION PIC X(1).
          05 EC1-LAYOUT-VERSION         PIC X(3).
