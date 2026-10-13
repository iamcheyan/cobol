       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKVAL-STARTER.
      *> STARTER for JOB002 (length and business validation).
      *> TODO: read the frozen snapshot at BANKVAL_IN, verify the raw
      *> byte length is exactly 55, validate the numeric key fields and
      *> the business rules (direction C/D, status N, business date,
      *> zero amount), then write BANKVAL_ACCEPTED / BANKVAL_REJECTED /
      *> BANKVAL_CONTROL and set RETURN-CODE (0/4/8/12).
      *> Until implemented this fails with RC12 and publishes nothing.
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
