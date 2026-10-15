      * 読取段落は成功時に現在レコードを更新し、状態10を個別に記録します。
      * EOF以外のI/Oエラーでは処理を失敗させます。
      * 片側だけのキーは孤立レコードです。一側EOF後は残りをすべて分類します。
      * 比較前にEOFを確認し、入力を閉じてから分類件数を表示します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MATCH20.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-MASTER
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT DAILY-TRANSACTIONS
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-MASTER.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
       FD DAILY-TRANSACTIONS.
       01 FD-TRANSACTION-RECORD.
          05 FD-TRANSACTION-ACCOUNT PIC X(10).
          05 FD-TRANSACTION-TYPE PIC X.
          05 FD-TRANSACTION-AMOUNT PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-TRANSACTION-STATUS PIC XX VALUE SPACES.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-MATCH-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT-ONLY-COUNT PIC 9(3) VALUE ZERO.
       01 WS-TRANSACTION-ONLY-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT ACCOUNT-MASTER
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "口座ファイルを開けません STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN INPUT DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "取引ファイルを開けません STATUS="
                   WS-TRANSACTION-STATUS
               CLOSE ACCOUNT-MASTER
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "口座と取引を開きました"
           PERFORM 1000-READ-ACCOUNT
           PERFORM 2000-READ-TRANSACTION
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y"
               AND WS-TRANSACTION-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 3000-MATCH-CURRENT-RECORDS
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       3000-MATCH-CURRENT-RECORDS.
           EVALUATE TRUE
               WHEN WS-ACCOUNT-EOF = "Y"
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN WS-TRANSACTION-EOF = "Y"
                   PERFORM 4000-REPORT-ACCOUNT-ONLY
                   PERFORM 1000-READ-ACCOUNT
               WHEN FD-ACCOUNT-NUMBER < FD-TRANSACTION-ACCOUNT
                   PERFORM 4000-REPORT-ACCOUNT-ONLY
                   PERFORM 1000-READ-ACCOUNT
               WHEN FD-ACCOUNT-NUMBER > FD-TRANSACTION-ACCOUNT
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN OTHER
                   PERFORM 4200-REPORT-MATCH
                   PERFORM 1000-READ-ACCOUNT
                   IF WS-IO-ERROR = "N"
                       PERFORM 2000-READ-TRANSACTION
                   END-IF
           END-EVALUATE.
       1000-READ-ACCOUNT.
           READ ACCOUNT-MASTER
               AT END
                   MOVE "Y" TO WS-ACCOUNT-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-ACCOUNT-STATUS NOT = "00"
               AND WS-ACCOUNT-STATUS NOT = "10"
               DISPLAY "口座ファイル読み取り失敗 STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       2000-READ-TRANSACTION.
           READ DAILY-TRANSACTIONS
               AT END
                   MOVE "Y" TO WS-TRANSACTION-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-TRANSACTION-STATUS NOT = "00"
               AND WS-TRANSACTION-STATUS NOT = "10"
               DISPLAY "取引ファイル読み取り失敗 STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       4000-REPORT-ACCOUNT-ONLY.
           ADD 1 TO WS-ACCOUNT-ONLY-COUNT
           DISPLAY "口座のみ 口座番号=" FD-ACCOUNT-NUMBER
               " 顧客番号=" FD-CUSTOMER-ID
               " 残高=" FD-ACCOUNT-BALANCE.
       4100-REPORT-TRANSACTION-ONLY.
           ADD 1 TO WS-TRANSACTION-ONLY-COUNT
           DISPLAY "取引のみ 口座番号="
               FD-TRANSACTION-ACCOUNT
               " 種別=" FD-TRANSACTION-TYPE
               " 金額=" FD-TRANSACTION-AMOUNT.
       4200-REPORT-MATCH.
           ADD 1 TO WS-MATCH-COUNT
           DISPLAY "一致 口座番号=" FD-ACCOUNT-NUMBER
               " 顧客番号=" FD-CUSTOMER-ID
               " 残高=" FD-ACCOUNT-BALANCE
               " 種別=" FD-TRANSACTION-TYPE
               " 金額=" FD-TRANSACTION-AMOUNT.
       9000-CLOSE-FILES.
           CLOSE ACCOUNT-MASTER
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "口座ファイルクローズ失敗 STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "取引ファイルクローズ失敗 STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "照合件数=" WS-MATCH-COUNT
               " 口座のみ=" WS-ACCOUNT-ONLY-COUNT
               " 取引のみ=" WS-TRANSACTION-ONLY-COUNT.
