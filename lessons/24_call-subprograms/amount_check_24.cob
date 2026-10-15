      * 调用契约：调用方按 BY REFERENCE 传入「金额 PIC 9(7)V99」（本模块只读）
      * 与「结果 PIC X(15)」（本模块写入），次序必须与调用方 USING 一致。
      * 状态取值 ZERO-AMOUNT（金额为零）、LIMIT-EXCEEDED（超过 1000.00）、
      * VALID（含恰好 1000.00）；用 GOBACK 返回，不决定调用方退出码。
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
