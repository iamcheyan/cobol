       IDENTIFICATION DIVISION.
       PROGRAM-ID. SYNCDB32.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
      * 调用方传入最终账户状态和共享批次计数。
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
      * 报表以新文件创建，批次日志以追加方式打开，两者状态分别检查。
      * 记录打开标志，发生部分失败时只关闭已成功打开的资源。
      * 数据库查询结果放入主机变量，与调用方的账户表分开处理。
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
      * SYNC-STATUS保存判定结果；OUTPUT-LINE供报表和日志共用。
       LINKAGE SECTION.
      * 按引用传递时，LINKAGE布局必须与BATCH-INTERFACE.CPY一致。
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
      * GixSQL会注释最后一个LINKAGE字段，因此要保留备用字节。
       PROCEDURE DIVISION USING WS-ACCOUNT-TABLE WS-BATCH-COUNTS.
      * 先打开输出文件，成功后才连接数据库并执行同步。
      * 退出前关闭已打开的资源，检查操作状态后再返回调用方。
       MAIN-SYNC.
           OPEN OUTPUT REPORT-FILE
           IF WS-REPORT-STATUS = "00"
               MOVE "Y" TO WS-REPORT-OPEN
           ELSE
               DISPLAY "错误=打开报告 状态="
                       WS-REPORT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF
           OPEN EXTEND LOG-FILE
           IF WS-LOG-STATUS = "00"
               MOVE "Y" TO WS-LOG-OPEN
           ELSE
               DISPLAY "错误=打开日志 状态=" WS-LOG-STATUS
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
                   DISPLAY "错误=关闭日志 状态=" WS-LOG-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-REPORT-OPEN = "Y"
               CLOSE REPORT-FILE
               IF WS-REPORT-STATUS NOT = "00"
                   DISPLAY "错误=关闭报告 状态="
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
      * 连接信息从环境变量读取，不把凭据写进源码。
      * SQLCODE为零表示连接成功；其他状态按系统故障处理。
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
               DISPLAY "连接=成功"
               MOVE "EVENT=DB_CONNECTED" TO WS-LOG-LINE
               PERFORM 8100-WRITE-LOG
           ELSE
               DISPLAY "连接=错误 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 扫描声明的账户行数，完成或发生故障时停止。
       2000-SYNC-TABLE.
           PERFORM VARYING WS-INDEX FROM 1 BY 1
             UNTIL WS-INDEX > WS-ACCOUNT-COUNT OR WS-FAILED = "Y"
               PERFORM 2100-SYNC-ACCOUNT
           END-PERFORM.
      * 将当前账户复制到主机变量，并在SELECT前清空结果字段。
      * 按主键查询后，将账户归为未变化、已更新或需插入。
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
               DISPLAY "错误=同步查询 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-EVALUATE
           IF WS-FAILED NOT = "Y"
               PERFORM 2400-REPORT-SYNC
           END-IF.
      * SQLCODE 100 转入 INSERT；其他查询错误停止处理。
      * 数据库操作成功后才报告对应决定。
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
               DISPLAY "错误=更新 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 按账户键更新客户标识和计算后的余额。
      * 仅统计成功更新；SQL 错误会设置共享失败标志。
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
               DISPLAY "错误=插入 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 从调用方计算出的账户值插入缺失的快照记录。
      * 仅统计成功插入；数据库错误会使批次失败。
       2400-REPORT-SYNC.
           MOVE WS-ACCOUNT-BALANCE(WS-INDEX)
             TO WS-EDITED-BALANCE
           MOVE SPACES TO WS-OUTPUT-LINE
           STRING "同步 " FUNCTION TRIM(WS-SYNC-STATUS)
                  " ACCOUNT=" WS-ACCOUNT-NO(WS-INDEX)
                  " 余额=" WS-EDITED-BALANCE
               INTO WS-OUTPUT-LINE
           END-STRING
           DISPLAY FUNCTION TRIM(WS-OUTPUT-LINE)
           WRITE REPORT-RECORD FROM WS-OUTPUT-LINE
           IF WS-REPORT-STATUS NOT = "00"
               DISPLAY "错误=写入报告 状态="
                       WS-REPORT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF
           MOVE WS-OUTPUT-LINE TO WS-LOG-LINE
           PERFORM 8100-WRITE-LOG.
      * 格式化处理结果、账户键和最终余额以供显示。
      * 将判定写入报表和日志；任一写入失败都作为批次故障处理。
       8100-WRITE-LOG.
           MOVE WS-LOG-LINE TO LOG-RECORD
           WRITE LOG-RECORD
           IF WS-LOG-STATUS NOT = "00"
               DISPLAY "错误=写入日志 状态=" WS-LOG-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 集中写日志，让每个事件共用同一状态检查。
      * 同步后重置连接，并向上报告断开错误。
       9000-DISCONNECT.
           EXEC SQL CONNECT RESET END-EXEC
           IF SQLCODE = 0
               DISPLAY "断开=成功"
           ELSE
               DISPLAY "断开=错误 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF
           IF WS-FAILED = "Y"
               STOP RUN RETURNING 1
           END-IF.
      * GixSQL会生成游标关闭代码，无须重复编写。
