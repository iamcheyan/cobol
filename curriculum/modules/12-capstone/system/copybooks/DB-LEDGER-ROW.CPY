      * Logical table 3 transaction_ledger -> db/ledger.dat.
      * Row: date|txid|account|direction|amount|commit_id
       01 DB-LEDGER-ROW.
          05 DBL-DATE             PIC X(8).
          05 DBL-TXID             PIC X(16).
          05 DBL-ACCOUNT          PIC X(10).
          05 DBL-DIRECTION        PIC X(1).
          05 DBL-AMOUNT           PIC 9(13).
          05 DBL-COMMIT-ID        PIC X(16).
