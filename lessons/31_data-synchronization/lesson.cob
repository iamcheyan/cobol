      * 输入契约：快照每行 27 字节＝账号 10＋客户号 8＋金额分 9，按账号升序且键唯一。
      * 金额为隐含小数的“分”；非数字金额按系统故障中止批次，不作为业务拒绝。
      * 本课只做单向核对：数据库独有的账户不参与比对，也不写入 RECON_RESULT。
      * 结果表以账号为主键，重复文件键或重跑会触发主键错误并中止批次。
      * 中止不撤销已提交的结果行：本课没有事务，也没有回滚。
      * 输出标签沿用仓库既有日文约定，中文含义见 README。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON31.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SNAPSHOT-FILE ASSIGN TO "snapshot.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
           SELECT DIFFERENCE-FILE ASSIGN TO "differences.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUT-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD SNAPSHOT-FILE.
       01 SNAPSHOT-RECORD PIC X(27).
      * 差异文件每次运行由 OPEN OUTPUT 截断重建；只有非 MATCH 分类写入其中。
       FD DIFFERENCE-FILE.
       01 DIFFERENCE-RECORD PIC X(80).
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
      * WS-EDITED-BALANCE 只负责报告里的定点显示（9(5).99），不参与比较。
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
       PROCEDURE DIVISION.
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
                   DISPLAY "エラー=出力クローズ 状態="
                           WS-OUT-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-INPUT-OPEN = "Y"
               CLOSE SNAPSHOT-FILE
               IF WS-FILE-STATUS NOT = "00"
                   DISPLAY "エラー=入力クローズ 状態="
                           WS-FILE-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           DISPLAY "集計 行数=" WS-ROW-COUNT
                   " 一致=" WS-MATCH-COUNT
                   " 変更=" WS-CHANGE-COUNT
                   " ファイルのみ=" WS-FILE-ONLY-COUNT
           IF WS-DB-OPEN = "Y"
               PERFORM 9000-DISCONNECT-DATABASE
           ELSE
               IF WS-FAILED = "Y"
                   STOP RUN RETURNING 1
               END-IF
           END-IF
           GOBACK.
       1000-OPEN-INPUT.
           OPEN INPUT SNAPSHOT-FILE
           IF WS-FILE-STATUS = "00"
               MOVE "Y" TO WS-INPUT-OPEN
           ELSE
               DISPLAY "エラー=入力OPEN 状態=" WS-FILE-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
       1100-OPEN-OUTPUT.
           OPEN OUTPUT DIFFERENCE-FILE
           IF WS-OUT-STATUS = "00"
               MOVE "Y" TO WS-OUTPUT-OPEN
           ELSE
               DISPLAY "エラー=出力OPEN 状態=" WS-OUT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
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
               DISPLAY "接続=成功"
           ELSE
               DISPLAY "接続=エラー SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
       2000-READ-SNAPSHOT.
           PERFORM UNTIL WS-EOF = "Y" OR WS-FAILED = "Y"
               READ SNAPSHOT-FILE
                   AT END
                       MOVE "Y" TO WS-EOF
                   NOT AT END
                       IF WS-FILE-STATUS = "00"
                           PERFORM 3000-RECONCILE-ROW
                       ELSE
                           DISPLAY "エラー=入力読取 状態="
                                   WS-FILE-STATUS
                           MOVE "Y" TO WS-FAILED
                       END-IF
               END-READ
           END-PERFORM.
       3000-RECONCILE-ROW.
           ADD 1 TO WS-ROW-COUNT
           MOVE SNAPSHOT-RECORD(1:10) TO WS-ACCOUNT
           MOVE SNAPSHOT-RECORD(11:8) TO WS-CUSTOMER
           MOVE SNAPSHOT-RECORD(19:9) TO WS-BALANCE-TEXT
      * 金额域必须是数字；文件单位是分，数据库 BALANCE 单位是元，比较前先换算。
           IF WS-BALANCE-TEXT IS NUMERIC
               COMPUTE WS-BALANCE =
                   FUNCTION NUMVAL(WS-BALANCE-TEXT) / 100
               PERFORM 3100-LOOKUP-ACCOUNT
           ELSE
               DISPLAY "エラー=不正残高 口座=" WS-ACCOUNT
               MOVE "Y" TO WS-FAILED
           END-IF.
       3100-LOOKUP-ACCOUNT.
      * SQLCODE 100 时驱动不改写宿主变量，故先清空接收项。
           MOVE SPACES TO WS-DB-CUSTOMER
           MOVE ZERO TO WS-DB-BALANCE
           EXEC SQL
               SELECT CUSTOMER_ID, BALANCE
                 INTO :WS-DB-CUSTOMER, :WS-DB-BALANCE
                 FROM ACCOUNT_SNAPSHOT
                WHERE ACCOUNT_NO = :WS-ACCOUNT
           END-EXEC
      * 客户号与金额都相等才算 MATCH，任一不同即 CHANGED（不细分差异种类）。
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
               DISPLAY "エラー=検索 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-EVALUATE
           IF WS-FAILED NOT = "Y"
               PERFORM 4000-WRITE-RESULT
           END-IF.
       4000-WRITE-RESULT.
      * 每个文件键写一行结果；INSERT 失败（如重复键）时本行不落库，
      * 但更早的行已经提交，差异文件也可能只写了一半。
           EXEC SQL
               INSERT INTO RECON_RESULT
                   (ACCOUNT_NO, FILE_STATUS, FILE_CUSTOMER,
                    FILE_BALANCE)
               VALUES (:WS-ACCOUNT, :WS-STATUS, :WS-CUSTOMER,
                       :WS-BALANCE)
           END-EXEC
           IF SQLCODE NOT = 0
               DISPLAY "エラー=挿入 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           ELSE
               MOVE WS-BALANCE TO WS-EDITED-BALANCE
               MOVE SPACES TO DIFFERENCE-RECORD
               STRING FUNCTION TRIM(WS-STATUS) " ACCOUNT="
                      WS-ACCOUNT " CUSTOMER=" WS-CUSTOMER
                      " BALANCE=" WS-EDITED-BALANCE
                   INTO DIFFERENCE-RECORD
               END-STRING
               DISPLAY FUNCTION TRIM(WS-STATUS)
                       " ACCOUNT=" WS-ACCOUNT " CUSTOMER="
                       WS-CUSTOMER " BALANCE=" WS-EDITED-BALANCE
               IF WS-STATUS NOT = "MATCH"
                   WRITE DIFFERENCE-RECORD
                   IF WS-OUT-STATUS NOT = "00"
                       DISPLAY "エラー=出力書込 状態="
                               WS-OUT-STATUS
                       MOVE "Y" TO WS-FAILED
                   END-IF
               END-IF
           END-IF.
       9000-DISCONNECT-DATABASE.
           EXEC SQL CONNECT RESET END-EXEC
           IF SQLCODE = 0
               DISPLAY "切断=成功"
           ELSE
               DISPLAY "切断=エラー SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF
           IF WS-FAILED = "Y"
               STOP RUN RETURNING 1
           END-IF.
