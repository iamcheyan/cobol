       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVELAB.
      *M02MOVE実験。固定結果をDISPLAYだけで・
      *銀行ファイルは処理しない
      *絶対に使わない。各例でCOBOLのMOVE規則を示す：
      *暗黙小数、カテゴリ変換、
      *空白埋め／切り詰め、符号付き表示。
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-N1 PIC 9(3)V99 VALUE 41.5.
       01 WS-N2 PIC 9(5) VALUE 0.
       01 WS-X1 PIC X(5) VALUE SPACES.
       01 WS-X2 PIC X(5) VALUE SPACES.
       01 WS-S1 PIC S9(3) SIGN IS LEADING SEPARATE VALUE -12.
       01 WS-S2 PIC S9(3)V99 SIGN IS LEADING SEPARATE VALUE -1.25.
       01 WS-X3 PIC X(5) VALUE SPACES.
       01 WS-T1 PIC 9(3) VALUE 0.
       01 WS-T2 PIC 9(3)V99 VALUE 0.
       PROCEDURE DIVISION.
           DISPLAY 'A|' WS-N1 '|'
           MOVE WS-N1 TO WS-N2
           DISPLAY 'B|' WS-N2 '|'
           MOVE WS-N2 TO WS-X1
           DISPLAY 'C|' WS-X1 '|'
           MOVE 'AB' TO WS-X2
           DISPLAY 'D|' WS-X2 '|'
           DISPLAY 'E|' WS-S1 '|'
           DISPLAY 'F|' WS-S2 '|'
           MOVE 'ABCDEFGH' TO WS-X3
           DISPLAY 'G|' WS-X3 '|'
           MOVE 12345 TO WS-T1
           DISPLAY 'H|' WS-T1 '|'
           MOVE 12345.67 TO WS-T2
           DISPLAY 'I|' WS-T2 '|'
           GOBACK.
