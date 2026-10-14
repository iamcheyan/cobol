      * 日本語：参照渡しまたは値渡しでリンケージ項
      * 目を変更する。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADD-ONE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EDITED-AMOUNT PIC 9(9) VALUE ZERO.
       LINKAGE SECTION.
       COPY "AMOUNT-INTERFACE.CPY".
      * 呼び出し元の契約に従って引数を受け取ります
      * 。
      * 加算はリンケージ項目に対して行われ、BY REFEREN
      * CEなら共有領域が変化します。
      * 編集項目を介して結果を表示し、呼び出し元へ
      * 戻ります。
       PROCEDURE DIVISION USING AMOUNT-ARGUMENT.
       0000-ADD-ONE.
           ADD 1 TO AMOUNT-ARGUMENT
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-AMOUNT
           DISPLAY "CALLEE=AFTER ADD VALUE=" WS-EDITED-AMOUNT
           GOBACK.
