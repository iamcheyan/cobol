      * 第17课：读取原始定长记录并按固定布局写出。
      * 顺序二进制文件的记录之间没有行结束分隔符。
      * 每条示例输入记录恰好占27个显示字符字节。
      * 字段位置：账户1–10、客户11–18、余额19–27。
      * 输出位置：客户1–8、账户9–18、余额19–27。
      * 输入和输出样例由连续拼接的原始记录字节组成。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FIXED17.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "accounts.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT BALANCE-FILE
               ASSIGN TO "balances.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-BALANCE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
       FD BALANCE-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-BALANCE-RECORD.
          05 FD-OUT-CUSTOMER-ID PIC X(8).
          05 FD-OUT-ACCOUNT-NUMBER PIC X(10).
          05 FD-OUT-BALANCE PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-BALANCE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
      * 打开原始主文件并创建定宽输出文件。
       0000-MAIN.
           OPEN INPUT ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=INPUT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN OUTPUT BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "OPEN=OUTPUT FAILED STATUS="
                   WS-BALANCE-STATUS
               CLOSE ACCOUNT-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=INPUT OK OPEN=OUTPUT OK"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 1000-READ-AND-WRITE
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 读取一条27字节记录，并写出重新排列的字段。
       1000-READ-AND-WRITE.
           READ ACCOUNT-FILE
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   PERFORM 1100-WRITE-BALANCE-RECORD
           END-READ.
      * 将命名字段移至输出记录所声明的位置。
       1100-WRITE-BALANCE-RECORD.
           MOVE FD-CUSTOMER-ID TO FD-OUT-CUSTOMER-ID
           MOVE FD-ACCOUNT-NUMBER TO FD-OUT-ACCOUNT-NUMBER
           MOVE FD-ACCOUNT-BALANCE TO FD-OUT-BALANCE
           WRITE FD-BALANCE-RECORD
           IF WS-BALANCE-STATUS = "00"
               ADD 1 TO WS-RECORD-COUNT
               DISPLAY "WROTE ACCOUNT=" FD-OUT-ACCOUNT-NUMBER
                   " CUSTOMER=" FD-OUT-CUSTOMER-ID
                   " BALANCE=" FD-OUT-BALANCE
           ELSE
               DISPLAY "WRITE=FAILED STATUS=" WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * 关闭两个文件并报告成功写入的记录数。
       9000-CLOSE-FILES.
           CLOSE ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "CLOSE=INPUT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "CLOSE=OUTPUT FAILED STATUS="
                   WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "CLOSE=OK RECORDS=" WS-RECORD-COUNT.
      * RECORD CONTAINS子句与FD字段定义的长度都是27字节。
      * DISPLAY字段使用文本字节，小数点位置由隐含小数位表示。
      * PIC 9(7)V99中的V不占用实际文件字节。
      * 因此，余额占用九个显示数字字节。
      * 输入样例由三条27字节记录组成，记录间没有分隔符。
      * 第二条记录恰好从字节偏移28处开始。
      * 输出记录以客户ID开头，而不是账户ID。
      * 接下来的十个字节存放账户号码。
      * 最后九个字节存放相同的数值余额。
      * ORGANIZATION SEQUENTIAL表示原始定长记录的字节布局。
      * 它与LINE SEQUENTIAL文本的物理格式不同。
      * 不要在顺序记录之间插入换行符。
      * 文本编辑器会添加行结束符，从而破坏此样例。
      * 每次READ成功都会向程序提供一条FD记录。
      * READ AT END会停止循环，且不会创建输出记录。
      * 每次WRITE成功都会添加一条恰好27字节的输出记录。
      * 输出文件大小等于记录数乘以27字节。
      * 文件状态00表示打开、读取、写入或关闭成功。
      * 程序保留输入文件中的账户顺序。
      * 排序、查找和算术运算都不会更改账户余额。
      * OPEN OUTPUT会替换balances.dat中已有的内容。
      * 路径相对于进程的当前工作目录。
      * 请在包含accounts.dat的临时目录中运行。
      * 此示例使用ASCII显示字符和数字。
      * 二进制COMP数据需要单独指定布局。
      * 输入和输出的字段顺序不同，但总长度相同。
      * 交换定宽数据文件前，请核对字段偏移。
      * 输入文件缺失时，会在打开输出文件前报告错误。
      * 成功关闭输出文件会刷新定长记录。
      * STOP RUN结束此定长记录转换示例。
