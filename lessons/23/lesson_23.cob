      * Lesson 23: import shared account and transaction declarations.
      * 第23课：导入共享的账户和交易声明。
      * レッスン23：共有の口座と取引の宣言をインポートします。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON23.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * COPY inserts declarations here during compilation.
      * 编译期间，COPY会在此处插入声明。
      * コンパイル時に、COPYがここへ宣言を挿入します。
       COPY "ACCOUNT-REC.CPY".
       COPY "TRANSACTION-REC.CPY".
       01 WS-POST-STATUS PIC X(12) VALUE SPACES.
       01 WS-POSTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-EDITED-AMOUNT PIC 9(7).99 VALUE ZERO.
       01 WS-EDITED-BALANCE PIC 9(7).99 VALUE ZERO.
       PROCEDURE DIVISION.
      * Run two valid postings followed by three rejected examples.
      * 先运行两个有效入账示例，再运行三个被拒绝的示例。
      * 有効な記帳を2件実行し、その後に拒否される例を3件実行します。
       0000-MAIN.
           PERFORM 1000-INITIALIZE-RECORDS
           PERFORM 1100-POST-DEPOSIT
           PERFORM 1200-POST-WITHDRAWAL
           PERFORM 1300-POST-OVERDRAFT
           PERFORM 1400-POST-UNKNOWN-TYPE
           PERFORM 1500-POST-MISSING-ACCOUNT
           PERFORM 3000-DISPLAY-SUMMARY
           STOP RUN.
      * Initialize the shared account record once for this batch.
      * 此批次只初始化一次共享账户记录。
      * このバッチでは共有口座レコードを1回だけ初期化します。
       1000-INITIALIZE-RECORDS.
           MOVE "A000000001" TO WS-ACCOUNT-NUMBER
           MOVE "C0001001" TO WS-CUSTOMER-ID
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE
           MOVE WS-ACCOUNT-NUMBER TO WS-TRANSACTION-ACCOUNT.
      * These paragraphs populate the shared transaction record.
      * 这些段落用于填充共享交易记录。
      * これらの段落で共有取引レコードを設定します。
       1100-POST-DEPOSIT.
           MOVE "D" TO WS-TRANSACTION-TYPE
           MOVE 125.50 TO WS-TRANSACTION-AMOUNT
           PERFORM 2000-POST-TRANSACTION.
       1200-POST-WITHDRAWAL.
           MOVE "C" TO WS-TRANSACTION-TYPE
           MOVE 25.25 TO WS-TRANSACTION-AMOUNT
           PERFORM 2000-POST-TRANSACTION.
       1300-POST-OVERDRAFT.
           MOVE "C" TO WS-TRANSACTION-TYPE
           MOVE 2000.00 TO WS-TRANSACTION-AMOUNT
           PERFORM 2000-POST-TRANSACTION.
       1400-POST-UNKNOWN-TYPE.
           MOVE "X" TO WS-TRANSACTION-TYPE
           MOVE 1.00 TO WS-TRANSACTION-AMOUNT
           PERFORM 2000-POST-TRANSACTION.
       1500-POST-MISSING-ACCOUNT.
           MOVE "A000000099" TO WS-TRANSACTION-ACCOUNT
           MOVE "D" TO WS-TRANSACTION-TYPE
           MOVE 1.00 TO WS-TRANSACTION-AMOUNT
           PERFORM 2000-POST-TRANSACTION.
      * Match, validate and post one transaction without reading a file.
      * 无需读取文件即可匹配、验证并入账一笔交易。
      * ファイルを読み込まずに、取引を照合、検証、記帳します。
       2000-POST-TRANSACTION.
           MOVE SPACES TO WS-POST-STATUS
           IF WS-TRANSACTION-ACCOUNT NOT = WS-ACCOUNT-NUMBER
               MOVE "NO_ACCOUNT" TO WS-POST-STATUS
           ELSE
               PERFORM 2100-VALIDATE-AND-POST
           END-IF
           PERFORM 2900-REPORT-TRANSACTION.
      * The type code selects the arithmetic performed on the balance.
      * 类型代码决定对余额执行的算术运算。
      * タイプコードで残高に対して行う算術演算を選択します。
       2100-VALIDATE-AND-POST.
           EVALUATE WS-TRANSACTION-TYPE
               WHEN "D"
                   ADD WS-TRANSACTION-AMOUNT
                       TO WS-ACCOUNT-BALANCE
                   MOVE "POSTED" TO WS-POST-STATUS
               WHEN "C"
                   PERFORM 2200-CHECK-WITHDRAWAL
               WHEN OTHER
                   MOVE "BAD_TYPE" TO WS-POST-STATUS
           END-EVALUATE.
      * A failed withdrawal leaves the account balance unchanged.
      * 取款失败时账户余额保持不变。
      * 引き出しに失敗しても口座残高は変わりません。
       2200-CHECK-WITHDRAWAL.
           IF WS-TRANSACTION-AMOUNT <= WS-ACCOUNT-BALANCE
               SUBTRACT WS-TRANSACTION-AMOUNT
                   FROM WS-ACCOUNT-BALANCE
               MOVE "POSTED" TO WS-POST-STATUS
           ELSE
               MOVE "INSUFFICIENT" TO WS-POST-STATUS
           END-IF.
      * Count and display every attempted transaction exactly once.
      * 每笔尝试处理的交易都只计数并显示一次。
      * 試行した各取引を、1回だけカウントして表示します。
       2900-REPORT-TRANSACTION.
           MOVE WS-TRANSACTION-AMOUNT TO WS-EDITED-AMOUNT
           IF WS-POST-STATUS = "POSTED"
               ADD 1 TO WS-POSTED-COUNT
               DISPLAY "RESULT=POSTED TYPE=" WS-TRANSACTION-TYPE
                   " AMOUNT=" WS-EDITED-AMOUNT
           ELSE
               ADD 1 TO WS-REJECTED-COUNT
               DISPLAY "RESULT=REJECTED STATUS="
                   FUNCTION TRIM(WS-POST-STATUS TRAILING)
           END-IF.
      * Report the shared account fields and batch totals.
      * 报告共享账户字段和批次总计。
      * 共有口座フィールドとバッチ合計を報告します。
       3000-DISPLAY-SUMMARY.
           MOVE WS-ACCOUNT-BALANCE TO WS-EDITED-BALANCE
           DISPLAY "ACCOUNT=" WS-ACCOUNT-NUMBER
               " CUSTOMER=" WS-CUSTOMER-ID
               " BALANCE=" WS-EDITED-BALANCE
           DISPLAY "SUMMARY POSTED=" WS-POSTED-COUNT
               " REJECTED=" WS-REJECTED-COUNT.
