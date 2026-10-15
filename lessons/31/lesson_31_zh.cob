      *程序标识以及运行期间使用的文件和数据库资源。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON31.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
      *指定行顺序文件，并保留每项文件操作的状态码。
       FILE-CONTROL.
           SELECT SNAPSHOT-FILE ASSIGN TO "snapshot.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
           SELECT DIFFERENCE-FILE ASSIGN TO "differences.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUT-STATUS.
      *定长记录使输入字段的位置和布局明确。
       DATA DIVISION.
       FILE SECTION.
       FD SNAPSHOT-FILE.
       01 SNAPSHOT-RECORD PIC X(27).
       FD DIFFERENCE-FILE.
       01 DIFFERENCE-RECORD PIC X(80).
      *工作字段分别保存原始文本、数值和运行状态。
      *压缩十进制保证金额精度；计数器汇总
      *各类对账结果。
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX.
       01 WS-OUT-STATUS PIC XX.
       01 WS-DATASRC PIC X(255).
       01 WS-DBUSER PIC X(64).
       01 WS-DBPASS PIC X(64).
       01 WS-ACCOUNT PIC X(10).
       01 WS-CUSTOMER PIC X(8).
       01 WS-BALANCE-TEXT PIC X(9).
       01 WS-DB-CUSTOMER PIC X(8).
       01 WS-DB-BALANCE PIC S9(7)V99 COMP-3.
       01 WS-BALANCE PIC S9(7)V99 COMP-3.
       01 WS-EDITED-BALANCE PIC 9(5).99.
       01 WS-STATUS PIC X(10).
       01 WS-ROW-COUNT PIC 9(3) VALUE ZERO.
       01 WS-MATCH-COUNT PIC 9(3) VALUE ZERO.
       01 WS-CHANGE-COUNT PIC 9(3) VALUE ZERO.
       01 WS-FILE-ONLY-COUNT PIC 9(3) VALUE ZERO.
       01 WS-DB-OPEN PIC X VALUE "N".
       01 WS-INPUT-OPEN PIC X VALUE "N".
       01 WS-OUTPUT-OPEN PIC X VALUE "N".
       01 WS-EOF PIC X VALUE "N".
       01 WS-FAILED PIC X VALUE "N".
       EXEC SQL INCLUDE SQLCA END-EXEC.
      *按依赖关系顺序执行各阶段；发生故障后跳过后续工作。
       PROCEDURE DIVISION.
      *先打开文件，确认成功后连接数据库，再开始对账。
      *仅关闭标记为已打开的资源；报告批次总数后
      *再断开数据库连接。
       MAIN-PROCEDURE.
           PERFORM 1000-OPEN-INPUT
           IF WS-FAILED NOT = "Y"
               PERFORM 1100-OPEN-OUTPUT
           END-IF
           IF WS-FAILED NOT = "Y"
               PERFORM 1200-CONNECT-DATABASE
           END-IF
           IF WS-DB-OPEN = "Y"
               PERFORM 2000-READ-SNAPSHOT
           END-IF
           IF WS-OUTPUT-OPEN = "Y"
               CLOSE DIFFERENCE-FILE
               IF WS-OUT-STATUS NOT = "00"
                   DISPLAY "错误=关闭输出 状态="
                           WS-OUT-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-INPUT-OPEN = "Y"
               CLOSE SNAPSHOT-FILE
               IF WS-FILE-STATUS NOT = "00"
                   DISPLAY "错误=关闭输入 状态="
                           WS-FILE-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           DISPLAY "汇总 行数=" WS-ROW-COUNT
                   " 匹配=" WS-MATCH-COUNT
                   " 已变更=" WS-CHANGE-COUNT
                   " 仅文件=" WS-FILE-ONLY-COUNT
           IF WS-DB-OPEN = "Y"
               PERFORM 9000-DISCONNECT-DATABASE
           ELSE
               IF WS-FAILED = "Y"
                   STOP RUN RETURNING 1
               END-IF
           END-IF
           GOBACK.
      *处理前先打开快照文件，并检查文件状态码。
       1000-OPEN-INPUT.
           OPEN INPUT SNAPSHOT-FILE
           IF WS-FILE-STATUS = "00"
               MOVE "Y" TO WS-INPUT-OPEN
           ELSE
               DISPLAY "错误=打开输入 状态=" WS-FILE-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
      *创建差异报告；若无法打开输出文件，就停止处理。
       1100-OPEN-OUTPUT.
           OPEN OUTPUT DIFFERENCE-FILE
           IF WS-OUT-STATUS = "00"
               MOVE "Y" TO WS-OUTPUT-OPEN
           ELSE
               DISPLAY "错误=打开输出 状态=" WS-OUT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
      *从DATASRC、DATASRC_USR以及
      *DATASRC_PWD环境变量读取连接参数。
      *嵌入式SQL通过SQLSTATE报告故障；不得显示
       1200-CONNECT-DATABASE.
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
           ELSE
               DISPLAY "连接=错误 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      *输入的数据库凭据。
       2000-READ-SNAPSHOT.
           PERFORM UNTIL WS-EOF = "Y" OR WS-FAILED = "Y"
               READ SNAPSHOT-FILE
                   AT END
                       MOVE "Y" TO WS-EOF
                   NOT AT END
                       IF WS-FILE-STATUS = "00"
                           PERFORM 3000-RECONCILE-ROW
                       ELSE
                           DISPLAY "错误=读取输入 状态="
                                   WS-FILE-STATUS
                           MOVE "Y" TO WS-FAILED
                       END-IF
               END-READ
           END-PERFORM.
      *逐条读取27字符的快照记录，直到EOF或发生故障。
      *按位置拆分账号(10)、客户号(8)和金额文本(9)。
      *NUMVAL转换前先验证余额均为数字；再除以
       3000-RECONCILE-ROW.
           ADD 1 TO WS-ROW-COUNT
           MOVE SNAPSHOT-RECORD(1:10) TO WS-ACCOUNT
           MOVE SNAPSHOT-RECORD(11:8) TO WS-CUSTOMER
           MOVE SNAPSHOT-RECORD(19:9) TO WS-BALANCE-TEXT
           IF WS-BALANCE-TEXT IS NUMERIC
               COMPUTE WS-BALANCE =
                   FUNCTION NUMVAL(WS-BALANCE-TEXT) / 100
               PERFORM 3100-LOOKUP-ACCOUNT
           ELSE
               DISPLAY "错误=余额无效 账户=" WS-ACCOUNT
               MOVE "Y" TO WS-FAILED
           END-IF.
      *100，将分转换为货币单位。
      *使用账号主变量查询数据库中对应的记录。
      *SQLCODE为0表示取得记录，可比较客户号和余额；
      *SQLCODE为100表示找不到该账户。
      *其他SQL错误都会停止处理，避免保存错误的对账结果。
       3100-LOOKUP-ACCOUNT.
           MOVE SPACES TO WS-DB-CUSTOMER
           MOVE ZERO TO WS-DB-BALANCE
           EXEC SQL
               SELECT CUSTOMER_ID, BALANCE
                 INTO :WS-DB-CUSTOMER, :WS-DB-BALANCE
                 FROM ACCOUNT_SNAPSHOT
                WHERE ACCOUNT_NO = :WS-ACCOUNT
           END-EXEC
           EVALUATE SQLCODE
             WHEN 0
               IF WS-CUSTOMER = WS-DB-CUSTOMER AND
                  WS-BALANCE = WS-DB-BALANCE
                   MOVE "MATCH" TO WS-STATUS
                   ADD 1 TO WS-MATCH-COUNT
               ELSE
                   MOVE "CHANGED" TO WS-STATUS
                   ADD 1 TO WS-CHANGE-COUNT
               END-IF
             WHEN 100
               MOVE "FILE_ONLY" TO WS-STATUS
               ADD 1 TO WS-FILE-ONLY-COUNT
             WHEN OTHER
               DISPLAY "错误=查询 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-EVALUATE
           IF WS-FAILED NOT = "Y"
               PERFORM 4000-WRITE-RESULT
           END-IF.
      *先将每条已分类的快照记录写入RECON_RESULT。
      *仅将非MATCH记录写入differences.txt，供后续重点复核。
      *STRING用于组装定长报告；检查输出状态以
      *发现并报告文件写入故障。
       4000-WRITE-RESULT.
           EXEC SQL
               INSERT INTO RECON_RESULT
                   (ACCOUNT_NO, FILE_STATUS, FILE_CUSTOMER,
                    FILE_BALANCE)
               VALUES (:WS-ACCOUNT, :WS-STATUS, :WS-CUSTOMER,
                       :WS-BALANCE)
           END-EXEC
           IF SQLCODE NOT = 0
               DISPLAY "错误=插入 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           ELSE
               MOVE WS-BALANCE TO WS-EDITED-BALANCE
               MOVE SPACES TO DIFFERENCE-RECORD
               STRING FUNCTION TRIM(WS-STATUS) " ACCOUNT="
                      WS-ACCOUNT " 客户=" WS-CUSTOMER
                      " BALANCE=" WS-EDITED-BALANCE
                   INTO DIFFERENCE-RECORD
               END-STRING
               DISPLAY FUNCTION TRIM(WS-STATUS)
                       " ACCOUNT=" WS-ACCOUNT " 客户="
                       WS-CUSTOMER " BALANCE=" WS-EDITED-BALANCE
               IF WS-STATUS NOT = "MATCH"
                   WRITE DIFFERENCE-RECORD
                   IF WS-OUT-STATUS NOT = "00"
                       DISPLAY "错误=写入输出 状态="
                               WS-OUT-STATUS
                       MOVE "Y" TO WS-FAILED
                   END-IF
               END-IF
           END-IF.
      *完成文件清理后重置SQL连接，并报告断开故障。
       9000-DISCONNECT-DATABASE.
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
