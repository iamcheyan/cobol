      *> STARTER for module 04 lesson 04.3. Builds as-is but INCOMPLETE.
      *> Complete the TODO paragraphs, set WS-EXERCISES-DONE to 'Y'.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. M04ENTERPRISE.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-ENT ASSIGN TO 'input.dat'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD IN-ENT.
       01 ENT-REC.
          COPY 'ENTERPRISE-CUSTOMER-V1.CPY'.
       WORKING-STORAGE SECTION.
       01 WS-STATUS PIC XX.
       01 WS-EXERCISES-DONE PIC X VALUE 'N'.
       PROCEDURE DIVISION.
       1000-MAIN.
           IF WS-EXERCISES-DONE NOT = 'Y'
               DISPLAY 'TODO,starter/M04ENTERPRISE.COB is not finished'
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
      *> TODO 04.3a: read 1,778-byte records; validate LAYOUT-VERSION,
      *> BINARY-ABI-CODE and a numeric CUSTOMER-ID; a bad structure ends
      *> RC8 and publishes nothing.
      *> TODO 04.3b: print located values (CUSTOMER-ID,
      *> RECORD-STATUS, LEGAL-SURNAME, CUSTOMER-CLASSIFICATION,
      *> RISK-SCORE, SYNC-STATE).
           DISPLAY 'LESSON,04.3'
           GOBACK.
