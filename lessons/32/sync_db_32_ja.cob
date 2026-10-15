       IDENTIFICATION DIVISION.
       PROGRAM-ID. SYNCDB32.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
      * 呼出側から最終口座状態と共有バッチ件数を受け取ります。
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
      * レポートは新規作成、ログは追記で開き、それぞれの状態を確認します。
      * オープン済みフラグを記録し、部分失敗時も開いた資源だけを閉じます。
      * DB検索結果はホスト変数へ受け取り、呼出側の口座表と分けて扱います。
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
      * SYNC-STATUSに判定を保持し、OUTPUT-LINEはレポートとログで共用します。
       LINKAGE SECTION.
      * 参照渡しのLINKAGE項目はBATCH-INTERFACE.CPYと同じ配置にします。
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
      * GixSQLが末尾のLINKAGE項目をコメント化するため、予備領域を設けます。
       PROCEDURE DIVISION USING WS-ACCOUNT-TABLE WS-BATCH-COUNTS.
      * 出力ファイルを開き、成功した場合だけDBへ接続して同期します。
      * 終了時は開いた資源を閉じ、各操作の状態を確認して呼出側へ返します。
       MAIN-SYNC.
           OPEN OUTPUT REPORT-FILE
           IF WS-REPORT-STATUS = "00"
               MOVE "Y" TO WS-REPORT-OPEN
           ELSE
               DISPLAY "エラー=レポートオープン 状態="
                       WS-REPORT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF
           OPEN EXTEND LOG-FILE
           IF WS-LOG-STATUS = "00"
               MOVE "Y" TO WS-LOG-OPEN
           ELSE
               DISPLAY "エラー=ログOPEN 状態=" WS-LOG-STATUS
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
                   DISPLAY "エラー=ログCLOSE 状態=" WS-LOG-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-REPORT-OPEN = "Y"
               CLOSE REPORT-FILE
               IF WS-REPORT-STATUS NOT = "00"
                   DISPLAY "エラー=レポートクローズ 状態="
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
      * 接続情報は環境変数から読み、認証情報をソースに埋め込みません。
      * SQLCODEがゼロなら接続成功です。それ以外はシステム障害として扱います。
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
               MOVE "EVENT=DB_CONNECTED" TO WS-LOG-LINE
               PERFORM 8100-WRITE-LOG
           ELSE
               DISPLAY "接続=エラー SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 口座表を宣言件数まで走査し、全件完了または障害時に終了します。
       2000-SYNC-TABLE.
           PERFORM VARYING WS-INDEX FROM 1 BY 1
             UNTIL WS-INDEX > WS-ACCOUNT-COUNT OR WS-FAILED = "Y"
               PERFORM 2100-SYNC-ACCOUNT
           END-PERFORM.
      * 口座をホスト変数へ移し、SELECT前に結果領域を初期化します。
      * 主キー検索の結果に応じて未変更・更新・挿入へ振り分けます。
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
               DISPLAY "エラー=同期検索 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-EVALUATE
           IF WS-FAILED NOT = "Y"
               PERFORM 2400-REPORT-SYNC
           END-IF.
      * 検索結果なしのSQLCODE 100ならINSERTし、その他のSQL障害は停止します。
      * DB操作が成功した後に限り、その口座の判定を報告します。
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
               DISPLAY "エラー=更新 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 口座キーを条件に、顧客IDと計算済み残高を更新します。
      * 更新成功数だけを加算し、SQL障害はバッチ失敗として記録します。
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
               DISPLAY "エラー=挿入 SQLSTATE=" SQLSTATE
               MOVE "Y" TO WS-FAILED
           END-IF.
      * 呼出側の計算結果から、DBにない口座行を挿入します。
      * 挿入成功数だけを加算し、SQL障害はバッチ失敗として記録します。
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
               DISPLAY "エラー=レポート書込 状態="
                       WS-REPORT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF
           MOVE WS-OUTPUT-LINE TO WS-LOG-LINE
           PERFORM 8100-WRITE-LOG.
      * 判定、口座キー、最終残高を出力行に整形します。
      * 判定をレポートとログに書き、どちらかの失敗もバッチ障害にします。
       8100-WRITE-LOG.
           MOVE WS-LOG-LINE TO LOG-RECORD
           WRITE LOG-RECORD
           IF WS-LOG-STATUS NOT = "00"
               DISPLAY "エラー=ログ書込 状態=" WS-LOG-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
      * ログ書込みを一か所に集め、全イベントで状態確認を統一します。
      * 同期後にDBを切断し、切断エラーも呼出側へ返します。
       9000-DISCONNECT.
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
      * GixSQLがカーソルの終了処理を生成するため、明示的な終端は不要です。
