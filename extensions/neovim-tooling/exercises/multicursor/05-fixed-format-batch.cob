      * 练习 5（综合）：把 3 条记录的状态码 "A" 改成 "P"，
      * 并把 PIC X(1) 改成 PIC X(2)。
      * 任务拆分：
      *   1) 光标停在 "A" 上，Ctrl+Shift+n 全量匹配，ci" 改成 "P"
      *   2) 光标停在 PIC 上，Ctrl+Shift+n，再用 C 改到行尾
      * 注意：两步分开做，不要把引号内容和 PIC 混在一次操作里。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FIXBAT.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-REC-01-STATUS    PIC X(1) VALUE "A".
       01  WS-REC-02-STATUS    PIC X(1) VALUE "A".
       01  WS-REC-03-STATUS    PIC X(1) VALUE "A".
       PROCEDURE DIVISION.
           DISPLAY WS-REC-01-STATUS
           DISPLAY WS-REC-02-STATUS
           DISPLAY WS-REC-03-STATUS
           STOP RUN.
