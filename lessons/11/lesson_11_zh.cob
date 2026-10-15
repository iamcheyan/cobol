      *第 11 课：在 OCCURS 表中存储一小批数据。
      *OCCURS 创建固定数量的重复数据条目。
      *组条目重复其所有从属基本项目。
      *括号中的数字下标用于选择表的一次出现项。
      *本课程使用普通的数字下标，而不是索引。
      *表界为四；循环访问条目 1 到 4。
      *贷方增加样本余额，借方减少样本余额。
      *显示未知代码并且余额保持不变。
      *表数据在处理之前使用 MOVE 加载。
      *这里不使用文件、外部输入或动态表。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. OCCURS11.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *每个 05 条目重复一个代码和一个两位小数的数量。
       01 WS-TRANSACTION-TABLE.
          05 WS-TRANSACTION-ENTRY OCCURS 4 TIMES.
             10 WS-TXN-CODE PIC X.
             10 WS-TXN-AMOUNT PIC 9(5)V99.
      *数字字段是表引用的下标。
       01 WS-SAMPLE-INDEX PIC 9(2) VALUE ZERO.
       01 WS-LAST-SAMPLE PIC 9 VALUE 4.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT-BALANCE PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
      *加载表，处理其填充范围，然后报告。
       0000-MAIN.
           PERFORM 1000-LOAD-TABLE
           PERFORM 2000-PROCESS-TABLE
           PERFORM 9000-REPORT
           STOP RUN.
      *使用数字下标初始化所有四个出现的位置。
       1000-LOAD-TABLE.
           MOVE "C" TO WS-TXN-CODE(1)
           MOVE 125.50 TO WS-TXN-AMOUNT(1)
           MOVE "D" TO WS-TXN-CODE(2)
           MOVE 40.10 TO WS-TXN-AMOUNT(2)
           MOVE "X" TO WS-TXN-CODE(3)
           MOVE 25.00 TO WS-TXN-AMOUNT(3)
           MOVE "C" TO WS-TXN-CODE(4)
           MOVE 20.00 TO WS-TXN-AMOUNT(4).
      *通过配置的最后一个索引处理填充的条目。
       2000-PROCESS-TABLE.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               PERFORM 2100-PROCESS-ENTRY
           END-PERFORM.
      *读取当前表项中的代码和金额。
       2100-PROCESS-ENTRY.
           DISPLAY "条目=" WS-SAMPLE-INDEX
               " 代码=" WS-TXN-CODE(WS-SAMPLE-INDEX)
               " 金额=" WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
           EVALUATE WS-TXN-CODE(WS-SAMPLE-INDEX)
               WHEN "C"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           + WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "动作=贷记"
               WHEN "D"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           - WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "动作=借记"
               WHEN OTHER
                   DISPLAY "动作=忽略未知代码"
           END-EVALUATE
           COMPUTE WS-PROCESSED-COUNT =
               WS-PROCESSED-COUNT + 1.
      *报告已处理的条目以及由此产生的帐户余额。
       9000-REPORT.
           DISPLAY "已处理=" WS-PROCESSED-COUNT
           DISPLAY "最终余额=" WS-ACCOUNT-BALANCE.
      *WS-TRANSACTION-TABLE 是所有表条目的父组。
      *OCCURS 4 TIMES 在此固定表中定义四个表项。
      *每个表项都包含 WS-TXN-CODE 和 WS-TXN-AMOUNT。
      *组级 OCCURS 重复其整个从属结构。
      *两个基本字段的每个条目使用相同的数字下标。
      *下标写在数据名称后面的括号中。
      *第一次出现项用下标 1 引用。
      *第四个也是最后一个表项用下标 4 引用。
      *WS-LAST-SAMPLE 绝不能超过声明的表上限。
      *循环在每次处理之前检查其结束条件。
      *下标为 4 的表项会被处理，因为退出条件使用大于号。
      *处理下标 4 后，下标变为 5，满足退出条件。
      *执行的入口段返回到循环体。
      *该循环将每个表条目的已处理计数递增一次。
      *数字下标是普通的数字数据项。
      *第12课介绍INDEXED BY和表索引数据项。
      *即使使用较少的条目，该表也具有固定的容量。
      *示例在循环之前填充所有已分配的表项。
      *OCCURS 不加载值或检查交易业务规则。
      *EVALUATE 使已经学习的代码分类保持明确。
      *未知代码分支使运行余额保持不变。
      *条目按照下标选择的顺序进行处理。
      *声明表时不会自动排序或查找表项。
      *后面的课程将使用帐户标识符搜索表。
      *四个样本量为 125.50、40.10、25.00 和 20.00。
      *接受的贷方和借方序列在余额 1105.40 处结束。
      *忽略的未知代码金额不会添加到余额中。
      *该表存储在 WORKING-STORAGE 中以供该程序运行。
      *固定的 OCCURS 边界简化了存储规划和表审查。
      *保持表边界和循环范围一致。
      *避免使用超出声明表项范围的下标。
      *该程序显示字段，而不是整个组记录。
      *STOP RUN 结束该固定工作台演示。
