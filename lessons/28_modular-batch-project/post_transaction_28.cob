      * 调用契约：LINKAGE 顺序须与调用方一致——账户记录、交易记录、状态字段，
      * 全部 BY REFERENCE；本程序只更新账户余额并写状态，不碰调用方的计数与日志。
      * 状态取值：POSTED / INSUFFICIENT / BAD_TYPE / NO_ACCOUNT。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. POST-TRANSACTION28.
       DATA DIVISION.
       LINKAGE SECTION.
       COPY "ACCOUNT-REC.CPY".
       COPY "TRANSACTION-REC.CPY".
       COPY "POST-STATUS.CPY".
       PROCEDURE DIVISION USING BY REFERENCE
           WS-ACCOUNT-RECORD
           WS-TRANSACTION-RECORD
           WS-POST-STATUS.
       0000-POST-TRANSACTION.
           IF WS-TRANSACTION-ACCOUNT NOT = WS-ACCOUNT-NUMBER
               MOVE "NO_ACCOUNT" TO WS-POST-STATUS
           ELSE
               EVALUATE WS-TRANSACTION-TYPE
                   WHEN "D"
                       ADD WS-TRANSACTION-AMOUNT
                           TO WS-ACCOUNT-BALANCE
                       MOVE "POSTED" TO WS-POST-STATUS
                   WHEN "C"
                       PERFORM 1000-CHECK-WITHDRAWAL
                   WHEN OTHER
                       MOVE "BAD_TYPE" TO WS-POST-STATUS
               END-EVALUATE
           END-IF
           GOBACK.
       1000-CHECK-WITHDRAWAL.
           IF WS-TRANSACTION-AMOUNT <= WS-ACCOUNT-BALANCE
               SUBTRACT WS-TRANSACTION-AMOUNT
                   FROM WS-ACCOUNT-BALANCE
               MOVE "POSTED" TO WS-POST-STATUS
           ELSE
               MOVE "INSUFFICIENT" TO WS-POST-STATUS
           END-IF.
