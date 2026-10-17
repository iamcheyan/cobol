      * Call contract: amount PIC 9(7)V99 BY REFERENCE (read-only here)
      * result PIC X(15) is written here; order must match caller USING.
      * Status: ZERO-AMOUNT (zero), LIMIT-EXCEEDED (over 1000.00),
      * VALID (including 1000.00); GOBACK does not set caller exit code.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CHECK-AMOUNT.
       DATA DIVISION.
       LINKAGE SECTION.
       01 LK-AMOUNT PIC 9(7)V99.
       01 LK-CHECK-RESULT PIC X(15).
       PROCEDURE DIVISION USING LK-AMOUNT LK-CHECK-RESULT.
       0000-VALIDATE-AMOUNT.
           EVALUATE TRUE
               WHEN LK-AMOUNT = ZERO
                   MOVE "ZERO-AMOUNT" TO LK-CHECK-RESULT
               WHEN LK-AMOUNT > 1000.00
                   MOVE "LIMIT-EXCEEDED" TO LK-CHECK-RESULT
               WHEN OTHER
                   MOVE "VALID" TO LK-CHECK-RESULT
           END-EVALUATE
           GOBACK.
