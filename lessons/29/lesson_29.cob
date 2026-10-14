       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON29.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 日本語：GnuCOBOL がソースをコンパイルする前に、GixSQL が EXEC SQL を展開する。
      * 日本語：SQLCA は実行した各データベース文の状態を保存する。
      * 日本語：データベース接続値はコンパイル済みプログラムの外部に置く。
      * 日本語：GixSQL は実行時にデータベースのパスと認証情報を受け取る。
       01 WS-DATASRC PIC X(255).
       01 WS-DBUSER PIC X(64).
       01 WS-DBPASS PIC X(64).
      * 日本語：ホスト変数の幅をデータベースのテキスト列と同じにする。
       01 WS-LOOKUP-ACCOUNT PIC X(10).
       01 WS-ACCOUNT PIC X(10).
       01 WS-CUSTOMER PIC X(8).
       01 WS-BALANCE PIC S9(7)V99 COMP-3.
       01 WS-EDITED-BALANCE PIC 9(5).99.
       01 WS-DB-OPEN PIC X VALUE "N".
       01 WS-FAILED PIC X VALUE "N".
      * 日本語：ホスト変数で COBOL フィールドを SQL 列またはパラメーターに結び付ける。
      * 日本語：SQLCODE と SQLSTATE は直近の SQL 操作の結果を示す。
      * 日本語：SQLCODE が 0 なら成功、100 なら検索結果が0行であることを示す。
      * 日本語：この例では、その他の SQLCODE 値はエラー処理経路に進む。
       EXEC SQL INCLUDE SQLCA END-EXEC.
       PROCEDURE DIVISION.
      * 日本語：以下の検索段落ではドライバー接続を共有する。
      * 日本語：次の課では複数行の検索結果に対応するカーソルを追加する。
       MAIN-PROCEDURE.
      * 日本語：データベースに接続して2回検索し、正常なセッションを閉じる。
           PERFORM 1000-CONNECT-DATABASE
      * 日本語：接続に失敗すると WS-DB-OPEN は N のままとなる。
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
      * 日本語：DISPLAY ENVIRONMENT-NAME で ACCEPT が読み取る環境変数を指定する。
      * 日本語：接続情報はソースのリテラルではなく環境から読み取る。
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
      * 日本語：SELECT INTO は一致した1行を COBOL のホスト変数にコピーする。
      * 日本語：以前の結果を消去し、行が見つからない場合に古い値を再利用しないようにする。
      * 日本語：主キー条件により、口座レコードは最大1行だけ返る。
      * 日本語：WS-LOOKUP-ACCOUNT は SQL 入力用のホスト変数。
           MOVE SPACES TO WS-ACCOUNT WS-CUSTOMER
           MOVE ZERO TO WS-BALANCE
           EXEC SQL
               SELECT ACCOUNT_NO, CUSTOMER_ID, BALANCE
                 INTO :WS-ACCOUNT, :WS-CUSTOMER, :WS-BALANCE
                 FROM ACCOUNT_SNAPSHOT
                WHERE ACCOUNT_NO = :WS-LOOKUP-ACCOUNT
           END-EXEC
      * 日本語：SQLCODE 100 は正常な該当なしの結果であり、データベース障害ではない。
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
      * 日本語：接続に成功した場合は、対応する CONNECT RESET を実行する。
           EXEC SQL CONNECT RESET END-EXEC
           IF SQLCODE = 0
               DISPLAY "DISCONNECT=OK"
           ELSE
               DISPLAY "DISCONNECT=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
