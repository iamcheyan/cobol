      *> Fault: REDEFINES must immediately follow the item it redefines.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FAULTREDEFINESADJ.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 BAD-REC.
          05 BAD-A PIC X(3) VALUE 'AAA'.
          05 BAD-B PIC X(3) VALUE 'BBB'.
          05 BAD-A-VIEW REDEFINES BAD-A PIC X(3).
       PROCEDURE DIVISION.
           DISPLAY BAD-A-VIEW
           GOBACK.
