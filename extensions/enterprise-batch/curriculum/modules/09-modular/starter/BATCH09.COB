       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCH09.
      *    STARTER for module 09. Compiles, returns RC 12, no publish.
      *    Implement the three TODO areas and CALL the shared modules
      *    (CUSTVAL, AMTCALC, LOGGER) as specified in DESIGN.md.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT C-FILE ASSIGN TO DYNAMIC C-PATH
               ORGANIZATION IS SEQUENTIAL FILE STATUS IS C-STAT.
           SELECT M-FILE ASSIGN TO DYNAMIC M-PATH
               ORGANIZATION IS SEQUENTIAL FILE STATUS IS M-STAT.
           SELECT T-FILE ASSIGN TO DYNAMIC T-PATH
               ORGANIZATION IS SEQUENTIAL FILE STATUS IS T-STAT.
           SELECT LEDGER-OUT ASSIGN TO DYNAMIC L-PATH
               ORGANIZATION IS LINE SEQUENTIAL FILE STATUS IS L-STAT.
           SELECT VALID-OUT ASSIGN TO DYNAMIC V-PATH
               ORGANIZATION IS LINE SEQUENTIAL FILE STATUS IS V-STAT.
           SELECT REJECT-OUT ASSIGN TO DYNAMIC R-PATH
               ORGANIZATION IS LINE SEQUENTIAL FILE STATUS IS R-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD C-FILE.
       01 C-BYTE PIC X.
       FD M-FILE.
       01 M-BYTE PIC X.
       FD T-FILE.
       01 T-BYTE PIC X.
       FD LEDGER-OUT.
       01 L-OUT PIC X(47).
       FD VALID-OUT.
       01 V-OUT PIC X(27).
       FD REJECT-OUT RECORD IS VARYING IN SIZE FROM 29 TO 46
           CHARACTERS DEPENDING ON R-LENGTH.
       01 R-OUT PIC X(46).
       WORKING-STORAGE SECTION.
       01 C-PATH PIC X(4096).
       01 M-PATH PIC X(4096).
       01 T-PATH PIC X(4096).
       01 L-PATH PIC X(4096).
       01 V-PATH PIC X(4096).
       01 R-PATH PIC X(4096).
       01 RUN-DATE PIC X(8).
       01 C-STAT PIC XX.
       01 M-STAT PIC XX.
       01 T-STAT PIC XX.
       01 L-STAT PIC XX.
       01 V-STAT PIC XX.
       01 R-STAT PIC XX.
       01 C-RAW PIC X(27).
       01 M-RAW PIC X(47).
       01 T-RAW PIC X(55).
       01 R-LENGTH BINARY-LONG.
       01 WS-SUB-RC PIC 9(2) COMP-5.
           COPY "AMTCALC-INTERFACE-V1.CPY".
           COPY "CUSTVAL-INTERFACE-V1.CPY".
           COPY "LOGGER-INTERFACE-V1.CPY".
           COPY "CUSTOMER-V1.CPY".
           COPY "ACCOUNT-V1.CPY".
           COPY "TRANSACTION-V1.CPY".
       PROCEDURE DIVISION.
       1000-MAIN.
      *    TODO 1: read customer.dat, call CUSTVAL per record, write the
      *    report plus valid/rejected customer outputs.
      *    TODO 2: key-break account.dat/transaction.dat, call AMTCALC
      *    per postable transaction, keep opening/closing/credit/debit.
      *    TODO 3: call LOGGER for JOBSTART, each decision and JOBEND.
           DISPLAY 'STARTER: not implemented; see README.md' UPON STDERR
           MOVE 12 TO RETURN-CODE
           STOP RUN.
