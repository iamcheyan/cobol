       IDENTIFICATION DIVISION.
       PROGRAM-ID. AMTCALC.
      *    Shared amount calculation, interface AMTCALC v1.
      *    Returns 0 accepted, 4 business reject, 8 interface error.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EXPECTED-LENGTH PIC 9(4) COMP-5.
       01 WS-LIMIT PIC S9(14) COMP-3 VALUE 9999999999999.
       01 WS-NLIMIT PIC S9(14) COMP-3 VALUE -9999999999999.
       01 WS-AMOUNT PIC 9(13) COMP-3.
       01 WS-DELTA PIC S9(14) COMP-3.
       01 WS-NEW PIC S9(14) COMP-3.
       LINKAGE SECTION.
           COPY "AMTCALC-INTERFACE-V1.CPY".
       PROCEDURE DIVISION USING AMT-CALC-INTERFACE.
       0000-CALCULATE.
           MOVE 0 TO RETURN-CODE
           MOVE SPACES TO AMT-REASON
           COMPUTE WS-EXPECTED-LENGTH = LENGTH OF AMT-CALC-INTERFACE
           IF AMT-IFACE-LENGTH NOT = WS-EXPECTED-LENGTH
              MOVE 'IFACE-LENGTH' TO AMT-REASON
              MOVE 8 TO RETURN-CODE
              GOBACK
           END-IF
           IF AMT-IFACE-VERSION NOT = '001'
              MOVE 'IFACE-VERSION' TO AMT-REASON
              MOVE 8 TO RETURN-CODE
              GOBACK
           END-IF
           IF AMT-IFACE-OP NOT = 'PST'
              MOVE 'IFACE-OP' TO AMT-REASON
              MOVE 8 TO RETURN-CODE
              GOBACK
           END-IF
           IF AMT-AMOUNT-IN IS NOT NUMERIC
              MOVE 'AMT-NOT-NUMERIC' TO AMT-REASON
              MOVE 4 TO RETURN-CODE
              GOBACK
           END-IF
           COMPUTE WS-AMOUNT = FUNCTION NUMVAL(AMT-AMOUNT-IN)
           IF WS-AMOUNT = 0
              MOVE 'ZERO-AMOUNT' TO AMT-REASON
              MOVE 4 TO RETURN-CODE
              GOBACK
           END-IF
           EVALUATE AMT-DIRECTION
             WHEN 'C'
               COMPUTE WS-DELTA = WS-AMOUNT
             WHEN 'D'
               COMPUTE WS-DELTA = 0 - WS-AMOUNT
             WHEN OTHER
               MOVE 'BAD-DIRECTION' TO AMT-REASON
               MOVE 4 TO RETURN-CODE
               GOBACK
           END-EVALUATE
           COMPUTE WS-NEW = AMT-BALANCE + WS-DELTA
           IF WS-NEW > WS-LIMIT OR WS-NEW < WS-NLIMIT
              MOVE 'OVERFLOW' TO AMT-REASON
              MOVE 4 TO RETURN-CODE
              GOBACK
           END-IF
           IF WS-NEW < 0
              MOVE 'OVERDRAFT' TO AMT-REASON
              MOVE 4 TO RETURN-CODE
              GOBACK
           END-IF
           MOVE WS-NEW TO AMT-BALANCE
           MOVE 'OK' TO AMT-REASON
           MOVE 0 TO RETURN-CODE
           GOBACK.
       END PROGRAM AMTCALC.
