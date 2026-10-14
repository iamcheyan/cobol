      * Mutate a linkage item passed by reference or by content.
      * 中文：通过引用或内容传递修改链接项。
      * 日本語：参照渡しまたは値渡しでリンケージ項目を変更する。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADD-ONE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EDITED-AMOUNT PIC 9(9) VALUE ZERO.
       LINKAGE SECTION.
       COPY "AMOUNT-INTERFACE.CPY".
       PROCEDURE DIVISION USING AMOUNT-ARGUMENT.
       0000-ADD-ONE.
           ADD 1 TO AMOUNT-ARGUMENT
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-AMOUNT
           DISPLAY "CALLEE=AFTER ADD VALUE=" WS-EDITED-AMOUNT
           GOBACK.
