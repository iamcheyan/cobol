      *論理テーブル5 batch_commit：db/commit/<date>.json。
      *項目：business_date、commit_id、run_id、new_transactions、
      *applied_transactions、ledger_sha256。
       01 DB-BATCH-COMMIT-ROW.
          05 DBCM-BUSINESS-DATE   PIC X(8).
          05 DBCM-COMMIT-ID       PIC X(16).
          05 DBCM-RUN-ID          PIC X(40).
          05 DBCM-NEW-TX          PIC 9(9).
          05 DBCM-APPLIED-TX      PIC 9(9).
          05 DBCM-LEDGER-SHA256   PIC X(64).
