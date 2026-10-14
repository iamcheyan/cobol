       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON29.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 中文：GixSQL 会在 GnuCOBOL 编译源代码前展开 EXEC SQL。
      * 中文：SQLCA 保存每条已执行数据库语句的状态。
      * 中文：数据库连接值保存在编译程序之外。
      * 中文：GixSQL 在运行时接收数据库路径和凭据。
       01 WS-DATASRC PIC X(255).
       01 WS-DBUSER PIC X(64).
       01 WS-DBPASS PIC X(64).
      * 中文：主机变量字段宽度应与数据库文本列相同。
       01 WS-LOOKUP-ACCOUNT PIC X(10).
       01 WS-ACCOUNT PIC X(10).
       01 WS-CUSTOMER PIC X(8).
       01 WS-BALANCE PIC S9(7)V99 COMP-3.
       01 WS-EDITED-BALANCE PIC 9(5).99.
       01 WS-DB-OPEN PIC X VALUE "N".
       01 WS-FAILED PIC X VALUE "N".
      * 中文：主机变量将 COBOL 字段绑定到 SQL 列或参数。
      * 中文：SQLCODE 和 SQLSTATE 描述最近一次 SQL 操作的结果。
      * 中文：SQLCODE 为零表示成功；100 表示查询未返回行。
      * 中文：在此示例中，其他 SQLCODE 值会进入错误处理路径。
       EXEC SQL INCLUDE SQLCA END-EXEC.
       PROCEDURE DIVISION.
      * 中文：下方的查询段落共用驱动程序连接。
      * 中文：下一课将为多行查询结果添加游标。
       MAIN-PROCEDURE.
      * 中文：连接数据库、执行两次查询，并关闭正常会话。
           PERFORM 1000-CONNECT-DATABASE
      * 中文：连接失败时，WS-DB-OPEN 保持为 N。
      * 中文：没有可用连接时，主流程会跳过查询。
           IF WS-DB-OPEN = "Y"
               MOVE "A000000001" TO WS-LOOKUP-ACCOUNT
               PERFORM 2000-LOOKUP-ACCOUNT
               MOVE "A99999999X" TO WS-LOOKUP-ACCOUNT
               PERFORM 2000-LOOKUP-ACCOUNT
               PERFORM 9000-DISCONNECT-DATABASE
           END-IF
           IF WS-FAILED = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           GOBACK.
       1000-CONNECT-DATABASE.
      * 中文：DISPLAY ENVIRONMENT-NAME 会指定 ACCEPT 读取的环境变量。
      * 中文：从环境读取连接数据，而不是将其写成源代码字面值。
      * 中文：下面三个名称与构建脚本设置的运行环境一致。
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
           ELSE
               DISPLAY "CONNECT=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
       2000-LOOKUP-ACCOUNT.
      * 中文：SELECT INTO 会将一条匹配记录复制到 COBOL 主机变量中。
      * 中文：清除先前结果，避免未找到记录时沿用旧值。
      * 中文：主键条件最多返回一条账户记录。
      * 中文：WS-LOOKUP-ACCOUNT 是 SQL 输入主机变量。
           MOVE SPACES TO WS-ACCOUNT WS-CUSTOMER
           MOVE ZERO TO WS-BALANCE
           EXEC SQL
               SELECT ACCOUNT_NO, CUSTOMER_ID, BALANCE
                 INTO :WS-ACCOUNT, :WS-CUSTOMER, :WS-BALANCE
                 FROM ACCOUNT_SNAPSHOT
                WHERE ACCOUNT_NO = :WS-LOOKUP-ACCOUNT
           END-EXEC
      * 中文：SQLCODE 100 表示正常的无匹配结果，并非数据库故障。
      * 中文：其他 SQL 错误会设置标志，最终使进程状态为 1。
           EVALUATE SQLCODE
             WHEN 0
               MOVE WS-BALANCE TO WS-EDITED-BALANCE
               DISPLAY "LOOKUP=" WS-LOOKUP-ACCOUNT
                       " STATUS=FOUND CUSTOMER=" WS-CUSTOMER
                       " BALANCE=" WS-EDITED-BALANCE
             WHEN 100
               DISPLAY "LOOKUP=" WS-LOOKUP-ACCOUNT
                       " STATUS=NOT_FOUND"
             WHEN OTHER
               DISPLAY "LOOKUP=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-EVALUATE.
       9000-DISCONNECT-DATABASE.
      * 中文：连接成功后会配对执行 CONNECT RESET。
           EXEC SQL CONNECT RESET END-EXEC
           IF SQLCODE = 0
               DISPLAY "DISCONNECT=OK"
           ELSE
               DISPLAY "DISCONNECT=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
