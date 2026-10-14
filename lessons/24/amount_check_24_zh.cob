      * 验证金额并向调用方返回状态。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CHECK-AMOUNT.
       DATA DIVISION.
       LINKAGE SECTION.
       01 LK-AMOUNT PIC 9(7)V99.
       01 LK-CHECK-RESULT PIC X(15).
      * 通过调用约定接收金额和结果存储区。
      * 先判断零值，再区分超出上限与有效金额。
      * 将结果代码写回调用方区域，并用GOBACK返回控制
      * 权。
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
