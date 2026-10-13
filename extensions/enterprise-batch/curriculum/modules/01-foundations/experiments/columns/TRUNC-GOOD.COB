       IDENTIFICATION DIVISION.
       PROGRAM-ID. TRUNC-GOOD.
      *> Corrected version of TRUNC-BAD: the literal 111110 is
      *> written entirely inside columns 12-72, so the compiler
      *> sees every digit and the result is 1 + 111110 = 111111.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-BASE PIC 9(9) VALUE 1.
       01 WS-TOTAL-AMOUNT-BALANCE-DISPLAY-XYZ PIC 9(38) VALUE 0.
       PROCEDURE DIVISION.
           COMPUTE WS-TOTAL-AMOUNT-BALANCE-DISPLAY-XYZ =
               WS-BASE + 111110
           DISPLAY 'RESULT=' WS-TOTAL-AMOUNT-BALANCE-DISPLAY-XYZ
           GOBACK.
