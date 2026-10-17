      * Contract: ADD-ONE receives the parameter address BY REFERENCE,
      * BY REFERENCE callers see the new value after the increment,
      * while BY CONTENT changes a copy only; caller stays unchanged.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADD-ONE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EDITED-AMOUNT PIC 9(9) VALUE ZERO.
       LINKAGE SECTION.
       COPY "AMOUNT-INTERFACE.CPY".
       PROCEDURE DIVISION USING AMOUNT-ARGUMENT.
       0000-ADD-ONE.
           ADD 1 TO AMOUNT-ARGUMENT
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-AMOUNT
           DISPLAY "被呼出側=加算後 値=" WS-EDITED-AMOUNT
           GOBACK.
