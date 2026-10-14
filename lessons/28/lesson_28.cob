      * 日本語：第28課：小規模な複数プログラム構成の記帳プロジェクトを作る。
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
      * 日本語：共有レコードとカウンターを Copybook で宣言する。
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
      * 日本語：口座フィールドは呼び出される2つのプログラムで共有する。
      * 日本語：取引レイアウトが CALL の入力契約となる。
      * 日本語：POST-STATUS は呼び出されたプログラムが返す判定結果を保持する。
      * 日本語：カウンターをレポートプログラムと共有する。
      * 日本語：V は暗黙の小数点を表し、記憶文字を使用しない。
      * 日本語：編集項目は DISPLAY 用に小数点を付ける。
      * 日本語：INITIALIZE は各バッチのカウント項目をリセットする。
      * 日本語：各ケースでは CALL の前に口座、種別、金額を設定する。
      * 日本語：拒否された引き出しでは口座残高は変わらない。
      * 日本語：未知のステータスを検出して、呼び出し側とモジュール間の契約を守る。
      * 日本語：すべての呼び出し後に、レポートモジュールが最終値を参照する。
       01 WS-EDITED-AMOUNT PIC 9(7).99 VALUE ZERO.
       01 WS-UNKNOWN-STATUS PIC X VALUE "N".
       PROCEDURE DIVISION.
      * 日本語：メインプログラムが初期化と取引の順序を管理する。
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
                   DISPLAY "ERROR=CLOSE_LOG STATUS=" WS-LOG-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
               MOVE "N" TO WS-LOG-OPEN
           END-IF
           IF WS-IO-ERROR = "Y" OR WS-UNKNOWN-STATUS = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 日本語：口座とバッチ集計項目を初期化する。
       1000-INITIALIZE-BATCH.
           INITIALIZE WS-ACCOUNT-RECORD WS-BATCH-COUNTS
           MOVE "A000000001" TO WS-ACCOUNT-NUMBER
           MOVE "C0001001" TO WS-CUSTOMER-ID
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE.
      * 日本語：各段落で取引を準備し、共通の CALL 経路を使う。
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
      * 日本語：呼び出し側は共有フィールド3つを参照渡しする。
       2000-CALL-POSTER.
           ADD 1 TO WS-TRANSACTION-NO
           MOVE SPACES TO WS-POST-STATUS
           MOVE WS-TRANSACTION-AMOUNT TO WS-EDITED-AMOUNT
           DISPLAY "CALL=POST ACCOUNT=" WS-TRANSACTION-ACCOUNT
               " TYPE=" WS-TRANSACTION-TYPE
               " AMOUNT=" WS-EDITED-AMOUNT
           CALL "POST-TRANSACTION28" USING BY REFERENCE
               WS-ACCOUNT-RECORD
               WS-TRANSACTION-RECORD
               WS-POST-STATUS
           PERFORM 2100-REPORT-RESULT
           IF WS-LOG-FAILED = "N"
               PERFORM 2200-LOG-POST-RESULT
           END-IF.
      * 日本語：呼び出し側が集計を管理し、モジュールの未知の結果を確認する。
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
           DISPLAY "CALL=RETURN STATUS="
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
               DISPLAY "ERROR=OPEN_LOG STATUS=" WS-LOG-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       9100-WRITE-LOG.
           IF WS-LOG-FAILED = "N"
               MOVE WS-LOG-MESSAGE TO FD-BATCH-LOG-RECORD
               WRITE FD-BATCH-LOG-RECORD
               IF WS-LOG-STATUS NOT = "00"
                   DISPLAY "ERROR=WRITE_LOG STATUS=" WS-LOG-STATUS
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
