      *M03雛形。ビルド可、未完了。
      *WS-EXERCISES-DONEが'N'の間はRC12で終了し、
      *何も公開しない。TODO段落を完成し値を'Y'にして
      *再実行。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. M03BYTES.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ABI-FILE ASSIGN TO 'abi.bin'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-ABI-STATUS.
           SELECT AMT-FILE ASSIGN TO 'amounts.bin'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-AMT-STATUS.
           SELECT IN-FILE ASSIGN TO 'input.dat'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-IN-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ABI-FILE.
       01 ABI-OUT PIC X(8).
       FD AMT-FILE.
       01 AMT-OUT PIC X(59).
       FD IN-FILE.
       01 IN-REC PIC X(7).
       WORKING-STORAGE SECTION.
       01 WS-ABI-STATUS PIC XX.
       01 WS-AMT-STATUS PIC XX.
       01 WS-IN-STATUS PIC XX.
       01 WS-LESSON PIC X(1).
       01 WS-EXERCISES-DONE PIC X VALUE 'N'.
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT WS-LESSON FROM ENVIRONMENT 'M03_LESSON'
           IF WS-EXERCISES-DONE NOT = 'Y'
               DISPLAY 'TODO,starter/M03BYTES.COB is not finished'
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           EVALUATE WS-LESSON
               WHEN '1' PERFORM 1100-LESSON-1
               WHEN '2' PERFORM 1200-LESSON-2
               WHEN '3' PERFORM 1300-LESSON-3
               WHEN OTHER MOVE 12 TO RETURN-CODE
           END-EVALUATE
           GOBACK.
       1100-LESSON-1.
      *TODO 03.1：DISPLAY／SIGN SEPARATE／COMP-3／COMPの
      *項目を宣言し、LENGTH OFを表示。COMPの
      *ビッグエンディアン確認既知値0x01020304abi.binへ書
           DISPLAY 'LESSON,03.1'
           DISPLAY 'TODO,03.1 declarations'.
       1200-LESSON-2.
      *TODO 03.2：DISPLAY、SIGN LEADING SEPARATE、COMP-3と
      *整数の最小通貨単位COMP項目に+12345.67と-12345.67を
      *格納し、生Bを小文字の16進数で出力。
           DISPLAY 'LESSON,03.2'
           DISPLAY 'TODO,03.2 hexdump'.
       1300-LESSON-3.
      *TODO 03.3：input.datから7BのCOMP-3レコードを読み、
      *演算前各数字ニブル0-9と符号ニブルC/D検証し、
      *理由付きでOK／REJECTを報告。
           DISPLAY 'LESSON,03.3'
           DISPLAY 'TODO,03.3 packed parser'.
