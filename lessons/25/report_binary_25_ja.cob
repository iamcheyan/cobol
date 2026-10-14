      * 日本語：値渡しされたバイナリ全語長引数を読
      * み取る。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. REPORT-BINARY.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EDITED-AMOUNT PIC 9(9) VALUE ZERO.
       LINKAGE SECTION.
       COPY "AMOUNT-INTERFACE.CPY".
      * BY VALUEで渡された全語長整数を受け取ります。
      * 受け取った値を表示用フィールドへ移し、呼び
      * 出し元の値は変更しません。
      * 診断出力後、GOBACKで呼び出し元へ制御を返しま
      * す。
       PROCEDURE DIVISION USING BY VALUE AMOUNT-ARGUMENT.
       0000-REPORT-VALUE.
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-AMOUNT
           DISPLAY "CALLEE=VALUE RECEIVED=" WS-EDITED-AMOUNT
           GOBACK.
