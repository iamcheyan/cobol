      * 中文：第28课：构建一个小型多程序记账项目。
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
      * 中文：共享记录和计数器在 Copybook 中声明。
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
      * 中文：账户字段由两个被调用程序共同使用。
      * 中文：交易布局构成 CALL 的输入契约。
      * 中文：POST-STATUS 保存被调用程序返回的判定结果。
      * 中文：计数器与报表程序共享。
      * 中文：V 表示隐含小数点，不占用存储字符。
      * 中文：编辑字段会添加小数点以供 DISPLAY 显示。
      * 中文：INITIALIZE 会重置每个批次的计数字段。
      * 中文：每种情形都在 CALL 前设置账户、类型和金额。
      * 中文：被拒绝的取款不会改变账户余额。
      * 中文：未知状态会触发防护，以维护调用方与模块间的契约。
      * 中文：所有调用完成后，报表模块会读取最终值。
       01 WS-EDITED-AMOUNT PIC 9(7).99 VALUE ZERO.
       01 WS-UNKNOWN-STATUS PIC X VALUE "N".
       PROCEDURE DIVISION.
      * 中文：主程序负责初始化和交易顺序。
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
      * 中文：初始化该账户和批次汇总字段。
       1000-INITIALIZE-BATCH.
           INITIALIZE WS-ACCOUNT-RECORD WS-BATCH-COUNTS
           MOVE "A000000001" TO WS-ACCOUNT-NUMBER
           MOVE "C0001001" TO WS-CUSTOMER-ID
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE.
      * 中文：每个段落准备一笔交易，并共用同一个 CALL 路径。
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
      * 中文：调用方通过引用传递三个共享字段。
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
      * 中文：调用方负责汇总，并检查模块返回的未知结果。
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
