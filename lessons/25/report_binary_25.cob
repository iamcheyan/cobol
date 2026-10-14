      * Read a binary full-word argument passed by value.
      * 中文：读取按值传递的二进制全字长参数。
      * 日本語：値渡しされたバイナリ全語長引数を読み取る。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. REPORT-BINARY.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EDITED-AMOUNT PIC 9(9) VALUE ZERO.
       LINKAGE SECTION.
       COPY "AMOUNT-INTERFACE.CPY".
       PROCEDURE DIVISION USING BY VALUE AMOUNT-ARGUMENT.
       0000-REPORT-VALUE.
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-AMOUNT
           DISPLAY "CALLEE=VALUE RECEIVED=" WS-EDITED-AMOUNT
           GOBACK.
