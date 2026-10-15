      * 第二个消费者：只导入账户 Copybook，与 LESSON23 共用同一份物理声明。
      * 报表行是程序内常量样例，不读外部文件。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCOUNT-REPORT23.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "ACCOUNT-REC.CPY".
      * 编辑字段只负责显示；存储宽度仍取自 Copybook 的 PIC 9(7)V99。
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
           DISPLAY "口座レポート 口座番号=" WS-ACCOUNT-NUMBER
               " 顧客番号=" WS-CUSTOMER-ID
               " 残高=" WS-REPORT-BALANCE.
