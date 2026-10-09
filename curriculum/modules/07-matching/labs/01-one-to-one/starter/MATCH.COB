       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-MATCH-L1.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      * TODO: Declare two input streams and their FILE STATUS items.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           COPY 'ACCOUNT-V1.CPY'.
           COPY 'TRANSACTION-V1.CPY'.
       01 M-PATH PIC X(4096).
       01 T-PATH PIC X(4096).
       01 RUN-DATE PIC X(8).
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT M-PATH FROM ENVIRONMENT 'ACCOUNT_FILE'
           ACCEPT T-PATH FROM ENVIRONMENT 'TRANSACTION_FILE'
           ACCEPT RUN-DATE FROM ENVIRONMENT 'BUSINESS_DATE'
      * TODO: Validate date, open files and read the first records.
      * TODO: Implement comparison, EOF draining and counters.
      * TODO: Close files; return 0 only after reconciliation.
           DISPLAY 'STARTER: NOT IMPLEMENTED' UPON STDERR
           MOVE 12 TO RETURN-CODE
           GOBACK.
