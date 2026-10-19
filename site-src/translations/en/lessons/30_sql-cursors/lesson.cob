      * 接続情報は環境から渡す。
      * DECLAREは登録、OPENで取得。
      * SQLCODE 0は行、100は終端。
      * OPEN成功時だけカーソルを閉じる。
      * 空表でも空白行を返すドライバー特例。
      * 次のFETCHで100。空白行も数える。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON30.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-DATASRC PIC X(255).
       01 WS-DBUSER PIC X(64).
       01 WS-DBPASS PIC X(64).
       01 WS-ACCOUNT PIC X(10).
       01 WS-CUSTOMER PIC X(8).
       01 WS-BALANCE PIC S9(7)V99 COMP-3.
      * 表示整数部は5桁。超過分は欠落。
       01 WS-EDITED-BALANCE PIC 9(5).99.
      * 行数は3桁。999行超で桁あふれ。
       01 WS-ROW-COUNT PIC 9(3) VALUE ZERO.
       01 WS-DB-OPEN PIC X VALUE "N".
       01 WS-CURSOR-OPEN PIC X VALUE "N".
       01 WS-DONE PIC X VALUE "N".
       01 WS-FAILED PIC X VALUE "N".
       EXEC SQL INCLUDE SQLCA END-EXEC.
       EXEC SQL
           DECLARE ACCOUNT-CURSOR CURSOR FOR
               SELECT ACCOUNT_NO, CUSTOMER_ID, BALANCE
                 FROM ACCOUNT_SNAPSHOT
                ORDER BY ACCOUNT_NO
       END-EXEC.
       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           PERFORM 1000-CONNECT-DATABASE
           IF WS-DB-OPEN = "Y"
               PERFORM 2000-OPEN-CURSOR
               IF WS-CURSOR-OPEN = "Y"
                   PERFORM 3000-FETCH-ROWS
                   PERFORM 4000-CLOSE-CURSOR
               END-IF
           END-IF
           DISPLAY "行数=" WS-ROW-COUNT
           IF WS-DB-OPEN = "Y"
               PERFORM 9000-DISCONNECT-DATABASE
           ELSE
               IF WS-FAILED = "Y"
                   STOP RUN RETURNING 1
               END-IF
           END-IF
           GOBACK.
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
               DISPLAY "接続=成功"
           ELSE
               DISPLAY "接続=エラー SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
       2000-OPEN-CURSOR.
           EXEC SQL OPEN ACCOUNT-CURSOR END-EXEC
           IF SQLCODE = 0
               MOVE "Y" TO WS-CURSOR-OPEN
               DISPLAY "オープン=成功"
           ELSE
               DISPLAY "オープン=エラー SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
       3000-FETCH-ROWS.
           PERFORM UNTIL WS-DONE = "Y"
               EXEC SQL
                   FETCH ACCOUNT-CURSOR
                       INTO :WS-ACCOUNT, :WS-CUSTOMER, :WS-BALANCE
               END-EXEC
               EVALUATE SQLCODE
                 WHEN 0
                   ADD 1 TO WS-ROW-COUNT
                   MOVE WS-BALANCE TO WS-EDITED-BALANCE
                   DISPLAY "行=" WS-ACCOUNT " CUSTOMER="
                           WS-CUSTOMER " BALANCE=" WS-EDITED-BALANCE
                 WHEN 100
                   DISPLAY "取得=EOF SQLCODE=100"
                   MOVE "Y" TO WS-DONE
                 WHEN OTHER
                   DISPLAY "取得=エラー SQLSTATE=" SQLSTATE
                   MOVE "Y" TO WS-FAILED WS-DONE
               END-EVALUATE
           END-PERFORM.
       4000-CLOSE-CURSOR.
           EXEC SQL CLOSE ACCOUNT-CURSOR END-EXEC
           IF SQLCODE = 0
               MOVE "N" TO WS-CURSOR-OPEN
               DISPLAY "クローズ=成功"
           ELSE
               DISPLAY "クローズ=エラー SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
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
