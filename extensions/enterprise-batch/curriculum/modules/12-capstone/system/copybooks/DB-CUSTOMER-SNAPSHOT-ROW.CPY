      *論理テーブル6 customer_snapshot。
      *db/snapshots/<date>/customer_snapshot.dat。当日不変。
      *正規化後はCAP-CUSTOMER-FEED v2（32 B）。
       01 DB-CUSTOMER-SNAPSHOT-ROW.
          05 DBCS-ROW-DATA        PIC X(32).
