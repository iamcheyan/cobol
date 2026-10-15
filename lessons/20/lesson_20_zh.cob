      * 按账户键归并排序结果的账户主档和交易文件。
      * 主档契约为27字符，交易契约为20字符。两个输入都须按相同的十字符账户号升序排列；本例不处理重复键。
      * 主流程打开两个输入并比较当前键。较小的一侧单独前进；键相等时归类为匹配并同时推进两流。
      * 读取段落成功时更新当前记录，状态10只标记对应流的EOF。其他I/O错误会使本次运行失败。
      * 仅存在一侧的键归为孤立记录。一侧结束后，另一侧剩余记录逐条分类。访问当前键前先检查EOF；关闭两个输入后报告分类总数。
      * 输入保持不变，顺序归并只使用固定大小的工作区。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MATCH20.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT 账户号-MASTER
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-账户号-STATUS.
           SELECT DAILY-TRANSACTIONS
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD 账户号-MASTER.
       01 FD-账户号-RECORD.
          05 FD-账户号-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-账户号-BALANCE PIC 9(7)V99.
       FD DAILY-TRANSACTIONS.
       01 FD-TRANSACTION-RECORD.
          05 FD-TRANSACTION-账户号 PIC X(10).
          05 FD-TRANSACTION-TYPE PIC X.
          05 FD-TRANSACTION-AMOUNT PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-账户号-STATUS PIC XX VALUE SPACES.
       01 WS-TRANSACTION-STATUS PIC XX VALUE SPACES.
       01 WS-账户号-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-MATCH-COUNT PIC 9(3) VALUE ZERO.
       01 WS-账户号-ONLY-COUNT PIC 9(3) VALUE ZERO.
       01 WS-TRANSACTION-ONLY-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT 账户号-MASTER
           IF WS-账户号-STATUS NOT = "00"
               DISPLAY "无法打开账户文件 STATUS="
                   WS-账户号-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN INPUT DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "无法打开交易文件 STATUS="
                   WS-TRANSACTION-STATUS
               CLOSE 账户号-MASTER
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "账户与交易文件已打开"
           PERFORM 1000-READ-账户号
           PERFORM 2000-READ-TRANSACTION
           PERFORM UNTIL WS-账户号-EOF = "Y"
               AND WS-TRANSACTION-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 3000-MATCH-CURRENT-RECORDS
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       3000-MATCH-CURRENT-RECORDS.
           EVALUATE TRUE
               WHEN WS-账户号-EOF = "Y"
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN WS-TRANSACTION-EOF = "Y"
                   PERFORM 4000-REPORT-账户号-ONLY
                   PERFORM 1000-READ-账户号
               WHEN FD-账户号-NUMBER < FD-TRANSACTION-账户号
                   PERFORM 4000-REPORT-账户号-ONLY
                   PERFORM 1000-READ-账户号
               WHEN FD-账户号-NUMBER > FD-TRANSACTION-账户号
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN OTHER
                   PERFORM 4200-REPORT-MATCH
                   PERFORM 1000-READ-账户号
                   IF WS-IO-ERROR = "N"
                       PERFORM 2000-READ-TRANSACTION
                   END-IF
           END-EVALUATE.
       1000-READ-账户号.
           READ 账户号-MASTER
               AT END
                   MOVE "Y" TO WS-账户号-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-账户号-STATUS NOT = "00"
               AND WS-账户号-STATUS NOT = "10"
               DISPLAY "读取账户文件失败 STATUS="
                   WS-账户号-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       2000-READ-TRANSACTION.
           READ DAILY-TRANSACTIONS
               AT END
                   MOVE "Y" TO WS-TRANSACTION-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-TRANSACTION-STATUS NOT = "00"
               AND WS-TRANSACTION-STATUS NOT = "10"
               DISPLAY "读取交易文件失败 STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       4000-REPORT-账户号-ONLY.
           ADD 1 TO WS-账户号-ONLY-COUNT
           DISPLAY "仅账户 账户号=" FD-账户号-NUMBER
               " 客户号=" FD-CUSTOMER-ID
               " 余额=" FD-账户号-BALANCE.
       4100-REPORT-TRANSACTION-ONLY.
           ADD 1 TO WS-TRANSACTION-ONLY-COUNT
           DISPLAY "仅交易 账户号="
               FD-TRANSACTION-账户号
               " 类型=" FD-TRANSACTION-TYPE
               " 金额=" FD-TRANSACTION-AMOUNT.
       4200-REPORT-MATCH.
           ADD 1 TO WS-MATCH-COUNT
           DISPLAY "匹配 账户号=" FD-账户号-NUMBER
               " 客户号=" FD-CUSTOMER-ID
               " 余额=" FD-账户号-BALANCE
               " 类型=" FD-TRANSACTION-TYPE
               " 金额=" FD-TRANSACTION-AMOUNT.
       9000-CLOSE-FILES.
           CLOSE 账户号-MASTER
           IF WS-账户号-STATUS NOT = "00"
               DISPLAY "关闭账户文件失败 STATUS="
                   WS-账户号-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "关闭交易文件失败 STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "照合记录数=" WS-MATCH-COUNT
               " 仅账户=" WS-账户号-ONLY-COUNT
               " 仅交易=" WS-TRANSACTION-ONLY-COUNT.
