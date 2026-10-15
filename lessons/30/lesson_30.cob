       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON30.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 接続情報は実行環境から取得する。
       01 WS-DATASRC PIC X(255).
       01 WS-DBUSER PIC X(64).
       01 WS-DBPASS PIC X(64).
      * これらの項目に選択したデータベース列の値を
      * 格納する。
       01 WS-ACCOUNT PIC X(10).
       01 WS-CUSTOMER PIC X(8).
       01 WS-BALANCE PIC S9(7)V99 COMP-3.
       01 WS-EDITED-BALANCE PIC 9(5).99.
       01 WS-ROW-COUNT PIC 9(3) VALUE ZERO.
       01 WS-DB-OPEN PIC X VALUE "N".
       01 WS-CURSOR-OPEN PIC X VALUE "N".
       01 WS-DONE PIC X VALUE "N".
       01 WS-FAILED PIC X VALUE "N".
       EXEC SQL INCLUDE SQLCA END-EXEC.
      * 主キーで並べるため、再実行しても行の順序が安定します。
       EXEC SQL
           DECLARE ACCOUNT-CURSOR CURSOR FOR
               SELECT ACCOUNT_NO, CUSTOMER_ID, BALANCE
                 FROM ACCOUNT_SNAPSHOT
                ORDER BY ACCOUNT_NO
       END-EXEC.
       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
      * 接続してカーソルを開き、データ末尾まで取得
      * してから閉じる。
           PERFORM 1000-CONNECT-DATABASE
           IF WS-DB-OPEN = "Y"
               PERFORM 2000-OPEN-CURSOR
               IF WS-CURSOR-OPEN = "Y"
                   PERFORM 3000-FETCH-ROWS
                   PERFORM 4000-CLOSE-CURSOR
               END-IF
           END-IF
           DISPLAY "ROWS=" WS-ROW-COUNT
           IF WS-DB-OPEN = "Y"
               PERFORM 9000-DISCONNECT-DATABASE
           ELSE
               IF WS-FAILED = "Y"
                   STOP RUN RETURNING 1
               END-IF
           END-IF
           GOBACK.
       1000-CONNECT-DATABASE.
      * ビルドスクリプトは SQLite
      * ファイルと空の認証情報を指定する。
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
       2000-OPEN-CURSOR.
      * OPENは結果セットを開始しますが、まだ行を取得しません。
           EXEC SQL OPEN ACCOUNT-CURSOR END-EXEC
           IF SQLCODE = 0
               MOVE "Y" TO WS-CURSOR-OPEN
               DISPLAY "CURSOR=OPEN"
           ELSE
               DISPLAY "CURSOR=OPEN_ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
       3000-FETCH-ROWS.
      * FETCHのたびに1行が上記のホスト変数へ格納されます。
           PERFORM UNTIL WS-DONE = "Y"
               EXEC SQL
                   FETCH ACCOUNT-CURSOR
                       INTO :WS-ACCOUNT, :WS-CUSTOMER, :WS-BALANCE
               END-EXEC
               EVALUATE SQLCODE
                 WHEN 0
                   ADD 1 TO WS-ROW-COUNT
                   MOVE WS-BALANCE TO WS-EDITED-BALANCE
                   DISPLAY "ROW=" WS-ACCOUNT " CUSTOMER="
                           WS-CUSTOMER " BALANCE=" WS-EDITED-BALANCE
                 WHEN 100
                   DISPLAY "FETCH=EOF SQLCODE=100"
                   MOVE "Y" TO WS-DONE
                 WHEN OTHER
                   DISPLAY "FETCH=ERROR SQLSTATE=" SQLSTATE
                   MOVE "Y" TO WS-FAILED WS-DONE
               END-EVALUATE
           END-PERFORM.
       4000-CLOSE-CURSOR.
      * EOFまたは取得エラーの後も、資源を解放するためカーソルを閉じます。
           EXEC SQL CLOSE ACCOUNT-CURSOR END-EXEC
           IF SQLCODE = 0
               MOVE "N" TO WS-CURSOR-OPEN
               DISPLAY "CURSOR=CLOSED"
           ELSE
               DISPLAY "CURSOR=CLOSE_ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
       9000-DISCONNECT-DATABASE.
      * カーソル処理後にCONNECT RESETを実行し、DB接続を解放します。
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
