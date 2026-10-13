      * Logical table 11 idempotency_key -> the (date, txid) key columns
      * of db/ledger.dat.  The single source of truth for "already
      * applied": a rerun never double-debits.
       01 DB-IDEMPOTENCY-KEY-ROW.
          05 DBK-BUSINESS-DATE    PIC X(8).
          05 DBK-TRANSACTION-ID  PIC X(16).
