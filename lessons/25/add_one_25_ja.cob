      * 引数の渡し方によってリンケージ項目への変更範囲が変わります。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADD-ONE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EDITED-AMOUNT PIC 9(9) VALUE ZERO.
       LINKAGE SECTION.
       COPY "AMOUNT-INTERFACE.CPY".
      * 呼び出し側が渡した引数をUSINGの契約に従って受け取ります。
      * 加算はリンケージ項目に対して行います。BY REFERENCEなら呼び出し側の値も変わります。
      * 編集項目で結果を表示し、GOBACKで呼び出し側へ戻ります。
       PROCEDURE DIVISION USING AMOUNT-ARGUMENT.
       0000-ADD-ONE.
           ADD 1 TO AMOUNT-ARGUMENT
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-AMOUNT
           DISPLAY "CALLEE=AFTER ADD VALUE=" WS-EDITED-AMOUNT
           GOBACK.
