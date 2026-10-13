      * Logical table 10 publish_registry -> db/publish_registry.dat.
      * Row: date|run_id|manifest_sha256|file_count|published_at
       01 DB-PUBLISH-REGISTRY-ROW.
          05 DBPR-DATE            PIC X(8).
          05 DBPR-RUN-ID          PIC X(40).
          05 DBPR-MANIFEST-SHA    PIC X(64).
          05 DBPR-FILE-COUNT      PIC 9(6).
          05 DBPR-PUBLISHED       PIC X(20).
