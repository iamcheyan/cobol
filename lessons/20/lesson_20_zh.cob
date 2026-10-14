      * 第20课：按账户号码匹配两个已排序的账户文件。
      * 主记录为27个字符；交易记录为20个字符。
      * 每个输入文件都按十字符键升序排列。
      * 归并过程将记录分类为匹配或仅存在于一侧。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MATCH20.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-MASTER
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT DAILY-TRANSACTIONS
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-MASTER.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
       FD DAILY-TRANSACTIONS.
       01 FD-TRANSACTION-RECORD.
          05 FD-TRANSACTION-ACCOUNT PIC X(10).
          05 FD-TRANSACTION-TYPE PIC X.
          05 FD-TRANSACTION-AMOUNT PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-TRANSACTION-STATUS PIC XX VALUE SPACES.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-MATCH-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT-ONLY-COUNT PIC 9(3) VALUE ZERO.
       01 WS-TRANSACTION-ONLY-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * 定位任一流之前先打开两个已排序的输入文件。
       0000-MAIN.
           OPEN INPUT ACCOUNT-MASTER
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN INPUT DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "OPEN=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               CLOSE ACCOUNT-MASTER
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=ACCOUNT OK OPEN=TRANSACTION OK"
           PERFORM 1000-READ-ACCOUNT
           PERFORM 2000-READ-TRANSACTION
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y"
               AND WS-TRANSACTION-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 3000-MATCH-CURRENT-RECORDS
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 比较当前键，并推进键值较小或相等的流。
       3000-MATCH-CURRENT-RECORDS.
           EVALUATE TRUE
               WHEN WS-ACCOUNT-EOF = "Y"
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN WS-TRANSACTION-EOF = "Y"
                   PERFORM 4000-REPORT-ACCOUNT-ONLY
                   PERFORM 1000-READ-ACCOUNT
               WHEN FD-ACCOUNT-NUMBER < FD-TRANSACTION-ACCOUNT
                   PERFORM 4000-REPORT-ACCOUNT-ONLY
                   PERFORM 1000-READ-ACCOUNT
               WHEN FD-ACCOUNT-NUMBER > FD-TRANSACTION-ACCOUNT
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN OTHER
                   PERFORM 4200-REPORT-MATCH
                   PERFORM 1000-READ-ACCOUNT
                   IF WS-IO-ERROR = "N"
                       PERFORM 2000-READ-TRANSACTION
                   END-IF
           END-EVALUATE.
      * 读取下一条主记录，或仅将此流标记为EOF。
       1000-READ-ACCOUNT.
           READ ACCOUNT-MASTER
               AT END
                   MOVE "Y" TO WS-ACCOUNT-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-ACCOUNT-STATUS NOT = "00"
               AND WS-ACCOUNT-STATUS NOT = "10"
               DISPLAY "READ=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * 读取下一条交易记录，或仅将此流标记为EOF。
       2000-READ-TRANSACTION.
           READ DAILY-TRANSACTIONS
               AT END
                   MOVE "Y" TO WS-TRANSACTION-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-TRANSACTION-STATUS NOT = "00"
               AND WS-TRANSACTION-STATUS NOT = "10"
               DISPLAY "READ=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * 主键排序位置早于当前交易键。
       4000-REPORT-ACCOUNT-ONLY.
           ADD 1 TO WS-ACCOUNT-ONLY-COUNT
           DISPLAY "ACCOUNT_ONLY ACCOUNT=" FD-ACCOUNT-NUMBER
               " CUSTOMER=" FD-CUSTOMER-ID
               " BALANCE=" FD-ACCOUNT-BALANCE.
      * 交易键排序位置早于当前主键。
       4100-REPORT-TRANSACTION-ONLY.
           ADD 1 TO WS-TRANSACTION-ONLY-COUNT
           DISPLAY "TRANSACTION_ONLY ACCOUNT="
               FD-TRANSACTION-ACCOUNT
               " TYPE=" FD-TRANSACTION-TYPE
               " AMOUNT=" FD-TRANSACTION-AMOUNT.
      * 相等的键标识一个账户及其每日交易。
       4200-REPORT-MATCH.
           ADD 1 TO WS-MATCH-COUNT
           DISPLAY "MATCH ACCOUNT=" FD-ACCOUNT-NUMBER
               " CUSTOMER=" FD-CUSTOMER-ID
               " BALANCE=" FD-ACCOUNT-BALANCE
               " TYPE=" FD-TRANSACTION-TYPE
               " AMOUNT=" FD-TRANSACTION-AMOUNT.
      * 关闭两个输入文件并报告三类记录的数量。
       9000-CLOSE-FILES.
           CLOSE ACCOUNT-MASTER
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "CLOSE=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "CLOSE=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "SUMMARY MATCHED=" WS-MATCH-COUNT
               " ACCOUNT_ONLY=" WS-ACCOUNT-ONLY-COUNT
               " TRANSACTION_ONLY=" WS-TRANSACTION-ONLY-COUNT.
      * 两个样例文件都按账户键升序排列。
      * 主键是十字符账户号码。
      * 交易键也是相同的十字符账户号码。
      * 主键较小时，表示没有交易键与之匹配。
      * 交易键较小时，表示没有主键与之匹配。
      * 相等的键会将一对记录分类为匹配。
      * 匹配后，两个输入流各推进一次。
      * 遇到仅存在于一侧的记录后，只推进该侧。
      * 一侧到达EOF后，另一侧剩余记录均为孤立记录。
      * 每个流都有独立的状态和EOF状态。
      * 状态10表示正常EOF；其他读取错误会停止归并。
      * AT END处理其后READ语句的EOF。
      * 检查FILE STATUS以区分其他读取失败。
      * 账户余额和交易金额都使用隐含分表示。
      * 此示例报告数值，但不计算新余额。
      * 重复键不在本课每个键对应一行的规则范围内。
      * 输入未排序会使顺序比较算法失效。
      * 请先按相同的账户键排序规则对两个文件排序。
      * 键字段长度相同，并按文本比较。
      * 前导零是这些账户键的重要组成部分。
      * 主记录和交易记录布局都是定宽文本行。
      * 每个物理行包含一条记录，字段之间没有分隔符。
      * FD记录长度与样例行长度相同。
      * 两个文件都是必需的，且必须成功打开。
      * 如果第二个OPEN失败，则关闭第一个输入文件。
      * READ成功时只推进该READ所指定的文件。
      * 无论行数多少，归并过程使用的工作存储量都固定。
      * 不会用OCCURS表将整个输入文件存入内存。
      * 这是顺序归并，不是对两个文件进行嵌套搜索。
      * 运行时间随输入记录总数增长。
      * 输出标签区分匹配以及两种方向的孤立记录。
      * 每个输入至多为匹配对贡献一行。
      * 比较前先检查EOF，再引用当前键。
      * 空文件对应的一侧产生零条记录。
      * 摘要统计分类结果，而非读取尝试次数。
      * 程序不会写入或更改任一样例输入文件。
      * 后续课程将增加排序和完整的批处理输出文件。
      * 请在此处运行，以便两个ASSIGN路径都能找到样例文件。
      * 发生I/O错误后，程序会返回非零状态。
      * 样例包含匹配记录、仅主文件记录和孤立记录。
      * 一条仅交易文件存在的记录排序在两个主键之间。
      * 另一条仅交易文件存在的记录在主文件EOF后仍然剩余。
      * 样例涵盖两个键的大小方向以及EOF处理。
      * STOP RUN将批处理状态码返回给操作系统。
