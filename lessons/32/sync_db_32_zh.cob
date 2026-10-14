       IDENTIFICATION DIVISION.
       PROGRAM-ID. SYNCDB32.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
      * 中文：调用方传入最终账户状态和共享批次计数。
       FILE-CONTROL.
           SELECT REPORT-FILE ASSIGN TO "account-report.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REPORT-STATUS.
           SELECT LOG-FILE ASSIGN TO "batch.log"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-LOG-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD REPORT-FILE.
       01 REPORT-RECORD PIC X(80).
       FD LOG-FILE.
       01 LOG-RECORD PIC X(100).
      * 中文：报表重新创建，批次日志以追加方式打开；分别检查状态。
      * 中文：打开标志记录可在部分失败后安全关闭的资源。
      * 中文：主机变量隔离数据库结果与调用方账户表存储。
       WORKING-STORAGE SECTION.
       01 WS-REPORT-STATUS PIC XX.
       01 WS-LOG-STATUS PIC XX.
       01 WS-REPORT-OPEN PIC X VALUE "N".
       01 WS-LOG-OPEN PIC X VALUE "N".
       01 WS-DB-OPEN PIC X VALUE "N".
       01 WS-DATASRC PIC X(255).
       01 WS-DBUSER PIC X(64).
       01 WS-DBPASS PIC X(64).
       01 WS-DB-CUSTOMER PIC X(8).
       01 WS-DB-BALANCE PIC S9(7)V99 COMP-3.
       01 WS-EDITED-BALANCE PIC 9(7).99.
       01 WS-SYNC-STATUS PIC X(10).
       01 WS-SYNC-ACCOUNT PIC X(10).
       01 WS-SYNC-CUSTOMER PIC X(8).
       01 WS-SYNC-BALANCE PIC S9(7)V99 COMP-3.
       01 WS-OUTPUT-LINE PIC X(80).
       01 WS-LOG-LINE PIC X(100).
       01 WS-INDEX PIC 99.
       EXEC SQL INCLUDE SQLCA END-EXEC.
      * 中文：SYNC-STATUS 保存结果；OUTPUT-LINE 供报表和日志共用。
       LINKAGE SECTION.
      * 中文：LINKAGE 必须与 BATCH-INTERFACE.CPY 一致以供引用传递。
       01 WS-ACCOUNT-TABLE.
          05 WS-ACCOUNT-ROW OCCURS 20 TIMES.
             10 WS-ACCOUNT-NO PIC X(10).
             10 WS-CUSTOMER-ID PIC X(8).
             10 WS-ACCOUNT-BALANCE PIC S9(7)V99 COMP-3.
       01 WS-BATCH-COUNTS.
          05 WS-ACCOUNT-COUNT PIC 99.
          05 WS-TRANSACTION-COUNT PIC 999.
          05 WS-POSTED-COUNT PIC 999.
          05 WS-REJECTED-COUNT PIC 999.
          05 WS-UPDATED-COUNT PIC 999.
          05 WS-UNCHANGED-COUNT PIC 999.
          05 WS-INSERTED-COUNT PIC 999.
          05 WS-FAILED PIC X.
          05 WS-INTERFACE-RESERVED PIC X.
      * 中文：GixSQL 会注释最后一个链接字段；保留此备用字节。
       PROCEDURE DIVISION USING WS-ACCOUNT-TABLE WS-BATCH-COUNTS.
      * 中文：先打开输出文件；无错误时才连接并同步数据库。
      * 中文：关闭已打开文件，并在返回前检查各自状态。
       MAIN-SYNC.
           OPEN OUTPUT REPORT-FILE
           IF WS-REPORT-STATUS = "00"
               MOVE "Y" TO WS-REPORT-OPEN
           ELSE
               DISPLAY "ERROR=OPEN REPORT STATUS="
                       WS-REPORT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF
           OPEN EXTEND LOG-FILE
           IF WS-LOG-STATUS = "00"
               MOVE "Y" TO WS-LOG-OPEN
           ELSE
               DISPLAY "ERROR=OPEN LOG STATUS=" WS-LOG-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF
           IF WS-FAILED NOT = "Y"
               PERFORM 1000-CONNECT-DATABASE
           END-IF
           IF WS-DB-OPEN = "Y" AND WS-FAILED NOT = "Y"
               PERFORM 2000-SYNC-TABLE
           END-IF
           IF WS-LOG-OPEN = "Y"
               MOVE "EVENT=SYNC_COMPLETE" TO WS-LOG-LINE
               PERFORM 8100-WRITE-LOG
               CLOSE LOG-FILE
               IF WS-LOG-STATUS NOT = "00"
                   DISPLAY "ERROR=CLOSE LOG STATUS=" WS-LOG-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-REPORT-OPEN = "Y"
               CLOSE REPORT-FILE
               IF WS-REPORT-STATUS NOT = "00"
                   DISPLAY "ERROR=CLOSE REPORT STATUS="
                           WS-REPORT-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-DB-OPEN = "Y"
               PERFORM 9000-DISCONNECT
           ELSE
               IF WS-FAILED = "Y"
                   STOP RUN RETURNING 1
               END-IF
           END-IF
           GOBACK.
      * 中文：从环境读取连接值，不在源代码中写入凭据字面值。
      * 中文：SQLCODE 为零表示连接成功；其他值均标记系统故障。
       1000-CONNECT-DATABASE.
           DISPLAY "DATASRC" UPON ENVIRONMENT-NAME
           ACCEPT WS-DATASRC FROM ENVIRONMENT-VALUE
           DISPLAY "DATASRC_USR" UPON ENVIRONMENT-NAME
           ACCEPT WS-DBUSER FROM ENVIRONMENT-VALUE
           DISPLAY "DATASRC_PWD" UPON ENVIRONMENT-NAME
           ACCEPT WS-DBPASS FROM ENVIRONMENT-VALUE
           EXEC SQL
               CONNECT TO :WS-DATASRC USER :WS-DBUSER
                           USING :WS-DBPASS
           END-EXEC
           IF SQLCODE = 0
               MOVE "Y" TO WS-DB-OPEN
               DISPLAY "CONNECT=OK"
               MOVE "EVENT=DB_CONNECTED" TO WS-LOG-LINE
               PERFORM 8100-WRITE-LOG
           ELSE
               DISPLAY "CONNECT=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 中文：扫描声明的账户行数，完成或发生故障时停止。
       2000-SYNC-TABLE.
           PERFORM VARYING WS-INDEX FROM 1 BY 1
             UNTIL WS-INDEX > WS-ACCOUNT-COUNT OR WS-FAILED = "Y"
               PERFORM 2100-SYNC-ACCOUNT
           END-PERFORM.
      * 中文：将一行账户复制到主机变量，并在 SELECT 前清空结果字段。
      * 中文：按主键将每个账户归类为未变化、已更新或已插入。
       2100-SYNC-ACCOUNT.
           MOVE WS-ACCOUNT-NO(WS-INDEX) TO WS-SYNC-ACCOUNT
           MOVE WS-CUSTOMER-ID(WS-INDEX) TO WS-SYNC-CUSTOMER
           MOVE WS-ACCOUNT-BALANCE(WS-INDEX) TO WS-SYNC-BALANCE
           MOVE SPACES TO WS-DB-CUSTOMER
           MOVE ZERO TO WS-DB-BALANCE
           EXEC SQL
               SELECT CUSTOMER_ID, BALANCE
                 INTO :WS-DB-CUSTOMER, :WS-DB-BALANCE
                 FROM ACCOUNT_SNAPSHOT
                WHERE ACCOUNT_NO = :WS-SYNC-ACCOUNT
           END-EXEC
           EVALUATE SQLCODE
             WHEN 0
               IF WS-DB-CUSTOMER = WS-SYNC-CUSTOMER AND
                  WS-DB-BALANCE = WS-SYNC-BALANCE
                   MOVE "UNCHANGED" TO WS-SYNC-STATUS
                   ADD 1 TO WS-UNCHANGED-COUNT
               ELSE
                   PERFORM 2200-UPDATE-ACCOUNT
               END-IF
             WHEN 100
               PERFORM 2300-INSERT-ACCOUNT
             WHEN OTHER
               DISPLAY "ERROR=SYNC LOOKUP SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-EVALUATE
           IF WS-FAILED NOT = "Y"
               PERFORM 2400-REPORT-SYNC
           END-IF.
      * 中文：SQLCODE 100 转入 INSERT；其他查询错误停止处理。
      * 中文：数据库操作成功后才报告对应决定。
       2200-UPDATE-ACCOUNT.
           EXEC SQL
               UPDATE ACCOUNT_SNAPSHOT
                  SET CUSTOMER_ID = :WS-SYNC-CUSTOMER,
                      BALANCE = :WS-SYNC-BALANCE
                WHERE ACCOUNT_NO = :WS-SYNC-ACCOUNT
           END-EXEC
           IF SQLCODE = 0
               MOVE "UPDATED" TO WS-SYNC-STATUS
               ADD 1 TO WS-UPDATED-COUNT
           ELSE
               DISPLAY "ERROR=UPDATE SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 中文：按账户键更新客户标识和计算后的余额。
      * 中文：仅统计成功更新；SQL 错误会设置共享失败标志。
       2300-INSERT-ACCOUNT.
           EXEC SQL
               INSERT INTO ACCOUNT_SNAPSHOT
                   (ACCOUNT_NO, CUSTOMER_ID, BALANCE)
               VALUES (:WS-SYNC-ACCOUNT, :WS-SYNC-CUSTOMER,
                       :WS-SYNC-BALANCE)
           END-EXEC
           IF SQLCODE = 0
               MOVE "INSERTED" TO WS-SYNC-STATUS
               ADD 1 TO WS-INSERTED-COUNT
           ELSE
               DISPLAY "ERROR=INSERT SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 中文：从调用方计算出的账户值插入缺失的快照记录。
      * 中文：仅统计成功插入；数据库错误会使批次失败。
       2400-REPORT-SYNC.
           MOVE WS-ACCOUNT-BALANCE(WS-INDEX)
             TO WS-EDITED-BALANCE
           MOVE SPACES TO WS-OUTPUT-LINE
           STRING "SYNC " FUNCTION TRIM(WS-SYNC-STATUS)
                  " ACCOUNT=" WS-ACCOUNT-NO(WS-INDEX)
                  " BALANCE=" WS-EDITED-BALANCE
               INTO WS-OUTPUT-LINE
           END-STRING
           DISPLAY FUNCTION TRIM(WS-OUTPUT-LINE)
           WRITE REPORT-RECORD FROM WS-OUTPUT-LINE
           IF WS-REPORT-STATUS NOT = "00"
               DISPLAY "ERROR=WRITE REPORT STATUS="
                       WS-REPORT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF
           MOVE WS-OUTPUT-LINE TO WS-LOG-LINE
           PERFORM 8100-WRITE-LOG.
      * 中文：格式化处理结果、账户键和最终余额以供显示。
      * 中文：将决定写入报表和日志；任一写入失败都会终止批次。
       8100-WRITE-LOG.
           MOVE WS-LOG-LINE TO LOG-RECORD
           WRITE LOG-RECORD
           IF WS-LOG-STATUS NOT = "00"
               DISPLAY "ERROR=WRITE LOG STATUS=" WS-LOG-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 中文：集中写日志，让每个事件共用同一状态检查。
      * 中文：同步后重置连接，并向上报告断开错误。
       9000-DISCONNECT.
           EXEC SQL CONNECT RESET END-EXEC
           IF SQLCODE = 0
               DISPLAY "DISCONNECT=OK"
           ELSE
               DISPLAY "DISCONNECT=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF
           IF WS-FAILED = "Y"
               STOP RUN RETURNING 1
           END-IF.
      * 中文：GixSQL 会附加其生成的游标尾部代码。
