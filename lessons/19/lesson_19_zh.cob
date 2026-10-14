      * 第19课：读取主文件和每日交易文件。
      * 每个输入文件都有自己的文件状态、EOF标志和计数。
      * 两个流中的记录数可能不同。
      * 本课读取文本记录，不匹配账户键。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MULTI19.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-INPUT
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT TRANSACTION-INPUT
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-INPUT.
       01 FD-ACCOUNT-RECORD PIC X(100).
       FD TRANSACTION-INPUT.
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-TRANSACTION-STATUS PIC XX VALUE SPACES.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-ACCOUNT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-TRANSACTION-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * 批处理读取任一流之前，两个输入文件都必须成功打开。
       0000-MAIN.
           OPEN INPUT ACCOUNT-INPUT
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN INPUT TRANSACTION-INPUT
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "OPEN=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               CLOSE ACCOUNT-INPUT
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=ACCOUNT OK OPEN=TRANSACTION OK"
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y"
               AND WS-TRANSACTION-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               IF WS-ACCOUNT-EOF = "N"
                   PERFORM 1000-READ-ACCOUNT
               END-IF
               IF WS-TRANSACTION-EOF = "N"
                   AND WS-IO-ERROR = "N"
                   PERFORM 2000-READ-TRANSACTION
               END-IF
           END-PERFORM
           CLOSE ACCOUNT-INPUT
           CLOSE TRANSACTION-INPUT
           IF WS-ACCOUNT-STATUS = "00"
               AND WS-TRANSACTION-STATUS = "00"
               DISPLAY "CLOSE=OK ACCOUNTS=" WS-ACCOUNT-COUNT
                   " TRANSACTIONS=" WS-TRANSACTION-COUNT
           ELSE
               DISPLAY "CLOSE=FAILED ACCOUNT=" WS-ACCOUNT-STATUS
                   " TRANSACTION=" WS-TRANSACTION-STATUS
               MOVE 1 TO RETURN-CODE
           END-IF
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 仅在账户流尚未到达EOF时读取。
       1000-READ-ACCOUNT.
           READ ACCOUNT-INPUT
               AT END
                   MOVE "Y" TO WS-ACCOUNT-EOF
               NOT AT END
                   IF WS-ACCOUNT-STATUS = "00"
                       ADD 1 TO WS-ACCOUNT-COUNT
                       DISPLAY "ACCOUNT="
                           FUNCTION TRIM(
                               FD-ACCOUNT-RECORD TRAILING)
                   END-IF
           END-READ
           IF WS-ACCOUNT-STATUS NOT = "00"
               AND WS-ACCOUNT-STATUS NOT = "10"
               DISPLAY "READ=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * 仅在交易流尚未到达EOF时读取。
       2000-READ-TRANSACTION.
           READ TRANSACTION-INPUT
               AT END
                   MOVE "Y" TO WS-TRANSACTION-EOF
               NOT AT END
                   IF WS-TRANSACTION-STATUS = "00"
                       ADD 1 TO WS-TRANSACTION-COUNT
                       DISPLAY "TRANSACTION="
                           FUNCTION TRIM(
                               FD-TRANSACTION-RECORD TRAILING)
                   END-IF
           END-READ
           IF WS-TRANSACTION-STATUS NOT = "00"
               AND WS-TRANSACTION-STATUS NOT = "10"
               DISPLAY "READ=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * OPEN INPUT为每个文件分配独立的状态。
      * 必须先打开第一个输入文件，才能尝试打开第二个。
      * 如果第二个OPEN失败，则关闭第一个文件。
      * 两个必需输入文件都打开之前，不执行READ。
      * 每个FD定义一条最多100字符的文本行。
      * 每个SELECT都使用LINE SEQUENTIAL组织方式。
      * 每个物理行都成为一条逻辑输入记录。
      * 较短的行会在FD记录区域中填充空格。
      * TRIM会在显示时去掉右侧填充空格。
      * 程序不会拆分或验证显示的字段。
      * 主记录和交易记录的布局不同。
      * 两个样例文件中可以看到各自的布局。
      * 每次循环对每个活动流最多尝试读取一次。
      * 账户文件可能先于交易文件到达EOF。
      * 交易文件可能先于账户文件到达EOF。
      * EOF标志只属于状态为10的那个文件。
      * READ成功时只增加该文件的记录计数。
      * 触发EOF的读取尝试不会增加任何记录计数。
      * 文件到达EOF后，后续每轮循环都会跳过它。
      * 两个EOF标志都设置后，处理结束。
      * 发生非EOF读取错误后，循环也会停止。
      * AT END处理其所属READ语句的状态10。
      * NOT AT END处理状态为00的成功READ。
      * 其他非零状态会作为输入错误报告。
      * I/O错误不同于正常文件结束。
      * 正常完成或读取出错后都会关闭两个文件。
      * 关闭错误会独立于读取计数报告。
      * 打开、读取或关闭失败时，返回码为非零。
      * 空文件在第一次READ尝试时就会到达EOF。
      * 一个文件为空不会阻止读取另一个文件。
      * 样例包含三条账户主记录。
      * 样例包含四条每日交易记录。
      * 这些文件特意使用不同的记录数。
      * 两个文件都处于活动状态时，显示输出交替进行。
      * 账户文件到达EOF后，仍继续读取交易记录。
      * 交易文件到达EOF后，仍继续读取账户记录。
      * 本课不进行账户与交易的匹配。
      * 下一课将按排序后的键匹配记录。
      * 生产作业应记录文件名和批次标识符。
      * 此示例保持简短输出，便于课堂检查。
      * 每次READ和CLOSE后都会检查文件状态。
      * OPEN成功后，文件状态为00。
      * 文件状态10表示顺序读取正常到达文件末尾。
      * OPEN失败会阻止批处理进入读取循环。
      * STOP RUN会将累计的RETURN-CODE返回给shell。
      * 请从课程目录运行，以便找到两个样例文件。
      * 将两个输入文件复制到可执行文件旁，以便独立测试。
      * 此程序不会创建或修改输出文件。
      * 第19课介绍独立的顺序输入流。
      * 第20课将在这些文件基础上进行有序匹配。
      * 两个输入文件不会共用EOF标志。
      * 记录数以三位数字字段显示。
      * 样例文件包含的记录少于一千条。
      * 文件结束是正常输入状态，不是I/O错误。
      * 账户流独立保留自己的当前位置。
      * 交易流有自己的当前位置。
      * 每次READ成功只推进所选文件。
      * 第二次OPEN失败时会释放已打开的第一个文件。
      * 空输入的行为也是练习场景的一部分。
      * 样例使用可打印ASCII字符以便阅读。
      * 本课不涉及解析和账户匹配。
      * 摘要确认从每个输入文件读取的数量。
      * 打印最终摘要前先关闭两个文件。
      * 行顺序运行时负责处理物理行结束符。
      * 换行字节不会复制到COBOL记录字段中。
      * 此示例使用两个输入；同一模式也可扩展。
      * 输入更多文件时，每个文件都应有自己的状态和EOF标志。
      * 只有一个流到达文件末尾时，不要停止所有流。
      * 完整的批处理必须为每种输入失败情况定义处理策略。
      * 本课采用首次READ错误后立即停止的策略。
      * 程序不会重新打开或倒回任一输入流。
      * 顺序READ按记录在文件中的原始顺序读取。
      * 两个输入文件都是必需的，且未声明为OPTIONAL。
      * 这些记录以只读方式处理，不会被更改。
