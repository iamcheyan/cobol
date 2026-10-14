       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON29.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * GixSQL expands EXEC SQL before GnuCOBOL compiles the source.
      * 中文：GixSQL 会在 GnuCOBOL 编译源代码前展开 EXEC SQL。
      * 日本語：GnuCOBOL がソースをコンパイルする前に、GixSQL が EXEC SQL を展開する。
      * SQLCA stores the status from each executed database statement.
      * 中文：SQLCA 保存每条已执行数据库语句的状态。
      * 日本語：SQLCA は実行した各データベース文の状態を保存する。
      * Database connection values stay outside the compiled program.
      * 中文：数据库连接值保存在编译程序之外。
      * 日本語：データベース接続値はコンパイル済みプログラムの外部に置く。
      * GixSQL receives the database path and credentials at run time.
      * 中文：GixSQL 在运行时接收数据库路径和凭据。
      * 日本語：GixSQL は実行時にデータベースのパスと認証情報を受け取る。
       01 WS-DATASRC PIC X(255).
       01 WS-DBUSER PIC X(64).
       01 WS-DBPASS PIC X(64).
      * Keep host fields the same width as the database text columns.
      * 中文：主机变量字段宽度应与数据库文本列相同。
      * 日本語：ホスト変数の幅をデータベースのテキスト列と同じにする。
       01 WS-LOOKUP-ACCOUNT PIC X(10).
       01 WS-ACCOUNT PIC X(10).
       01 WS-CUSTOMER PIC X(8).
       01 WS-BALANCE PIC S9(7)V99 COMP-3.
       01 WS-EDITED-BALANCE PIC 9(5).99.
       01 WS-DB-OPEN PIC X VALUE "N".
       01 WS-FAILED PIC X VALUE "N".
      * Host variables bind COBOL fields to SQL columns or parameters.
      * 中文：主机变量将 COBOL 字段绑定到 SQL 列或参数。
      * 日本語：ホスト変数で COBOL フィールドを SQL 列またはパラメーターに結び付ける。
      * SQLCODE and SQLSTATE describe the most recent SQL operation.
      * 中文：SQLCODE 和 SQLSTATE 描述最近一次 SQL 操作的结果。
      * 日本語：SQLCODE と SQLSTATE は直近の SQL 操作の結果を示す。
      * SQLCODE zero means success; 100 means a query returned no row.
      * 中文：SQLCODE 为零表示成功；100 表示查询未返回行。
      * 日本語：SQLCODE が 0 なら成功、100 なら検索結果が0行であることを示す。
      * Other SQLCODE values take the error path in this example.
      * 中文：在此示例中，其他 SQLCODE 值会进入错误处理路径。
      * 日本語：この例では、その他の SQLCODE 値はエラー処理経路に進む。
       EXEC SQL INCLUDE SQLCA END-EXEC.
       PROCEDURE DIVISION.
      * The driver connection is shared by the lookup paragraphs below.
      * 中文：下方的查询段落共用驱动程序连接。
      * 日本語：以下の検索段落ではドライバー接続を共有する。
      * The next lesson adds a cursor for multi-row query results.
      * 中文：下一课将为多行查询结果添加游标。
      * 日本語：次の課では複数行の検索結果に対応するカーソルを追加する。
       MAIN-PROCEDURE.
      * Connect, perform two lookups, and close a good session.
      * 中文：连接数据库、执行两次查询，并关闭正常会话。
      * 日本語：データベースに接続して2回検索し、正常なセッションを閉じる。
           PERFORM 1000-CONNECT-DATABASE
      * A failed connection leaves WS-DB-OPEN set to N.
      * 中文：连接失败时，WS-DB-OPEN 保持为 N。
      * 日本語：接続に失敗すると WS-DB-OPEN は N のままとなる。
      * The main flow skips queries when no connection is available.
      * 中文：没有可用连接时，主流程会跳过查询。
      * 日本語：接続できない場合、メイン処理は検索をスキップする。
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
      * DISPLAY ENVIRONMENT-NAME selects the variable read by ACCEPT.
      * 中文：DISPLAY ENVIRONMENT-NAME 会指定 ACCEPT 读取的环境变量。
      * 日本語：DISPLAY ENVIRONMENT-NAME で ACCEPT が読み取る環境変数を指定する。
      * Read connection data from the environment, not source literals.
      * 中文：从环境读取连接数据，而不是将其写成源代码字面值。
      * 日本語：接続情報はソースのリテラルではなく環境から読み取る。
      * The three names below match the build script's run environment.
      * 中文：下面三个名称与构建脚本设置的运行环境一致。
      * 日本語：以下の3つの名前はビルドスクリプトの実行環境設定と一致する。
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
      * SELECT INTO copies one matching row into COBOL host variables.
      * 中文：SELECT INTO 会将一条匹配记录复制到 COBOL 主机变量中。
      * 日本語：SELECT INTO は一致した1行を COBOL のホスト変数にコピーする。
      * Clear prior results so a missing row cannot reuse old values.
      * 中文：清除先前结果，避免未找到记录时沿用旧值。
      * 日本語：以前の結果を消去し、行が見つからない場合に古い値を再利用しないようにする。
      * The primary-key predicate can return at most one account row.
      * 中文：主键条件最多返回一条账户记录。
      * 日本語：主キー条件により、口座レコードは最大1行だけ返る。
      * WS-LOOKUP-ACCOUNT is the SQL input host variable.
      * 中文：WS-LOOKUP-ACCOUNT 是 SQL 输入主机变量。
      * 日本語：WS-LOOKUP-ACCOUNT は SQL 入力用のホスト変数。
           MOVE SPACES TO WS-ACCOUNT WS-CUSTOMER
           MOVE ZERO TO WS-BALANCE
           EXEC SQL
               SELECT ACCOUNT_NO, CUSTOMER_ID, BALANCE
                 INTO :WS-ACCOUNT, :WS-CUSTOMER, :WS-BALANCE
                 FROM ACCOUNT_SNAPSHOT
                WHERE ACCOUNT_NO = :WS-LOOKUP-ACCOUNT
           END-EXEC
      * SQLCODE 100 is a normal no-match result, not a database failure.
      * 中文：SQLCODE 100 表示正常的无匹配结果，并非数据库故障。
      * 日本語：SQLCODE 100 は正常な該当なしの結果であり、データベース障害ではない。
      * Other SQL errors set a flag that becomes process status 1.
      * 中文：其他 SQL 错误会设置标志，最终使进程状态为 1。
      * 日本語：その他の SQL エラーはフラグを設定し、最終的にプロセスステータスを 1 にする。
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
      * A successful connect is paired with CONNECT RESET.
      * 中文：连接成功后会配对执行 CONNECT RESET。
      * 日本語：接続に成功した場合は、対応する CONNECT RESET を実行する。
           EXEC SQL CONNECT RESET END-EXEC
           IF SQLCODE = 0
               DISPLAY "DISCONNECT=OK"
           ELSE
               DISPLAY "DISCONNECT=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
