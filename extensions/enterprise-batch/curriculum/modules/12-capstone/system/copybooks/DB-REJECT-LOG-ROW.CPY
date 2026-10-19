      *論理テーブル8 reject_log：db/reject_log.dat。
      *形式：date|stage|txid|customer または reason。
       01 DB-REJECT-LOG-ROW.
          05 DBRL-DATE            PIC X(8).
          05 DBRL-STAGE           PIC X(10).
          05 DBRL-KEY             PIC X(16).
          05 DBRL-REASON          PIC X(16).
