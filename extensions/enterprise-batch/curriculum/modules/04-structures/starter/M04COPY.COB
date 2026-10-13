      *> STARTER for module 04 lesson 04.2. Builds as-is but INCOMPLETE.
      *> Complete the TODO paragraphs, set WS-EXERCISES-DONE to 'Y'.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. M04COPY.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EXERCISES-DONE PIC X VALUE 'N'.
       PROCEDURE DIVISION.
       1000-MAIN.
           IF WS-EXERCISES-DONE NOT = 'Y'
               DISPLAY 'TODO,starter/M04COPY.COB is not finished'
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
      *> TODO 04.2a: COPY the enterprise copybook (V1) and again with
      *> COPY REPLACING that widens CUSTOMER-CLASSIFICATION to PIC X(2).
      *> TODO 04.2b: show LENGTH OF V2 - LENGTH OF V1 = 1.
      *> TODO 04.2c: extract CUSTOMER-ID with reference modification.
           DISPLAY 'LESSON,04.2'
           GOBACK.
