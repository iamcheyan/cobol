      *M04レッスン04.1雛形。ビルド可・未完了。
      *TODO段落を完成しWS-EXERCISES-DONEを'Y'に。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. M04SHAPE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EXERCISES-DONE PIC X VALUE 'N'.
       01 WS-N PIC 9(3).
       PROCEDURE DIVISION.
       1000-MAIN.
           IF WS-EXERCISES-DONE NOT = 'Y'
               DISPLAY 'TODO,starter/M04SHAPE.COB is not finished'
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
      *TODO 04.1a:REDEFINESビューを持つグループを宣言し・
      *親のLENGTH OFが二重にならないことを確認。
      *TODO 04.1b：2項目にまたがる66レベルRENAMESを宣言。
      *TODO 04.1c：OCCURS ... INDEXED BYを宣言し、SETで
      *索引指定した項目を読み取る。
      *TODO 04.1d:カウンター依存OCCURS n TO m TIMESを宣言。
      *カウンター変更でLENGTH OFが変わることを示す。
           DISPLAY 'LESSON,04.1'
           MOVE 0 TO WS-N
           DISPLAY 'REDEFINES,WRAP-LEN,' WS-N
           GOBACK.
