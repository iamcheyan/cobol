      * 第 11 课：在 OCCURS 表中存储一小批数据。
      * OCCURS 创建固定数量的重复数据条目。
      * 组条目重复其所有从属基本项目。
      * 括号中的数字下标选择表中的一个匹配项。
      * 本课程使用普通的数字下标，而不是索引。
      * 表界为四；循环访问条目 1 到 4。
      * 贷方增加样本余额，借方减少样本余额。
      * 显示未知代码并且余额保持不变。
      * 表数据在处理之前使用 MOVE 加载。
      * 这里不使用文件、外部输入或动态表。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. OCCURS11.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 每个 05 条目重复一个代码和一个两位小数的数量。
       01 WS-TRANSACTION-TABLE.
          05 WS-TRANSACTION-ENTRY OCCURS 4 TIMES.
             10 WS-TXN-CODE PIC X.
             10 WS-TXN-AMOUNT PIC 9(5)V99.
      * 数字字段是表引用的下标。
       01 WS-SAMPLE-INDEX PIC 9(2) VALUE ZERO.
       01 WS-LAST-SAMPLE PIC 9 VALUE 4.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT-BALANCE PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
      * 加载表，处理其填充范围，然后报告。
       0000-MAIN.
           PERFORM 1000-LOAD-TABLE
           PERFORM 2000-PROCESS-TABLE
           PERFORM 9000-REPORT
           STOP RUN.
      * 使用数字下标初始化所有四个出现的位置。
       1000-LOAD-TABLE.
           MOVE "C" TO WS-TXN-CODE(1)
           MOVE 125.50 TO WS-TXN-AMOUNT(1)
           MOVE "D" TO WS-TXN-CODE(2)
           MOVE 40.10 TO WS-TXN-AMOUNT(2)
           MOVE "X" TO WS-TXN-CODE(3)
           MOVE 25.00 TO WS-TXN-AMOUNT(3)
           MOVE "C" TO WS-TXN-CODE(4)
           MOVE 20.00 TO WS-TXN-AMOUNT(4).
      * 通过配置的最后一个索引处理填充的条目。
       2000-PROCESS-TABLE.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               PERFORM 2100-PROCESS-ENTRY
           END-PERFORM.
      * 读取当前发生的代码和金额。
       2100-PROCESS-ENTRY.
           DISPLAY "ENTRY=" WS-SAMPLE-INDEX
               " CODE=" WS-TXN-CODE(WS-SAMPLE-INDEX)
               " AMOUNT=" WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
           EVALUATE WS-TXN-CODE(WS-SAMPLE-INDEX)
               WHEN "C"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           + WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "ACTION=CREDIT"
               WHEN "D"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           - WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "ACTION=DEBIT"
               WHEN OTHER
                   DISPLAY "ACTION=IGNORED_UNKNOWN_CODE"
           END-EVALUATE
           COMPUTE WS-PROCESSED-COUNT =
               WS-PROCESSED-COUNT + 1.
      * 报告已处理的条目以及由此产生的帐户余额。
       9000-REPORT.
           DISPLAY "PROCESSED=" WS-PROCESSED-COUNT
           DISPLAY "FINAL-BALANCE=" WS-ACCOUNT-BALANCE.
      * WS-TRANSACTION-TABLE 是所有表条目的父组。
      * OCCURS 4 TIMES 在此固定表中分配四次出现。
      * 每次出现都包含 WS-TXN-CODE 和 WS-TXN-AMOUNT。
      * 组级 OCCURS 重复其整个从属结构。
      * 两个基本字段的每个条目使用相同的数字下标。
      * 下标写在数据名称后面的括号中。
      * 第一次出现的位置用下标 1 表示。
      * 第四个也是最后一个出现的情况用下标 4 表示。
      * WS-LAST-SAMPLE 绝不能超过声明的表上限。
      * 循环在每次处理之前检查其结束条件。
      * 处理索引 4 是因为退出测试使用大于。
      * 在索引4之后，索引5满足退出测试。
      * 执行的入口段返回到循环体。
      * 该循环将每个表条目的已处理计数递增一次。
      * 数字下标是普通的数字数据项。
      * 第12课介绍INDEXED BY和表索引数据项。
      * 即使使用较少的条目，该表也具有固定的容量。
      * 该示例填充循环之前的每个分配的事件。
      * OCCURS 不加载值或检查交易业务规则。
      * EVALUATE 使已经学习的代码分类保持明确。
      * 未知代码分支使运行余额保持不变。
      * 条目按照下标选择的顺序进行处理。
      * 声明表时不会发生隐式排序或查找。
      * 后面的课程将使用帐户标识符搜索表。
      * 四个样本量为 125.50、40.10、25.00 和 20.00。
      * 接受的贷方和借方序列在余额 1105.40 处结束。
      * 忽略的未知代码金额不会添加到余额中。
      * 该表存储在 WORKING-STORAGE 中以供该程序运行。
      * 固定的 OCCURS 边界简化了存储规划和表审查。
      * 保持表边界和循环范围一致。
      * 避免使用声明的出现范围之外的下标。
      * 该程序显示字段，而不是整个组记录。
      * STOP RUN 结束该固定工作台演示。
