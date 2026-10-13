      * NON-CONTRACT / intentionally wrong layout demo. This copybook is
      * NOT the CUSTOMER v1 interface: it wrongly declares CUSTOMER-NAME
      * as X(11), which makes the record 28 bytes. It exists only so
      * LENGTH-PROBE can show a single wrong PIC shifting every later
      * offset. The frozen contract is copybooks/CUSTOMER-V1.CPY (27 B,
      * last byte CUSTOMER-STATUS only). Never use this file as a layout
      * version or copy it into a job.
       01 CUSTOMER-RECORD.
          05 CUSTOMER-ID PIC X(8).
          05 CUSTOMER-NAME PIC X(11).
          05 BALANCE-DEMO PIC X(8).
          05 CUSTOMER-STATUS PIC X.
