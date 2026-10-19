      * 論理テーブル10 publish_registry。
      * 格納先:db/publish_registry.dat
       01 DB-PUBLISH-REGISTRY-ROW.
          05 DBPR-DATE            PIC X(8).
          05 DBPR-RUN-ID          PIC X(40).
          05 DBPR-MANIFEST-SHA    PIC X(64).
          05 DBPR-FILE-COUNT      PIC 9(6).
          05 DBPR-PUBLISHED       PIC X(20).
