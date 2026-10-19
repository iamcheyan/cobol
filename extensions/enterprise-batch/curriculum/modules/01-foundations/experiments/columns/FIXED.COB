       IDENTIFICATION DIVISION.
       PROGRAM-ID. CONVERT-FIXED.
      *書式比較ペアの固定形式版。
      *同じ処理をFREE.COBでは自由形式で記述。
      *どちらもRESULT=に続いて末尾11111138桁を表示。
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-BASE PIC 9(9) VALUE 1.
       01 WS-RESULT PIC 9(38) VALUE 0.
       PROCEDURE DIVISION.
           COMPUTE WS-RESULT = WS-BASE + 111110
           DISPLAY 'RESULT=' WS-RESULT
           GOBACK.
