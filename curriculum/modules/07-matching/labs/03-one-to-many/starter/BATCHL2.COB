       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-MATCH-L2-STARTER.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT M-FILE ASSIGN TO DYNAMIC M-PATH
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS M-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD M-FILE.
       01 M-BYTE PIC X.
       WORKING-STORAGE SECTION.
       01 M-PATH PIC X(4096).
       01 M-STATUS PIC XX.
       01 TODO-COUNT PIC 9(12) VALUE 0.
           COPY "ACCOUNT-V1.CPY".
           COPY "TRANSACTION-V1.CPY".
       PROCEDURE DIVISION.
       1000-MAIN.
           DISPLAY 'TODO: implement validated 1:N key break'
           DISPLAY 'TODO: add indexed reversal ledger and controls'
           MOVE 12 TO RETURN-CODE
           GOBACK.
