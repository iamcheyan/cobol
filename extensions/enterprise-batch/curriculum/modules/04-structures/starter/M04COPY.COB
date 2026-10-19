      *M04レッスン04.2雛形。ビルド可・未完了。
      *TODO段落を完成しWS-EXERCISES-DONEを'Y'に。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. M04COPY.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EXERCISES-DONE PIC X VALUE 'N'.
       PROCEDURE DIVISION.
       1000-MAIN.
           IF WS-EXERCISES-DONE NOT = 'Y'
               DISPLAY 'TODO,starter/M04COPY.COB is not finished'
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
      *TODO 04.2a：enterprise copybook（V1）をCOPYし、さらに
      *COPY REPLACINGでCUSTOMER-CLASSIFICATIONをPIC X(2)へ拡張。
      *TODO 04.2b：LENGTH OF V2 - LENGTH OF V1 = 1を示す。
      *TODO 04.2c：参照修飾でCUSTOMER-IDを取り出す。
           DISPLAY 'LESSON,04.2'
           GOBACK.
