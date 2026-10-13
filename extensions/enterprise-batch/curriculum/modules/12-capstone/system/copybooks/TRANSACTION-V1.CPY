      * TRANSACTION v1 -- FROZEN, 55 bytes, ASCII, LF terminated.
      * 1-10  account_id      10 digits, match key
      * 11-26 transaction_id  16 chars, idempotency key part
      * 27-34 business_date   8 digits, must equal the run business date
      * 35-40 sequence_no     6 digits, per-account processing order
      * 41    direction       C credit, D debit
      * 42-54 amount          13 digits, minor unit, non-negative
      * 55    status          N new; other statuses are policy-specific
       01 TRANSACTION-V1-RECORD.
          05 TX1-ACCOUNT-ID      PIC X(10).
          05 TX1-TRANSACTION-ID  PIC X(16).
          05 TX1-BUSINESS-DATE   PIC X(8).
          05 TX1-SEQUENCE-NO     PIC X(6).
          05 TX1-DIRECTION       PIC X(1).
          05 TX1-AMOUNT          PIC X(13).
          05 TX1-STATUS          PIC X(1).
