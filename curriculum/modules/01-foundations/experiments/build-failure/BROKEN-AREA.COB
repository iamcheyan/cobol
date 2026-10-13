       IDENTIFICATION DIVISION.
       PROGRAM-ID. BROKEN-AREA.
      *> Deliberately broken fixed-format source for lesson 01.2. The
      *> MOVE statement starts at column 5, which is still Area A, so
      *> the compiler does not see a valid statement there. Area B
      *> statements must start at column 12 or later.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-N PIC 9 VALUE 0.
       PROCEDURE DIVISION.
       1000-MAIN.
    MOVE 1 TO WS-N.
           DISPLAY 'N=' WS-N
           GOBACK.
