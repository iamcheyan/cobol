      *================================================================*
      * TX-REC.CPY: 80-BYTE FIXED-LENGTH BANK TRANSACTION RECORD       *
      *================================================================*
       01  TX-RECORD.
           05  TX-HEADER.
               10  TX-DATE             PIC 9(08).
               10  TX-TIME             PIC 9(06).
               10  TX-ID               PIC X(10).
               10  TX-TYPE             PIC X(03).
                   88  TX-DEPOSIT      VALUE "DEP".
                   88  TX-WITHDRAW     VALUE "WDR".
                   88  TX-TRANSFER     VALUE "XFR".
           05  TX-AMOUNT               PIC 9(09)V99.
           05  TX-BODY                 PIC X(42).
      *    -- REDEFINES: DEPOSIT/WITHDRAW FORMAT (42 BYTES) --
           05  TX-DEP-INFO REDEFINES TX-BODY.
               10  TX-DEP-ACCOUNT      PIC X(16).
               10  TX-DEP-BRANCH       PIC X(08).
               10  TX-DEP-TELLER       PIC X(06).
               10  FILLER              PIC X(12).
      *    -- REDEFINES: TRANSFER FORMAT (42 BYTES) --
           05  TX-XFR-INFO REDEFINES TX-BODY.
               10  TX-XFR-FROM-ACCT    PIC X(16).
               10  TX-XFR-TO-ACCT      PIC X(16).
               10  TX-XFR-CHANNEL      PIC X(06).
               10  FILLER              PIC X(04).
