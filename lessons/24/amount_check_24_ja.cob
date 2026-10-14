      * 金額を検証し、呼び出し元にステータスを返し
      * ます。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CHECK-AMOUNT.
       DATA DIVISION.
       LINKAGE SECTION.
       01 LK-AMOUNT PIC 9(7)V99.
       01 LK-CHECK-RESULT PIC X(15).
      * 呼び出し規約で渡された金額と結果領域を受け
      * 取ります。
      * ゼロを先に判定し、上限超過と通常の有効値を
      * 区別します。
      * 結果コードは呼び出し元の領域へ返し、GOBACKで
      * 制御を戻します。
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
