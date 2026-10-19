       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKVAL-STARTER.
      *JOB002の雛形（長さと業務規則の検証）。
      *TODO: BANKVAL_INの固定スナップショットを読み、
      * 生データの
      *B長が55であること、数値キー項目と
      *業務規則（direction C/D、status N、営業日、
      *金額0）を検証。BANKVAL_ACCEPTED /
      * BANKVAL_REJECTED
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TX-IN ASSIGN TO DYNAMIC IN-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS IN-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD TX-IN.
       01 IN-LINE PIC X(400).
       WORKING-STORAGE SECTION.
       01 IN-PATH PIC X(4096).
       01 IN-STAT PIC XX.
       PROCEDURE DIVISION.
           ACCEPT IN-PATH FROM ENVIRONMENT 'BANKVAL_IN'
           DISPLAY 'BANKVAL starter: TODO not implemented' UPON STDERR
           MOVE 12 TO RETURN-CODE
           GOBACK.
