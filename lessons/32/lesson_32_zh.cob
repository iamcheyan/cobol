       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON32.
      * 中文：此程序协调完整的对账批次。
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 中文：工作模块共享这些完全一致的记录和计数器布局。
       COPY "BATCH-INTERFACE.CPY".
       01 WS-CHECK-COUNT PIC 999 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
      * 中文：重置账户表、计数器和工作模块错误标志。
           INITIALIZE WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           MOVE "N" TO WS-FAILED
      * 中文：读取账户主数据并应用交易流。
      * 中文：记账模块负责两个输入文件和业务规则。
           CALL "LOADPOST32" USING BY REFERENCE
               WS-ACCOUNT-TABLE WS-BATCH-COUNTS
      * 中文：文件故障后不要同步不完整的账户表。
           IF WS-FAILED NOT = "Y"
      * 中文：同步模块负责 SQLite、报表和数据库状态。
               CALL "SYNCDB32" USING BY REFERENCE
                   WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           END-IF
      * 中文：报告最终计数前先验证批次算术关系。
           PERFORM 3000-CHECK-COUNTS
           PERFORM 1000-REPORT-SUMMARY
           PERFORM 2000-RETURN-STATUS
           GOBACK.
       1000-REPORT-SUMMARY.
      * 中文：业务拒绝计为拒绝记录，不计为系统故障。
           DISPLAY "SUMMARY ACCOUNTS=" WS-ACCOUNT-COUNT
                   " TX=" WS-TRANSACTION-COUNT
                   " POSTED=" WS-POSTED-COUNT
                   " REJECTED=" WS-REJECTED-COUNT
                   " UPDATED=" WS-UPDATED-COUNT
                   " UNCHANGED=" WS-UNCHANGED-COUNT
                   " INSERTED=" WS-INSERTED-COUNT.
       2000-RETURN-STATUS.
      * 中文：只有发生系统故障时，shell 才会收到非零状态。
           IF WS-FAILED = "Y"
               MOVE 1 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
       3000-CHECK-COUNTS.
      * 中文：每笔读取的交易都必须记账或拒绝。
           COMPUTE WS-CHECK-COUNT =
               WS-POSTED-COUNT + WS-REJECTED-COUNT
           IF WS-CHECK-COUNT NOT = WS-TRANSACTION-COUNT
               DISPLAY "ERROR=TRANSACTION COUNT MISMATCH"
               MOVE "Y" TO WS-FAILED
           END-IF
      * 中文：同步成功时，每个已加载账户都恰好归类一次。
           IF WS-FAILED NOT = "Y"
               COMPUTE WS-CHECK-COUNT =
                   WS-UPDATED-COUNT + WS-UNCHANGED-COUNT
                   + WS-INSERTED-COUNT
               IF WS-CHECK-COUNT NOT = WS-ACCOUNT-COUNT
                   DISPLAY "ERROR=SYNC COUNT MISMATCH"
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
      * 中文：LOADPOST32 读取固定长度为 27 和 20 个字符的记录。
      * 中文：金额字段保存整数分，隐含小数点。
      * 中文：工作模块在共享表中最多保存二十个账户。
      * 中文：重复账户键会在记账开始前导致失败。
      * 中文：存款和允许的取款会更新此表。
      * 中文：透支以及未知交易类型或账户均属于业务拒绝。
      * 中文：业务拒绝不会改变最终账户余额。
      * 中文：接受和拒绝的记录分别写入不同的顺序文件。
      * 中文：批次日志记录每笔交易的判定结果。
      * 中文：SYNCDB32 根据主键查询最终账户。
      * 中文：数据库余额相同时，报告为 UNCHANGED。
      * 中文：余额不同时，会更新为根据文件计算出的结果。
      * 中文：数据库中不存在该键时，从账户主数据插入记录。
      * 中文：报表说明对每个已加载账户作出的判定。
      * 中文：使用相同输入重新运行时，最终余额会收敛到相同结果。
      * 中文：重放输入时，会从其中声明的期初余额开始。
      * 中文：因此，不会将同一笔存款重复应用到账户数据库状态。
      * 中文：输出文件与数据库更改不属于同一原子事务。
      * 中文：运行脚本会创建可复现的 SQLite 初始数据库。
      * 中文：运行现有数据操作用于检查确定性的重启行为。
      * 中文：生产批次会添加持久化的批次标识符。
      * 中文：还会定义事务提交和恢复协议。
      * 中文：这些边界会在此处记录，而不进行模拟。
      * 中文：模块调用通过引用使用共享的 Copybook 布局。
      * 中文：此驱动程序负责最终汇总和进程返回状态。
      * 中文：记账和同步模块分别管理自己的文件和 SQL 操作。
      * 中文：此集成批次的补充设计说明。
      * 中文：驱动程序将工作模块状态转换为进程返回码。
      * 工作模块通过引用接收这些表并更新共享状态。
      * 中文：每个计数器都用于上面的批次算术检查。
      * 中文：已记账和已拒绝计数共同划分全部交易输入。
      * 中文：SQL 操作成功后，同步计数会对每个账户进行归类。
      * 中文：金额文本表示整数分，而非本地化的小数格式。
      * 中文：每笔输入交易都需要扫描一次来查询账户。
      * 中文：对于更大的主数据，需要专门设计表结构或索引查询方案。
      * 中文：此示例限制主数据行数，以便控制内存用量。
      * 中文：重建会创建干净数据库；重新运行则保留数据库记录。
      * 中文：检查使用临时数据，因此课程样例数据保持不变。
       END PROGRAM LESSON32.
