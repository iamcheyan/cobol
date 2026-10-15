      *LOAD_POSTは呼び出されるバッチモジュールで、主ドライバーではありません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOADPOST32.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
      *口座・取引の入力と、承認・拒否・ログの出力を定義します。
      *各行順ファイルに個別の状態項目を設け、エラーを確認します。
       FILE-CONTROL.
           SELECT ACCOUNT-FILE ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT TRANSACTION-FILE ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
           SELECT ACCEPTED-FILE ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCEPTED-STATUS.
           SELECT REJECTED-FILE ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REJECTED-STATUS.
           SELECT LOG-FILE ASSIGN TO "batch.log"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-LOG-STATUS.
      *入力は固定長レコードで、出力には報告用の領域を確保します。
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-FILE.
       01 ACCOUNT-INPUT PIC X(27).
       FD TRANSACTION-FILE.
       01 TRANSACTION-INPUT PIC X(20).
       FD ACCEPTED-FILE.
       01 ACCEPTED-RECORD PIC X(80).
       FD REJECTED-FILE.
       01 REJECTED-RECORD PIC X(80).
       FD LOG-FILE.
       01 LOG-RECORD PIC X(100).
      *TRANSACTION.CPYが共有バッチ状態と口座テーブルを定義します。
      *オープン済みフラグにより、途中失敗時も安全に後始末できます。
      *パック10進数で金額を保持し、理由項目に拒否コードを格納します。
       WORKING-STORAGE SECTION.
       COPY "TRANSACTION.CPY".
       01 WS-ACCOUNT-STATUS PIC XX.
       01 WS-TRANSACTION-STATUS PIC XX.
       01 WS-ACCEPTED-STATUS PIC XX.
       01 WS-REJECTED-STATUS PIC XX.
       01 WS-LOG-STATUS PIC XX.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-ACCOUNT-OPEN PIC X VALUE "N".
       01 WS-TRANSACTION-OPEN PIC X VALUE "N".
       01 WS-ACCEPTED-OPEN PIC X VALUE "N".
       01 WS-REJECTED-OPEN PIC X VALUE "N".
       01 WS-LOG-OPEN PIC X VALUE "N".
       01 WS-FOUND PIC X VALUE "N".
       01 WS-INDEX PIC 99 VALUE ZERO.
       01 WS-SEARCH-INDEX PIC 99 VALUE ZERO.
       01 WS-REASON PIC X(16).
       01 WS-AMOUNT PIC S9(7)V99 COMP-3.
       01 WS-EDITED-BALANCE PIC 9(7).99.
       01 WS-OUTPUT-LINE PIC X(80).
       01 WS-LOG-LINE PIC X(100).
      *BATCH-INTERFACE.CPYは呼び出し元が所有する表と件数を定義します。
      *USINGでモジュール境界を越えてレコードを共有します。
       LINKAGE SECTION.
       COPY "BATCH-INTERFACE.CPY".
      *呼び出し元と口座状態・件数を共有し、GOBACKで戻ります。
       PROCEDURE DIVISION USING WS-ACCOUNT-TABLE WS-BATCH-COUNTS.
      *資源を開き、口座を読込み、正常なら取引を計上します。
      *呼び出し元へ戻る前に共通の後始末を必ず実行します。
       MAIN-LOAD.
           PERFORM 1000-OPEN-FILES
           IF WS-FAILED NOT = "Y"
               PERFORM 1100-LOAD-ACCOUNTS
           END-IF
           IF WS-FAILED NOT = "Y"
               PERFORM 2000-POST-TRANSACTIONS
           END-IF
           PERFORM 8000-CLOSE-FILES
           GOBACK.
      *入力を先に開き、その後出力を作成して各状態を確認します。
      *ログを開けた後にだけバッチ開始イベントを記録します。
       1000-OPEN-FILES.
           OPEN INPUT ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS = "00"
               MOVE "Y" TO WS-ACCOUNT-OPEN
           ELSE
               DISPLAY "エラー=口座OPEN " WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF
           IF WS-FAILED NOT = "Y"
               OPEN INPUT TRANSACTION-FILE
               IF WS-TRANSACTION-STATUS = "00"
                   MOVE "Y" TO WS-TRANSACTION-OPEN
               ELSE
                   DISPLAY "エラー=取引OPEN " WS-TRANSACTION-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-FAILED NOT = "Y"
               OPEN OUTPUT ACCEPTED-FILE
               IF WS-ACCEPTED-STATUS = "00"
                   MOVE "Y" TO WS-ACCEPTED-OPEN
               ELSE
                   DISPLAY "エラー=受理OPEN " WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-FAILED NOT = "Y"
               OPEN OUTPUT REJECTED-FILE
               IF WS-REJECTED-STATUS = "00"
                   MOVE "Y" TO WS-REJECTED-OPEN
               ELSE
                   DISPLAY "エラー=拒否OPEN " WS-REJECTED-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-FAILED NOT = "Y"
               OPEN OUTPUT LOG-FILE
               IF WS-LOG-STATUS = "00"
                   MOVE "Y" TO WS-LOG-OPEN
                   MOVE "EVENT=BATCH_START" TO WS-LOG-LINE
                   PERFORM 8200-WRITE-LOG
               ELSE
                   DISPLAY "エラー=ログOPEN 状態=" WS-LOG-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
      *口座マスタをEOFまで読み、有効な各レコードを処理します。
       1100-LOAD-ACCOUNTS.
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y" OR WS-FAILED = "Y"
               READ ACCOUNT-FILE
                   AT END
                       MOVE "Y" TO WS-ACCOUNT-EOF
                   NOT AT END
                       IF WS-ACCOUNT-STATUS = "00"
                           PERFORM 1110-STORE-ACCOUNT
                       ELSE
                           DISPLAY "口座READ=" WS-ACCOUNT-STATUS
                           MOVE "Y" TO WS-FAILED
                       END-IF
               END-READ
           END-PERFORM.
      *追加前に口座テーブルの上限20件を確認します。
      *10/8/9桁を解析し、数字のセント額を100で割ります。
      *既存行を検索し、口座番号の重複を検出します。
       1110-STORE-ACCOUNT.
           IF WS-ACCOUNT-COUNT = 20
               DISPLAY "エラー=口座容量超過"
               MOVE "Y" TO WS-FAILED
           ELSE
               ADD 1 TO WS-ACCOUNT-COUNT
               MOVE ACCOUNT-INPUT(1:10)
                 TO WS-ACCOUNT-NO(WS-ACCOUNT-COUNT)
               MOVE ACCOUNT-INPUT(11:8)
                 TO WS-CUSTOMER-ID(WS-ACCOUNT-COUNT)
               IF ACCOUNT-INPUT(19:9) IS NUMERIC
                   COMPUTE WS-ACCOUNT-BALANCE(WS-ACCOUNT-COUNT) =
                       FUNCTION NUMVAL(ACCOUNT-INPUT(19:9)) / 100
               ELSE
                   DISPLAY "エラー=口座残高不正"
                   MOVE "Y" TO WS-FAILED
               END-IF
               PERFORM VARYING WS-SEARCH-INDEX FROM 1 BY 1
                 UNTIL WS-SEARCH-INDEX >= WS-ACCOUNT-COUNT
                   IF WS-ACCOUNT-NO(WS-SEARCH-INDEX) =
                      WS-ACCOUNT-NO(WS-ACCOUNT-COUNT)
                       DISPLAY "エラー=口座重複="
                               WS-ACCOUNT-NO(WS-ACCOUNT-COUNT)
                       MOVE "Y" TO WS-FAILED
                   END-IF
               END-PERFORM
           END-IF.
      *取引を順に処理し、読込みエラーでバッチを終了します。
       2000-POST-TRANSACTIONS.
           PERFORM UNTIL WS-TRANSACTION-EOF = "Y" OR WS-FAILED = "Y"
               READ TRANSACTION-FILE
                   AT END
                       MOVE "Y" TO WS-TRANSACTION-EOF
                   NOT AT END
                       IF WS-TRANSACTION-STATUS = "00"
                           PERFORM 2100-POST-ONE
                       ELSE
                           DISPLAY "取引READ=" WS-TRANSACTION-STATUS
                           MOVE "Y" TO WS-FAILED
                       END-IF
               END-READ
           END-PERFORM.
      *20文字のレコードを口座、種別、金額に分割します。
      *口座添字を検索して金額を検証し、不正なら拒否理由を設定します。
      *有効な取引を適用し、承認または拒否ファイルへ振り分けます。
      *出力行をイベントログにも渡し、処理の追跡性を保ちます。
       2100-POST-ONE.
           ADD 1 TO WS-TRANSACTION-COUNT
           MOVE TRANSACTION-INPUT(1:10)
             TO WS-TRANSACTION-ACCOUNT
           MOVE TRANSACTION-INPUT(11:1)
             TO WS-TRANSACTION-TYPE
           MOVE TRANSACTION-INPUT(12:9)
             TO WS-TRANSACTION-AMOUNT-TEXT
           MOVE "N" TO WS-FOUND
           MOVE ZERO TO WS-INDEX
           PERFORM VARYING WS-SEARCH-INDEX FROM 1 BY 1
             UNTIL WS-SEARCH-INDEX > WS-ACCOUNT-COUNT OR
                   WS-FOUND = "Y"
               IF WS-ACCOUNT-NO(WS-SEARCH-INDEX) =
                  WS-TRANSACTION-ACCOUNT
                   MOVE WS-SEARCH-INDEX TO WS-INDEX
                   MOVE "Y" TO WS-FOUND
               END-IF
           END-PERFORM
           MOVE SPACES TO WS-REASON
           IF WS-TRANSACTION-AMOUNT-TEXT IS NOT NUMERIC
               MOVE "BAD_AMOUNT" TO WS-REASON
           ELSE
               COMPUTE WS-AMOUNT =
                   FUNCTION NUMVAL(WS-TRANSACTION-AMOUNT-TEXT) / 100
               IF WS-FOUND NOT = "Y"
                   MOVE "NO_ACCOUNT" TO WS-REASON
               ELSE
                   PERFORM 2200-APPLY-TRANSACTION
               END-IF
           END-IF
           IF WS-REASON = SPACES
               PERFORM 2300-WRITE-POSTED
           ELSE
               PERFORM 2400-WRITE-REJECTED
           END-IF
           MOVE WS-OUTPUT-LINE TO WS-LOG-LINE
           PERFORM 8200-WRITE-LOG.
      *Dは入金、Cは残高が足りる場合だけ出金します。
      *未知の種別は残高を変更せず拒否します。
       2200-APPLY-TRANSACTION.
           EVALUATE WS-TRANSACTION-TYPE
             WHEN "D"
               ADD WS-AMOUNT TO WS-ACCOUNT-BALANCE(WS-INDEX)
             WHEN "C"
               IF WS-AMOUNT > WS-ACCOUNT-BALANCE(WS-INDEX)
                   MOVE "INSUFFICIENT" TO WS-REASON
               ELSE
                   SUBTRACT WS-AMOUNT
                     FROM WS-ACCOUNT-BALANCE(WS-INDEX)
               END-IF
             WHEN OTHER
               MOVE "BAD_TYPE" TO WS-REASON
           END-EVALUATE.
      *更新後残高を整形・表示し、accepted.txtへ書き込みます。
      *書込み失敗時は共有バッチ状態をエラーにします。
       2300-WRITE-POSTED.
           ADD 1 TO WS-POSTED-COUNT
           MOVE WS-ACCOUNT-BALANCE(WS-INDEX)
             TO WS-EDITED-BALANCE
           MOVE SPACES TO WS-OUTPUT-LINE
           STRING "POSTED TX=" WS-TRANSACTION-COUNT
                  " ACCOUNT=" WS-TRANSACTION-ACCOUNT
                  " TYPE=" WS-TRANSACTION-TYPE
                  " BALANCE=" WS-EDITED-BALANCE
               INTO WS-OUTPUT-LINE
           END-STRING
           DISPLAY FUNCTION TRIM(WS-OUTPUT-LINE)
           WRITE ACCEPTED-RECORD FROM WS-OUTPUT-LINE
           IF WS-ACCEPTED-STATUS NOT = "00"
               DISPLAY "エラー=受理WRITE " WS-ACCEPTED-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
      *取引番号、口座、検証理由を記録して確認可能にします。
       2400-WRITE-REJECTED.
           ADD 1 TO WS-REJECTED-COUNT
           MOVE SPACES TO WS-OUTPUT-LINE
           STRING "REJECTED TX=" WS-TRANSACTION-COUNT
                  " ACCOUNT=" WS-TRANSACTION-ACCOUNT
                  " REASON=" FUNCTION TRIM(WS-REASON)
               INTO WS-OUTPUT-LINE
           END-STRING
           DISPLAY FUNCTION TRIM(WS-OUTPUT-LINE)
           WRITE REJECTED-RECORD FROM WS-OUTPUT-LINE
           IF WS-REJECTED-STATUS NOT = "00"
               DISPLAY "エラー=拒否WRITE " WS-REJECTED-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
      *オープン済みのファイルだけを閉じ、状態を確認します。
      *ログを閉じる前にバッチ完了イベントを記録します。
       8000-CLOSE-FILES.
           IF WS-ACCOUNT-OPEN = "Y"
               CLOSE ACCOUNT-FILE
               IF WS-ACCOUNT-STATUS NOT = "00"
                   DISPLAY "エラー=口座ファイルクローズ "
                           WS-ACCOUNT-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-TRANSACTION-OPEN = "Y"
               CLOSE TRANSACTION-FILE
               IF WS-TRANSACTION-STATUS NOT = "00"
                   DISPLAY "エラー=取引ファイルクローズ "
                           WS-TRANSACTION-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-ACCEPTED-OPEN = "Y"
               CLOSE ACCEPTED-FILE
               IF WS-ACCEPTED-STATUS NOT = "00"
                   DISPLAY "エラー=受理出力クローズ "
                           WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-REJECTED-OPEN = "Y"
               CLOSE REJECTED-FILE
               IF WS-REJECTED-STATUS NOT = "00"
                   DISPLAY "エラー=拒否出力クローズ "
                           WS-REJECTED-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF
           IF WS-LOG-OPEN = "Y"
               MOVE "EVENT=POSTING_COMPLETE" TO WS-LOG-LINE
               PERFORM 8200-WRITE-LOG
               CLOSE LOG-FILE
               IF WS-LOG-STATUS NOT = "00"
                   DISPLAY "エラー=ログCLOSE 状態=" WS-LOG-STATUS
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
      *ログ書込みを集約し、同じ状態確認を一貫して行います。
       8200-WRITE-LOG.
           MOVE WS-LOG-LINE TO LOG-RECORD
           WRITE LOG-RECORD
           IF WS-LOG-STATUS NOT = "00"
               DISPLAY "エラー=ログ書込 状態=" WS-LOG-STATUS
               MOVE "Y" TO WS-FAILED
           END-IF.
