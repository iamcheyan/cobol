      * 正金额规则会拒绝零和所有负数。
      * 最高金额边界包含限值；恰好等于限值也接受。
      * 账户还必须处于有效状态才能通过本例检查。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. IF04.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
       01 WS-MAXIMUM-AMOUNT PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
           DISPLAY "交易参考号="
               WS-TRANSACTION-REFERENCE
           DISPLAY "账户状态=" WS-ACCOUNT-STATUS
           DISPLAY "交易金额=" WS-TRANSACTION-AMOUNT
           DISPLAY "金额上限=" WS-MAXIMUM-AMOUNT
      * 检查上限前先拒绝零和负数。
           IF WS-TRANSACTION-AMOUNT <= ZERO
               DISPLAY "决定=REJECTED"
               DISPLAY "原因=AMOUNT_NOT_POSITIVE"
           ELSE
               IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
                   DISPLAY "决定=REJECTED"
                   DISPLAY "原因=AMOUNT_OVER_LIMIT"
               ELSE
                   IF WS-ACCOUNT-STATUS = "A"
                       DISPLAY "决定=ACCEPTED"
                       DISPLAY "原因=WITHIN_RULES"
                   ELSE
                       DISPLAY "决定=REJECTED"
                       DISPLAY "原因=ACCOUNT_INACTIVE"
                   END-IF
               END-IF
           END-IF
      * 原因文本指出优先级最高的失败规则。
      * 拒绝结果属于业务结果，不是系统错误。
      * 拒绝是业务结果，与文件I/O故障等系统错误不同。
           STOP RUN.
