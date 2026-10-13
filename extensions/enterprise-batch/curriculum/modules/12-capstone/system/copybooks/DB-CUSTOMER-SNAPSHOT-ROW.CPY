      * Logical table 6 customer_snapshot ->
      * db/snapshots/<date>/customer_snapshot.dat (immutable/day).
      * Rows are CAP-CUSTOMER-FEED v2 (32 B) after normalization.
       01 DB-CUSTOMER-SNAPSHOT-ROW.
          05 DBCS-ROW-DATA        PIC X(32).
