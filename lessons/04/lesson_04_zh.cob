      * 第04课：判断单笔交易是否符合账户规则。
      * 本例演示嵌套IF和明确的ELSE路径。
      * 值固定在WORKING-STORAGE中，确保运行结果可复现。
      * 本例只验证单笔金额和账户状态。
      * 本例不使用余额、文件或外部输入。
      * 正金额规则会拒绝零和所有负数。
      * 最高金额边界包含限值；恰好等于限值也接受。
      * 账户还必须处于有效状态才能通过本例检查。
      * 每个分支都会显示对应的决定和原因。
      * PROGRAM-ID指定编译此源码时使用的程序名。
      * DATA DIVISION将数据与可执行逻辑分开。
      * 本例中每个01条目定义一个基本字段。
      * 过程部仅使用条件和DISPLAY语句。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. IF04.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 引用号作为文本标识符保存，包括其中的连字符。
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
      * 在此明确说明的小型状态体系中，A表示有效。
      * 本例将其他状态值视为无效。
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
      * 带符号金额使验证规则能够拒绝负数。
      * 独立符号让正负数输出清晰明确。
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
      * 此限额是教学规则，不是银行产品限额。
      * 交易金额和限额都有两位小数。
       01 WS-MAXIMUM-AMOUNT PIC 9(7)V99 VALUE 1000.00.
      * 引用号在本程序中没有算术含义。
      * 账户状态是单字符业务代码。
      * 带符号金额可用于测试负数输入。
      * 规则限额不带符号，并有两位小数。
       PROCEDURE DIVISION.
      * 选择业务路径前先显示输入值。
           DISPLAY "TRANSACTION-REFERENCE="
               WS-TRANSACTION-REFERENCE
           DISPLAY "ACCOUNT-STATUS=" WS-ACCOUNT-STATUS
           DISPLAY "TRANSACTION-AMOUNT=" WS-TRANSACTION-AMOUNT
           DISPLAY "MAXIMUM-AMOUNT=" WS-MAXIMUM-AMOUNT
      * 第一条规则处理下边界。
      * 条件为假时继续下一条验证规则。
      * 只有之前的规则均通过，才会执行后续嵌套检查。
      * 检查上限前先拒绝零和负数。
      * 此ELSE属于上方的下界条件。
           IF WS-TRANSACTION-AMOUNT <= ZERO
               DISPLAY "DECISION=REJECTED"
               DISPLAY "REASON=AMOUNT_NOT_POSITIVE"
           ELSE
      * 恰好等于限额的值会通过此比较。
               IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
                   DISPLAY "DECISION=REJECTED"
                   DISPLAY "REASON=AMOUNT_OVER_LIMIT"
               ELSE
      * 只有处于两个数值边界内的金额才会到达此检查。
                   IF WS-ACCOUNT-STATUS = "A"
                       DISPLAY "DECISION=ACCEPTED"
                       DISPLAY "REASON=WITHIN_RULES"
                   ELSE
                       DISPLAY "DECISION=REJECTED"
                       DISPLAY "REASON=ACCOUNT_INACTIVE"
                   END-IF
               END-IF
           END-IF
      * 第一个END-IF关闭账户状态检查。
      * 第二个END-IF关闭金额限额检查。
      * 第三个END-IF关闭正金额检查。
      * 每个嵌套IF都用一个ELSE处理假路径。
      * 金额等于限值时，大于比较为假，流程继续。
      * END-IF关闭条件，但不结束句子。
      * STOP RUN处的句点结束此COBOL句子。
      * 显式作用域表明每个ELSE分支属于哪个IF。
      * 原因文本指出优先级最高的失败规则。
      * 比较运算符定义包含边界的上限。
      * 缩进有助阅读，但不决定COBOL作用域。
      * 数值比较使用实际值，而非显示文本。
      * 两个值都是数值型，均有两位小数。
      * 本课不模拟文件状态或持久账簿。
      * 实际系统还需要授权和重复交易检查。
      * 系统必须定义币种、交易类型和入账规则。
      * 拒绝结果属于业务结果，不是系统错误。
      * 后续课程将用PERFORM处理多笔交易。
      * 后续将另行介绍用EVALUATE处理多个代码值。
      * 固定值使每次编译运行检查都可重现。
      * 边界练习中每次只改一个VALUE子句。
      * 显式作用域界定嵌套IF；COBOL整句仍由句点结束。
      * 金额规则比较数值字段，而不是格式化后的显示文本。
      * 拒绝是业务结果，与文件I/O故障等系统错误不同。
      * 生产系统还需定义币种、交易类型、授权和重复检查。
      * 本课只判定一条固定记录，不记账也不更新余额。
      * 后续课程将使用PERFORM处理多笔交易。
           STOP RUN.
