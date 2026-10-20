      * 练习 4：把 6 个占位号 000 改造成连续序号 001-006.
      * 任务：gaip 加光标到 6 行，光标停在 000 上，用 g<C-a> 一次递增。
      * 说明：sequenceIncrement treats all cursors as one sequence.
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
