      *> ENTERPRISE-CLASS v1 -- small, versioned enterprise-customer
      *> class lab layout for the module 11.5 maintenance exercise
      *> (layout 001, 23 bytes, ASCII, one LF per record; LF is not
      *> counted in the width).
      *>
      *> NAMING / RELATIONSHIP: the canonical course enterprise record
      *> is module 07 L4 ENTERPRISE-CUSTOMER-V1 -- 175 leaf fields,
      *> fixed 1778 bytes -- whose CUSTOMER-CLASSIFICATION is X(1) in
      *> v1 and X(2) in v2.  This lab must NOT reuse that name for a
      *> 23-byte record (same name + incompatible layout = version
      *> drift).  It therefore has a DISTINCT interface name,
      *> ENTERPRISE-CLASS, and is a documented reduced projection: it
      *> keeps the same classification semantics (A/B/C/D ->
      *> A1/B1/C1/D1) but only the fields needed for the drill.
      *>
      *> This is also SEPARATE from the 27-byte canonical CUSTOMER v1:
      *> that record's byte 27 is the record STATUS (A/D), never a
      *> classification.
      *>
      *> 1-3   layout_version   3 chars, fixed '001'
      *> 4-11  customer_id      8 digits, leading zeros kept
      *> 12    record_status    1 char: A active, I inactive
      *> 13-22 customer_name    10 chars, left justified, space padded
      *> 23    customer_classification 1 char: A/B/C/D
       01 ENTERPRISE-CLASS-V1.
          05 LAYOUT-VERSION PIC X(3).
          05 CUSTOMER-ID PIC X(8).
          05 RECORD-STATUS PIC X(1).
          05 CUSTOMER-NAME PIC X(10).
          05 CUSTOMER-CLASSIFICATION PIC X(1).
