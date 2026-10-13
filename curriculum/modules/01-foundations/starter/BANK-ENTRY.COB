       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-ENTRY-STARTER.
      *> Module 01 starter: the nightly batch entry skeleton.
      *> It compiles but is NOT implemented. It must return RC 12 and
      *> must not publish accepted/rejected outputs until the TODOs
      *> below are done. Do not edit the instructor reference.
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
       01 RUN-DATE PIC X(8).
       01 IN-STATUS PIC XX.
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT IN-PATH FROM ENVIRONMENT 'INPUT_FILE'
           ACCEPT RUN-DATE FROM ENVIRONMENT 'BUSINESS_DATE'
      *> TODO 1: OPEN INPUT the posted file and detect OPEN failure.
      *> TODO 2: read raw bytes until X'0A' and reject any record whose
      *>         byte length is not exactly 47 (short/long/no final LF).
      *> TODO 3: validate account id digits, layout '001', date equals
      *>         BUSINESS_DATE, sign in {+,-}, balance numeric, and that
      *>         account ids are strictly ascending.
      *> TODO 4: accept status A/F/C into PASS_OUTPUT_FILE, reject the
      *>         rest with UNKNOWN-STATUS into REJECT_OUTPUT_FILE.
      *> TODO 5: DISPLAY the JOB/BUSINESS-DATE/CONTROL report lines and
      *>         set RETURN-CODE 0 (no reject) or 4 (some rejects).
           DISPLAY 'TODO: implement validated account posted-file entry'
           MOVE 12 TO RETURN-CODE
           GOBACK.
