       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON32.
      * 此程序协调完整的对账批次。
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 驱动程序与工作模块通过同一Copybook共享记录和计数器布局。
       COPY "BATCH-INTERFACE.CPY".
       01 WS-CHECK-COUNT PIC 999 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
      * 重置账户表、计数器和工作模块错误标志。
           INITIALIZE WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           MOVE "N" TO WS-FAILED
      * 记账模块读取账户主档并依次处理交易。
      * 只有记账完整成功后才同步计算结果，避免写入不完整的账户状态。
           CALL "LOADPOST32" USING BY REFERENCE
               WS-ACCOUNT-TABLE WS-BATCH-COUNTS
      * 文件处理失败时停止同步，避免将部分账户结果写入数据库。
           IF WS-FAILED NOT = "Y"
      * 同步模块查询SQLite账户，更新差异并生成报表。
               CALL "SYNCDB32" USING BY REFERENCE
                   WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           END-IF
      * 报告最终计数前，先核对输入、受理和拒绝数量的关系。
           PERFORM 3000-CHECK-COUNTS
           PERFORM 1000-REPORT-SUMMARY
           PERFORM 2000-RETURN-STATUS
           GOBACK.
       1000-REPORT-SUMMARY.
      * 余额不足或未知代码属于业务拒绝，不代表批处理系统故障。
           DISPLAY "SUMMARY ACCOUNTS=" WS-ACCOUNT-COUNT
                   " TX=" WS-TRANSACTION-COUNT
                   " POSTED=" WS-POSTED-COUNT
                   " REJECTED=" WS-REJECTED-COUNT
                   " UPDATED=" WS-UPDATED-COUNT
                   " UNCHANGED=" WS-UNCHANGED-COUNT
                   " INSERTED=" WS-INSERTED-COUNT.
       2000-RETURN-STATUS.
      * 只有文件或数据库等系统故障才会使进程返回非零状态。
           IF WS-FAILED = "Y"
               MOVE 1 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
       3000-CHECK-COUNTS.
      * 核对受理数与拒绝数，确保每笔输入交易都有明确处理结果。
           COMPUTE WS-CHECK-COUNT =
               WS-POSTED-COUNT + WS-REJECTED-COUNT
           IF WS-CHECK-COUNT NOT = WS-TRANSACTION-COUNT
               DISPLAY "ERROR=TRANSACTION COUNT MISMATCH"
               MOVE "Y" TO WS-FAILED
           END-IF
      * 同步成功后，每个账户会归为未变化、已更新或已插入之一。
           IF WS-FAILED NOT = "Y"
               COMPUTE WS-CHECK-COUNT =
                   WS-UPDATED-COUNT + WS-UNCHANGED-COUNT
                   + WS-INSERTED-COUNT
               IF WS-CHECK-COUNT NOT = WS-ACCOUNT-COUNT
                   DISPLAY "ERROR=SYNC COUNT MISMATCH"
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
      * LOADPOST32读取27字节账户记录和20字节交易记录。
      * 金额用整数分保存，PIC中的V表示隐含小数点位置。
      * 共享账户表最多容纳20条记录；主键重复会在记账前使批次失败。
      * 存款和余额足够的取款会更新账户；其他不合规交易记为业务拒绝。
      * 拒绝交易不改余额，并写入拒绝文件；受理记录和判定也会记录到日志。
      * SYNCDB32按主键查询数据库账户。余额相同时报告UNCHANGED。
      * 余额不同时更新为批次计算结果；数据库缺少账户时从账户主档插入。
      * 报表逐账户记录同步结果。同一输入重跑时，会从输入期初余额重算，
      * 避免把同一笔存款重复累加到数据库余额。
      * 文件输出与数据库写入并非同一原子事务。运行脚本可重建测试数据库；
      * 重跑操作则保留数据库行，用于检查重复执行的行为。生产系统还需设计
      * 持久批次编号、事务提交边界和故障恢复流程。
      * 模块调用按引用传递Copybook共享布局；驱动程序负责汇总和进程返回码。
      * 各工作模块分别管理文件或SQL处理，并把结果返回给驱动程序。
      * 受理数加拒绝数应等于输入交易数；数据库同步结果按账户统计。
      * 金额以整数分表示，不受本地小数格式影响。账户数增大后，应采用索引
      * 或合适的数据结构，避免每笔交易都线性扫描账户表。
      * 本例限制账户数量以控制内存。重建会创建干净数据库，重跑保留现有行。
      * 课程检查使用临时数据，不修改课程样例文件。
       END PROGRAM LESSON32.
