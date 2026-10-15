      * 文件处理失败时不将部分账户表同步到数据库。
      * 业务拒绝不算系统故障；每笔读入交易必须归为已记账或已拒绝。
      * 重复账户键在记账前报错；透支和未知账户/类型被拒绝且不改余额。
      * 相同输入从声明的期初余额重新应用，因此重跑不会重复累加存款。
      * 文件输出与数据库更新不是原子操作；生产批次需要持久批次ID及提交/恢复协议。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON32.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "BATCH-INTERFACE.CPY".
       01 WS-CHECK-COUNT PIC 999 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           INITIALIZE WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           MOVE "N" TO WS-FAILED
           CALL "LOADPOST32" USING BY REFERENCE
               WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           IF WS-FAILED NOT = "Y"
               CALL "SYNCDB32" USING BY REFERENCE
                   WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           END-IF
           PERFORM 3000-CHECK-COUNTS
           PERFORM 1000-REPORT-SUMMARY
           PERFORM 2000-RETURN-STATUS
           GOBACK.
       1000-REPORT-SUMMARY.
           DISPLAY "汇总 账户=" WS-ACCOUNT-COUNT
                   " 交易=" WS-TRANSACTION-COUNT
                   " 已过账=" WS-POSTED-COUNT
                   " 拒绝=" WS-REJECTED-COUNT
                   " 已更新=" WS-UPDATED-COUNT
                   " 未变更=" WS-UNCHANGED-COUNT
                   " 已插入=" WS-INSERTED-COUNT.
       2000-RETURN-STATUS.
           IF WS-FAILED = "Y"
               MOVE 1 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
       3000-CHECK-COUNTS.
           COMPUTE WS-CHECK-COUNT =
               WS-POSTED-COUNT + WS-REJECTED-COUNT
           IF WS-CHECK-COUNT NOT = WS-TRANSACTION-COUNT
               DISPLAY "错误=交易数量不匹配"
               MOVE "Y" TO WS-FAILED
           END-IF
           IF WS-FAILED NOT = "Y"
               COMPUTE WS-CHECK-COUNT =
                   WS-UPDATED-COUNT + WS-UNCHANGED-COUNT
                   + WS-INSERTED-COUNT
               IF WS-CHECK-COUNT NOT = WS-ACCOUNT-COUNT
                   DISPLAY "错误=同步数量不匹配"
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
       END PROGRAM LESSON32.
