      * 练习 2：把下面 4 个不同长度的 PIC 子句统一成 PIC 9(9).
      * 任务：gaip 逐行加光标，fP 定位到 PIC，再用 C 改到行尾。
      * 关键：4 行长度不同，必须用 C（change to end of line），不能用 cw。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. UNIFYP.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ACCT-ID          PIC X(10).
       01  WS-ACCT-NAME        PIC X(20).
       01  WS-ACCT-BAL         PIC 9(7)V99.
       01  WS-ACCT-STATUS      PIC X(1).
       PROCEDURE DIVISION.
           STOP RUN.
