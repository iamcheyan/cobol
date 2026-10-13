      *> STARTER for module 04 lesson 04.1. Builds as-is but INCOMPLETE.
      *> Complete the TODO paragraphs, set WS-EXERCISES-DONE to 'Y'.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. M04SHAPE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EXERCISES-DONE PIC X VALUE 'N'.
       01 WS-N PIC 9(3).
       PROCEDURE DIVISION.
       1000-MAIN.
           IF WS-EXERCISES-DONE NOT = 'Y'
               DISPLAY 'TODO,starter/M04SHAPE.COB is not finished'
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
      *> TODO 04.1a: declare a group with a REDEFINES view; prove that
      *> LENGTH OF the parent is not doubled.
      *> TODO 04.1b: declare a 66-level RENAMES over two fields.
      *> TODO 04.1c: declare OCCURS ... INDEXED BY and use SET to read
      *> an item by index.
      *> TODO 04.1d: declare OCCURS n TO m TIMES DEPENDING ON a counter
      *> and show LENGTH OF changes when the counter changes.
           DISPLAY 'LESSON,04.1'
           MOVE 0 TO WS-N
           DISPLAY 'REDEFINES,WRAP-LEN,' WS-N
           GOBACK.
