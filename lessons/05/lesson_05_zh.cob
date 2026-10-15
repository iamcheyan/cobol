      * WHEN OTHER 处理没有指定 WHEN 替代项的任何代码。
      * 在生产中使用接口契约定义的代码值。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVAL05.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
       01 WS-TRANSACTION-CODE PIC X VALUE "D".
       PROCEDURE DIVISION.
           DISPLAY "交易参考号="
               WS-TRANSACTION-REFERENCE
           DISPLAY "交易代码=" WS-TRANSACTION-CODE
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   DISPLAY "类别=DEPOSIT"
                   DISPLAY "操作=ADD_TO_ACCOUNT"
               WHEN "W"
                   DISPLAY "类别=WITHDRAWAL"
                   DISPLAY "操作=SUBTRACT_FROM_ACCOUNT"
               WHEN "T"
                   DISPLAY "类别=TRANSFER"
                   DISPLAY "操作=PROCESS_BOTH_ACCOUNTS"
               WHEN OTHER
                   DISPLAY "类别=UNKNOWN"
                   DISPLAY "操作=REJECT_FOR_REVIEW"
           END-EVALUATE
      * 小写的 d 不是合约使用的大写代码 D。
      * 转账操作需要来源账户和目标账户标识。
      * 切勿将未知代码默默地解释为存款。
      * 定义空白代码是否缺失或格式错误。
      * 精确匹配意味着小写 d 与大写 D 不匹配。
           STOP RUN.
