       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON30.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 日本語：接続情報は実行環境から取得する。
       01 WS-DATASRC PIC X(255).
       01 WS-DBUSER PIC X(64).
       01 WS-DBPASS PIC X(64).
      * 日本語：これらの項目に選択したデータベース列の値を格納する。
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
      * 日本語：主キーにより、繰り返し実行しても順序が安定する。
       EXEC SQL
           DECLARE ACCOUNT-CURSOR CURSOR FOR
               SELECT ACCOUNT_NO, CUSTOMER_ID, BALANCE
                 FROM ACCOUNT_SNAPSHOT
                ORDER BY ACCOUNT_NO
       END-EXEC.
       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
      * 日本語：接続してカーソルを開き、データ末尾まで取得してから閉じる。
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
      * 日本語：ビルドスクリプトは SQLite ファイルと空の認証情報を指定する。
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
      * 日本語：OPEN は結果セットを開始するが、行は取得しない。
           EXEC SQL OPEN ACCOUNT-CURSOR END-EXEC
           IF SQLCODE = 0
               MOVE "Y" TO WS-CURSOR-OPEN
               DISPLAY "CURSOR=OPEN"
           ELSE
               DISPLAY "CURSOR=OPEN_ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
       3000-FETCH-ROWS.
      * 日本語：FETCH のたびに1行が上記のホスト変数に格納される。
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
      * 日本語：EOF や取得エラーの後もリソース解放のために閉じる。
           EXEC SQL CLOSE ACCOUNT-CURSOR END-EXEC
           IF SQLCODE = 0
               MOVE "N" TO WS-CURSOR-OPEN
               DISPLAY "CURSOR=CLOSED"
           ELSE
               DISPLAY "CURSOR=CLOSE_ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
       9000-DISCONNECT-DATABASE.
      * 日本語：カーソル処理後、CONNECT RESET でデータベース接続を解放する。
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
