       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-FILEVAL-STARTER.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT A-FILE ASSIGN TO DYNAMIC A-PATH
               ORGANIZATION IS SEQUENTIAL FILE STATUS IS A-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD A-FILE.
       01 A-BYTE PIC X.
       WORKING-STORAGE SECTION.
       01 A-PATH PIC X(4096).
       01 A-STAT PIC XX.
       01 RUN-DATE PIC X(8).
           COPY "ACCOUNT-V1.CPY".
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT A-PATH FROM ENVIRONMENT 'ACCOUNT_FILE'
           ACCEPT RUN-DATE FROM ENVIRONMENT 'BUSINESS_DATE'
           DISPLAY 'TODO: read 47-byte records and detect length/CRLF'
           DISPLAY 'TODO: validate id/date/currency/status/balance'
           DISPLAY 'TODO: write accepted/rejected and file status log'
           MOVE 12 TO RETURN-CODE
           GOBACK.
