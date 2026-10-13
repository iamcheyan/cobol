       IDENTIFICATION DIVISION.
       PROGRAM-ID. BROKEN-PERFORM.
      *> Deliberately broken build for lesson 01.2. The PERFORM target
      *> 5000-SETTLE-PARAGRAPH is never defined, so cobc reports an
      *> undefined paragraph. The learner must locate the failing line
      *> from the compiler diagnostic and fix/rename it.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COUNT PIC 9(4) VALUE 0.
       PROCEDURE DIVISION.
       1000-MAIN.
           PERFORM 5000-SETTLE-PARAGRAPH
           DISPLAY 'COUNT=' WS-COUNT
           GOBACK.
       2000-COUNT-ONE.
           ADD 1 TO WS-COUNT.
