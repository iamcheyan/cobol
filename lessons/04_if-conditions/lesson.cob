      * 样例固定在程序内，不读终端、文件或数据库。
      * 拒绝是业务结果而非系统故障，退出码仍为 0。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. IF04.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 这四个值仅服务本课演示，不是业务政策。
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
       01 WS-MAXIMUM-AMOUNT PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
      * 先回显参与判断的四个值，便于核对判定。
           DISPLAY "取引参照番号="
               WS-TRANSACTION-REFERENCE
           DISPLAY "口座状態=" WS-ACCOUNT-STATUS
           DISPLAY "取引金額=" WS-TRANSACTION-AMOUNT
           DISPLAY "上限金額=" WS-MAXIMUM-AMOUNT
      * 只报首个失败规则；优先级见下面的嵌套顺序。
           IF WS-TRANSACTION-AMOUNT <= ZERO
      * 规则一：金额必须为正，所以零和负数都拒绝。
               DISPLAY "判定=REJECTED"
               DISPLAY "理由=AMOUNT_NOT_POSITIVE"
           ELSE
      * 规则二：上限含端点，恰好等于上限仍继续。
               IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
                   DISPLAY "判定=REJECTED"
                   DISPLAY "理由=AMOUNT_OVER_LIMIT"
               ELSE
      * 规则三：仅状态字符 A 算有效账户。
      * 其余状态都走同一理由，不区分状态码。
                   IF WS-ACCOUNT-STATUS = "A"
                       DISPLAY "判定=ACCEPTED"
                       DISPLAY "理由=WITHIN_RULES"
                   ELSE
                       DISPLAY "判定=REJECTED"
                       DISPLAY "理由=ACCOUNT_INACTIVE"
                   END-IF
               END-IF
           END-IF
           STOP RUN.
