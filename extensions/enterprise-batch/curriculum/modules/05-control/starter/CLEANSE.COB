       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-CLEANSE-STARTER.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT C-FILE ASSIGN TO DYNAMIC C-PATH
               ORGANIZATION IS SEQUENTIAL FILE STATUS IS C-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD C-FILE.
       01 C-BYTE PIC X.
       WORKING-STORAGE SECTION.
       01 C-PATH PIC X(4096).
       01 C-STAT PIC XX.
       01 RUN-DATE PIC X(8).
           COPY "CUSTOMER-V1.CPY".
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT C-PATH FROM ENVIRONMENT 'CUSTOMER_FILE'
           ACCEPT RUN-DATE FROM ENVIRONMENT 'BUSINESS_DATE'
           DISPLAY 'TODO: read 27-byte records without counting LF'
           DISPLAY 'TODO: reject short/long/CRLF/no final LF as RC8'
           DISPLAY 'TODO: normalise status, classify business reasons'
           DISPLAY 'TODO: emit accepted.dat, rejected.dat, control RC'
           MOVE 12 TO RETURN-CODE
           GOBACK.
