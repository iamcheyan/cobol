      * 呼出元から金額と結果領域を受け取る金額検証サブプログラムです。
      * ゼロを最初に判定し、次に1000.00超過を確認します。上限以下の正数は有効です。
      * 判定コードを共有領域へ設定し、GOBACKで呼出元へ制御を返します。
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
