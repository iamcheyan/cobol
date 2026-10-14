      * 第 15 课：一次一行阅读日常交易文本。
      * LINE SEQUENTIAL 在每一物理行上存储一个文本记录。
      * READ 检索下一条记录，直到 AT END 子句运行。
      * FD记录区域中填充短行。
      * TRIM 仅为显示操作删除该填充。
      * 该程序将记录作为文本读取，并且不解析字段。
      * 在此处运行以便 ASSIGN 找到输入装置。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. READ15.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-FILE
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-FILE.
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
      * 在尝试任何读取之前会报告打开失败。
       0000-MAIN.
           OPEN INPUT TRANSACTION-FILE
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "OPEN=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=OK"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               PERFORM 1000-READ-ONE-RECORD
           END-PERFORM
           DISPLAY "EOF=YES RECORDS=" WS-RECORD-COUNT
           CLOSE TRANSACTION-FILE
           IF WS-FILE-STATUS = "00"
               DISPLAY "CLOSE=OK"
           ELSE
               DISPLAY "CLOSE=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * READ 获取一根物理行或表示文件结束。
       1000-READ-ONE-RECORD.
           READ TRANSACTION-FILE
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   ADD 1 TO WS-RECORD-COUNT
                   DISPLAY "RECORD="
                       FUNCTION TRIM(FD-TRANSACTION-RECORD TRAILING)
           END-READ.
      * OPEN INPUT 准备现有文件以供读取。
      * 成功打开报告文件状态 00。
      * 缺少所需文件会导致 OPEN 返回非零状态。
      * 如果无法打开其输入，程序将返回状态 1。
      * FD 描述了一行顺序的文本记录。
      * 行顺序记录在每个物理换行符处结束。
      * 输入记录比 100 个字符的 FD 区域短。
      * GnuCOBOL 用空格填充较短的行顺序记录。
      * FUNCTION TRIM 仅删除右侧的显示填充。
      * TRIM 不会改变存储的文件记录本身。
      * 没有随机密钥的 READ 将检索下一个连续记录。
      * READ AT END 表示没有下一条记录可用。
      * EOF 分支设置一个标志并且不增加计数。
      * 循环在第一次 READ 到达文件末尾后结束。
      * 最后的换行符不会创建额外的空数据记录。
      * 每次成功读取，记录计数器都会增加一次。
      * 程序显示每个输入记录的原始文本。
      * 在本课中，它不会拆分以竖线分隔的字段。
      * 成功读取后文件状态为 00。
      * 文件结束后的文件状态为 10，直到文件关闭。
      * CLOSE 成功时返回状态 00。
      * 该文件必须存在，因为此 SELECT 不是可选的。
      * 输入路径是相对于当前目录的。
      * 从课程目录启动程序以使用其固定装置。
      * 该程序不执行写入操作，也不更改输入数据。
      * 下一课将编写接受和拒绝的输出记录。
      * 第 18 课将解析分隔符分隔的字段。
      * 该装置包含四个每日帐户交易记录。
      * 记录的长度不同以展示线路处理。
      * 每次读取都使用相同的FD记录区域。
      * 只有 READ AT END 将此输入流标记为完成。
      * 文件读取错误与普通的文件结束错误不同。
      * 诊断 I/O 故障时应检查文件状态。
      * 读取循环后关闭文件，即使它是空的。
      * 输出计数确认所有可用记录均已被访问。
      * 空文件将报告 EOF，记录计数为零。
      * 本课程中不会进行表搜索或帐户余额更新。
      * STOP RUN 结束顺序输入演示。
      * 该装置使用管道字符来分隔可见字段。
      * 在本课中，每一整行都保留一个字符记录。
      * 日期和交易标识符的显示不带检查。
      * 交易代码和金额不会转换为 COBOL 字段。
      * 稍后的课程将解析分隔列中的字段。
      * 行顺序文件在记录之间使用换行符分隔符。
      * 文本编辑器可以直接创建此输入装置。
      * 第一次 READ 尝试时，空输入到达 AT END。
      * 成功读取只会将计数增加一次。
      * FD 记录宽度必须容纳最长的输入行。
