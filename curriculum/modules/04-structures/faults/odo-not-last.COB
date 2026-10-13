      *> Fault: an OCCURS DEPENDING ON item must be the last variable
      *> item of its group. Data after it must not compile.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FAULTODONOTLAST.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 BAD-REC.
          05 BAD-COUNT PIC 9(2) VALUE 03.
          05 BAD-ITEM OCCURS 0 TO 10 TIMES
             DEPENDING ON BAD-COUNT PIC X(5).
          05 BAD-TRAILER PIC X(5) VALUE SPACES.
       PROCEDURE DIVISION.
           DISPLAY BAD-TRAILER
           GOBACK.
