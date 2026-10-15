      * 第 08 课：运行小型固定数据帐户交易批次。
      * 本课程结合了领域、数学、IF、EVALUATE 和 PERFORM。
      * 命名段落将设置、处理和报告分开。
      * 五个固定交易执行接受和拒绝路径。
      * 这里不使用文件、数据库、表或终端输入。
      * D 贷记余额；当资金充足时，W 将其记入借方。
      * 其他交易代码会被拒绝，以便后续审查。
      * 在此示例中，所有金额均使用两个小数位置。
      * 这是一个学习批次，而不是生产分类帐系统。
      * 它的输入和输出在运行过程中保持确定性。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCH08.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 处理样本批次之前的初始帐户余额。
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-CURRENT-BALANCE PIC 9(7)V99 VALUE ZERO.
      * 样本索引和最后一个索引控制内联 PERFORM 循环。
       01 WS-SAMPLE-INDEX PIC 9(3) VALUE ZERO.
       01 WS-LAST-SAMPLE PIC 9 VALUE 5.
      * 当前的示例代码和数量会在每次循环时加载。
       01 WS-TRANSACTION-CODE PIC X VALUE SPACE.
       01 WS-TRANSACTION-AMOUNT PIC S9(5)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE ZERO.
      * 计数器区分已处理、已接受和已拒绝的记录。
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCEPTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Main 按依赖顺序调用三个批处理阶段。
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-BATCH
           PERFORM 9000-REPORT
           STOP RUN.
      * 在处理之前初始化共享余额和计数器。
       1000-INITIALIZE.
           MOVE WS-OPENING-BALANCE TO WS-CURRENT-BALANCE
           MOVE ZERO TO WS-PROCESSED-COUNT
           MOVE ZERO TO WS-ACCEPTED-COUNT
           MOVE ZERO TO WS-REJECTED-COUNT
           DISPLAY "批次=START"
           DISPLAY "期初余额=" WS-OPENING-BALANCE.
      * 使用样本编号按顺序处理每个固定记录。
       2000-PROCESS-BATCH.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               PERFORM 2100-LOAD-SAMPLE
               PERFORM 2200-CLASSIFY-AND-POST
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM.
      * 加载与每个样本编号相关的代码和数量。
       2100-LOAD-SAMPLE.
           EVALUATE WS-SAMPLE-INDEX
               WHEN 1
                   MOVE "D" TO WS-TRANSACTION-CODE
                   MOVE 125.50 TO WS-TRANSACTION-AMOUNT
               WHEN 2
                   MOVE "W" TO WS-TRANSACTION-CODE
                   MOVE 40.10 TO WS-TRANSACTION-AMOUNT
               WHEN 3
                   MOVE "W" TO WS-TRANSACTION-CODE
                   MOVE 1500.00 TO WS-TRANSACTION-AMOUNT
               WHEN 4
                   MOVE "D" TO WS-TRANSACTION-CODE
                   MOVE -5.00 TO WS-TRANSACTION-AMOUNT
               WHEN 5
                   MOVE "X" TO WS-TRANSACTION-CODE
                   MOVE 25.00 TO WS-TRANSACTION-AMOUNT
               WHEN OTHER
                   MOVE "X" TO WS-TRANSACTION-CODE
                   MOVE ZERO TO WS-TRANSACTION-AMOUNT
           END-EVALUATE
           DISPLAY "记录=" WS-SAMPLE-INDEX
               " 代码=" WS-TRANSACTION-CODE
               " 金额=" WS-TRANSACTION-AMOUNT.
      * 对当前记录进行分类并仅应用接受的金额。
       2200-CLASSIFY-AND-POST.
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   IF WS-TRANSACTION-AMOUNT > ZERO
                       COMPUTE WS-CURRENT-BALANCE =
                           WS-CURRENT-BALANCE
                               + WS-TRANSACTION-AMOUNT
                       COMPUTE WS-ACCEPTED-COUNT =
                           WS-ACCEPTED-COUNT + 1
                       DISPLAY "结果=ACCEPTED 原因=DEPOSIT"
                   ELSE
                       COMPUTE WS-REJECTED-COUNT =
                           WS-REJECTED-COUNT + 1
                       DISPLAY "结果=REJECTED"
                           " 原因=AMOUNT_NOT_POSITIVE"
                   END-IF
               WHEN "W"
                   IF WS-TRANSACTION-AMOUNT > ZERO
                       IF WS-TRANSACTION-AMOUNT
                           <= WS-CURRENT-BALANCE
                           COMPUTE WS-CURRENT-BALANCE =
                               WS-CURRENT-BALANCE
                                   - WS-TRANSACTION-AMOUNT
                           COMPUTE WS-ACCEPTED-COUNT =
                               WS-ACCEPTED-COUNT + 1
                           DISPLAY "结果=ACCEPTED"
                               " 原因=WITHDRAWAL"
                       ELSE
                           COMPUTE WS-REJECTED-COUNT =
                               WS-REJECTED-COUNT + 1
                           DISPLAY "结果=REJECTED"
                               " 原因=INSUFFICIENT_FUNDS"
                       END-IF
                   ELSE
                       COMPUTE WS-REJECTED-COUNT =
                           WS-REJECTED-COUNT + 1
                       DISPLAY "结果=REJECTED"
                           " 原因=AMOUNT_NOT_POSITIVE"
                   END-IF
               WHEN OTHER
                   COMPUTE WS-REJECTED-COUNT =
                       WS-REJECTED-COUNT + 1
                   DISPLAY "结果=REJECTED"
                       " 原因=UNKNOWN_TRANSACTION_CODE"
           END-EVALUATE.
      * 完成样本批次后报告总计和余额。
       9000-REPORT.
           DISPLAY "已处理数=" WS-PROCESSED-COUNT
           DISPLAY "已接受数=" WS-ACCEPTED-COUNT
           DISPLAY "已拒绝数=" WS-REJECTED-COUNT
           DISPLAY "最终余额=" WS-CURRENT-BALANCE.
      * 主段落是程序唯一的入口执行序列。
      * 每个 PERFORM 返回到其段落调用之后的语句。
      * 该流程段落使用 PERFORM VARYING 进行记录迭代。
      * 加载段落将固定数据与业务规则分开。
      * EVALUATE 将样本索引映射到其固定代码和数量。
      * 第二个 EVALUATE 选择存款、取款或未知逻辑。
      * IF 在过账前检查正金额和可用资金。
      * 被拒绝的记录会增加计数并保持余额不变。
      * 已接受的记录会同时更改余额和已接受的计数。
      * 每完成一条记录后，处理的计数就会增加一次。
      * 五个记录产生两个接受的结果和三个拒绝的结果。
      * 信贷将余额从 1000.00 提高到 1125.50。
      * 有效取款使余额降至 1085.40。
      * 巨额提款将被拒绝，且余额不会改变。
      * 在余额更改之前，负存款将被拒绝。
      * 未知代码被拒绝，且不会入账其金额。
      * 计数器报告记录结果，而不是会计分录。
      * 初始化在每个事务处理步骤之前进行。
      * 处理段落返回后，报告段落读取共享计数和余额。
      * 每个段落的最后一句话都以句号结束。
      * EVALUATE 嵌入示例直到表格课程。
      * 后面的课程将样本存储在可重用的数据结构中。
      * 生产批次还需要文件状态和重新启动处理。
      * 定义并发性和幂等性的生产规则。
      * STOP RUN 结束这个集成的语言基础示例。
