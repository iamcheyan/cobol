      *> ENTERPRISE-CLASS v2 -- reviewed target of the 11.5 task
      *> (layout 002, 24 bytes).  CUSTOMER-CLASSIFICATION widens from
      *> 1 to 2 chars (A->A1, B->B1, C->C1, D->D1) and LAYOUT-VERSION
      *> becomes '002'.  v1 files are migrated by migrate-customer.py,
      *> never rewritten in place, and a v1 file is rejected by a v2
      *> reader on width.
      *>
      *> NAMING / RELATIONSHIP: distinct name from the canonical module
      *> 07 L4 ENTERPRISE-CUSTOMER-V1 (1778 bytes / 175 fields); see
      *> ENTERPRISE-CLASS-V1.CPY.  The 27-byte canonical CUSTOMER v1
      *> teaching interface (byte 27 = status) is unchanged by this
      *> version.
      *>
      *> 1-3   layout_version   3 chars, fixed '002'
      *> 4-11  customer_id      8 digits, leading zeros kept
      *> 12    record_status    1 char: A active, I inactive
      *> 13-22 customer_name    10 chars, left justified, space padded
      *> 23-24 customer_classification 2 chars: A1/B1/C1/D1
       01 ENTERPRISE-CLASS-V2.
          05 LAYOUT-VERSION PIC X(3).
          05 CUSTOMER-ID PIC X(8).
          05 RECORD-STATUS PIC X(1).
          05 CUSTOMER-NAME PIC X(10).
          05 CUSTOMER-CLASSIFICATION PIC X(2).
