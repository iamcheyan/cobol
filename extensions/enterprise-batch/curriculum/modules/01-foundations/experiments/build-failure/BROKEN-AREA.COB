       IDENTIFICATION DIVISION.
       PROGRAM-ID. BROKEN-AREA.
      *01.2の固定形式エラー例。
      *MOVE文が列5（Area A）から始まる。
      *コンパイラは有効な文と認識しない。Area B文は
      *列12以降に置く必要がある。
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-N PIC 9 VALUE 0.
       PROCEDURE DIVISION.
       1000-MAIN.
    MOVE 1 TO WS-N.
           DISPLAY 'N=' WS-N
           GOBACK.
