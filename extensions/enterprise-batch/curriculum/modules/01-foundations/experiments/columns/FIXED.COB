       IDENTIFICATION DIVISION.
       PROGRAM-ID. CONVERT-FIXED.
      *> Fixed-format half of the format comparison pair. The same
      *> logic is written in FREE.COB using free format. Both must
      *> print RESULT= followed by 38 digits ending in 111111.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-BASE PIC 9(9) VALUE 1.
       01 WS-RESULT PIC 9(38) VALUE 0.
       PROCEDURE DIVISION.
           COMPUTE WS-RESULT = WS-BASE + 111110
           DISPLAY 'RESULT=' WS-RESULT
           GOBACK.
