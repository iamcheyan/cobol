      * 第21课：使用过程对未排序的账户文件排序。
      * 输入过程将记录RELEASE到排序工作文件。
      * 输出过程按键升序RETURN记录。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SORT21.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT UNSORTED-INPUT
               ASSIGN TO "accounts-unsorted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
           SELECT SORT-WORK ASSIGN TO DISK.
       DATA DIVISION.
       FILE SECTION.
       FD UNSORTED-INPUT.
       01 FD-INPUT-RECORD PIC X(27).
       SD SORT-WORK.
       01 SD-SORT-RECORD.
          05 SD-ACCOUNT-NUMBER PIC X(10).
          05 SD-CUSTOMER-ID PIC X(8).
          05 SD-ACCOUNT-BALANCE PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-INPUT-STATUS PIC XX VALUE SPACES.
       01 WS-INPUT-EOF PIC X VALUE "N".
       01 WS-SORT-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-INPUT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-OUTPUT-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * SORT控制输入、排序和输出阶段。
       0000-MAIN.
           SORT SORT-WORK ON ASCENDING KEY SD-ACCOUNT-NUMBER
               INPUT PROCEDURE 1000-LOAD-INPUT
               OUTPUT PROCEDURE 2000-RETURN-SORTED.
           IF SORT-RETURN NOT = ZERO
               DISPLAY "SORT=FAILED STATUS=" SORT-RETURN
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "SUMMARY INPUT=" WS-INPUT-COUNT
               " OUTPUT=" WS-OUTPUT-COUNT
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 读取输入行，并将每条有效记录RELEASE给SORT。
       1000-LOAD-INPUT.
           OPEN INPUT UNSORTED-INPUT
           IF WS-INPUT-STATUS NOT = "00"
               DISPLAY "OPEN=INPUT FAILED STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           ELSE
               PERFORM UNTIL WS-INPUT-EOF = "Y"
                   OR WS-IO-ERROR = "Y"
                   PERFORM 1100-READ-AND-RELEASE
               END-PERFORM
               CLOSE UNSORTED-INPUT
               IF WS-INPUT-STATUS NOT = "00"
                   DISPLAY "CLOSE=INPUT FAILED STATUS="
                       WS-INPUT-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
      * 加载一行；AT END只结束输入过程的循环。
       1100-READ-AND-RELEASE.
           READ UNSORTED-INPUT
               AT END
                   MOVE "Y" TO WS-INPUT-EOF
               NOT AT END
                   IF WS-INPUT-STATUS = "00"
                       MOVE FD-INPUT-RECORD TO SD-SORT-RECORD
                       RELEASE SD-SORT-RECORD
                       IF SORT-RETURN = ZERO
                           ADD 1 TO WS-INPUT-COUNT
                       ELSE
                           DISPLAY "RELEASE=FAILED STATUS="
                               SORT-RETURN
                           MOVE "Y" TO WS-IO-ERROR
                       END-IF
                   END-IF
           END-READ
           IF WS-INPUT-STATUS NOT = "00"
               AND WS-INPUT-STATUS NOT = "10"
               DISPLAY "READ=INPUT FAILED STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * 逐条RETURN排序后的记录，直到SORT报告输出EOF。
       2000-RETURN-SORTED.
           PERFORM UNTIL WS-SORT-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               RETURN SORT-WORK
                   AT END
                       MOVE "Y" TO WS-SORT-EOF
                   NOT AT END
                       IF SORT-RETURN = ZERO
                           ADD 1 TO WS-OUTPUT-COUNT
                           DISPLAY "SORTED ACCOUNT="
                               SD-ACCOUNT-NUMBER
                               " CUSTOMER=" SD-CUSTOMER-ID
                               " BALANCE=" SD-ACCOUNT-BALANCE
                       ELSE
                           DISPLAY "RETURN=FAILED STATUS="
                               SORT-RETURN
                           MOVE "Y" TO WS-IO-ERROR
                       END-IF
               END-RETURN
           END-PERFORM.
      * 输入文件特意没有按键排序。
      * 记录宽度为27个字符，与第17课相同。
      * 账户号码占据第1至第10位。
      * 客户ID占据第11至第18位。
      * 余额占据第19至第27位。
      * 排序工作记录使用相同的字段布局。
      * SORT-WORK使用SD而不是FD定义。
      * 工作文件由SORT管理；程序不会OPEN它。
      * 输入过程作为SORT输入阶段的一部分运行。
      * RELEASE将当前SD记录添加到排序工作文件。
      * 输入过程会持续读取，直到源文件到达EOF。
      * FILE STATUS用于区分EOF和其他输入错误。
      * 排序输出过程开始前会关闭源文件。
      * 排序阶段按声明的键排列记录。
      * 账户键是带前导零的定宽文本。
      * 此样例中没有重复键。
      * 排序完成后运行输出过程。
      * RETURN每次取回一条已排序记录。
      * RETURN AT END会结束输出过程循环。
      * 输出过程按键升序显示记录。
      * SORT成功后，输入和输出计数应相等。
      * 空输入产生零次RELEASE和零条RETURN记录。
      * 只有RELEASE成功后才增加输入计数。
      * 只有RETURN成功后才增加输出计数。
      * 源文件OPEN、READ或CLOSE出错时会设置失败标志。
      * 非零SORT-RETURN表示RELEASE、RETURN或SORT失败。
      * 检测到I/O错误后，进程返回状态1。
      * 此程序显示排序后的记录，不创建输出文件。
      * 排序工作区域可以大于小型内存表。
      * GnuCOBOL可能会为大型排序使用临时存储。
      * 样例使用可打印字符和单个物理行。
      * 每行三个定宽字段之间没有分隔符。
      * 行结束符不属于27字符的FD记录。
      * 请从此目录运行，以便ASSIGN能找到输入样例。
      * 排序不会验证账户或客户标识符。
      * 排序不会更改输入文件的原始顺序。
      * 程序不依赖输入键的顺序。
      * 排序结果仅按账户号码升序排列。
      * 后续批处理可以将此有序流用于文件匹配。
      * 第20课使用有序账户键进行顺序匹配。
      * 输入过程必须像被PERFORM的过程一样正常结束。
      * 输出过程必须在最后一次RETURN后结束。
      * SORT会在各自阶段调用这两个命名过程。
      * 在SORT输入过程中可以使用RELEASE。
      * 在SORT输出过程中可以使用RETURN。
      * 每次排序工作操作后都会检查SORT-RETURN。
      * 最终摘要会显示是否有记录丢失或重复。
      * 此小型练习中的计数器都是三位数字字段。
      * 预期输入包含四个不同的账户键。
      * 输出顺序与输入顺序无关。
      * STOP RUN会将最终RETURN-CODE返回给shell。
