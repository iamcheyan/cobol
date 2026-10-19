      *入力MANIFESTの行形式。
      *business_date=<YYYYMMDD>。
      *layout_transaction=001 / accounting=001 / customer=001。
      *file <name> <sha256>。
       01 MANIFEST-RECORD.
          05 MF-TAG               PIC X(12).
          05 MF-NAME              PIC X(64).
          05 MF-SHA256            PIC X(64).
