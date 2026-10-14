       IDENTIFICATION DIVISION.
       PROGRAM-ID. SYNCDB32.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
      * 日本語：呼び出し元から最終口座状態と共有バッチ件数を受け取る。
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
      * 日本語：レポートは新規作成し、バッチログは追記する。状態は個別に確認する。
      * 日本語：オープン済みフラグで部分失敗後に閉じる資源を把握する。
      * 日本語：ホスト変数で DB 結果を呼び出し元の表から分離する。
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
      * 日本語：SYNC-STATUS は結果を保持し、OUTPUT-LINE は両出力で共用する。
       LINKAGE SECTION.
      * 日本語：参照渡しのため LINKAGE は BATCH-INTERFACE.CPY と一致させる。
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
      * 日本語：GixSQL は最後のリンケージ項目をコメント化するため予備バイトを残す。
       PROCEDURE DIVISION USING WS-ACCOUNT-TABLE WS-BATCH-COUNTS.
      * 日本語：出力を先に開き、障害がなければ接続して同期する。
      * 日本語：開いたファイルを閉じ、戻る前に各状態を確認する。
       MAIN-SYNC.
           OPEN OUTPUT REPORT-FILE
           IF WS-REPORT-STATUS = "00"
               MOVE "Y" TO WS-REPORT-OPEN
           ELSE
               DISPLAY "ERROR=OPEN REPORT STATUS="
                       WS-REPORT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF
           OPEN EXTEND LOG-FILE
           IF WS-LOG-STATUS = "00"
               MOVE "Y" TO WS-LOG-OPEN
           ELSE
               DISPLAY "ERROR=OPEN LOG STATUS=" WS-LOG-STATUS
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
                   DISPLAY "ERROR=CLOSE LOG STATUS=" WS-LOG-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-REPORT-OPEN = "Y"
               CLOSE REPORT-FILE
               IF WS-REPORT-STATUS NOT = "00"
                   DISPLAY "ERROR=CLOSE REPORT STATUS="
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
      * 日本語：接続値は環境から読み、ソースに認証情報を書かない。
      * 日本語：SQLCODE がゼロなら接続成功。それ以外は障害とする。
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
               DISPLAY "CONNECT=OK"
               MOVE "EVENT=DB_CONNECTED" TO WS-LOG-LINE
               PERFORM 8100-WRITE-LOG
           ELSE
               DISPLAY "CONNECT=ERROR SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 日本語：宣言件数まで走査し、完了または障害時に停止する。
       2000-SYNC-TABLE.
           PERFORM VARYING WS-INDEX FROM 1 BY 1
             UNTIL WS-INDEX > WS-ACCOUNT-COUNT OR WS-FAILED = "Y"
               PERFORM 2100-SYNC-ACCOUNT
           END-PERFORM.
      * 日本語：1口座をホスト変数へ移し、SELECT 前に結果を消去する。
      * 日本語：主キー検索で各口座を未変更、更新、挿入に分類する。
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
               DISPLAY "ERROR=SYNC LOOKUP SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-EVALUATE
           IF WS-FAILED NOT = "Y"
               PERFORM 2400-REPORT-SYNC
           END-IF.
      * 日本語：SQLCODE 100 は INSERT、それ以外の検索エラーは停止する。
      * 日本語：DB 操作の成功後にだけ結果を報告する。
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
               DISPLAY "ERROR=UPDATE SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 日本語：口座キーで顧客識別子と計算済み残高を更新する。
      * 日本語：成功した更新だけを加算し、SQL エラーで失敗フラグを立てる。
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
               DISPLAY "ERROR=INSERT SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 日本語：呼び出し元の計算値から未登録のスナップショットを挿入する。
      * 日本語：成功した挿入だけを加算し、DB エラーはバッチ失敗とする。
       2400-REPORT-SYNC.
           MOVE WS-ACCOUNT-BALANCE(WS-INDEX)
             TO WS-EDITED-BALANCE
           MOVE SPACES TO WS-OUTPUT-LINE
           STRING "SYNC " FUNCTION TRIM(WS-SYNC-STATUS)
                  " ACCOUNT=" WS-ACCOUNT-NO(WS-INDEX)
                  " BALANCE=" WS-EDITED-BALANCE
               INTO WS-OUTPUT-LINE
           END-STRING
           DISPLAY FUNCTION TRIM(WS-OUTPUT-LINE)
           WRITE REPORT-RECORD FROM WS-OUTPUT-LINE
           IF WS-REPORT-STATUS NOT = "00"
               DISPLAY "ERROR=WRITE REPORT STATUS="
                       WS-REPORT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF
           MOVE WS-OUTPUT-LINE TO WS-LOG-LINE
           PERFORM 8100-WRITE-LOG.
      * 日本語：結果、口座キー、最終残高を表示用に整形する。
      * 日本語：決定をレポートとログへ書き、どちらの失敗もバッチ障害とする。
       8100-WRITE-LOG.
           MOVE WS-LOG-LINE TO LOG-RECORD
           WRITE LOG-RECORD
           IF WS-LOG-STATUS NOT = "00"
               DISPLAY "ERROR=WRITE LOG STATUS=" WS-LOG-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 日本語：ログ書込みを集約し、全イベントで同じ状態確認を行う。
      * 日本語：同期後に接続をリセットし、切断エラーを呼び出し元へ伝える。
       9000-DISCONNECT.
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
      * 日本語：GixSQL は生成したカーソル用フッターを追加する。
