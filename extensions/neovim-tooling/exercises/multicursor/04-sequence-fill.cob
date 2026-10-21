      * 练习 4：把 6 个占位号 000 改造成连续序号 001-006.
      * 任务：在 000 上按 Ctrl+Shift+n 全选匹配，再逐个改成不同序号（本机未映射 g<C-a>）。
      * 说明：本机 multicursor 配置未绑定 sequenceIncrement。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SEQFILL.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-LINE-01          PIC X(40) VALUE "000".
       01  WS-LINE-02          PIC X(40) VALUE "000".
       01  WS-LINE-03          PIC X(40) VALUE "000".
       01  WS-LINE-04          PIC X(40) VALUE "000".
       01  WS-LINE-05          PIC X(40) VALUE "000".
       01  WS-LINE-06          PIC X(40) VALUE "000".
       PROCEDURE DIVISION.
           STOP RUN.
