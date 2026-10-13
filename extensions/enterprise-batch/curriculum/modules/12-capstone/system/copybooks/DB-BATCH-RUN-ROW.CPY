      * Logical table 4 batch_run -> db/run/<date>.table.
      * Row: date|run_id|layout|phase|rc (phase start/applied/published)
       01 DB-BATCH-RUN-ROW.
          05 DBR-DATE             PIC X(8).
          05 DBR-RUN-ID           PIC X(40).
          05 DBR-LAYOUT           PIC X(2).
          05 DBR-PHASE            PIC X(12).
          05 DBR-RC               PIC X(2).
