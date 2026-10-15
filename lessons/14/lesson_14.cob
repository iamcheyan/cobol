      *レッスン 14: 型指定されたトランザクションを口座レコードと照合します。
      *取引先レコードは階層的にグループ化され、テーブルに保持されます。
      *トランザクション ペイロードは、REDEFINES を通じてストレージを共有します。
      *SEARCH ALL は、トランザクション アカウント キーをマスター データに関連付けます。
      *入金レイアウトと転送レイアウトのストレージ サイズは同じです。
      *送金では、残高を変更する前に両方のアカウントを確認します。
      *マスター テーブルは、実際にはアカウント キーの昇順になっています。
      *この固定データ バッチでは、ファイルやデータベースは使用されません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MATCH14.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *アカウントの ID と残高は、1 つの反復されたマスター レコードを形成します。
       01 WS-ACCOUNT-TABLE.
          05 WS-ACCOUNT-ENTRY OCCURS 3 TIMES
             ASCENDING KEY IS WS-ACCOUNT-NUMBER
             INDEXED BY WS-ACCOUNT-IDX.
             10 WS-ACCOUNT-INFO.
                15 WS-ACCOUNT-NUMBER PIC X(10).
                15 WS-ACCOUNT-BALANCE PIC 9(7)V99.
      *各トランザクションにはタイプがあり、その後に共有ペイロード領域が続きます。
       01 WS-TRANSACTION-TABLE.
          05 WS-TRANSACTION-ENTRY OCCURS 4 TIMES.
             10 WS-TRANSACTION-CODE PIC X.
             10 WS-DEPOSIT-VIEW.
                15 WS-DEPOSIT-ACCOUNT PIC X(10).
                15 WS-DEPOSIT-AMOUNT PIC 9(5)V99.
                15 WS-DEPOSIT-REFERENCE PIC X(10).
             10 WS-TRANSFER-VIEW REDEFINES WS-DEPOSIT-VIEW.
                15 WS-SOURCE-ACCOUNT PIC X(10).
                15 WS-TARGET-ACCOUNT PIC X(10).
                15 WS-TRANSFER-AMOUNT PIC 9(5)V99.
       01 WS-TRANSACTION-NUMBER PIC 9 VALUE ZERO.
       01 WS-SEARCH-KEY PIC X(10) VALUE SPACES.
       01 WS-ACCOUNT-FOUND PIC X VALUE "N".
       01 WS-SOURCE-INDEX USAGE INDEX.
       01 WS-PROCESSED-COUNT PIC 9(2) VALUE ZERO.
       01 WS-POSTED-COUNT PIC 9(2) VALUE ZERO.
       01 WS-拒否-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
      *トランザクションを処理する前に、両方のメモリ内データ セットをロードします。
       0000-MAIN.
           PERFORM 1000-LOAD-ACCOUNTS
           PERFORM 1100-LOAD-TRANSACTIONS
           DISPLAY "バッチ=START 口座数=3 取引数=4"
           PERFORM VARYING WS-TRANSACTION-NUMBER FROM 1 BY 1
               UNTIL WS-TRANSACTION-NUMBER > 4
               PERFORM 2000-PROCESS-TRANSACTION
               ADD 1 TO WS-PROCESSED-COUNT
           END-PERFORM
           PERFORM 9000-REPORT
           STOP RUN.
      *エントリは実際のキーの昇順でロードされます。
       1000-LOAD-ACCOUNTS.
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER(1)
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE(1)
           MOVE "0002468101" TO WS-ACCOUNT-NUMBER(2)
           MOVE 200.00 TO WS-ACCOUNT-BALANCE(2)
           MOVE "0007654321" TO WS-ACCOUNT-NUMBER(3)
           MOVE 50.00 TO WS-ACCOUNT-BALANCE(3).
      *入金ペイロードと転送ペイロードは同じ 27 文字を占めます。
       1100-LOAD-TRANSACTIONS.
           MOVE "D" TO WS-TRANSACTION-CODE(1)
           MOVE "0001234567" TO WS-DEPOSIT-ACCOUNT(1)
           MOVE 125.50 TO WS-DEPOSIT-AMOUNT(1)
           MOVE "DEP-000001" TO WS-DEPOSIT-REFERENCE(1)
           MOVE "T" TO WS-TRANSACTION-CODE(2)
           MOVE "0001234567" TO WS-SOURCE-ACCOUNT(2)
           MOVE "0007654321" TO WS-TARGET-ACCOUNT(2)
           MOVE 40.00 TO WS-TRANSFER-AMOUNT(2)
           MOVE "D" TO WS-TRANSACTION-CODE(3)
           MOVE "0002468101" TO WS-DEPOSIT-ACCOUNT(3)
           MOVE 75.00 TO WS-DEPOSIT-AMOUNT(3)
           MOVE "DEP-000003" TO WS-DEPOSIT-REFERENCE(3)
           MOVE "T" TO WS-TRANSACTION-CODE(4)
           MOVE "0007654321" TO WS-SOURCE-ACCOUNT(4)
           MOVE "0009999999" TO WS-TARGET-ACCOUNT(4)
           MOVE 20.00 TO WS-TRANSFER-AMOUNT(4).
      *トランザクション コードによって、どのペイロード ビューがアクティブになるかが決まります。
       2000-PROCESS-TRANSACTION.
           DISPLAY "取引=" WS-TRANSACTION-NUMBER
               " 種別=" WS-TRANSACTION-CODE(WS-TRANSACTION-NUMBER)
           EVALUATE WS-TRANSACTION-CODE(WS-TRANSACTION-NUMBER)
               WHEN "D"
                   PERFORM 2100-POST-DEPOSIT
               WHEN "T"
                   PERFORM 2200-POST-TRANSFER
               WHEN OTHER
                   DISPLAY "結果=拒否 REASON=UNKNOWN_TYPE"
                   ADD 1 TO WS-拒否-COUNT
           END-EVALUATE.
      *デポジットにより、一致する 1 つのアカウント残高が変更されます。
       2100-POST-DEPOSIT.
           MOVE WS-DEPOSIT-ACCOUNT(WS-TRANSACTION-NUMBER)
               TO WS-SEARCH-KEY
           PERFORM 3000-FIND-ACCOUNT
           IF WS-ACCOUNT-FOUND = "Y"
               COMPUTE WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX) =
                   WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
                       + WS-DEPOSIT-AMOUNT(WS-TRANSACTION-NUMBER)
               DISPLAY "結果=POSTED 入金口座="
                   WS-DEPOSIT-ACCOUNT(WS-TRANSACTION-NUMBER)
                   " 金額="
                   WS-DEPOSIT-AMOUNT(WS-TRANSACTION-NUMBER)
               ADD 1 TO WS-POSTED-COUNT
           ELSE
               DISPLAY "結果=拒否 REASON=ACCOUNT_NOT_FOUND"
               ADD 1 TO WS-拒否-COUNT
           END-IF.
      *いずれかの残高を適用する前に、両方の振込口座を検証してください。
       2200-POST-TRANSFER.
           MOVE WS-SOURCE-ACCOUNT(WS-TRANSACTION-NUMBER)
               TO WS-SEARCH-KEY
           PERFORM 3000-FIND-ACCOUNT
           IF WS-ACCOUNT-FOUND = "Y"
               SET WS-SOURCE-INDEX TO WS-ACCOUNT-IDX
               MOVE WS-TARGET-ACCOUNT(WS-TRANSACTION-NUMBER)
                   TO WS-SEARCH-KEY
               PERFORM 3000-FIND-ACCOUNT
               IF WS-ACCOUNT-FOUND = "Y"
                   IF WS-ACCOUNT-BALANCE(WS-SOURCE-INDEX)
                       >= WS-TRANSFER-AMOUNT(WS-TRANSACTION-NUMBER)
                       COMPUTE WS-ACCOUNT-BALANCE(WS-SOURCE-INDEX) =
                           WS-ACCOUNT-BALANCE(WS-SOURCE-INDEX)
                               - WS-TRANSFER-AMOUNT(
                                   WS-TRANSACTION-NUMBER)
                       COMPUTE WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX) =
                           WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
                               + WS-TRANSFER-AMOUNT(
                                   WS-TRANSACTION-NUMBER)
                       DISPLAY "結果=POSTED 振込元口座="
                           WS-SOURCE-ACCOUNT(WS-TRANSACTION-NUMBER)
                           " 振込先口座="
                           WS-TARGET-ACCOUNT(WS-TRANSACTION-NUMBER)
                       ADD 1 TO WS-POSTED-COUNT
                   ELSE
                       DISPLAY "結果=拒否"
                           " REASON=INSUFFICIENT_FUNDS"
                       ADD 1 TO WS-拒否-COUNT
                   END-IF
               ELSE
                   DISPLAY "結果=拒否"
                       " REASON=TARGET_NOT_FOUND"
                   ADD 1 TO WS-拒否-COUNT
               END-IF
           ELSE
               DISPLAY "結果=拒否"
                   " REASON=SOURCE_NOT_FOUND"
               ADD 1 TO WS-拒否-COUNT
           END-IF.
      *SEARCH ALL では、一意の昇順アカウント キーが使用されます。
       3000-FIND-ACCOUNT.
           MOVE "N" TO WS-ACCOUNT-FOUND
           SEARCH ALL WS-ACCOUNT-ENTRY
               AT END
                   CONTINUE
               WHEN WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                   = WS-SEARCH-KEY
                   MOVE "Y" TO WS-ACCOUNT-FOUND
           END-SEARCH.
      *各アカウントの残高とバッチ結果の数をレポートします。
       9000-REPORT.
           DISPLAY "口座残高 口座=" WS-ACCOUNT-NUMBER(1)
               " 残高=" WS-ACCOUNT-BALANCE(1)
           DISPLAY "口座残高 口座=" WS-ACCOUNT-NUMBER(2)
               " 残高=" WS-ACCOUNT-BALANCE(2)
           DISPLAY "口座残高 口座=" WS-ACCOUNT-NUMBER(3)
               " 残高=" WS-ACCOUNT-BALANCE(3)
           DISPLAY "集計 処理件数=" WS-PROCESSED-COUNT
               " 成功=" WS-POSTED-COUNT
               " 拒否=" WS-拒否-COUNT.
