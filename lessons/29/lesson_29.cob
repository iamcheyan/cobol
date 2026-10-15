       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON29.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * GixSQLはEXEC SQLを展開してから、GnuCOBOLがソースをコンパイルします。
      * SQLCAには、実行した各SQL文の状態が保存されます。
      * 接続先と認証情報はソースや実行ファイルに埋め込まず、実行環境から渡します。
      * GixSQLは実行時にDBパスと認証情報を環境から受け取ります。
       01 WS-DATASRC PIC X(255).
       01 WS-DBUSER PIC X(64).
       01 WS-DBPASS PIC X(64).
      * ホスト変数のPIC幅を対応するDB列の幅に合わせます。
       01 WS-LOOKUP-ACCOUNT PIC X(10).
       01 WS-ACCOUNT PIC X(10).
       01 WS-CUSTOMER PIC X(8).
       01 WS-BALANCE PIC S9(7)V99 COMP-3.
       01 WS-EDITED-BALANCE PIC 9(5).99.
       01 WS-DB-OPEN PIC X VALUE "N".
       01 WS-FAILED PIC X VALUE "N".
      * ホスト変数はCOBOL項目とSQL列・パラメーターを結び付けます。
      * SQLCODEとSQLSTATEは直前のSQL操作の結果を示します。
      * SQLCODE 0は成功、100は検索結果なしを示します。
      * この例では、それ以外のSQLCODEをシステムエラーとして扱います。
       EXEC SQL INCLUDE SQLCA END-EXEC.
       PROCEDURE DIVISION.
      * 検索段落はドライバーが開いた接続を共有します。
      * 次の課では複数行の結果を処理するカーソルを学びます。
       MAIN-PROCEDURE.
      * DBへ接続して2回検索し、最後に接続を正常終了します。
           PERFORM 1000-CONNECT-DATABASE
      * 接続に失敗した場合、WS-DB-OPENはNのままです。
      * 接続できない場合、メイン処理は検索をスキップします。
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
      * DISPLAY ENVIRONMENT-NAMEにより、ACCEPTが読む環境変数を指定します。
      * 接続情報はソース内の定数ではなく環境変数から読み取ります。
      * 環境変数名はビルドスクリプトが設定する名前と一致させます。
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
      * SELECT INTOは一致した1行をCOBOLのホスト変数へ格納します。
      * 検索前に結果領域を初期化し、該当行がない場合の古い値再利用を防ぎます。
      * 主キー検索は口座を最大1行だけ返します。
      * WS-LOOKUP-ACCOUNT は SQL 入力用のホスト変数。
           MOVE SPACES TO WS-ACCOUNT WS-CUSTOMER
           MOVE ZERO TO WS-BALANCE
           EXEC SQL
               SELECT ACCOUNT_NO, CUSTOMER_ID, BALANCE
                 INTO :WS-ACCOUNT, :WS-CUSTOMER, :WS-BALANCE
                 FROM ACCOUNT_SNAPSHOT
                WHERE ACCOUNT_NO = :WS-LOOKUP-ACCOUNT
           END-EXEC
      * SQLCODE 100は正常な該当なしで、DB障害ではありません。
      * その他のSQLエラーは失敗フラグを立て、プロセスを終了コード1にします。
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
      * 接続に成功した場合に限り、対応するCONNECT RESETを実行します。
           EXEC SQL CONNECT RESET END-EXEC
           IF SQLCODE = 0
               DISPLAY "DISCONNECT=OK"
           ELSE
               DISPLAY "DISCONNECT=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
