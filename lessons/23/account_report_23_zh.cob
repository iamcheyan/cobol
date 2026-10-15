      * 使用共享账户定义生成独立的账户报告。
      * 主流程设置账户号、客户编号和余额，然后调用报告段落。
      * 报告段落将余额移入编辑显示字段，并以带小数点的格式输出账户资料。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCOUNT-REPORT23.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "ACCOUNT-REC.CPY".
       01 WS-REPORT-BALANCE PIC 9(7).99 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-LOAD-REPORT-ROW
           PERFORM 2000-DISPLAY-REPORT-ROW
           STOP RUN.
       1000-LOAD-REPORT-ROW.
           MOVE "A000000009" TO WS-ACCOUNT-NUMBER
           MOVE "C0001009" TO WS-CUSTOMER-ID
           MOVE 20.00 TO WS-ACCOUNT-BALANCE.
       2000-DISPLAY-REPORT-ROW.
           MOVE WS-ACCOUNT-BALANCE TO WS-REPORT-BALANCE
           DISPLAY "账户报告 账户号码=" WS-ACCOUNT-NUMBER
               " 客户号码=" WS-CUSTOMER-ID
               " 余额=" WS-REPORT-BALANCE.
