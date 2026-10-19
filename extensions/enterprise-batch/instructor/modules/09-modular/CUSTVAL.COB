       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTVAL.
      *    共通顧客検証M、IF CUSTVAL v1。
      *    RC: 0 有効、4 業務却下、8 IFエラー。
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EXPECTED-LENGTH PIC 9(4) COMP-5.
       LINKAGE SECTION.
           COPY "CUSTVAL-INTERFACE-V1.CPY".
       PROCEDURE DIVISION USING CUST-VAL-INTERFACE.
       0000-VALIDATE.
           MOVE 0 TO RETURN-CODE
           MOVE SPACES TO CVL-REASON
           COMPUTE WS-EXPECTED-LENGTH = LENGTH OF CUST-VAL-INTERFACE
           IF CVL-IFACE-LENGTH NOT = WS-EXPECTED-LENGTH
              MOVE 'IFACE-LENGTH' TO CVL-REASON
              MOVE 8 TO RETURN-CODE
              GOBACK
           END-IF
           IF CVL-IFACE-VERSION NOT = '001'
              MOVE 'IFACE-VERSION' TO CVL-REASON
              MOVE 8 TO RETURN-CODE
              GOBACK
           END-IF
           IF CVL-CUSTOMER-ID IS NOT NUMERIC
              MOVE 'BAD-ID' TO CVL-REASON
              MOVE 4 TO RETURN-CODE
              GOBACK
           END-IF
           IF CVL-NAME = SPACES
              MOVE 'CUST-NO-NAME' TO CVL-REASON
              MOVE 4 TO RETURN-CODE
              GOBACK
           END-IF
           EVALUATE CVL-STATUS-IN
             WHEN 'A'
               MOVE 'OK' TO CVL-REASON
               MOVE 0 TO RETURN-CODE
             WHEN 'D'
               MOVE 'CUST-DISABLED' TO CVL-REASON
               MOVE 4 TO RETURN-CODE
             WHEN OTHER
               MOVE 'CUST-BAD-STATUS' TO CVL-REASON
               MOVE 4 TO RETURN-CODE
           END-EVALUATE
           GOBACK.
       END PROGRAM CUSTVAL.
