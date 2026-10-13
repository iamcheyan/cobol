       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTLOAD-STARTER.
      *> Module 02 starter: the CUSTOMER v1 loader skeleton.
      *> It compiles but is NOT implemented. It must return RC 12 and
      *> must not publish accepted/rejected outputs until the TODOs are
      *> done. The CUSTOMER v1 copybook is provided for the layout.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO DYNAMIC IN-PATH
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS IN-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD IN-FILE.
       01 IN-BYTE PIC X.
       WORKING-STORAGE SECTION.
       01 IN-PATH PIC X(4096).
       01 IN-STATUS PIC XX.
           COPY "CUSTOMER-V1.CPY".
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT IN-PATH FROM ENVIRONMENT 'INPUT_FILE'
      *> TODO 1: OPEN INPUT and read raw bytes until X'0A'; reject any
      *>         record whose byte length is not exactly 27.
      *> TODO 2: validate customer id digits and strictly ascending ids.
      *> TODO 3: reject blank name (NAME-MISSING), non-digit balance
      *>         (BAD-AMOUNT) and bad status (UNKNOWN-STATUS), using
      *>         that priority order.
      *> TODO 4: accumulate accepted BALANCE-DEMO into an 18-digit sum.
      *> TODO 5: DISPLAY 'JOB|CUSTLOAD|V1' and the CONTROL line, then
      *>         set RETURN-CODE 0 (no rejects) or 4 (some rejects).
           DISPLAY 'TODO: implement validated CUSTOMER v1 loading'
           MOVE 12 TO RETURN-CODE
           GOBACK.
