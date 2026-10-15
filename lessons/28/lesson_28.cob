      * 第28課：記帳と残高報告を別プログラムに分けます。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON28.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT BATCH-LOG
               ASSIGN TO "batch.log"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-LOG-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD BATCH-LOG.
       01 FD-BATCH-LOG-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
      * 共有する口座・取引レコードと件数はCopybookで定義します。
       COPY "ACCOUNT-REC.CPY".
       COPY "TRANSACTION-REC.CPY".
       COPY "POST-STATUS.CPY".
       COPY "BATCH-COUNTS.CPY".
       01 WS-LOG-STATUS PIC XX VALUE SPACES.
       01 WS-LOG-OPEN PIC X VALUE "N".
       01 WS-LOG-FAILED PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-LOG-MESSAGE PIC X(100) VALUE SPACES.
       01 WS-TRANSACTION-NO PIC 9(3) VALUE ZERO.
      * CALLで共有する項目を定義し、引数の意味を呼出側と揃えます。
      * POST-STATUSには記帳結果が返ります。業務拒否は通常の判定として扱い、
      * 未知の状態コードだけを呼出契約の異常として検出します。
      * 金額PICのVは暗黙小数点で、記憶領域を占有しません。
      * 表示項目は小数点を補い、金額を読みやすくします。
      * INITIALIZEで件数を戻し、取引条件を設定してから共通段落をCALLします。
      * 残高不足の引出しは拒否され、口座残高は変わりません。
      * 全取引の処理後、共有値を使って最終残高と件数を報告します。
       01 WS-EDITED-AMOUNT PIC 9(7).99 VALUE ZERO.
       01 WS-UNKNOWN-STATUS PIC X VALUE "N".
       PROCEDURE DIVISION.
      * メイン段落が初期化と取引順を管理します。
       0000-MAIN.
           PERFORM 9000-OPEN-LOG
           IF WS-LOG-OPEN = "Y"
               IF WS-IO-ERROR = "N"
                   PERFORM 1000-INITIALIZE-BATCH
                   PERFORM 1050-RUN-TRANSACTIONS
                   CALL "REPORT-ACCOUNT28" USING BY REFERENCE
                       WS-ACCOUNT-RECORD WS-BATCH-COUNTS
                   IF WS-LOG-FAILED = "N"
                       PERFORM 9200-LOG-BATCH-END
                   END-IF
               END-IF
               CLOSE BATCH-LOG
               IF WS-LOG-STATUS NOT = "00"
                   DISPLAY "エラー=ログCLOSE 状態=" WS-LOG-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
               MOVE "N" TO WS-LOG-OPEN
           END-IF
           IF WS-IO-ERROR = "Y" OR WS-UNKNOWN-STATUS = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 口座とバッチ集計項目を初期化する。
       1000-INITIALIZE-BATCH.
           INITIALIZE WS-ACCOUNT-RECORD WS-BATCH-COUNTS
           MOVE "A000000001" TO WS-ACCOUNT-NUMBER
           MOVE "C0001001" TO WS-CUSTOMER-ID
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE.
      * 各段落で取引を準備し、共通段落からCALLして記帳結果を受け取ります。
       1100-POST-DEPOSIT.
           MOVE "A000000001" TO WS-TRANSACTION-ACCOUNT
           MOVE "D" TO WS-TRANSACTION-TYPE
           MOVE 125.50 TO WS-TRANSACTION-AMOUNT
           PERFORM 2000-CALL-POSTER.
       1200-POST-WITHDRAWAL.
           MOVE "A000000001" TO WS-TRANSACTION-ACCOUNT
           MOVE "C" TO WS-TRANSACTION-TYPE
           MOVE 25.25 TO WS-TRANSACTION-AMOUNT
           PERFORM 2000-CALL-POSTER.
       1300-POST-OVERDRAFT.
           MOVE "A000000001" TO WS-TRANSACTION-ACCOUNT
           MOVE "C" TO WS-TRANSACTION-TYPE
           MOVE 2000.00 TO WS-TRANSACTION-AMOUNT
           PERFORM 2000-CALL-POSTER.
       1400-POST-UNKNOWN-TYPE.
           MOVE "A000000001" TO WS-TRANSACTION-ACCOUNT
           MOVE "X" TO WS-TRANSACTION-TYPE
           MOVE 1.00 TO WS-TRANSACTION-AMOUNT
           PERFORM 2000-CALL-POSTER.
       1500-POST-MISSING-ACCOUNT.
           MOVE "A000000099" TO WS-TRANSACTION-ACCOUNT
           MOVE "D" TO WS-TRANSACTION-TYPE
           MOVE 1.00 TO WS-TRANSACTION-AMOUNT
           PERFORM 2000-CALL-POSTER.
      * 参照渡しの3項目は、呼出先の変更が呼出側にも反映されます。
      * 集計は呼出側が管理し、戻り値の状態コードを確認します。
       2000-CALL-POSTER.
           ADD 1 TO WS-TRANSACTION-NO
           MOVE SPACES TO WS-POST-STATUS
           MOVE WS-TRANSACTION-AMOUNT TO WS-EDITED-AMOUNT
           DISPLAY "呼出=過帳 口座=" WS-TRANSACTION-ACCOUNT
               " TYPE=" WS-TRANSACTION-TYPE
               " 金額=" WS-EDITED-AMOUNT
           CALL "POST-TRANSACTION28" USING BY REFERENCE
               WS-ACCOUNT-RECORD
               WS-TRANSACTION-RECORD
               WS-POST-STATUS
           PERFORM 2100-REPORT-RESULT
           IF WS-LOG-FAILED = "N"
               PERFORM 2200-LOG-POST-RESULT
           END-IF.
      * 呼出側が件数を集計し、未知の状態コードを検査します。
       2100-REPORT-RESULT.
           EVALUATE WS-POST-STATUS
               WHEN "POSTED"
                   ADD 1 TO WS-POSTED-COUNT
               WHEN "INSUFFICIENT"
                   ADD 1 TO WS-REJECTED-COUNT
               WHEN "BAD_TYPE"
                   ADD 1 TO WS-REJECTED-COUNT
               WHEN "NO_ACCOUNT"
                   ADD 1 TO WS-REJECTED-COUNT
               WHEN OTHER
                   MOVE "Y" TO WS-UNKNOWN-STATUS
                   ADD 1 TO WS-REJECTED-COUNT
           END-EVALUATE
           DISPLAY "呼出=戻り 状態="
               FUNCTION TRIM(WS-POST-STATUS TRAILING).
       1050-RUN-TRANSACTIONS.
           PERFORM 1100-POST-DEPOSIT
           IF WS-IO-ERROR = "N"
               PERFORM 1200-POST-WITHDRAWAL
           END-IF
           IF WS-IO-ERROR = "N"
               PERFORM 1300-POST-OVERDRAFT
           END-IF
           IF WS-IO-ERROR = "N"
               PERFORM 1400-POST-UNKNOWN-TYPE
           END-IF
           IF WS-IO-ERROR = "N"
               PERFORM 1500-POST-MISSING-ACCOUNT
           END-IF.
       9000-OPEN-LOG.
           OPEN OUTPUT BATCH-LOG
           IF WS-LOG-STATUS = "00"
               MOVE "Y" TO WS-LOG-OPEN
               MOVE "EVENT=BATCH_START ID=TRAINING-001"
                   TO WS-LOG-MESSAGE
               PERFORM 9100-WRITE-LOG
           ELSE
               DISPLAY "エラー=ログOPEN 状態=" WS-LOG-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       9100-WRITE-LOG.
           IF WS-LOG-FAILED = "N"
               MOVE WS-LOG-MESSAGE TO FD-BATCH-LOG-RECORD
               WRITE FD-BATCH-LOG-RECORD
               IF WS-LOG-STATUS NOT = "00"
                   DISPLAY "エラー=ログWRITE 状態=" WS-LOG-STATUS
                   MOVE "Y" TO WS-LOG-FAILED
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
       9200-LOG-BATCH-END.
           MOVE SPACES TO WS-LOG-MESSAGE
           STRING "EVENT=BATCH_END POSTED=" DELIMITED BY SIZE
               WS-POSTED-COUNT DELIMITED BY SIZE
               " REJECTED=" DELIMITED BY SIZE
               WS-REJECTED-COUNT DELIMITED BY SIZE
               " IO_ERROR=" DELIMITED BY SIZE
               WS-IO-ERROR DELIMITED BY SIZE
               INTO WS-LOG-MESSAGE
           END-STRING
           PERFORM 9100-WRITE-LOG.
       2200-LOG-POST-RESULT.
           MOVE SPACES TO WS-LOG-MESSAGE
           STRING "EVENT=TRANSACTION NO=" DELIMITED BY SIZE
               WS-TRANSACTION-NO DELIMITED BY SIZE
               " ACCOUNT=" DELIMITED BY SIZE
               WS-TRANSACTION-ACCOUNT DELIMITED BY SIZE
               " TYPE=" DELIMITED BY SIZE
               WS-TRANSACTION-TYPE DELIMITED BY SIZE
               " STATUS=" DELIMITED BY SIZE
               WS-POST-STATUS DELIMITED BY SPACE
               INTO WS-LOG-MESSAGE
           END-STRING
           PERFORM 9100-WRITE-LOG.
