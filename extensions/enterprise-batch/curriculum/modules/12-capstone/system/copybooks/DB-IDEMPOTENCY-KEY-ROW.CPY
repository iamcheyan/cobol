      * 論理テーブル11 idempotency_keyのキーは(date, txid)。
      * キーはdb/ledger.datに属。
      * 適用済み判定唯一情報源
       01 DB-IDEMPOTENCY-KEY-ROW.
          05 DBK-BUSINESS-DATE    PIC X(8).
          05 DBK-TRANSACTION-ID  PIC X(16).
