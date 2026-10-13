      * Shared reject record: 55 byte transaction (or 32 byte enterprise
      * customer v2; 31 byte v1 padded) followed by one separator and a
      * 10 character field-level reason.
       01 REJECT-RECORD.
          05 REJ-DATA             PIC X(55).
          05 REJ-SEP              PIC X(1).
          05 REJ-REASON           PIC X(10).
