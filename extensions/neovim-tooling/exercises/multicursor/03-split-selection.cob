      * 练习 3：把 4 个逗号分隔的初值各改成 "N".
      * 任务：选中 "A,B,C,D"，用 S 按逗号切分，再 ci" 改引号内容。
      * 注意：只改引号内的值，不要碰字段名。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SPLITSL.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-FLAG-A           PIC X(1) VALUE "A".
       01  WS-FLAG-B           PIC X(1) VALUE "B".
       01  WS-FLAG-C           PIC X(1) VALUE "C".
       01  WS-FLAG-D           PIC X(1) VALUE "D".
       PROCEDURE DIVISION.
           STOP RUN.
