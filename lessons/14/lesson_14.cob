      * Lesson 14: match typed transactions against account records.
      * 第 14 课：将输入的交易与帐户记录进行匹配。
      * レッスン 14: 型指定されたトランザクションを口座レコードと照合します。
      * Account records are grouped in a hierarchy and kept in a table.
      * 帐户记录按层次结构分组并保存在表中。
      * 取引先レコードは階層的にグループ化され、テーブルに保持されます。
      * Transaction payloads share storage through REDEFINES.
      * 交易有效负载通过 REDEFINES 共享存储。
      * トランザクション ペイロードは、REDEFINES を通じてストレージを共有します。
      * SEARCH ALL associates transaction account keys with master data.
      * SEARCH ALL 将交易帐户密钥与主数据相关联。
      * SEARCH ALL は、トランザクション アカウント キーをマスター データに関連付けます。
      * Deposit and transfer layouts have equal storage size.
      * 存款和转账布局具有相同的存储大小。
      * 入金レイアウトと転送レイアウトのストレージ サイズは同じです。
      * Transfers check both accounts before changing any balance.
      * 在更改任何余额之前，转账会检查两个帐户。
      * 送金では、残高を変更する前に両方のアカウントを確認します。
      * The master table is actually in ascending account-key order.
      * 主表实际上是按帐户密钥升序排列的。
      * マスター テーブルは、実際にはアカウント キーの昇順になっています。
      * This fixed-data batch uses no files or database.
      * 此固定数据批次不使用文件或数据库。
      * この固定データ バッチでは、ファイルやデータベースは使用されません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MATCH14.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Account identity and balance form one repeated master record.
      * 账户身份和余额形成一份重复的主记录。
      * アカウントの ID と残高は、1 つの反復されたマスター レコードを形成します。
       01 WS-ACCOUNT-TABLE.
          05 WS-ACCOUNT-ENTRY OCCURS 3 TIMES
             ASCENDING KEY IS WS-ACCOUNT-NUMBER
             INDEXED BY WS-ACCOUNT-IDX.
             10 WS-ACCOUNT-INFO.
                15 WS-ACCOUNT-NUMBER PIC X(10).
                15 WS-ACCOUNT-BALANCE PIC 9(7)V99.
      * Each transaction has a type followed by a shared payload area.
      * 每个事务都有一个类型，后跟一个共享有效负载区域。
      * 各トランザクションにはタイプがあり、その後に共有ペイロード領域が続きます。
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
       01 WS-REJECTED-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
      * Load both in-memory data sets before processing any transaction.
      * 在处理任何事务之前加载两个内存数据集。
      * トランザクションを処理する前に、両方のメモリ内データ セットをロードします。
       0000-MAIN.
           PERFORM 1000-LOAD-ACCOUNTS
           PERFORM 1100-LOAD-TRANSACTIONS
           DISPLAY "BATCH=START ACCOUNTS=3 TRANSACTIONS=4"
           PERFORM VARYING WS-TRANSACTION-NUMBER FROM 1 BY 1
               UNTIL WS-TRANSACTION-NUMBER > 4
               PERFORM 2000-PROCESS-TRANSACTION
               ADD 1 TO WS-PROCESSED-COUNT
           END-PERFORM
           PERFORM 9000-REPORT
           STOP RUN.
      * Entries are loaded in the actual ascending key order.
      * 条目按实际的升序键顺序加载。
      * エントリは実際のキーの昇順でロードされます。
       1000-LOAD-ACCOUNTS.
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER(1)
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE(1)
           MOVE "0002468101" TO WS-ACCOUNT-NUMBER(2)
           MOVE 200.00 TO WS-ACCOUNT-BALANCE(2)
           MOVE "0007654321" TO WS-ACCOUNT-NUMBER(3)
           MOVE 50.00 TO WS-ACCOUNT-BALANCE(3).
      * Deposit and transfer payloads occupy the same 27 characters.
      * 存款和转账有效负载占用相同的 27 个字符。
      * 入金ペイロードと転送ペイロードは同じ 27 文字を占めます。
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
      * The transaction code determines which payload view is active.
      * 事务代码确定哪个有效负载视图处于活动状态。
      * トランザクション コードによって、どのペイロード ビューがアクティブになるかが決まります。
       2000-PROCESS-TRANSACTION.
           DISPLAY "TXN=" WS-TRANSACTION-NUMBER
               " TYPE=" WS-TRANSACTION-CODE(WS-TRANSACTION-NUMBER)
           EVALUATE WS-TRANSACTION-CODE(WS-TRANSACTION-NUMBER)
               WHEN "D"
                   PERFORM 2100-POST-DEPOSIT
               WHEN "T"
                   PERFORM 2200-POST-TRANSFER
               WHEN OTHER
                   DISPLAY "RESULT=REJECTED REASON=UNKNOWN_TYPE"
                   ADD 1 TO WS-REJECTED-COUNT
           END-EVALUATE.
      * A deposit changes one matched account balance.
      * 一笔存款会改变一个匹配的账户余额。
      * デポジットにより、一致する 1 つのアカウント残高が変更されます。
       2100-POST-DEPOSIT.
           MOVE WS-DEPOSIT-ACCOUNT(WS-TRANSACTION-NUMBER)
               TO WS-SEARCH-KEY
           PERFORM 3000-FIND-ACCOUNT
           IF WS-ACCOUNT-FOUND = "Y"
               COMPUTE WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX) =
                   WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
                       + WS-DEPOSIT-AMOUNT(WS-TRANSACTION-NUMBER)
               DISPLAY "RESULT=POSTED DEPOSIT ACCOUNT="
                   WS-DEPOSIT-ACCOUNT(WS-TRANSACTION-NUMBER)
                   " AMOUNT="
                   WS-DEPOSIT-AMOUNT(WS-TRANSACTION-NUMBER)
               ADD 1 TO WS-POSTED-COUNT
           ELSE
               DISPLAY "RESULT=REJECTED REASON=ACCOUNT_NOT_FOUND"
               ADD 1 TO WS-REJECTED-COUNT
           END-IF.
      * Validate both transfer accounts before applying either balance.
      * 在应用任一余额之前验证两个转账帐户。
      * いずれかの残高を適用する前に、両方の振込口座を検証してください。
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
                       DISPLAY "RESULT=POSTED TRANSFER SOURCE="
                           WS-SOURCE-ACCOUNT(WS-TRANSACTION-NUMBER)
                           " TARGET="
                           WS-TARGET-ACCOUNT(WS-TRANSACTION-NUMBER)
                       ADD 1 TO WS-POSTED-COUNT
                   ELSE
                       DISPLAY "RESULT=REJECTED"
                           " REASON=INSUFFICIENT_FUNDS"
                       ADD 1 TO WS-REJECTED-COUNT
                   END-IF
               ELSE
                   DISPLAY "RESULT=REJECTED"
                       " REASON=TARGET_NOT_FOUND"
                   ADD 1 TO WS-REJECTED-COUNT
               END-IF
           ELSE
               DISPLAY "RESULT=REJECTED"
                   " REASON=SOURCE_NOT_FOUND"
               ADD 1 TO WS-REJECTED-COUNT
           END-IF.
      * SEARCH ALL uses the unique ascending account key.
      * SEARCH ALL 使用唯一的升序帐户密钥。
      * SEARCH ALL では、一意の昇順アカウント キーが使用されます。
       3000-FIND-ACCOUNT.
           MOVE "N" TO WS-ACCOUNT-FOUND
           SEARCH ALL WS-ACCOUNT-ENTRY
               AT END
                   CONTINUE
               WHEN WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                   = WS-SEARCH-KEY
                   MOVE "Y" TO WS-ACCOUNT-FOUND
           END-SEARCH.
      * Report each account balance and batch outcome counts.
      * 报告每个帐户余额和批次结果计数。
      * 各アカウントの残高とバッチ結果の数をレポートします。
       9000-REPORT.
           DISPLAY "BALANCE ACCOUNT=" WS-ACCOUNT-NUMBER(1)
               " VALUE=" WS-ACCOUNT-BALANCE(1)
           DISPLAY "BALANCE ACCOUNT=" WS-ACCOUNT-NUMBER(2)
               " VALUE=" WS-ACCOUNT-BALANCE(2)
           DISPLAY "BALANCE ACCOUNT=" WS-ACCOUNT-NUMBER(3)
               " VALUE=" WS-ACCOUNT-BALANCE(3)
           DISPLAY "SUMMARY PROCESSED=" WS-PROCESSED-COUNT
               " POSTED=" WS-POSTED-COUNT
               " REJECTED=" WS-REJECTED-COUNT.
