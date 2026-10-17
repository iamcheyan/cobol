      * ファイル障害時はDB同期しない。
      * 取引を記帳か業務拒否に分類する。
      * 口座重複は失敗。残高不足等は取引拒否。
      * 期首残高から再適用し、二重入金を防ぐ。
      * ファイルとDBは別更新。本番では復旧が必要。
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
           DISPLAY "集計 口座=" WS-ACCOUNT-COUNT
                   " 取引=" WS-TRANSACTION-COUNT
                   " 記帳=" WS-POSTED-COUNT
                   " 拒否=" WS-REJECTED-COUNT
                   " 更新=" WS-UPDATED-COUNT
                   " 変更なし=" WS-UNCHANGED-COUNT
                   " 挿入=" WS-INSERTED-COUNT.
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
               DISPLAY "エラー=取引件数不一致"
               MOVE "Y" TO WS-FAILED
           END-IF
           IF WS-FAILED NOT = "Y"
               COMPUTE WS-CHECK-COUNT =
                   WS-UPDATED-COUNT + WS-UNCHANGED-COUNT
                   + WS-INSERTED-COUNT
               IF WS-CHECK-COUNT NOT = WS-ACCOUNT-COUNT
                   DISPLAY "エラー=同期件数不一致"
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
       END PROGRAM LESSON32.
